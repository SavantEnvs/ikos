/*
 * mayhem/harnesses/ikos_fuzz_common.hpp — the front half shared by BOTH ikos fuzz harnesses.
 *
 * WHY THIS EXISTS (PR #1184 review, ethan42): the first integration fuzzed the two CLI binaries on a
 * mutated FILE. Every one of the 149 "defects" Mayhem reported was LLVM's *bitcode reader* calling
 * llvm::report_fatal_error on a corrupt bitcode header, with a stack that starts at
 * llvm::sys::PrintStackTrace inside the PREBUILT LLVM 14 (/opt/toolchains/llvm14 — a release build with
 * no debug info, so those frames can never be symbolized). Not ikos bugs, and untriageable.
 *
 * The fix is this common front half. Every input is:
 *   1. capped (an over-long module is a time sink, not a bug),
 *   2. parsed as LLVM IR *TEXT* with llvm::parseAssembly() — NEVER handed to the bitcode reader, which
 *      is where the report_fatal_error noise came from. A parse error is not a finding: return 0.
 *   3. run through llvm::verifyModule(). Only a VALID module reaches ikos.
 * From step 4 on, every crash is attributable: the frames are in ikos code (core/, ar/, analyzer/,
 * frontend/llvm/), which mayhem/build.sh compiles with $DEBUG_FLAGS (DWARF <= 3) so Mayhem can
 * symbolize them. LLVM's own frames still cannot be symbolized (prebuilt release libraries) — if a
 * crash bottoms out in LLVM, read the LLVM-FATAL / llvm:: marker below and treat it as an LLVM issue.
 *
 * No InitLLVM: that is what installs LLVM's signal handler + PrintStackTrace. We want ASan's report
 * (symbolized, with the ikos frames) and nothing else on top of it.
 */

#pragma once

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <memory>
#include <set>
#include <string>

#include <llvm/AsmParser/Parser.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Verifier.h>
#include <llvm/Support/ErrorHandling.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/Support/raw_ostream.h>

