; Minimal reproducer: `ikos-pp -opt=aggressive -inline-all` produces a module that LLVM's own
; verifier rejects, because ikos's mark_internal_inline pass adds `alwaysinline` to @helper without
; noticing that it already carries `noinline`. @helper's address escapes to an external function, so
; the always-inliner that runs next cannot inline it away and the contradictory attribute pair
; reaches the verifier. See README.md.
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare dso_local void @sink(void ()*)

define internal void @helper() #0 {
  ret void
}

define dso_local i32 @main() {
  call void @sink(void ()* @helper)
  ret i32 0
}

attributes #0 = { noinline nounwind }
