; ModuleID = '/mayhem/analyzer/test/regression/boa/test-17.c'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @foo(float* noundef %0, i32 noundef %1, float noundef %2) #0 {
  %4 = alloca float*, align 8
  %5 = alloca i32, align 4
  %6 = alloca float, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store float* %0, float** %4, align 8
  store i32 %1, i32* %5, align 4
  store float %2, float* %6, align 4
  store i32 0, i32* %7, align 4
  store i32 0, i32* %8, align 4
  %12 = load i32, i32* %5, align 4
  %13 = sub nsw i32 %12, 1
  store i32 %13, i32* %9, align 4
  store i32 0, i32* %10, align 4
  store i32 0, i32* %11, align 4
  %14 = load float, float* %6, align 4
  %15 = load float*, float** %4, align 8
  %16 = load i32, i32* %8, align 4
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds float, float* %15, i64 %17
  %19 = load float, float* %18, align 4
  %20 = fcmp ole float %14, %19
  br i1 %20, label %21, label %23

21:                                               ; preds = %3
  %22 = load i32, i32* %8, align 4
  store i32 %22, i32* %10, align 4
  store i32 1, i32* %11, align 4
  br label %36

23:                                               ; preds = %3
  %24 = load float, float* %6, align 4
  %25 = load float*, float** %4, align 8
  %26 = load i32, i32* %9, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds float, float* %25, i64 %27
  %29 = load float, float* %28, align 4
  %30 = fcmp oge float %24, %29
  br i1 %30, label %31, label %34

31:                                               ; preds = %23
  %32 = load i32, i32* %9, align 4
  %33 = sub nsw i32 %32, 1
  store i32 %33, i32* %10, align 4
  store i32 1, i32* %11, align 4
  br label %35

34:                                               ; preds = %23
  br label %35

35:                                               ; preds = %34, %31
  br label %36

36:                                               ; preds = %35, %21
  %37 = load i32, i32* %11, align 4
  %38 = icmp eq i32 %37, 0
  br i1 %38, label %39, label %109

39:                                               ; preds = %36
  %40 = load float, float* %6, align 4
  %41 = fcmp olt float %40, 0.000000e+00
  br i1 %41, label %42, label %75

42:                                               ; preds = %39
  br label %43

43:                                               ; preds = %73, %42
  %44 = load i32, i32* %8, align 4
  %45 = load i32, i32* %9, align 4
  %46 = add nsw i32 %44, %45
  %47 = sdiv i32 %46, 2
  store i32 %47, i32* %7, align 4
  %48 = load float, float* %6, align 4
  %49 = load float*, float** %4, align 8
  %50 = load i32, i32* %7, align 4
  %51 = sext i32 %50 to i64
  %52 = getelementptr inbounds float, float* %49, i64 %51
  %53 = load float, float* %52, align 4
  %54 = fcmp olt float %48, %53
  br i1 %54, label %55, label %58

55:                                               ; preds = %43
  %56 = load i32, i32* %7, align 4
  %57 = sub nsw i32 %56, 1
  store i32 %57, i32* %9, align 4
  br label %73

58:                                               ; preds = %43
  %59 = load float, float* %6, align 4
  %60 = load float*, float** %4, align 8
  %61 = load i32, i32* %7, align 4
  %62 = add nsw i32 %61, 1
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds float, float* %60, i64 %63
  %65 = load float, float* %64, align 4
  %66 = fcmp oge float %59, %65
  br i1 %66, label %67, label %70

67:                                               ; preds = %58
  %68 = load i32, i32* %7, align 4
  %69 = add nsw i32 %68, 1
  store i32 %69, i32* %8, align 4
  br label %72

70:                                               ; preds = %58
  %71 = load i32, i32* %7, align 4
  store i32 %71, i32* %10, align 4
  br label %74

72:                                               ; preds = %67
  br label %73

73:                                               ; preds = %72, %55
  br label %43

74:                                               ; preds = %70
  br label %108

75:                                               ; preds = %39
  br label %76

76:                                               ; preds = %106, %75
  %77 = load i32, i32* %8, align 4
  %78 = load i32, i32* %9, align 4
  %79 = add nsw i32 %77, %78
  %80 = sdiv i32 %79, 2
  store i32 %80, i32* %7, align 4
  %81 = load float, float* %6, align 4
  %82 = load float*, float** %4, align 8
  %83 = load i32, i32* %7, align 4
  %84 = sext i32 %83 to i64
  %85 = getelementptr inbounds float, float* %82, i64 %84
  %86 = load float, float* %85, align 4
  %87 = fcmp ole float %81, %86
  br i1 %87, label %88, label %91

88:                                               ; preds = %76
  %89 = load i32, i32* %7, align 4
  %90 = sub nsw i32 %89, 1
  store i32 %90, i32* %9, align 4
  br label %106

91:                                               ; preds = %76
  %92 = load float, float* %6, align 4
  %93 = load float*, float** %4, align 8
  %94 = load i32, i32* %7, align 4
  %95 = add nsw i32 %94, 1
  %96 = sext i32 %95 to i64
  %97 = getelementptr inbounds float, float* %93, i64 %96
  %98 = load float, float* %97, align 4
  %99 = fcmp ogt float %92, %98
  br i1 %99, label %100, label %103

100:                                              ; preds = %91
  %101 = load i32, i32* %7, align 4
  %102 = add nsw i32 %101, 1
  store i32 %102, i32* %8, align 4
  br label %105

103:                                              ; preds = %91
  %104 = load i32, i32* %7, align 4
  store i32 %104, i32* %10, align 4
  br label %107

105:                                              ; preds = %100
  br label %106

106:                                              ; preds = %105, %88
  br label %76

107:                                              ; preds = %103
  br label %108

108:                                              ; preds = %107, %74
  br label %109

109:                                              ; preds = %108, %36
  %110 = load i32, i32* %10, align 4
  ret i32 %110
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main(i32 noundef %0, i8** noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i8**, align 8
  %6 = alloca i32, align 4
  %7 = alloca [100 x float], align 16
  %8 = alloca float, align 4
  store i32 0, i32* %3, align 4
  store i32 %0, i32* %4, align 4
  store i8** %1, i8*** %5, align 8
  store i32 100, i32* %6, align 4
  store float 3.400000e+01, float* %8, align 4
  %9 = bitcast [100 x float]* %7 to float*
  %10 = load i32, i32* %6, align 4
  %11 = load float, float* %8, align 4
  %12 = call i32 @foo(float* noundef %9, i32 noundef %10, float noundef %11)
  ret i32 %12
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"uwtable", i32 1}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"clang version 14.0.6 (https://github.com/llvm/llvm-project.git f28c006a5895fc0e329fe15fead81e37457cb1d1)"}
