; ModuleID = '/mayhem/analyzer/test/regression/prover/test-29.cpp'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@_ZL1x = internal global i32 0, align 4
@_ZL1y = internal global i32 0, align 4
@_ZL1z = internal global i32 0, align 4
@_ZTIDn = external dso_local constant i8*

; Function Attrs: mustprogress noinline norecurse uwtable
define dso_local noundef i32 @main() #0 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i8*, align 8
  %4 = alloca i32, align 4
  store i32 0, i32* %1, align 4
  %5 = invoke noundef i32 @_ZL1fv()
          to label %6 unwind label %21

6:                                                ; preds = %0
  store i32 %5, i32* %2, align 4
  %7 = load i32, i32* %2, align 4
  %8 = icmp eq i32 %7, -1
  br i1 %8, label %9, label %40

9:                                                ; preds = %6
  %10 = load i32, i32* @_ZL1x, align 4
  %11 = icmp eq i32 %10, 1
  br i1 %11, label %12, label %18

12:                                               ; preds = %9
  %13 = load i32, i32* @_ZL1y, align 4
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %18

15:                                               ; preds = %12
  %16 = load i32, i32* @_ZL1z, align 4
  %17 = icmp eq i32 %16, 0
  br label %18

18:                                               ; preds = %15, %12, %9
  %19 = phi i1 [ false, %12 ], [ false, %9 ], [ %17, %15 ]
  %20 = zext i1 %19 to i32
  call void @__ikos_assert(i32 noundef %20) #3
  br label %68

21:                                               ; preds = %0
  %22 = landingpad { i8*, i32 }
          catch i8* null
  %23 = extractvalue { i8*, i32 } %22, 0
  store i8* %23, i8** %3, align 8
  %24 = extractvalue { i8*, i32 } %22, 1
  store i32 %24, i32* %4, align 4
  br label %25

25:                                               ; preds = %21
  %26 = load i8*, i8** %3, align 8
  %27 = call i8* @__cxa_begin_catch(i8* %26) #3
  %28 = load i32, i32* @_ZL1x, align 4
  %29 = icmp eq i32 %28, 0
  br i1 %29, label %30, label %36

30:                                               ; preds = %25
  %31 = load i32, i32* @_ZL1y, align 4
  %32 = icmp eq i32 %31, 0
  br i1 %32, label %33, label %36

33:                                               ; preds = %30
  %34 = load i32, i32* @_ZL1z, align 4
  %35 = icmp eq i32 %34, 0
  br label %36

36:                                               ; preds = %33, %30, %25
  %37 = phi i1 [ false, %30 ], [ false, %25 ], [ %35, %33 ]
  %38 = zext i1 %37 to i32
  call void @__ikos_assert(i32 noundef %38) #3
  call void @__cxa_end_catch()
  br label %39

39:                                               ; preds = %36, %68
  ret i32 0

40:                                               ; preds = %6
  %41 = load i32, i32* %2, align 4
  %42 = icmp eq i32 %41, -2
  br i1 %42, label %43, label %55

43:                                               ; preds = %40
  %44 = load i32, i32* @_ZL1x, align 4
  %45 = icmp eq i32 %44, 2
  br i1 %45, label %46, label %52

46:                                               ; preds = %43
  %47 = load i32, i32* @_ZL1y, align 4
  %48 = icmp eq i32 %47, 1
  br i1 %48, label %49, label %52

49:                                               ; preds = %46
  %50 = load i32, i32* @_ZL1z, align 4
  %51 = icmp eq i32 %50, 0
  br label %52

52:                                               ; preds = %49, %46, %43
  %53 = phi i1 [ false, %46 ], [ false, %43 ], [ %51, %49 ]
  %54 = zext i1 %53 to i32
  call void @__ikos_assert(i32 noundef %54) #3
  br label %67

55:                                               ; preds = %40
  %56 = load i32, i32* @_ZL1x, align 4
  %57 = icmp eq i32 %56, 3
  br i1 %57, label %58, label %64

