/*
 * mayhem/harnesses/ikos_pp_fuzzer.cpp — in-process libFuzzer harness for ikos's LLVM pass pipeline
 * (Mayhem target `ikos-pp`; binary /mayhem/ikos-pp, reproducer /mayhem/ikos-pp-standalone).
 *
 * WHAT IT FUZZES
 *   ikos's OWN LLVM passes, in frontend/llvm/src/pass/ (libikos-pp):
 *     lower_cst_expr, lower_select, mark_internal_inline, name_values, remove_printf_calls,
 *     remove_unreachable_blocks
 *   driven by the exact pass pipeline frontend/llvm/src/ikos_pp.cpp builds for `-opt=aggressive`
 *   `-inline-all` (the ikos passes interleaved with the LLVM transforms that feed them), plus the
 *   name-values pass, which the `aggressive` pipeline does not schedule but `ikos-pp -opt=custom
 *   -name-values` does — running it here is the only way this ikos pass gets fuzzed at all.
 *
 * INPUT: LLVM IR *text* (see mayhem/harnesses/ikos_fuzz_common.hpp for why it is never bitcode).
 * Parsed and verified there; only a VALID module reaches the pipeline.
 *
 * ORACLE (this is a bug detector, not just a crash detector): after the pipeline runs, the module is
 * verified AGAIN. A pass that turns a valid module into an invalid one is a real ikos-pp defect —
 * ikos-pp itself schedules llvm::createVerifierPass() for exactly this reason, but that path ends in
 * llvm::report_fatal_error() inside the prebuilt LLVM (unsymbolizable). We call llvm::verifyModule()
 * directly instead and abort() with the verifier's own message, so the report names the broken thing.
 *
 * Also a finding: any C++ exception escaping the pipeline (ikos's passes are not supposed to throw;
 * the rejection path for unsupported input is in the AR importer, not here) and, of course, any
 * ASan/UBSan report or failed ikos_assert (mayhem/build.sh builds the fuzz tree with
 * -DENABLE_ASSERTIONS=ON, which is ikos's own switch for keeping ikos_assert live in a Release build).
 */

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <exception>
#include <memory>
#include <string>

#include <llvm/ADT/StringSet.h>
#include <llvm/IR/Attributes.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/LegacyPassManager.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Verifier.h>
#include <llvm/InitializePasses.h>
#include <llvm/PassRegistry.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Transforms/IPO.h>
#include <llvm/Transforms/IPO/AlwaysInliner.h>
#include <llvm/Transforms/IPO/Internalize.h>
#include <llvm/Transforms/InstCombine/InstCombine.h>
#include <llvm/Transforms/Scalar.h>
#include <llvm/Transforms/Scalar/GVN.h>
#include <llvm/Transforms/Utils.h>
#include <llvm/Transforms/Utils/UnifyFunctionExitNodes.h>

#include <ikos/frontend/llvm/pass.hpp>

#include "ikos_fuzz_common.hpp"

namespace ikos_pp = ikos::frontend::pass;

