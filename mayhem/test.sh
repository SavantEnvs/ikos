#!/usr/bin/env bash
#
# mayhem/test.sh — behavioral oracle for ikos: known-answer tests through the CLEAN analyzer.
#
# Runs /mayhem/ikos-analyzer-oracle (built by mayhem/build.sh with the project's NORMAL flags — no
# sanitizer, no -gdwarf-3, dynamically linked) on FIXED committed inputs (the bitcode fixtures under
# mayhem/oracle-fixtures/, produced by mayhem/gen-seeds.sh from mayhem/oracle-fixtures/src/*.c —
# they are the ORACLE's inputs, deliberately NOT the fuzz corpus: the harnesses take textual IR and
# their corpus churns, while these six modules and the numbers asserted below must never move) with
# every checker enabled and `--display-checks=all`, and asserts EXACT computed results twice over:
#   1. the per-status counts of the check lines the analyzer prints (ok / warning / error /
#      unreachable), and
#   2. the same analysis read back out of the sqlite result database it wrote (`checks` table, rows
#      grouped by status: 0 ok, 1 warning, 2 error, 3 unreachable), via python3's sqlite3 module.
# A patch that neuters the program to a no-op (or the verify-repo sabotage shim, which LD_PRELOADs a
# constructor that _exit(0)s the binary before it parses anything) prints nothing and writes no
# database, so every assertion FAILS. bash/coreutils/python3 do the comparison and are whitelisted by
# the shim, so the check happens where sabotage cannot hide. Probes are unconditional: a missing
# binary or fixture is a FAILURE, never a skip. This script only RUNS things — it never compiles.
# Emits a CTRF summary + a compact `CTRF {...}` stdout marker; exit non-zero iff failed>0.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
SRC="${SRC:-/mayhem}"
cd "$SRC"

ORACLE=/mayhem/ikos-analyzer-oracle
FIXTURES="$SRC/mayhem/oracle-fixtures"
ANALYSES="boa,dbz,nullity,prover,upa,uva,sio,uio,shc,poa,pcmp,sound,fca,dca,dfa"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

# Fail loudly if build.sh did not produce the oracle binary (a build bug, not a skip).
if [ ! -x "$ORACLE" ]; then
  echo "FATAL: $ORACLE missing/not executable — mayhem/build.sh did not build the oracle" >&2
  emit_ctrf "ikos-kat" 0 1 0
  exit 1
fi

TMPD="$(mktemp -d "${TMPDIR:-/tmp}/ikos-kat.XXXXXX")"
trap 'rm -rf "$TMPD"' EXIT

passed=0
failed=0

# kat_seed <name> <ok> <warning> <error> <unreachable> <db0> <db1> <db2> <db3>
#   Runs the oracle on $FIXTURES/<name>.bc and asserts (a) the exact number of "[ok]" / "[warning]" /
#   "[error]" / "[unreachable]" check lines printed by --display-checks=all (every output line is one
#   check message: `<file>:<line>:<col>: [<status>] <check>(...)`; nothing else may be printed), and
#   (b) the exact per-status row counts in the sqlite `checks` table of the database it wrote (status
#   0 ok, 1 warning, 2 error, 3 unreachable). The database stores one row per check while the display
#   prints one line per check message, so the two families of numbers differ and are asserted
#   independently.
kat_seed() {
  local name="$1" want_ok="$2" want_warn="$3" want_err="$4" want_unr="$5"
  local want_db0="$6" want_db1="$7" want_db2="$8" want_db3="$9"
  local bc="$FIXTURES/$name.bc" db="$TMPD/$name.db" out="$TMPD/$name.out"
  local got_ok got_warn got_err got_unr got_other got_db want_db
  if [ ! -f "$bc" ]; then
    echo "FAIL  $name: fixture $bc missing"; failed=$((failed + 2)); return
  fi
  rm -f "$db"
  "$ORACLE" -a="$ANALYSES" --entry-points=main --progress=no --display-checks=all -o="$db" "$bc" >"$out" 2>&1
  got_ok=$(grep -cE ' \[ok\] '           "$out")
  got_warn=$(grep -cE ' \[warning\] '    "$out")
  got_err=$(grep -cE ' \[error\] '       "$out")
  got_unr=$(grep -cE ' \[unreachable\] ' "$out")
  got_other=$(grep -cvE ' \[(ok|warning|error|unreachable)\] ' "$out")
  if [ "$got_ok" = "$want_ok" ] && [ "$got_warn" = "$want_warn" ] && [ "$got_err" = "$want_err" ] \
     && [ "$got_unr" = "$want_unr" ] && [ "$got_other" = 0 ]; then
    echo "PASS  $name: display-checks ok=$got_ok warning=$got_warn error=$got_err unreachable=$got_unr"
    passed=$((passed + 1))
  else
    echo "FAIL  $name: display-checks want ok=$want_ok warning=$want_warn error=$want_err unreachable=$want_unr (other=0), got ok=$got_ok warning=$got_warn error=$got_err unreachable=$got_unr other=$got_other"
    sed 's/^/        /' "$out" | head -20
    failed=$((failed + 1))
  fi
  want_db="0=$want_db0 1=$want_db1 2=$want_db2 3=$want_db3"
  got_db=$(python3 - "$db" <<'PY' 2>/dev/null
import sqlite3, sys
con = sqlite3.connect("file:%s?mode=ro" % sys.argv[1], uri=True)
rows = dict(con.execute("select status, count(*) from checks group by status").fetchall())
print("0=%d 1=%d 2=%d 3=%d" % (rows.get(0, 0), rows.get(1, 0), rows.get(2, 0), rows.get(3, 0)))
PY
)
  if [ "$got_db" = "$want_db" ]; then
    echo "PASS  $name: sqlite checks by status [$got_db]"
    passed=$((passed + 1))
  else
    echo "FAIL  $name: sqlite checks by status want [$want_db] got [${got_db:-<no database>}]"
    failed=$((failed + 1))
  fi
}

# Known-answer values measured on the committed fixtures with the clean ikos-analyzer (same flags):
#            display lines: ok  warning error unreachable | sqlite rows: status 0    1   2   3
# Regenerating the seeds (mayhem/gen-seeds.sh) requires re-measuring these.
kat_seed dbz                  124   1     0     0                       108   1   0   0
kat_seed boa                  176  12     0     0                       150  10   0   0
kat_seed null                 164   1     0     0                       141   1   0   0
kat_seed uva                  200   8     2     0                       170   8   2   0
kat_seed safe                 572  42     0    10                       487  39   0  10
kat_seed loop                 548  49     0     0                       476  40   0   0

emit_ctrf "ikos-kat" "$passed" "$failed" 0
