; ModuleID = '/mayhem/analyzer/test/regression/prover/test-23.c'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32* @f() #0 {
  %1 = alloca i32*, align 8
  %2 = call noalias i8* @malloc(i64 noundef 4) #4
  %3 = bitcast i8* %2 to i32*
  store i32* %3, i32** %1, align 8
  %4 = load i32*, i32** %1, align 8
  %5 = icmp eq i32* %4, null
  br i1 %5, label %6, label %7

6:                                                ; preds = %0
  call void @exit(i32 noundef 0) #5
  unreachable

7:                                                ; preds = %0
  %8 = load i32*, i32** %1, align 8
  ret i32* %8
}

; Function Attrs: nounwind
declare dso_local noalias i8* @malloc(i64 noundef) #1

; Function Attrs: noreturn nounwind
declare dso_local void @exit(i32 noundef) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32*, align 8
  %2 = alloca i32*, align 8
  %3 = call i32* @f()
  store i32* %3, i32** %1, align 8
  %4 = load i32*, i32** %1, align 8
  store i32 0, i32* %4, align 4
  %5 = call i32* @f()
  store i32* %5, i32** %2, align 8
  %6 = load i32*, i32** %2, align 8
  store i32 42, i32* %6, align 4
  %7 = load i32*, i32** %1, align 8
  %8 = load i32*, i32** %2, align 8
  %9 = icmp ne i32* %7, %8
  %10 = zext i1 %9 to i32
  call void @__ikos_assert(i32 noundef %10)
  %11 = load i32*, i32** %1, align 8
  %12 = load i32, i32* %11, align 4
  %13 = icmp eq i32 %12, 0
  %14 = zext i1 %13 to i32
  call void @__ikos_assert(i32 noundef %14)
  %15 = load i32*, i32** %2, align 8
  %16 = load i32, i32* %15, align 4
  %17 = icmp eq i32 %16, 42
  %18 = zext i1 %17 to i32
  call void @__ikos_assert(i32 noundef %18)
  ret i32 0
}

declare dso_local void @__ikos_assert(i32 noundef) #3

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"uwtable", i32 1}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"clang version 14.0.6 (https://github.com/llvm/llvm-project.git f28c006a5895fc0e329fe15fead81e37457cb1d1)"}
