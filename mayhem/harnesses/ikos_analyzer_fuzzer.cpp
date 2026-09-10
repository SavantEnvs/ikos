/*
 * mayhem/harnesses/ikos_analyzer_fuzzer.cpp — in-process libFuzzer harness for ikos's ANALYSIS
 * pipeline (Mayhem target `ikos-analyzer`; binary /mayhem/ikos-analyzer, reproducer
 * /mayhem/ikos-analyzer-standalone).
 *
 * WHAT IT FUZZES — the whole of analyzer/src/ikos_analyzer.cpp's main(), in process, minus the
 * command line and the on-disk database:
 *   1. the `ikos-pp -opt=basic` pass pipeline, because that is what the production `ikos` driver runs
 *      before the analyzer (analyzer/python/ikos/args.py: default_opt_level = 'basic'), so the
 *      analyzer never sees un-preprocessed IR in the field either;
 *   2. llvm_to_ar::Importer (frontend/llvm/src/import/*.cpp) — LLVM module -> ikos AR bundle;
 *   3. ar::TypeVerifier + ar::FrontendVerifier, then the AR passes the CLI runs (simplify-cfg,
 *      simplify-upcast-comparison);
 *   4. the analysis itself: liveness, widening hints, and the interprocedural sequential value
 *      analysis over the interval domain with the boa/dbz/nullity/uva/prover checkers — i.e. the
 *      abstract-interpretation fixpoint in core/ plus the checkers in analyzer/src/checker/.
 *
 * INPUT: LLVM IR *text*, parsed and verified by mayhem/harnesses/ikos_fuzz_common.hpp (read its
 * header for why the bitcode reader is never involved). Only a VALID module reaches ikos.
 *
 * WHAT COUNTS AS A FINDING: an ASan/UBSan report, a failed ikos_assert / ikos_unreachable
 * (mayhem/build.sh configures the fuzz tree with ikos's own -DENABLE_ASSERTIONS=ON, so those stay
 * live in the Release build — an assertion failure inside an abstract domain is precisely the bug
 * class this target exists for), or an unexpected C++ exception. NOT a finding, because the ikos
 * command line treats each of them as a clean "I can't analyse this input" failure and prints it as
 * an `error:` (see the catch blocks at the end of main() in analyzer/src/ikos_analyzer.cpp):
 *   - llvm_to_ar::ImportError / TypeDebugInfoMismatch — unsupported instruction, type or debug info
 *   - analyzer::Exception and its subclasses (LogicError, ArgumentError, FrontendError, sqlite::DbError)
 *   - std::bad_alloc — an out-of-memory on a pathological module is a resource limit, not a defect
 *
 * BOUNDS: work, not timers (fleet rule — no alarm()/ITIMER_REAL). The input size and instruction
 * count are capped in ikos_fuzz_common.hpp; here the entry-point count and the widening/narrowing
 * budget are capped too, so a single input stays in the tens of milliseconds.
 */

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <exception>
#include <memory>
#include <new>
#include <ostream>
#include <string>
#include <vector>

#include <boost/filesystem.hpp>

#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/LegacyPassManager.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Verifier.h>
#include <llvm/InitializePasses.h>
#include <llvm/PassRegistry.h>
#include <llvm/Support/CommandLine.h>
#include <llvm/Transforms/IPO.h>
#include <llvm/Transforms/Scalar.h>
#include <llvm/Transforms/Utils.h>
#include <llvm/Transforms/Utils/UnifyFunctionExitNodes.h>

#include <ikos/ar/pass/simplify_cfg.hpp>
#include <ikos/ar/pass/simplify_upcast_comparison.hpp>
#include <ikos/ar/semantic/bundle.hpp>
#include <ikos/ar/semantic/context.hpp>
#include <ikos/ar/semantic/function.hpp>
#include <ikos/ar/verify/frontend.hpp>
#include <ikos/ar/verify/type.hpp>

#include <ikos/frontend/llvm/import.hpp>
#include <ikos/frontend/llvm/pass.hpp>

#include <ikos/analyzer/analysis/call_context.hpp>
#include <ikos/analyzer/analysis/context.hpp>
#include <ikos/analyzer/analysis/fixpoint_parameters.hpp>
#include <ikos/analyzer/analysis/hardware_addresses.hpp>
#include <ikos/analyzer/analysis/literal.hpp>
#include <ikos/analyzer/analysis/liveness.hpp>
#include <ikos/analyzer/analysis/memory_location.hpp>
#include <ikos/analyzer/analysis/option.hpp>
#include <ikos/analyzer/analysis/value/interprocedural/sequential/analysis.hpp>
#include <ikos/analyzer/analysis/variable.hpp>
#include <ikos/analyzer/analysis/widening_hint.hpp>
#include <ikos/analyzer/checker/name.hpp>
#include <ikos/analyzer/database/output.hpp>
#include <ikos/analyzer/database/sqlite.hpp>
#include <ikos/analyzer/exception.hpp>
#include <ikos/analyzer/util/log.hpp>

#include "ikos_fuzz_common.hpp"