namespace {

/// \brief True if any defined function carries `noinline`
///
/// See build_aggressive_pipeline() and
/// mayhem/ikos-pp/known-findings/mark-internal-inline-noinline-conflict/.
bool has_noinline_function(const llvm::Module& module) {
  for (const llvm::Function& fun : module) {
    if (!fun.isDeclaration() && fun.hasFnAttribute(llvm::Attribute::NoInline)) {
      return true;
    }
  }
  return false;
}

/// \brief Build the `ikos-pp -opt=aggressive -inline-all` pipeline
///
/// Mirrors the Aggressive branch of main() in frontend/llvm/src/ikos_pp.cpp, entry point "main"
/// (the default when -entry-points is not given). Three deliberate differences, all documented: the
/// name-values pass is added, the -inline-all leg is skipped for modules that trip a known ikos
/// defect, and the terminating llvm::createVerifierPass() is replaced by an explicit
/// llvm::verifyModule() in the caller.
void build_aggressive_pipeline(llvm::legacy::PassManager& pm, const llvm::Module& module) {
  // Turn all functions internal so that we can apply some global optimizations (opt -internalize)
  llvm::StringSet<> exclude_set;
  exclude_set.insert("main");
  pm.add(llvm::createInternalizePass([=](const llvm::GlobalValue& gv) {
    return exclude_set.find(gv.getName()) != exclude_set.end();
  }));

  // Name all unnamed values (ikos-pp -name-values) — an ikos pass the aggressive pipeline itself
  // never schedules; running it here is what puts frontend/llvm/src/pass/name_values.cpp under test.
  pm.add(ikos_pp::create_name_values_pass());

  pm.add(llvm::createGlobalDCEPass());
  pm.add(ikos_pp::create_remove_unreachable_blocks_pass());
  pm.add(llvm::createGlobalOptimizerPass());
  pm.add(llvm::createPromoteMemoryToRegisterPass());
  pm.add(llvm::createCFGSimplificationPass());
  pm.add(llvm::createSROAPass());
  pm.add(llvm::createGVNPass());
  pm.add(llvm::createInstructionCombiningPass());
  pm.add(llvm::createGlobalDCEPass());
  pm.add(llvm::createCFGSimplificationPass());
  pm.add(llvm::createJumpThreadingPass());
  pm.add(llvm::createSCCPPass());
  pm.add(llvm::createDeadCodeEliminationPass());
  pm.add(llvm::createLowerInvokePass());
  pm.add(llvm::createCFGSimplificationPass());

  // -inline-all. SKIPPED for a module that already contains a `noinline` function: ikos's
  // mark_internal_inline pass adds `alwaysinline` to every internal definition without checking for
  // `noinline`, and the two attributes are mutually exclusive — so the pass hands LLVM a module its
  // own verifier rejects. That is a REAL ikos defect, reproduced and written up in
  // mayhem/ikos-pp/known-findings/mark-internal-inline-noinline-conflict/ (the stock CLI dies the
  // same way: `ikos-pp -opt=aggressive -inline-all` -> "LLVM ERROR: Broken function found").
  // Suppressing that one known input class here is what keeps the target fuzzing the other thirty
  // passes instead of rediscovering this single bug on every mutation that types `noinline`. Remove
  // the guard once the pass is fixed.
  if (!has_noinline_function(module)) {
    pm.add(ikos_pp::create_mark_internal_inline_pass());
    pm.add(llvm::createAlwaysInlinerLegacyPass());
    pm.add(llvm::createGlobalDCEPass());
  }

  pm.add(ikos_pp::create_remove_unreachable_blocks_pass());
  pm.add(llvm::createDeadCodeEliminationPass());
  pm.add(llvm::createLoopSimplifyPass());
  pm.add(llvm::createCFGSimplificationPass());
  pm.add(llvm::createLCSSAPass());
  pm.add(llvm::createLICMPass());
  pm.add(llvm::createPromoteMemoryToRegisterPass());
  pm.add(llvm::createLoopDeletionPass());
  pm.add(llvm::createCFGSimplificationPass());
  pm.add(llvm::createGlobalDCEPass());
  pm.add(llvm::createDeadCodeEliminationPass());
  pm.add(ikos_pp::create_remove_unreachable_blocks_pass());
  pm.add(llvm::createLowerSwitchPass());
  pm.add(llvm::createLowerAtomicPass());
  pm.add(ikos_pp::create_lower_cst_expr_pass());
  pm.add(llvm::createDeadCodeEliminationPass());
  pm.add(ikos_pp::create_remove_printf_calls_pass());
  pm.add(llvm::createDeadCodeEliminationPass());
  pm.add(llvm::createGlobalDCEPass());
  pm.add(ikos_pp::create_lower_select_pass());
  pm.add(llvm::createUnifyFunctionExitNodesPass());
}

} // end anonymous namespace

extern "C" int LLVMFuzzerInitialize(int* /*argc*/, char*** /*argv*/) {
  ikos_fuzz::install_error_handlers();

  // Same registry initialization as main() in frontend/llvm/src/ikos_pp.cpp, minus the passes the
  // aggressive pipeline cannot reach. Process-wide, so it happens exactly once.
  llvm::PassRegistry& registry = *llvm::PassRegistry::getPassRegistry();
  llvm::initializeCore(registry);
  llvm::initializeScalarOpts(registry);
  llvm::initializeVectorization(registry);
  llvm::initializeIPO(registry);
  llvm::initializeAnalysis(registry);
  llvm::initializeTransformUtils(registry);
  llvm::initializeInstCombine(registry);
  llvm::initializeAggressiveInstCombine(registry);
  llvm::initializeTarget(registry);
  ikos_pp::initialize_ikos_passes(registry);
  return 0;
}

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
  // A fresh context per input: llvm::LLVMContext interns every type, constant and metadata node it
  // ever sees, so a shared one would grow without bound across iterations.
  llvm::LLVMContext context;

  std::unique_ptr< llvm::Module > module =
      ikos_fuzz::parse_and_verify(data, size, context);
  if (!module) {
    return 0; // not valid LLVM IR text — not a finding
  }

  // ---- from here on, a crash is an ikos-pp defect ----
  try {
    llvm::legacy::PassManager pass_manager;
    build_aggressive_pipeline(pass_manager, *module);
    pass_manager.run(*module);
  } catch (const std::exception& err) {
    std::fprintf(stderr,
                 "ikos-pp-fuzz: ikos LLVM pass pipeline threw std::exception: %s\n",
                 err.what());
    std::fflush(stderr);
    std::abort();
  } catch (...) {
    std::fprintf(stderr,
                 "ikos-pp-fuzz: ikos LLVM pass pipeline threw an unknown exception\n");
    std::fflush(stderr);
    std::abort();
  }

  // ---- the oracle: the pipeline must not break a module that was valid going in ----
  std::string report;
  llvm::raw_string_ostream report_stream(report);
  if (llvm::verifyModule(*module, &report_stream)) {
    report_stream.flush();
    std::fprintf(stderr,
                 "ikos-pp-fuzz: the ikos-pp pass pipeline turned a VALID module into a broken one; "
                 "llvm::verifyModule says: %s\n",
                 report.c_str());
    std::fflush(stderr);
    std::abort();
  }

  return 0;
}
