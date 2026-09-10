; ModuleID = '/mayhem/analyzer/test/regression/dfa/test-3-delete.cpp'
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%class.Foo = type { i8 }

; Function Attrs: mustprogress noinline norecurse uwtable
define dso_local noundef i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca %class.Foo*, align 8
  %3 = alloca %class.Foo*, align 8
  store i32 0, i32* %1, align 4
  %4 = call noalias noundef nonnull i8* @_Znwm(i64 noundef 1) #3
  %5 = bitcast i8* %4 to %class.Foo*
  store %class.Foo* %5, %class.Foo** %2, align 8
  %6 = load %class.Foo*, %class.Foo** %2, align 8
  store %class.Foo* %6, %class.Foo** %3, align 8
  %7 = load %class.Foo*, %class.Foo** %2, align 8
  %8 = icmp eq %class.Foo* %7, null
  br i1 %8, label %11, label %9

9:                                                ; preds = %0
  %10 = bitcast %class.Foo* %7 to i8*
  call void @_ZdlPv(i8* noundef %10) #4
  br label %11

11:                                               ; preds = %9, %0
  %12 = load %class.Foo*, %class.Foo** %3, align 8
  %13 = icmp eq %class.Foo* %12, null
  br i1 %13, label %16, label %14

14:                                               ; preds = %11
  %15 = bitcast %class.Foo* %12 to i8*
  call void @_ZdlPv(i8* noundef %15) #4
  br label %16

16:                                               ; preds = %14, %11
  %17 = load i32, i32* %1, align 4
  ret i32 %17
}

; Function Attrs: nobuiltin allocsize(0)
declare dso_local noundef nonnull i8* @_Znwm(i64 noundef) #1

; Function Attrs: nobuiltin nounwind
declare dso_local void @_ZdlPv(i8* noundef) #2

attributes #0 = { mustprogress noinline norecurse uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nobuiltin allocsize(0) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nobuiltin nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { builtin allocsize(0) }
attributes #4 = { builtin nounwind }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"uwtable", i32 1}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"clang version 14.0.6 (https://github.com/llvm/llvm-project.git f28c006a5895fc0e329fe15fead81e37457cb1d1)"}