namespace ar = ikos::ar;
namespace llvm_to_ar = ikos::frontend::import;
namespace ikos_pp = ikos::frontend::pass;
namespace analyzer = ikos::analyzer;

namespace {

/// \brief Largest number of entry points we analyse
///
/// The analysis is run once per entry point, so an input declaring fifty functions would cost fifty
/// fixpoints. Production analyses one (`main`); this keeps the tail bounded without hiding the
/// multi-entry-point code path.
constexpr std::size_t MaxEntryPoints = 8;

/// \brief Number of loop iterations before widening / of narrowing iterations
///
/// The ikos-analyzer defaults (-widening-delay=1, -widening-period=1) with a FIXED narrowing budget
/// instead of "narrow until convergence" (-narrowing-iterations=1): the fixpoint still widens and
/// narrows — the code paths we want — but cannot iterate for minutes on an adversarial loop nest.
constexpr unsigned WideningDelay = 1;
constexpr unsigned WideningPeriod = 1;
constexpr unsigned NarrowingIterations = 1;

/// \brief Sink for the AR verifiers' diagnostics
///
/// The CLI prints them to std::cerr; a fuzz target wants the crash report and nothing else. An
/// ostream built on a null streambuf discards everything written to it.
std::ostream& discard() {
  static std::ostream stream(nullptr);
  return stream;
}

/// \brief Empty stand-ins for the two `-hardware-addresses*` command-line options
///
/// analyzer::HardwareAddresses has exactly one constructor and it takes the llvm::cl objects. We
/// never call llvm::cl::ParseCommandLineOptions(), so these keep their (empty) default values and no
/// hardware address range is declared — the ikos-analyzer default.
llvm::cl::list< std::string > FuzzHardwareAddresses("ikos-fuzz-hardware-addresses",
                                                    llvm::cl::Hidden);
llvm::cl::opt< std::string > FuzzHardwareAddressesFile(
    "ikos-fuzz-hardware-addresses-file", llvm::cl::Hidden);

/// \brief Build the `ikos-pp -opt=basic` pipeline
///
/// Mirrors the Basic branch of main() in frontend/llvm/src/ikos_pp.cpp — the preprocessing the
/// production `ikos` driver applies before handing a module to ikos-analyzer.
void build_basic_pipeline(llvm::legacy::PassManager& pm) {
  pm.add(llvm::createPromoteMemoryToRegisterPass());
  pm.add(llvm::createGlobalDCEPass());
  pm.add(llvm::createDeadCodeEliminationPass());
  pm.add(llvm::createLowerSwitchPass());
  pm.add(ikos_pp::create_remove_unreachable_blocks_pass());
  pm.add(llvm::createLowerAtomicPass());
  pm.add(ikos_pp::create_lower_cst_expr_pass());
  pm.add(llvm::createDeadCodeEliminationPass());
  pm.add(ikos_pp::create_lower_select_pass());
  pm.add(llvm::createUnifyFunctionExitNodesPass());
}

/// \brief Entry points: `main` if it is defined, otherwise every defined function
std::vector< ar::Function* > entry_points(ar::Bundle* bundle) {
  std::vector< ar::Function* > result;
  ar::Function* main_fun = bundle->function_or_null("main");
  if (main_fun != nullptr && main_fun->is_definition()) {
    result.push_back(main_fun);
    return result;
  }
  for (auto it = bundle->function_begin(), et = bundle->function_end(); it != et; ++it) {
    if ((*it)->is_definition()) {
      result.push_back(*it);
      if (result.size() >= MaxEntryPoints) {
        break;
      }
    }
  }
  return result;
}

analyzer::AnalysisOptions make_analysis_options(ar::Bundle* bundle) {
  return analyzer::AnalysisOptions{
      .analyses = {analyzer::CheckerName::BufferOverflow,
                   analyzer::CheckerName::DivisionByZero,
                   analyzer::CheckerName::NullPointerDereference,
                   analyzer::CheckerName::UninitializedVariable,
                   analyzer::CheckerName::AssertProver},
      .entry_points = entry_points(bundle),
      .no_init_globals = {},
      .machine_int_domain = analyzer::MachineIntDomainOption::Interval,
      .procedural = analyzer::Procedural::Interprocedural,
      .num_threads = 1,
      .widening_strategy = analyzer::WideningStrategy::Widen,
      .narrowing_strategy = analyzer::NarrowingStrategy::Narrow,
      .widening_delay = WideningDelay,
      .widening_delay_functions = {},
      .widening_period = WideningPeriod,
      .narrowing_iterations = boost::optional< unsigned >(NarrowingIterations),
      .use_liveness = true,
      .use_pointer = true,
      .use_widening_hints = true,
      .use_partitioning_domain = false,
      .use_fixpoint_cache = true,
      .use_checks = true,
      .trace_ar_statements = false,
      .globals_init_policy = analyzer::GlobalsInitPolicy::SkipBigArrays,
      .progress = analyzer::ProgressOption::None,
      .display_invariants = analyzer::DisplayOption::None,
      .display_checks = analyzer::DisplayOption::None,
      .hardware_addresses = {bundle, FuzzHardwareAddresses, FuzzHardwareAddressesFile},
      .argc = boost::none,
  };
}

/// \brief The analysis, on an already parsed + verified module
void analyze(llvm::Module& module) {
  // In-memory result database: no file is ever created, so nothing is left behind between iterations
  // and two concurrent Mayhem executions cannot collide (the CLI writes a sqlite file instead).
  analyzer::sqlite::DbConnection db(":memory:");
  db.set_journal_mode(analyzer::sqlite::JournalMode::Off);
  db.set_synchronous_flag(analyzer::sqlite::SynchronousFlag::Off);
  analyzer::OutputDatabase output_db(db);

  // LLVM -> AR. ImportError (incl. TypeDebugInfoMismatch) means "ikos does not support this input".
  ar::Context ar_context;
  llvm_to_ar::Importer importer(ar_context);
  ar::Bundle* bundle =
      importer.import(module,
                      llvm_to_ar::Importer::EnableLibIkos |
                          llvm_to_ar::Importer::EnableLibc |
                          llvm_to_ar::Importer::EnableLibcpp);

  // The CLI exits 7 / 8 here rather than analysing; so do we.
  if (!ar::TypeVerifier(/*all = */ true).verify(bundle, discard())) {
    return;
  }
  if (!ar::FrontendVerifier(/*all = */ true).verify(bundle, discard())) {
    return;
  }

  ar::SimplifyCFGPass().run(bundle);
  ar::SimplifyUpcastComparisonPass().run(bundle);

  analyzer::AnalysisOptions opts = make_analysis_options(bundle);
  if (opts.entry_points.empty()) {
    return; // nothing to analyse
  }
  opts.save(output_db.settings);

  analyzer::MemoryFactory mem_factory;
  analyzer::VariableFactory var_factory(bundle);
  analyzer::LiteralFactory lit_factory(var_factory, bundle->data_layout());
  analyzer::CallContextFactory call_context_factory;
  analyzer::FixpointParameters fixpoint_parameters(opts);

  analyzer::Context ctx(bundle,
                        opts,
                        boost::filesystem::path("."),
                        output_db,
                        mem_factory,
                        var_factory,
                        lit_factory,
                        call_context_factory,
                        fixpoint_parameters);

  analyzer::LivenessAnalysis liveness(ctx);
  liveness.run();
  ctx.liveness = &liveness;

  analyzer::WideningHintAnalysis widening_hint(ctx);
  widening_hint.run();

  // The interprocedural sequential value analysis — the ikos-analyzer default (-proc=inter, -j=1).
  // It runs the fixpoint and the checkers, writing results into the in-memory database.
  analyzer::value::interprocedural::sequential::Analysis(ctx).run();
}

} // end anonymous namespace