58:                                               ; preds = %55
  %59 = load i32, i32* @_ZL1y, align 4
  %60 = icmp eq i32 %59, 2
  br i1 %60, label %61, label %64

61:                                               ; preds = %58
  %62 = load i32, i32* @_ZL1z, align 4
  %63 = icmp eq i32 %62, 1
  br label %64

64:                                               ; preds = %61, %58, %55
  %65 = phi i1 [ false, %58 ], [ false, %55 ], [ %63, %61 ]
  %66 = zext i1 %65 to i32
  call void @__ikos_assert(i32 noundef %66) #3
  br label %67

67:                                               ; preds = %64, %52
  br label %68

68:                                               ; preds = %67, %18
  br label %39
}

; Function Attrs: mustprogress noinline uwtable
define internal noundef i32 @_ZL1fv() #1 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = call i32 @__ikos_nondet_int() #3
  store i32 %3, i32* %2, align 4
  %4 = load i32, i32* %2, align 4
  %5 = icmp slt i32 %4, 0
  br i1 %5, label %6, label %9

6:                                                ; preds = %0
  %7 = call i8* @__cxa_allocate_exception(i64 8) #3
  %8 = bitcast i8* %7 to i8**
  store i8* null, i8** %8, align 16
  call void @__cxa_throw(i8* %7, i8* bitcast (i8** @_ZTIDn to i8*), i8* null) #4
  unreachable

9:                                                ; preds = %0
  %10 = load i32, i32* @_ZL1x, align 4
  %11 = add nsw i32 %10, 1
  store i32 %11, i32* @_ZL1x, align 4
  %12 = call i32 @__ikos_nondet_int() #3
  store i32 %12, i32* %2, align 4
  %13 = load i32, i32* %2, align 4
  %14 = icmp slt i32 %13, 0
  br i1 %14, label %15, label %16

15:                                               ; preds = %9
  store i32 -1, i32* %1, align 4
  br label %32

16:                                               ; preds = %9
  %17 = load i32, i32* @_ZL1x, align 4
  %18 = add nsw i32 %17, 1
  store i32 %18, i32* @_ZL1x, align 4
  %19 = load i32, i32* @_ZL1y, align 4
  %20 = add nsw i32 %19, 1
  store i32 %20, i32* @_ZL1y, align 4
  %21 = call i32 @__ikos_nondet_int() #3
  store i32 %21, i32* %2, align 4
  %22 = load i32, i32* %2, align 4
  %23 = icmp slt i32 %22, 0
  br i1 %23, label %24, label %25

24:                                               ; preds = %16
  store i32 -2, i32* %1, align 4
  br label %32

25:                                               ; preds = %16
  %26 = load i32, i32* @_ZL1x, align 4
  %27 = add nsw i32 %26, 1
  store i32 %27, i32* @_ZL1x, align 4
  %28 = load i32, i32* @_ZL1y, align 4
  %29 = add nsw i32 %28, 1
  store i32 %29, i32* @_ZL1y, align 4
  %30 = load i32, i32* @_ZL1z, align 4
  %31 = add nsw i32 %30, 1
  store i32 %31, i32* @_ZL1z, align 4
  store i32 0, i32* %1, align 4
  br label %32

32:                                               ; preds = %25, %24, %15
  %33 = load i32, i32* %1, align 4
  ret i32 %33
}

declare dso_local i32 @__gxx_personality_v0(...)

; Function Attrs: nounwind
declare dso_local void @__ikos_assert(i32 noundef) #2

declare dso_local i8* @__cxa_begin_catch(i8*)

declare dso_local void @__cxa_end_catch()

; Function Attrs: nounwind
declare dso_local i32 @__ikos_nondet_int() #2

declare dso_local i8* @__cxa_allocate_exception(i64)

declare dso_local void @__cxa_throw(i8*, i8*, i8*)

attributes #0 = { mustprogress noinline norecurse uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress noinline uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { noreturn }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"uwtable", i32 1}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"clang version 14.0.6 (https://github.com/llvm/llvm-project.git f28c006a5895fc0e329fe15fead81e37457cb1d1)"}
