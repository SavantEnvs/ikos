#
# mayhem/harnesses/CMakeLists.txt — the two in-process libFuzzer harnesses + their standalone
# reproducers. NOT part of upstream's build: mayhem/build.sh appends a guarded
# `add_subdirectory(${MAYHEM_HARNESS_DIR} mayhem-harnesses)` to the SHADOW copy of the upstream
# top-level CMakeLists.txt (mayhem-build/src), so the committed tree stays byte-for-byte pristine and
# the oracle build — which does not define MAYHEM_HARNESS_DIR — never sees these targets.
#
# Each harness is built from ikos's OWN object files, with ikos's OWN include directories and link
# libraries, read straight off the upstream targets:
#   * ikos-analyzer: the ikos-analyzer executable's objects MINUS its main() — build.sh's shadow patch
#     splits analyzer/CMakeLists.txt's add_executable(ikos-analyzer ...) into an OBJECT library plus a
#     one-source executable, so the harness and the CLI compile those ~90 translation units ONCE.
#   * ikos-pp: libikos-pp (frontend/llvm/src/pass/*.cpp) via the ikos-pp executable's link libraries.
# Reading INCLUDE_DIRECTORIES / LINK_LIBRARIES off the upstream targets (rather than restating boost /
# gmp / sqlite3 / tbb / the LLVM component list here) is what keeps this file correct when upstream
# changes its dependency set.
#
# The sanitizers, -fsanitize=fuzzer-no-link and $DEBUG_FLAGS arrive through CMAKE_{C,CXX}_FLAGS, and
# mayhem/lsan_off.cc through CMAKE_EXE_LINKER_FLAGS — both set by build.sh for the whole fuzz tree, so
# every binary below is sanitized, SanCov-instrumented, DWARF-3 and LSan-disabled-at-build-time.

cmake_minimum_required(VERSION 3.4.3 FATAL_ERROR)

foreach(_t ikos-analyzer ikos-analyzer-objs ikos-pp ikos-pp-lib)
  if (NOT TARGET ${_t})
    message(FATAL_ERROR "mayhem harnesses: expected upstream target '${_t}' is not defined "
                        "(upstream layout changed, or build.sh's shadow patch did not apply)")
  endif()
endforeach()

if (NOT MAYHEM_FUZZING_ENGINE)
  message(FATAL_ERROR "mayhem harnesses: MAYHEM_FUZZING_ENGINE (\$LIB_FUZZING_ENGINE) is empty")
endif()
if (NOT EXISTS "${MAYHEM_STANDALONE_MAIN}")
  message(FATAL_ERROR "mayhem harnesses: MAYHEM_STANDALONE_MAIN "
                      "('${MAYHEM_STANDALONE_MAIN}') does not exist")
endif()

# Threads::Threads and Boost::* are IMPORTED targets created by the find_package() calls in
# analyzer/CMakeLists.txt and frontend/llvm/CMakeLists.txt, and an imported target is visible only in
# the directory that created it — re-create them here (same components, same versions) before reusing
# those directories' link lists, which name them. Everything else in those lists (the LLVM archives,
# gmp, sqlite3, tbb, the ikos libraries) is a plain path or a real target and needs nothing.
find_package(Threads REQUIRED)
find_package(Boost 1.55.0 REQUIRED COMPONENTS filesystem system thread)

# The LLVM component libraries in those link lists are IMPORTED targets (LLVMCore, LLVMipo, ...)
# defined by LLVMExports.cmake, which LLVMConfig pulls in — and, like every imported target, they are
# visible only in the directory that created them. Without this include they degrade to bare `-lLLVMipo`
# flags: the archive is found but its INTERFACE dependencies (LLVMFrontendOpenMP, LLVMLinker, ...) are
# not, and the link fails on hundreds of undefined LLVM symbols. LLVM_CMAKE_DIR / LLVM_LIBRARY_DIR are
# CACHE variables (cmake/FindLLVM.cmake) so they are visible here.
if (NOT LLVM_CMAKE_DIR OR NOT LLVM_LIBRARY_DIR)
  message(FATAL_ERROR "mayhem harnesses: LLVM_CMAKE_DIR/LLVM_LIBRARY_DIR unset (cmake/FindLLVM.cmake caches both)")
endif()
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(LLVMConfig)
link_directories("${LLVM_LIBRARY_DIR}")

get_target_property(MAYHEM_ANALYZER_INCS ikos-analyzer INCLUDE_DIRECTORIES)
get_target_property(MAYHEM_ANALYZER_LIBS ikos-analyzer LINK_LIBRARIES)
get_target_property(MAYHEM_PP_INCS ikos-pp INCLUDE_DIRECTORIES)
get_target_property(MAYHEM_PP_LIBS ikos-pp LINK_LIBRARIES)

# mayhem_harness(<target> <source> <includes> <libraries> <standalone?> [extra sources...])
#   standalone = OFF -> linked with $LIB_FUZZING_ENGINE (the Mayhem target)
#   standalone = ON  -> linked with $STANDALONE_FUZZ_MAIN (the crash reproducer)
function(mayhem_harness name source incs libs standalone)
  set(_srcs "${CMAKE_CURRENT_SOURCE_DIR}/${source}" ${ARGN})
  if (standalone)
    list(APPEND _srcs "${MAYHEM_STANDALONE_MAIN}")
  endif()
  add_executable(${name} ${_srcs})
  target_include_directories(${name} PRIVATE ${incs} "${CMAKE_CURRENT_SOURCE_DIR}")
  target_link_libraries(${name} ${libs})
  set_target_properties(${name} PROPERTIES
    CXX_STANDARD 14
    CXX_STANDARD_REQUIRED ON)
  if (NOT standalone)
    set_target_properties(${name} PROPERTIES LINK_FLAGS "${MAYHEM_FUZZING_ENGINE}")
  endif()
endfunction()

# --- Mayhem target `ikos-analyzer`: the analysis pipeline, in process -----------------------------
# libikos-pp is added to the analyzer's own link list: the CLI runs the preprocessor as a separate
# PROCESS (the `ikos` driver invokes ikos-pp, then ikos-analyzer), so the analyzer executable never
# links it — the in-process harness, which runs the same `-opt=basic` pipeline itself, must.
set(MAYHEM_ANALYZER_HARNESS_LIBS ikos-pp-lib ${MAYHEM_ANALYZER_LIBS})
mayhem_harness(mayhem-ikos-analyzer ikos_analyzer_fuzzer.cpp
               "${MAYHEM_ANALYZER_INCS}" "${MAYHEM_ANALYZER_HARNESS_LIBS}" OFF
               $<TARGET_OBJECTS:ikos-analyzer-objs>)
mayhem_harness(mayhem-ikos-analyzer-standalone ikos_analyzer_fuzzer.cpp
               "${MAYHEM_ANALYZER_INCS}" "${MAYHEM_ANALYZER_HARNESS_LIBS}" ON
               $<TARGET_OBJECTS:ikos-analyzer-objs>)

# --- Mayhem target `ikos-pp`: ikos's LLVM pass pipeline, in process -------------------------------
mayhem_harness(mayhem-ikos-pp ikos_pp_fuzzer.cpp
               "${MAYHEM_PP_INCS}" "${MAYHEM_PP_LIBS}" OFF)
mayhem_harness(mayhem-ikos-pp-standalone ikos_pp_fuzzer.cpp
               "${MAYHEM_PP_INCS}" "${MAYHEM_PP_LIBS}" ON)