extern "C" int LLVMFuzzerInitialize(int* /*argc*/, char*** /*argv*/) {
  ikos_fuzz::install_error_handlers();

  // ikos-analyzer itself never prints below Warning; silence it completely so the fuzzer's output is
  // the crash report and nothing else.
  analyzer::log::Level = analyzer::LogLevel::None;

  llvm::PassRegistry& registry = *llvm::PassRegistry::getPassRegistry();
  llvm::initializeCore(registry);
  llvm::initializeScalarOpts(registry);
  llvm::initializeIPO(registry);
  llvm::initializeAnalysis(registry);
  llvm::initializeTransformUtils(registry);
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

  // Preprocess exactly as the production driver does. A pipeline that BREAKS the module is an
  // ikos-pp defect, and the `ikos-pp` target is the one that reports it (with the verifier message);
  // here we just decline to analyse IR the preprocessor already invalidated.
  try {
    llvm::legacy::PassManager pass_manager;
    build_basic_pipeline(pass_manager);
    pass_manager.run(*module);
  } catch (const std::exception& err) {
    std::fprintf(stderr,
                 "ikos-analyzer-fuzz: the ikos-pp basic pipeline threw std::exception: %s\n",
                 err.what());
    std::fflush(stderr);
    std::abort();
  }
  if (llvm::verifyModule(*module, &llvm::nulls())) {
    return 0;
  }

  // ---- from here on, a crash is an ikos defect ----
  try {
    analyze(*module);
  } catch (const llvm_to_ar::ImportError&) {
    return 0; // unsupported instruction / type / debug info — the CLI's exit 5
  } catch (const analyzer::Exception&) {
    return 0; // LogicError / ArgumentError / FrontendError / sqlite::DbError — the CLI's exit 1 or 9
  } catch (const std::bad_alloc&) {
    return 0; // a resource limit on a pathological module, not a defect
  } catch (const std::exception& err) {
    std::fprintf(stderr,
                 "ikos-analyzer-fuzz: the analysis threw an unexpected std::exception (%s)\n",
                 err.what());
    std::fflush(stderr);
    std::abort();
  } catch (...) {
    std::fprintf(stderr, "ikos-analyzer-fuzz: the analysis threw an unknown exception\n");
    std::fflush(stderr);
    std::abort();
  }

  return 0;
}
