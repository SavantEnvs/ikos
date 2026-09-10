; ModuleID = '/mayhem/analyzer/test/regression/uio/test-1-overflow-unsafe.c'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 0, i32* %1, align 4
  %5 = call i32 @__ikos_nondet_uint()
  store i32 %5, i32* %2, align 4
  %6 = call i32 @__ikos_nondet_uint()
  store i32 %6, i32* %3, align 4
  %7 = load i32, i32* %2, align 4
  %8 = icmp uge i32 %7, -2
  br i1 %8, label %9, label %16

9:                                                ; preds = %0
  %10 = load i32, i32* %3, align 4
  %11 = icmp uge i32 %10, 2
  br i1 %11, label %12, label %16

12:                                               ; preds = %9
  %13 = load i32, i32* %2, align 4
  %14 = load i32, i32* %3, align 4
  %15 = add i32 %13, %14
  store i32 %15, i32* %4, align 4
  br label %17

16:                                               ; preds = %9, %0
  store i32 42, i32* %4, align 4
  br label %17

17:                                               ; preds = %16, %12
  %18 = load i32, i32* %4, align 4
  %19 = call i32 (i8*, ...) @printf(i8* noundef getelementptr inbounds ([3 x i8], [3 x i8]* @.str, i64 0, i64 0), i32 noundef %18)
  %20 = load i32, i32* %1, align 4
  ret i32 %20
}

declare dso_local i32 @__ikos_nondet_uint() #1

declare dso_local i32 @printf(i8* noundef, ...) #1

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"uwtable", i32 1}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"clang version 14.0.6 (https://github.com/llvm/llvm-project.git f28c006a5895fc0e329fe15fead81e37457cb1d1)"}
