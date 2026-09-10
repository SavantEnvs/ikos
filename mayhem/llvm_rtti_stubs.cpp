// mayhem/llvm_rtti_stubs.cpp — typeinfo objects for the LLVM base classes ikos derives from.
//
// The pinned LLVM 14 release tarball (see mayhem/Dockerfile) is built with -fno-rtti, so it never
// emits `typeinfo for llvm::Pass`, `llvm::ModulePass`, `llvm::cl::Option`, ... . ikos is compiled
// WITH RTTI (it uses typeid in ar/support/traceable.hpp, so per-TU -fno-rtti is not an option) and
// defines classes deriving from those LLVM bases; every such derived class's typeinfo references its
// base's typeinfo, which would be an undefined symbol at link time. This TU supplies them, laid out
// per the Itanium C++ ABI (__class_type_info for root classes, __si_class_type_info for a class with
// a single public non-virtual base). Their CONTENT is never inspected at run time: LLVM itself does
// no RTTI, and ikos never dynamic_casts to / catches an LLVM type — they exist only to satisfy the
// linker. Linked (via CMAKE_EXE_LINKER_FLAGS) into both the sanitized fuzz build and the clean
// oracle build. No upstream file is touched.
extern "C" const void* const _ZTVN10__cxxabiv117__class_type_infoE[];     // vtable for __cxxabiv1::__class_type_info
extern "C" const void* const _ZTVN10__cxxabiv120__si_class_type_infoE[];  // vtable for __cxxabiv1::__si_class_type_info

struct ClassTI {
  const void* const* vptr;
  const char* name;
};
struct SiClassTI {
  const void* const* vptr;
  const char* name;
  const void* base;
};

// Root classes (no base): llvm::Pass, llvm::cl::Option, llvm::cl::generic_parser_base,
// llvm::cl::GenericOptionValue.
extern "C" const char _ZTSN4llvm4PassE[] = "N4llvm4PassE";
extern "C" const ClassTI _ZTIN4llvm4PassE = {&_ZTVN10__cxxabiv117__class_type_infoE[2], _ZTSN4llvm4PassE};

extern "C" const char _ZTSN4llvm2cl6OptionE[] = "N4llvm2cl6OptionE";
extern "C" const ClassTI _ZTIN4llvm2cl6OptionE = {&_ZTVN10__cxxabiv117__class_type_infoE[2], _ZTSN4llvm2cl6OptionE};

extern "C" const char _ZTSN4llvm2cl19generic_parser_baseE[] = "N4llvm2cl19generic_parser_baseE";
extern "C" const ClassTI _ZTIN4llvm2cl19generic_parser_baseE = {&_ZTVN10__cxxabiv117__class_type_infoE[2],
                                                                _ZTSN4llvm2cl19generic_parser_baseE};

extern "C" const char _ZTSN4llvm2cl18GenericOptionValueE[] = "N4llvm2cl18GenericOptionValueE";
extern "C" const ClassTI _ZTIN4llvm2cl18GenericOptionValueE = {&_ZTVN10__cxxabiv117__class_type_infoE[2],
                                                               _ZTSN4llvm2cl18GenericOptionValueE};

// Single-inheritance classes deriving from llvm::Pass: llvm::ModulePass, llvm::FunctionPass.
extern "C" const char _ZTSN4llvm10ModulePassE[] = "N4llvm10ModulePassE";
extern "C" const SiClassTI _ZTIN4llvm10ModulePassE = {&_ZTVN10__cxxabiv120__si_class_type_infoE[2],
                                                      _ZTSN4llvm10ModulePassE, &_ZTIN4llvm4PassE};

extern "C" const char _ZTSN4llvm12FunctionPassE[] = "N4llvm12FunctionPassE";
extern "C" const SiClassTI _ZTIN4llvm12FunctionPassE = {&_ZTVN10__cxxabiv120__si_class_type_infoE[2],
                                                        _ZTSN4llvm12FunctionPassE, &_ZTIN4llvm4PassE};
