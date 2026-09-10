#!/usr/bin/env bash
#
# mayhem/gen-seeds.sh — (re)generate every COMMITTED fixture this integration needs. Run at PORT time
# inside the commit image (it has the bundled clang-14 at /opt/toolchains/llvm14), NOT by build.sh:
# these are committed fixtures (SPEC §6.2 item 16), and Mayhem reads the seed corpora off the CI
# checkout via the Mayhemfiles' `file://mayhem/<target>/testsuite` entries.
#
#   1. mayhem/<target>/testsuite/*.ll — the fuzz corpora, for BOTH targets.
#      Both harnesses take LLVM IR *TEXT* (see mayhem/harnesses/ikos_fuzz_common.hpp: raw bytes fed to
#      the bitcode reader are what made Mayhem run #2 report 149 unsymbolizable LLVM
#      report_fatal_error "defects"), so the corpus is .ll — which also mutates far better than the
#      bitcode container. The programs are ikos's OWN regression suite
#      (analyzer/test/regression/<check>/*.c|*.cpp, 353 files across the 16 check categories: boa,
#      dbz, dfa, fca, mem, null, pcmp, poa, prover, shc, sio, sound, uio, uma, upa, uva), compiled the
#      way ikos's `ikos-scan` driver compiles user code (-O0 -Xclang -disable-O0-optnone) but with
#      -g0: debug info would triple the size of every seed for no extra ikos coverage (the analyzer
#      only warns when a module has none, and the AR FrontendVerifier checks for the attached llvm
#      Value, not for a DILocation). `source_filename` is dropped so a seed does not carry the
#      absolute path it was built from; everything else, including the target triple and datalayout,
#      is kept — ikos reads the datalayout for its pointer/integer widths.
#      Per category we keep the SEED_PER_CATEGORY smallest-to-largest EVENLY SPREAD files under
#      SEED_MAX_BYTES, so all 16 check categories are represented and no single seed is a time sink.
#
#   2. mayhem/oracle-fixtures/*.bc — the FIXED inputs of the behavioral oracle (mayhem/test.sh),
#      compiled from mayhem/oracle-fixtures/src/*.c. These are NOT seeds: they are bitcode, they
#      feed the CLEAN ikos-analyzer-oracle binary through its normal command line, and test.sh asserts
#      their exact check counts — so regenerating them means re-measuring those numbers.
set -euo pipefail

SRC="${SRC:-/mayhem}"
CLANG=/opt/toolchains/llvm14/bin/clang
SEED_MAX_BYTES="${SEED_MAX_BYTES:-8192}"
SEED_PER_CATEGORY="${SEED_PER_CATEGORY:-5}"

[ -x "$CLANG" ] || { echo "FATAL: $CLANG missing (run this inside the commit image)" >&2; exit 1; }

# ---- 1. the fuzz corpora -----------------------------------------------------------------------
REGRESSION="$SRC/analyzer/test/regression"
for t in ikos-analyzer ikos-pp; do
  rm -rf "${SRC:?}/mayhem/$t/testsuite"
  mkdir -p "$SRC/mayhem/$t/testsuite"
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

shopt -s nullglob
for dir in "$REGRESSION"/*/; do
  category="$(basename "$dir")"
  # Only the check-category directories hold programs; the suite's helpers (runalltests, *.py) have none.
  srcs=("$dir"*.c "$dir"*.cpp)
  [ "${#srcs[@]}" -gt 0 ] || continue
  mkdir -p "$WORK/$category"
  while IFS= read -r s; do
    name="$(basename "$s")"; name="${name%.*}"
    out="$WORK/$category/$name.ll"
    "$CLANG" -S -emit-llvm -O0 -g0 -Xclang -disable-O0-optnone -w \
             -I"$SRC/analyzer/include" -o "$out" "$s" 2>/dev/null || { rm -f "$out"; continue; }
    sed -i '/^source_filename = /d' "$out"
    [ "$(stat -c%s "$out")" -le "$SEED_MAX_BYTES" ] || rm -f "$out"
  done < <(printf '%s\n' "${srcs[@]}" | sort)
done
shopt -u nullglob

python3 - "$WORK" "$SRC/mayhem/ikos-analyzer/testsuite" "$SRC/mayhem/ikos-pp/testsuite" \
         "$SEED_PER_CATEGORY" <<'PY'
import os, shutil, sys
work, out_analyzer, out_pp, per_category = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
total = 0
for category in sorted(os.listdir(work)):
    cdir = os.path.join(work, category)
    files = sorted(os.listdir(cdir))
    if not files:
        continue
    # Sort by size, then take `per_category` evenly spread picks: the smallest, the largest that
    # still fits the cap, and the sizes in between — a size spread, not just the trivial programs.
    files.sort(key=lambda f: (os.path.getsize(os.path.join(cdir, f)), f))
    n = min(per_category, len(files))
    picks = [files[round(i * (len(files) - 1) / max(n - 1, 1))] for i in range(n)]
    for f in dict.fromkeys(picks):
        src = os.path.join(cdir, f)
        name = "%s-%s" % (category, f)
        shutil.copyfile(src, os.path.join(out_analyzer, name))
        shutil.copyfile(src, os.path.join(out_pp, name))
        total += 1
    print("%-8s %2d of %3d candidates" % (category, len(dict.fromkeys(picks)), len(files)))
print("total seeds per target: %d" % total)
PY

# ---- 2. the behavioral-oracle fixtures -----------------------------------------------------------
# Exactly as ikos's own `ikos-scan` driver compiles user code (analyzer/python/ikos/scan.py):
# -g -O0 -Xclang -disable-O0-optnone -D_FORTIFY_SOURCE=0. -fdebug-compilation-dir keeps the
# DICompileUnit directory (and so the fixture bytes) path-independent.
SEEDSRC="$SRC/mayhem/oracle-fixtures/src"
FIXTURES="$SRC/mayhem/oracle-fixtures"
# The compile runs FROM $SEEDSRC with a bare relative filename, exactly as it did when the committed
# fixtures were produced: the file name reaches the bitcode (source_filename, DIFile), so compiling
# the same source by absolute path would change the fixture bytes — and with them the check counts
# mayhem/test.sh asserts. Regenerating here must be byte-identical; it is a `cmp` away.
mkdir -p "$FIXTURES"
( cd "$SEEDSRC"
  for c in *.c; do
    "$CLANG" -g -O0 -Xclang -disable-O0-optnone -D_FORTIFY_SOURCE=0 -fdebug-compilation-dir=/seed-src \
             -c -emit-llvm "$c" -o "$FIXTURES/${c%.c}.bc"
  done )

echo "== seeds:"
ls "$SRC/mayhem/ikos-analyzer/testsuite" | wc -l
du -sh "$SRC/mayhem/ikos-analyzer/testsuite" "$SRC/mayhem/ikos-pp/testsuite" "$FIXTURES"
