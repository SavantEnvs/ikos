; ModuleID = '/mayhem/analyzer/test/regression/fca/test-2-error.c'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca [3 x i8*], align 16
  %3 = alloca i32, align 4
  %4 = alloca void (i32*)*, align 8
  store i32 0, i32* %1, align 4
  %5 = getelementptr inbounds [3 x i8*], [3 x i8*]* %2, i64 0, i64 0
  store i8* bitcast (void (i32)* @a to i8*), i8** %5, align 16
  %6 = getelementptr inbounds [3 x i8*], [3 x i8*]* %2, i64 0, i64 1
  store i8* bitcast (void (i64)* @b to i8*), i8** %6, align 8
  %7 = getelementptr inbounds [3 x i8*], [3 x i8*]* %2, i64 0, i64 2
  store i8* bitcast (void (double)* @c to i8*), i8** %7, align 16
  %8 = call i32 @__ikos_nondet_int()
  store i32 %8, i32* %3, align 4
  %9 = load i32, i32* %3, align 4
  %10 = icmp sge i32 %9, 0
  br i1 %10, label %11, label %21

11:                                               ; preds = %0
  %12 = load i32, i32* %3, align 4
  %13 = icmp sle i32 %12, 2
  br i1 %13, label %14, label %21

14:                                               ; preds = %11
  %15 = load i32, i32* %3, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds [3 x i8*], [3 x i8*]* %2, i64 0, i64 %16
  %18 = load i8*, i8** %17, align 8
  %19 = bitcast i8* %18 to void (i32*)*
  store void (i32*)* %19, void (i32*)** %4, align 8
  %20 = load void (i32*)*, void (i32*)** %4, align 8
  call void %20(i32* noundef null)
  br label %21

21:                                               ; preds = %14, %11, %0
  ret i32 0
}

; Function Attrs: noinline nounwind uwtable
define internal void @a(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, i32* %2, align 4
  ret void
}

; Function Attrs: noinline nounwind uwtable
define internal void @b(i64 noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 %0, i64* %2, align 8
  ret void
}

; Function Attrs: noinline nounwind uwtable
define internal void @c(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, double* %2, align 8
  ret void
}

declare dso_local i32 @__ikos_nondet_int() #1

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"uwtable", i32 1}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"clang version 14.0.6 (https://github.com/llvm/llvm-project.git f28c006a5895fc0e329fe15fead81e37457cb1d1)"}
