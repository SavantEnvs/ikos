; ModuleID = '/mayhem/analyzer/test/regression/pcmp/test-2-warnings.c'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i1 @f(i32* noundef %0, i32* noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca i32*, align 8
  %6 = alloca i32*, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32* %0, i32** %5, align 8
  store i32* %1, i32** %6, align 8
  store i32 %2, i32* %7, align 4
  store i32 %3, i32* %8, align 4
  %9 = load i32*, i32** %5, align 8
  %10 = load i32, i32* %7, align 4
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds i32, i32* %9, i64 %11
  %13 = load i32*, i32** %6, align 8
  %14 = load i32, i32* %8, align 4
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, i32* %13, i64 %15
  %17 = icmp ult i32* %12, %16
  ret i1 %17
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32*, align 8
  %3 = alloca i32*, align 8
  %4 = alloca i32*, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i8, align 1
  store i32 0, i32* %1, align 4
  %8 = call noalias i8* @calloc(i64 noundef 10, i64 noundef 4) #3
  %9 = bitcast i8* %8 to i32*
  store i32* %9, i32** %2, align 8
  %10 = call noalias i8* @calloc(i64 noundef 10, i64 noundef 4) #3
  %11 = bitcast i8* %10 to i32*
  store i32* %11, i32** %3, align 8
  %12 = call i32 @__ikos_nondet_uint()
  %13 = urem i32 %12, 10
  store i32 %13, i32* %5, align 4
  %14 = call i32 @__ikos_nondet_uint()
  %15 = urem i32 %14, 10
  store i32 %15, i32* %6, align 4
  %16 = call i32 @__ikos_nondet_int()
  %17 = icmp ne i32 %16, 0
  br i1 %17, label %18, label %20

18:                                               ; preds = %0
  %19 = load i32*, i32** %2, align 8
  store i32* %19, i32** %4, align 8
  br label %22

20:                                               ; preds = %0
  %21 = load i32*, i32** %3, align 8
  store i32* %21, i32** %4, align 8
  br label %22

22:                                               ; preds = %20, %18
  %23 = load i32*, i32** %4, align 8
  %24 = load i32*, i32** %3, align 8
  %25 = load i32, i32* %5, align 4
  %26 = load i32, i32* %6, align 4
  %27 = call zeroext i1 @f(i32* noundef %23, i32* noundef %24, i32 noundef %25, i32 noundef %26)
  %28 = zext i1 %27 to i8
  store i8 %28, i8* %7, align 1
  %29 = load i32*, i32** %2, align 8
  %30 = bitcast i32* %29 to i8*
  call void @free(i8* noundef %30) #3
  %31 = load i32*, i32** %3, align 8
  %32 = bitcast i32* %31 to i8*
  call void @free(i8* noundef %32) #3
  %33 = load i8, i8* %7, align 1
  %34 = trunc i8 %33 to i1
  %35 = zext i1 %34 to i32
  ret i32 %35
}

; Function Attrs: nounwind
declare dso_local noalias i8* @calloc(i64 noundef, i64 noundef) #1

declare dso_local i32 @__ikos_nondet_uint() #2

declare dso_local i32 @__ikos_nondet_int() #2

; Function Attrs: nounwind
declare dso_local void @free(i8* noundef) #1

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
