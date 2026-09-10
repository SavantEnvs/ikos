; ModuleID = '/mayhem/analyzer/test/regression/upa/test-4-unsafe.c'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: noinline nounwind uwtable
define dso_local i16* @foo(i8* noundef %0, i8* noundef %1) #0 {
  %3 = alloca i8*, align 8
  %4 = alloca i8*, align 8
  store i8* %0, i8** %3, align 8
  store i8* %1, i8** %4, align 8
  %5 = load i8*, i8** %3, align 8
  %6 = load i8*, i8** %4, align 8
  %7 = load i8, i8* %6, align 1
  %8 = zext i8 %7 to i32
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds i8, i8* %5, i64 %9
  %11 = bitcast i8* %10 to i16*
  ret i16* %11
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i16, align 2
  %3 = alloca i8, align 1
  %4 = alloca i16*, align 8
  store i32 0, i32* %1, align 4
  store i16 0, i16* %2, align 2
  store i8 3, i8* %3, align 1
  %5 = call i32 @__ikos_nondet_int()
  %6 = icmp ne i32 %5, 0
  br i1 %6, label %7, label %12

7:                                                ; preds = %0
  %8 = load i8, i8* %3, align 1
  %9 = zext i8 %8 to i32
  %10 = mul nsw i32 5, %9
  %11 = trunc i32 %10 to i8
  store i8 %11, i8* %3, align 1
  br label %13

12:                                               ; preds = %0
  store i8 7, i8* %3, align 1
  br label %13

13:                                               ; preds = %12, %7
  %14 = bitcast i16* %2 to i8*
  %15 = call i16* @foo(i8* noundef %14, i8* noundef %3)
  store i16* %15, i16** %4, align 8
  %16 = load i16*, i16** %4, align 8
  %17 = load i16, i16* %16, align 2
  %18 = zext i16 %17 to i32
  ret i32 %18
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