namespace ikos_fuzz {

/// \brief Largest input we accept, in bytes
///
/// Bounds the WORK rather than installing a timer (fleet rule: no alarm()/ITIMER_REAL; a
/// timer_create() bound would only be needed if bounding the work were impossible).
constexpr std::size_t MaxInputSize = 64 * 1024;

/// \brief Largest module we hand to ikos, in LLVM instructions
///
/// A 64 KiB text module can still describe a function with tens of thousands of instructions, and the
/// abstract-interpretation fixpoint is superlinear in that. Cap it so a single input cannot take
/// minutes. Far above every committed seed (the largest, prover-test-29.ll at the 8 KiB cap, has
/// ~150 instructions), so the corpus is never touched by it.
constexpr std::size_t MaxInstructions = 20000;

/// \brief True while llvm::parseAssembly() is on the stack
///
/// See llvm_fatal_handler().
inline bool& in_llvm_parse() {
  static thread_local bool flag = false;
  return flag;
}

/// \brief Thrown out of llvm::report_fatal_error() while parsing
struct LLVMParseFatalError {
  std::string reason;
};

/// \brief What llvm::report_fatal_error() does in this process
///
/// LLVM answers a malformed .ll construct in two very different ways. Most are SMDiagnostic parse
/// errors, which parseAssembly() returns cleanly. A handful call llvm::report_fatal_error() from
/// deep inside the parser instead — llvm::DataLayout::reset() on a bad `target datalayout` string is
/// the one a fuzzer finds in seconds ("not a number, or does not fit in an unsigned int"). That is
/// an LLVM input-validation quirk, not an ikos defect, and its stack is entirely inside the prebuilt
/// LLVM 14 where nothing symbolizes — the exact class of unusable report this rework exists to kill.
/// So while the parser is running we turn it into a C++ exception that parse_and_verify() catches
/// and answers with "not valid IR" (report_fatal_error is [[noreturn]], so an exception is the only
/// way back; the half-built Module leaks, and LLVMContextImpl's destructor frees it when the
/// per-input context goes away).
///
/// ANYWHERE ELSE — i.e. once a VERIFIED module is being transformed or analysed by ikos — a fatal
/// error is real news: we print a greppable marker and crash, so triage can tell an LLVM-side fatal
/// error apart from an ikos defect at a glance.
inline void llvm_fatal_handler(void* /*user_data*/,
                               const char* reason,
                               bool /*gen_crash_diag*/) {
  const char* msg = reason != nullptr ? reason : "<null>";
  if (in_llvm_parse()) {
    throw LLVMParseFatalError{std::string(msg)};
  }
  std::fprintf(stderr,
               "LLVM-FATAL: llvm::report_fatal_error on a VERIFIED module: %s\n",
               msg);
  std::fflush(stderr);
  std::abort();
}

/// \brief Install the process-wide LLVM error handler (call once, from LLVMFuzzerInitialize)
inline void install_error_handlers() {
  llvm::install_fatal_error_handler(&llvm_fatal_handler, nullptr);
}

/// \brief The datalayout every input is given
///
/// x86_64 Linux — what the bundled clang 14 puts in the committed seeds.
constexpr const char* CanonicalDataLayout =
    "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"";

/// \brief Characters llvm::LLLexer skips between tokens (embedded NULs included — it treats them as
/// whitespace, which is why a line-oriented scan is not good enough here)
inline bool is_ll_space(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' || c == '\v' || c == '\0';
}

/// \brief Blank every `target datalayout = "..."` in the input and prepend the canonical one
///
/// llvm::LLParser::parseTargetDefinition() hands the datalayout string straight to
/// llvm::DataLayout::reset(), which answers a malformed specifier with llvm::report_fatal_error().
/// The handler below turns that into an exception so it is not a crash, but the unwind runs through
/// LLVM frames compiled -fno-exceptions, which have no cleanups — so every such input leaks the
/// half-built Module (~6.6 KB, measured with LeakSanitizer). A fuzzer edits the datalayout string
/// constantly, so that adds up to hundreds of MB an hour and would eventually trip Mayhem's RSS
/// limit. Neutralizing the construct before the parser sees it removes the whole class: the exception
/// path stays as a correctness backstop for the rare spellings this misses (a `;` comment between the
/// two keywords) rather than as the normal case.
///
/// The scan is token-level, not line-level, precisely because LLVM's lexer does not care about lines
/// and treats NUL as whitespace. The cost is that a fuzzer cannot explore alternative datalayouts —
/// ikos does read one, through ar::Bundle::data_layout() — which is a small and bounded loss.
inline std::string normalize_datalayout(const std::uint8_t* data, std::size_t size) {
  static const std::string kKeyword = "datalayout";
  static const std::string kTarget = "target";

  std::string text(reinterpret_cast< const char* >(data), size);
  std::size_t pos = 0;
  while ((pos = text.find(kKeyword, pos)) != std::string::npos) {
    std::size_t after = pos + kKeyword.size();

    // Backwards: whitespace, then the keyword `target` as a whole token.
    std::size_t before = pos;
    while (before > 0 && is_ll_space(text[before - 1])) {
      --before;
    }
    bool matched = before >= kTarget.size() &&
                   text.compare(before - kTarget.size(), kTarget.size(), kTarget) == 0;
    std::size_t start = matched ? before - kTarget.size() : 0;
    if (matched && start > 0) {
      const char prev = text[start - 1];
      matched = std::isalnum(static_cast< unsigned char >(prev)) == 0 && prev != '_' &&
                prev != '.' && prev != '$' && prev != '%' && prev != '@' && prev != '!';
    }

    // Forwards: `= "..."`. Anything else never reaches DataLayout::reset().
    if (matched) {
      std::size_t i = after;
      while (i < text.size() && is_ll_space(text[i])) {
        ++i;
      }
      if (i < text.size() && text[i] == '=') {
        ++i;
        while (i < text.size() && is_ll_space(text[i])) {
          ++i;
        }
        if (i < text.size() && text[i] == '"') {
          const std::size_t close = text.find('"', i + 1);
          if (close != std::string::npos) {
            // Blank in place: same length, so no offset bookkeeping.
            std::fill(text.begin() + static_cast< std::ptrdiff_t >(start),
                      text.begin() + static_cast< std::ptrdiff_t >(close + 1),
                      ' ');
            pos = close + 1;
            continue;
          }
        }
      }
    }
    pos = after;
  }

  return std::string(CanonicalDataLayout) + "\n" + text;
}

/// \brief The only `@llvm.*` intrinsics an input may name
///
/// LLVM 14's .ll parser auto-upgrades intrinsic declarations at the end of the parse
/// (LLParser::validateEndOfModule -> UpgradeCallsToIntrinsic -> Intrinsic::getName), and that
/// remangling path SEGVs on a malformed OVERLOADED intrinsic name — `@llvm.lifetime.start.p0i8main`
/// is enough, and a fuzzer types that in about two minutes. The stack is entirely inside the
/// prebuilt LLVM 14 (getMangledTypeStr / UpgradeIntrinsicFunction); it is an LLVM defect, not an
/// ikos one, and it cannot be symbolized — the same worthless report this rework exists to remove.
/// Unlike the report_fatal_error family it is a hard signal, so there is nothing to catch: the only
/// defence is not to feed LLVM such a name.
///
/// The list is therefore an allowlist, not a denylist, and it is exactly the set
/// frontend/llvm/src/import/ recognises (Intrinsic::dbg_*, lifetime_*, memcpy/memmove/memset,
/// va*, trap, stack{save,restore}, prefetch, eh_typeid_for) in the manglings clang emits for
/// x86_64 — so nothing ikos actually models is lost, while every unknown `@llvm.` spelling is
/// rejected as "not valid IR".
inline bool intrinsic_is_known(const std::string& name) {
  static const std::set< std::string > known = {
      "llvm.dbg.declare", "llvm.dbg.value", "llvm.dbg.label", "llvm.dbg.addr",
      "llvm.lifetime.start.p0i8", "llvm.lifetime.end.p0i8",
      "llvm.memcpy.p0i8.p0i8.i64", "llvm.memcpy.p0i8.p0i8.i32",
      "llvm.memmove.p0i8.p0i8.i64", "llvm.memmove.p0i8.p0i8.i32",
      "llvm.memset.p0i8.i64", "llvm.memset.p0i8.i32",
      "llvm.va_start", "llvm.va_end", "llvm.va_copy",
      "llvm.trap", "llvm.stacksave", "llvm.stackrestore",
      "llvm.prefetch.p0i8", "llvm.eh.typeid.for",
  };
  return known.find(name) != known.end();
}

/// \brief True if every `@llvm.…` name in the text is on the allowlist above
inline bool intrinsic_names_are_known(const std::string& text) {
  static const std::string prefix = "@llvm.";
  std::size_t pos = 0;
  while ((pos = text.find(prefix, pos)) != std::string::npos) {
    std::size_t begin = pos + 1; // skip '@'
    std::size_t end = begin;
    while (end < text.size() &&
           (std::isalnum(static_cast< unsigned char >(text[end])) != 0 || text[end] == '.' ||
            text[end] == '_')) {
      ++end;
    }
    if (!intrinsic_is_known(text.substr(begin, end - begin))) {
      return false;
    }
    pos = end;
  }
  return true;
}

/// \brief Parse `data` as LLVM IR text and verify it
///
/// \returns a VALID module, or nullptr if the input is not valid LLVM IR text (not a finding)
inline std::unique_ptr< llvm::Module > parse_and_verify(const std::uint8_t* data,
                                                        std::size_t size,
                                                        llvm::LLVMContext& ctx) {
  if (size == 0 || size > MaxInputSize) {
    return nullptr;
  }

  // std::string guarantees a NUL at data()[size], which the .ll lexer requires of its MemoryBufferRef.
  const std::string text = normalize_datalayout(data, size);
  llvm::MemoryBufferRef buffer(text, "fuzz.ll");

  if (!intrinsic_names_are_known(text)) {
    return nullptr; // an `@llvm.` name LLVM 14's auto-upgrader would crash on — see above
  }

  llvm::SMDiagnostic err;
  std::unique_ptr< llvm::Module > module;
  in_llvm_parse() = true;
  try {
    module = llvm::parseAssembly(buffer, err, ctx);
  } catch (const LLVMParseFatalError&) {
    in_llvm_parse() = false;
    return nullptr; // LLVM's own parser rejected it fatally — see llvm_fatal_handler()
  }
  in_llvm_parse() = false;
  if (!module) {
    return nullptr; // not LLVM IR text — the overwhelmingly common case, and NOT a bug
  }

  // Only a well-formed module goes to ikos. ikos's own tools bail out here too (both CLIs run the
  // verifier immediately after parsing and exit non-zero on a broken module), so analysing one would
  // be testing a contract ikos never promises.
  if (llvm::verifyModule(*module, &llvm::nulls())) {
    return nullptr;
  }

  std::size_t instructions = 0;
  for (const llvm::Function& fun : *module) {
    for (const llvm::BasicBlock& bb : fun) {
      instructions += bb.size();
      if (instructions > MaxInstructions) {
        return nullptr;
      }
    }
  }

  return module;
}

} // end namespace ikos_fuzz
