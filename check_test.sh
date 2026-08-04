#!/usr/bin/env bash
# check_test.sh — the fail-open cases check.sh must never regress on.
#
# Every case here is a way the gate once reported success without having
# checked anything. A broken gate and a working gate print almost the same
# thing, so the only way to keep this one honest is to assert the failures.
#
#   ./check_test.sh

set -uo pipefail
cd "$(dirname "$0")" || exit 2
GATE="$PWD/check.sh"

pass=0
fail=0

# Build a throwaway repo, run the gate in it, compare the exit code.
# $1 label · $2 expected exit · $3 setup body (runs inside the temp repo)
case_() {
  local label="$1" want="$2" body="$3" tmp got
  tmp=$(mktemp -d) || return
  (
    cd "$tmp" || exit 2
    git init -q .
    printf '*.local\n' > .gitignore
    cp "$GATE" .
    eval "$body"
    git add -A >/dev/null 2>&1
  )
  ( cd "$tmp" && ./check.sh >/dev/null 2>&1 ); got=$?
  rm -rf "$tmp"

  if [ "$got" -eq "$want" ]; then
    printf '  ok    %-52s exit %s\n' "$label" "$got"
    pass=$((pass + 1))
  else
    printf '  FAIL  %-52s exit %s, wanted %s\n' "$label" "$got" "$want"
    fail=$((fail + 1))
  fi
}

deny() { printf "INSENSITIVE='%s'\nSENSITIVE=''\nNUMBERS=''\nLOCALE_CHARS=''\n" "$1" > denylist.local; }

printf 'check_test.sh — fail-open regression locks\n\n'

# 1 — the baseline. Without this the rest prove nothing: a gate that always
# fails would pass every other case here.
case_ 'seeded term is found' 1 \
  'deny secretproject; echo "secretproject" > a.md'

case_ 'clean tree passes' 0 \
  'deny secretproject; echo "nothing here" > a.md'

# 2 — an invalid pattern once disabled its whole category and still printed
# PASS, because grep's exit status was discarded.
case_ 'invalid regex is an error, not a pass' 2 \
  'deny "secretproject|*bad["; echo "secretproject" > a.md'

# 3 — a configured-nothing denylist once passed over a seeded term.
case_ 'empty denylist is an error, not a pass' 2 \
  "printf \"INSENSITIVE=''\nSENSITIVE=''\nNUMBERS=''\nLOCALE_CHARS=''\n\" > denylist.local
   echo secretproject > a.md"

# 4 — work written but not staged is when a leak is most likely, and
# git ls-files could not see it.
case_ 'untracked file is scanned' 1 \
  'deny secretproject; echo "secretproject" > brand-new.md; git add .gitignore denylist.local >/dev/null 2>&1 || true'

# 5 — git C-quotes non-ASCII paths by default, naming a file that does not
# exist. A tool that screens for non-English text was blind to exactly those.
# The name is built from bytes at runtime so this file stays pure ASCII: a
# fixture that hard-codes a non-ASCII letter would be flagged by whatever
# LOCALE_CHARS the person running the gate happens to use.
case_ 'non-ASCII filename is scanned' 1 \
  'deny secretproject; fn=$(printf "cafe-resum\303\251.md"); echo "secretproject" > "$fn"'

# 6 — multi-word terms broke when flatten() deleted interior spaces.
case_ 'multi-word term matches' 1 \
  "deny 'legacy service name'; echo 'built on the legacy service name here' > a.md"

# 7 — the gate must never report a pass over nothing. Excluding denylist.local
# through .git/info/exclude rather than .gitignore leaves the repository with
# no scannable file at all, which is the condition under test.
case_ 'nothing to scan is an error' 2 \
  'rm -f .gitignore
   printf "denylist.local\n" >> .git/info/exclude
   deny secretproject'

# 8 — an unrecognised argument once fell through to a full scan.
printf '\n'
tmp=$(mktemp -d)
( cd "$tmp" && git init -q . && printf '*.local\n' > .gitignore && cp "$GATE" . \
  && printf "INSENSITIVE='x'\nSENSITIVE=''\nNUMBERS=''\nLOCALE_CHARS=''\n" > denylist.local )
( cd "$tmp" && ./check.sh --nonsense >/dev/null 2>&1 ); got=$?
rm -rf "$tmp"
if [ "$got" -eq 2 ]; then
  printf '  ok    %-52s exit %s\n' 'unknown argument is rejected' "$got"; pass=$((pass + 1))
else
  printf '  FAIL  %-52s exit %s, wanted 2\n' 'unknown argument is rejected' "$got"; fail=$((fail + 1))
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
