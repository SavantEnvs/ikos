; ModuleID = '/mayhem/analyzer/test/regression/upa/test-7-unsafe.c'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @foo(i8 noundef zeroext %0, i8 noundef zeroext %1) #0 {
  %3 = alloca i8, align 1
  %4 = alloca i8, align 1
  store i8 %0, i8* %3, align 1
  store i8 %1, i8* %4, align 1
  %5 = load i8, i8* %3, align 1
  %6 = zext i8 %5 to i32
  %7 = load i8, i8* %4, align 1
  %8 = zext i8 %7 to i32
  %9 = add nsw i32 %6, %8
  %10 = trunc i32 %9 to i8
  ret i8 %10
}

; Function Attrs: noinline nounwind uwtable
define dso_local zeroext i8 @bar(i8 noundef zeroext %0) #0 {
  %2 = alloca i8, align 1
  store i8 %0, i8* %2, align 1
  %3 = load i8, i8* %2, align 1
  %4 = zext i8 %3 to i32
  %5 = load i8, i8* %2, align 1
  %6 = call zeroext i8 @foo(i8 noundef zeroext %5, i8 noundef zeroext 10)
  %7 = zext i8 %6 to i32
  %8 = add nsw i32 %4, %7
  %9 = trunc i32 %8 to i8
  ret i8 %9
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main(i32 noundef %0, i8** noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i8**, align 8
  %6 = alloca [56 x i8], align 16
  %7 = alloca i8, align 1
  %8 = alloca i8, align 1
  %9 = alloca i16*, align 8
  store i32 0, i32* %3, align 4
  store i32 %0, i32* %4, align 4
  store i8** %1, i8*** %5, align 8
  %10 = call zeroext i8 @foo(i8 noundef zeroext 5, i8 noundef zeroext 10)
  store i8 %10, i8* %7, align 1
  %11 = load i8, i8* %7, align 1
  %12 = zext i8 %11 to i32
  %13 = load i8, i8* %7, align 1
  %14 = call zeroext i8 @bar(i8 noundef zeroext %13)
  %15 = zext i8 %14 to i32
  %16 = add nsw i32 %12, %15
  %17 = trunc i32 %16 to i8
  store i8 %17, i8* %8, align 1
  %18 = load i8, i8* %8, align 1
  %19 = load i8, i8* %7, align 1
  %20 = zext i8 %19 to i64
  %21 = getelementptr inbounds [56 x i8], [56 x i8]* %6, i64 0, i64 %20
  store i8 %18, i8* %21, align 1
  %22 = load i8, i8* %7, align 1
  %23 = zext i8 %22 to i64
  %24 = getelementptr inbounds [56 x i8], [56 x i8]* %6, i64 0, i64 %23
  %25 = load i8, i8* %24, align 1
  %26 = zext i8 %25 to i32
  %27 = load i8, i8* %8, align 1
  %28 = zext i8 %27 to i32
  %29 = add nsw i32 %26, %28
  %30 = add nsw i32 %29, 1
  %31 = sext i32 %30 to i64
  %32 = inttoptr i64 %31 to i16*
  store i16* %32, i16** %9, align 8
  %33 = load i16*, i16** %9, align 8
  %34 = load i16, i16* %33, align 2
  %35 = zext i16 %34 to i32
  ret i32 %35
}

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"uwtable", i32 1}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"clang version 14.0.6 (https://github.com/llvm/llvm-project.git f28c006a5895fc0e329fe15fead81e37457cb1d1)"}
