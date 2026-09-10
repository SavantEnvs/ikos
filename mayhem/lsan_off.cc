// mayhem/lsan_off.cc — disable LeakSanitizer at BUILD time for every ASan-built target (fleet
// policy, PORTING.md / SPEC §6.2 item 15). Leaks are not the bug class this fleet fuzzes for —
// ikos-analyzer/ikos-pp are allocate-and-exit batch tools whose exit-time leak reports would drown
// real ASan/UBSan defects. `-fsanitize=address` always bundles LSan in, so the sanctioned off-switch
// is this weak-interface hook linked into every sanitized binary (fuzz targets AND the cmake
// configure-time probes, via CMAKE_EXE_LINKER_FLAGS) — never a runtime disable/enable wrap, never a
// compiled-in sanitizer default-options override, never a Mayhemfile sanitizer-options env line (all three
// are gate FAILs; Mayhem alone owns the runtime option set).
extern "C" int __lsan_is_turned_off(void) { return 1; }
