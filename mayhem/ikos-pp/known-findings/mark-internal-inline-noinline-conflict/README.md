# ikos-pp: `mark-internal-inline` marks a `noinline` function `alwaysinline`, producing invalid IR

Found by the `ikos-pp` harness (`mayhem/harnesses/ikos_pp_fuzzer.cpp`) on the very first seed pass,
2026-09-14. Reproduced against the stock command-line tool, so it is not a harness artefact.

## Cause

`frontend/llvm/src/pass/mark_internal_inline.cpp`:

```cpp
for (Function& f : m) {
  if (!f.isDeclaration() && f.hasLocalLinkage()) {
    f.addFnAttr(Attribute::AlwaysInline);
    change = true;
  }
}
```

The pass adds `alwaysinline` to every internal definition without looking at what is already there.
`noinline` and `alwaysinline` are mutually exclusive in LLVM IR, so any module with an internal
`noinline` function comes out of the pass invalid. When the function's address escapes, the
always-inliner scheduled right after cannot inline it away, and the contradiction survives to
`ikos-pp`'s own terminating `llvm::createVerifierPass()`.

## Impact

`ikos-pp -opt=aggressive -inline-all` — and therefore `ikos --opt=aggressive --inline-all` — aborts
with `LLVM ERROR: Broken function found, compilation aborted!` on any such program instead of
analysing it. Clang emits `noinline` for `__attribute__((noinline))`, for `-O0` without
`-disable-O0-optnone` (via `optnone`, which implies `noinline`), and for anything built
`-fno-inline`, so this is reachable from ordinary user code, not only from fuzzer output. It is a
denial of analysis, not a memory-safety defect: the abort is LLVM's, on a module ikos itself built.

## Reproduce

```
$ ikos-pp -opt=aggressive -inline-all -entry-points=main -o=/tmp/out.bc reproducer.ll
Attributes 'noinline and alwaysinline' are incompatible!
void ()* @helper
in function helper
LLVM ERROR: Broken function found, compilation aborted!
```

`mayhem/build.sh` no longer builds the `ikos-pp` CLI (`/mayhem/ikos-pp` is the fuzz harness), so
build it explicitly first:
`cmake --build /mayhem/mayhem-build/fuzz --target ikos-pp` → `mayhem-build/fuzz/frontend/llvm/ikos-pp`.

Inside the harness the same input is caught by the post-pipeline `llvm::verifyModule()` oracle, which
aborts with `ikos-pp-fuzz: the ikos-pp pass pipeline turned a VALID module into a broken one`. The
harness deliberately SKIPS the `-inline-all` leg for modules that already contain a `noinline`
function (`has_noinline_function()` in `mayhem/harnesses/ikos_pp_fuzzer.cpp`) so that this one known
defect does not consume the whole fuzzing budget; delete that guard to see it again.

## One-line fix

```cpp
if (!f.isDeclaration() && f.hasLocalLinkage() && !f.hasFnAttribute(Attribute::NoInline)) {
```
