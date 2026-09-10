; ModuleID = '/mayhem/analyzer/test/regression/mem/test-12.c'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct.foo = type { [5 x i32], i32, [10 x i32] }

@x = dso_local global %struct.foo* null, align 8

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main(i32 noundef %0, i8** noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i8**, align 8
  %6 = alloca i32*, align 8
  %7 = alloca i32*, align 8
  store i32 0, i32* %3, align 4
  store i32 %0, i32* %4, align 4
  store i8** %1, i8*** %5, align 8
  %8 = call noalias i8* @malloc(i64 noundef 64) #3
  %9 = bitcast i8* %8 to %struct.foo*
  store %struct.foo* %9, %struct.foo** @x, align 8
  %10 = load %struct.foo*, %struct.foo** @x, align 8
  %11 = icmp ne %struct.foo* %10, null
  br i1 %11, label %13, label %12

12:                                               ; preds = %2
  store i32 0, i32* %3, align 4
  br label %81

13:                                               ; preds = %2
  %14 = load %struct.foo*, %struct.foo** @x, align 8
  %15 = getelementptr inbounds %struct.foo, %struct.foo* %14, i32 0, i32 0
  %16 = getelementptr inbounds [5 x i32], [5 x i32]* %15, i64 0, i64 2
  store i32 5, i32* %16, align 4
  %17 = load %struct.foo*, %struct.foo** @x, align 8
  %18 = getelementptr inbounds %struct.foo, %struct.foo* %17, i32 0, i32 0
  %19 = getelementptr inbounds [5 x i32], [5 x i32]* %18, i64 0, i64 3
  store i32 15, i32* %19, align 4
  %20 = load %struct.foo*, %struct.foo** @x, align 8
  %21 = getelementptr inbounds %struct.foo, %struct.foo* %20, i32 0, i32 0
  %22 = getelementptr inbounds [5 x i32], [5 x i32]* %21, i64 0, i64 4
  store i32 25, i32* %22, align 4
  %23 = load %struct.foo*, %struct.foo** @x, align 8
  %24 = getelementptr inbounds %struct.foo, %struct.foo* %23, i32 0, i32 0
  %25 = getelementptr inbounds [5 x i32], [5 x i32]* %24, i64 0, i64 0
  store i32* %25, i32** %6, align 8
  %26 = load i32*, i32** %6, align 8
  %27 = getelementptr inbounds i32, i32* %26, i64 4
  store i32* %27, i32** %6, align 8
  %28 = load %struct.foo*, %struct.foo** @x, align 8
  %29 = getelementptr inbounds %struct.foo, %struct.foo* %28, i32 0, i32 2
  %30 = getelementptr inbounds [10 x i32], [10 x i32]* %29, i64 0, i64 0
  store i32 333, i32* %30, align 4
  %31 = load %struct.foo*, %struct.foo** @x, align 8
  %32 = getelementptr inbounds %struct.foo, %struct.foo* %31, i32 0, i32 2
  %33 = getelementptr inbounds [10 x i32], [10 x i32]* %32, i64 0, i64 5
  store i32 555, i32* %33, align 4
  %34 = load %struct.foo*, %struct.foo** @x, align 8
  %35 = getelementptr inbounds %struct.foo, %struct.foo* %34, i32 0, i32 2
  %36 = getelementptr inbounds [10 x i32], [10 x i32]* %35, i64 0, i64 0
  store i32* %36, i32** %7, align 8
  %37 = load i32*, i32** %6, align 8
  %38 = load i32, i32* %37, align 4
  %39 = icmp eq i32 %38, 25
  br i1 %39, label %40, label %44

40:                                               ; preds = %13
  %41 = load i32*, i32** %7, align 8
  %42 = load i32, i32* %41, align 4
  %43 = icmp eq i32 %42, 333
  br label %44

44:                                               ; preds = %40, %13
  %45 = phi i1 [ false, %13 ], [ %43, %40 ]
  %46 = zext i1 %45 to i32
  call void @__ikos_assert(i32 noundef %46)
  %47 = load i32*, i32** %7, align 8
  %48 = getelementptr inbounds i32, i32* %47, i64 5
  store i32* %48, i32** %7, align 8
  %49 = load i32*, i32** %7, align 8
  %50 = load i32, i32* %49, align 4
  %51 = icmp eq i32 %50, 555
  br i1 %51, label %52, label %60

52:                                               ; preds = %44
  %53 = load i32*, i32** %7, align 8
  %54 = load i32, i32* %53, align 4
  %55 = load %struct.foo*, %struct.foo** @x, align 8
  %56 = getelementptr inbounds %struct.foo, %struct.foo* %55, i32 0, i32 2
  %57 = getelementptr inbounds [10 x i32], [10 x i32]* %56, i64 0, i64 5
  %58 = load i32, i32* %57, align 4
  %59 = icmp eq i32 %54, %58
  br label %60

60:                                               ; preds = %52, %44
  %61 = phi i1 [ false, %44 ], [ %59, %52 ]
  %62 = zext i1 %61 to i32
  call void @__ikos_assert(i32 noundef %62)
  %63 = load i32*, i32** %6, align 8
  store i32* %63, i32** %7, align 8
  %64 = load i32*, i32** %7, align 8
  %65 = getelementptr inbounds i32, i32* %64, i32 1
  store i32* %65, i32** %7, align 8
  %66 = load i32*, i32** %7, align 8
  store i32 888, i32* %66, align 4
  %67 = load %struct.foo*, %struct.foo** @x, align 8
  %68 = getelementptr inbounds %struct.foo, %struct.foo* %67, i32 0, i32 0
  %69 = getelementptr inbounds [5 x i32], [5 x i32]* %68, i64 0, i64 5
  %70 = load i32, i32* %69, align 4
  %71 = icmp eq i32 %70, 888
  %72 = zext i1 %71 to i32
  call void @__ikos_assert(i32 noundef %72)
  %73 = load i32*, i32** %7, align 8
  %74 = load i32, i32* %73, align 4
  %75 = load %struct.foo*, %struct.foo** @x, align 8
  %76 = getelementptr inbounds %struct.foo, %struct.foo* %75, i32 0, i32 0
  %77 = getelementptr inbounds [5 x i32], [5 x i32]* %76, i64 0, i64 5
  %78 = load i32, i32* %77, align 4
  %79 = icmp eq i32 %74, %78
  %80 = zext i1 %79 to i32
  call void @__ikos_assert(i32 noundef %80)
  store i32 42, i32* %3, align 4
  br label %81

81:                                               ; preds = %60, %12
  %82 = load i32, i32* %3, align 4
  ret i32 %82
}

; Function Attrs: nounwind
declare dso_local noalias i8* @malloc(i64 noundef) #1

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
