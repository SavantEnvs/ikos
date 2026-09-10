; ModuleID = '/mayhem/analyzer/test/regression/mem/test-20.c'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32*, align 8
  %3 = alloca i32*, align 8
  %4 = alloca i32*, align 8
  store i32 0, i32* %1, align 4
  %5 = call noalias i8* @malloc(i64 noundef 4) #3
  %6 = bitcast i8* %5 to i32*
  store i32* %6, i32** %2, align 8
  %7 = call noalias i8* @malloc(i64 noundef 4) #3
  %8 = bitcast i8* %7 to i32*
  store i32* %8, i32** %3, align 8
  %9 = call noalias i8* @malloc(i64 noundef 4) #3
  %10 = bitcast i8* %9 to i32*
  store i32* %10, i32** %4, align 8
  %11 = load i32*, i32** %2, align 8
  %12 = icmp ne i32* %11, null
  br i1 %12, label %13, label %19

13:                                               ; preds = %0
  %14 = load i32*, i32** %3, align 8
  %15 = icmp ne i32* %14, null
  br i1 %15, label %16, label %19

16:                                               ; preds = %13
  %17 = load i32*, i32** %4, align 8
  %18 = icmp ne i32* %17, null
  br i1 %18, label %20, label %19

19:                                               ; preds = %16, %13, %0
  store i32 0, i32* %1, align 4
  br label %42

20:                                               ; preds = %16
  %21 = load i32*, i32** %3, align 8
  store i32 3, i32* %21, align 4
  %22 = load i32*, i32** %4, align 8
  store i32 5, i32* %22, align 4
  %23 = call i32 @__ikos_nondet_int()
  %24 = icmp ne i32 %23, 0
  br i1 %24, label %25, label %27

25:                                               ; preds = %20
  %26 = load i32*, i32** %3, align 8
  store i32* %26, i32** %2, align 8
  br label %29

27:                                               ; preds = %20
  %28 = load i32*, i32** %4, align 8
  store i32* %28, i32** %2, align 8
  br label %29

29:                                               ; preds = %27, %25
  %30 = load i32*, i32** %2, align 8
  %31 = load i32, i32* %30, align 4
  %32 = icmp sge i32 %31, 3
  br i1 %32, label %33, label %37

33:                                               ; preds = %29
  %34 = load i32*, i32** %2, align 8
  %35 = load i32, i32* %34, align 4
  %36 = icmp sle i32 %35, 5
  br label %37

37:                                               ; preds = %33, %29
  %38 = phi i1 [ false, %29 ], [ %36, %33 ]
  %39 = zext i1 %38 to i32
  call void @__ikos_assert(i32 noundef %39)
  %40 = load i32*, i32** %2, align 8
  %41 = load i32, i32* %40, align 4
  store i32 %41, i32* %1, align 4
  br label %42

42:                                               ; preds = %37, %19
  %43 = load i32, i32* %1, align 4
  ret i32 %43
}

; Function Attrs: nounwind
declare dso_local noalias i8* @malloc(i64 noundef) #1

declare dso_local i32 @__ikos_nondet_int() #2

declare dso_local void @__ikos_assert(i32 noundef) #2

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"uwtable", i32 1}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"clang version 14.0.6 (https://github.com/llvm/llvm-project.git f28c006a5895fc0e329fe15fead81e37457cb1d1)"}
