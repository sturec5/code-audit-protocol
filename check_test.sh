#!/usr/bin/env bash
# check_test.sh — the fail-open cases check.sh must never regress on.
#
# Every case here is a way the gate once reported success without having
# checked anything. A broken gate and a working gate print almost the same
# thing, so the only way to keep this one honest is to assert the failures.
#
# The suite is held to its own standard. A case whose fixture cannot be built
# has not run, and counting it as neither pass nor fail would make this file the
# thing it exists to prevent — measured: with mktemp failing, an earlier version
# printed "1 passed, 0 failed" and exited 0 with eight cases silently gone.
#
#   ./check_test.sh
#
# Mutation is how you check the suite still bites. Strip a scan from a copy of
# check.sh and at least one case below must go red:
#   sed -i '' '/case-sensitive terms/d' check.sh && ./check_test.sh

set -uo pipefail
cd "$(dirname "$0")" || exit 2
GATE="$PWD/check.sh"

pass=0
fail=0

# A temp directory or nothing. Returns non-zero rather than an empty string,
# because `cd ""` succeeds as a no-op in bash — an unchecked mktemp would run
# the fixture in this repository and overwrite .gitignore and denylist.local.
mk() {
  local d
  d=$(mktemp -d) || return 1
  [ -n "$d" ] && [ -d "$d" ] || return 1
  printf '%s' "$d"
}

# Build a throwaway repo, run the gate in it, compare the exit code.
# $1 label · $2 expected exit · $3 setup body (runs inside the temp repo)
#
# Nothing is staged for you. check.sh reads both the index and untracked files,
# and a blanket `git add -A` here once staged everything — which left the
# untracked half of that read with no test at all while a case named for it
# passed. Cases that mean to exercise the index stage explicitly.
case_() {
  local label="$1" want="$2" body="$3" nogit="${4:-}" tmp got
  if ! tmp=$(mk); then
    printf '  FAIL  %-52s fixture not created\n' "$label"
    fail=$((fail + 1))
    return
  fi
  (
    cd "$tmp" || exit 2
    if [ -z "$nogit" ]; then
      git init -q .
      printf '*.local\n' > .gitignore
    fi
    cp "$GATE" .
    eval "$body"
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

# One category populated, the rest empty. check.sh scans four separately and
# only the case-insensitive one used to be tested, so deleting any of the other
# three left the suite fully green.
deny_only() {
  local c
  for c in INSENSITIVE SENSITIVE NUMBERS LOCALE_CHARS; do
    if [ "$c" = "$1" ]; then printf "%s='%s'\n" "$c" "$2"; else printf "%s=''\n" "$c"; fi
  done > denylist.local
}

deny() { deny_only INSENSITIVE "$1"; }

printf 'check_test.sh — fail-open regression locks\n\n'

# 1 — the baseline. Without this the rest prove nothing: a gate that always
# fails would pass every other case here. Staged, so the index half of the file
# list is under test.
case_ 'seeded term is found (staged)' 1 \
  'deny secretproject; echo "secretproject" > a.md; git add a.md >/dev/null 2>&1'

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
# git ls-files could not see it. The offending file is never staged; a clean file
# is, and that is load-bearing. With nothing in the index, dropping --others
# empties the file list and check.sh falls back to a bare `find` for *.md, which
# finds the file anyway and hides the loss — measured: the case passed with
# --others deleted until this line existed.
case_ 'untracked file is scanned' 1 \
  'deny secretproject; echo "nothing here" > tracked.md; git add tracked.md >/dev/null 2>&1
   echo "secretproject" > brand-new.md'

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

# 7 — the three scan categories that had no test at all. Each of these goes red
# if its scan line is deleted from check.sh; before they existed, all three
# could be removed with the suite reporting nine passes.
case_ 'case-sensitive term matches' 1 \
  "deny_only SENSITIVE 'SecretProject'; echo 'SecretProject ships here' > a.md"

# ...and the same scan must NOT match a different casing, or it is not the
# case-sensitive category and the distinction the denylist draws is a fiction.
case_ 'case-sensitive term ignores other casing' 0 \
  "deny_only SENSITIVE 'SecretProject'; echo 'secretproject ships here' > a.md"

case_ 'measured figure is found' 1 \
  "deny_only NUMBERS '2185'; echo 'we ran 2185 trades' > a.md"

# The pattern and the seeded text are both built from bytes at runtime, for the
# same reason case 5 is.
case_ 'non-English letter is found' 1 \
  'deny_only LOCALE_CHARS "$(printf "[\303\251]")"; printf "caf\303\251 notes\n" > a.md'

# 8 — a push transfers the message and the author, not just the tree. The gate
# was blind to both, and shipped a foreign machine's username 2 commits deep
# with every file scan green.
commit_as() { # $1 name, $2 email, $3 message
  git add -A >/dev/null 2>&1
  git -c user.name="$1" -c user.email="$2" commit -qm "$3"
}

case_ 'denylisted term in a commit message' 1 \
  'deny secretproject; echo clean > a.md
   commit_as t t@example.com "this one mentions secretproject in the subject"'

case_ 'denylisted term in a branch name' 1 \
  'deny secretproject; echo clean > a.md
   commit_as t t@example.com "ordinary message"
   git branch secretproject-wip'

# 9 — authorship is an allowlist, so the case that matters is the identity the
# denylist would never have caught. "stranger" is on no list here.
case_ 'undeclared commit author is rejected' 1 \
  'deny_only INSENSITIVE nomatchhere
   printf "EXPECTED_IDENTITY=%s\n" "\"expected <ok@example.com>\"" >> denylist.local
   echo clean > a.md
   commit_as stranger stranger@example.com "ordinary message"'

# ...and the mirror, or the check above would also pass while rejecting
# everything, which is a different way of verifying nothing.
case_ 'declared commit author passes' 0 \
  'deny_only INSENSITIVE nomatchhere
   printf "EXPECTED_IDENTITY=%s\n" "\"expected <ok@example.com>\"" >> denylist.local
   echo clean > a.md
   commit_as expected ok@example.com "ordinary message"'

# 10 — the gate must never report a pass over nothing. Excluding denylist.local
# through .git/info/exclude rather than .gitignore leaves the repository with
# no scannable file at all, which is the condition under test.
case_ 'nothing to scan is an error' 2 \
  'rm -f .gitignore
   printf "denylist.local\n" >> .git/info/exclude
   deny secretproject'

# 9 — the non-git fallback, which exists so the gate still works from a tarball.
# Every other case builds a git repo, so this branch had no test: deleting it
# left the suite green. Fourth argument skips git init.
case_ 'non-git checkout still scans' 1 \
  'deny secretproject; echo "secretproject" > a.md' nogit

# 11 — an unrecognised argument once fell through to a full scan.
printf '\n'
if ! tmp=$(mk); then
  printf '  FAIL  %-52s fixture not created\n' 'unknown argument is rejected'
  fail=$((fail + 1))
else
  ( cd "$tmp" && git init -q . && printf '*.local\n' > .gitignore && cp "$GATE" . \
    && printf "INSENSITIVE='x'\nSENSITIVE=''\nNUMBERS=''\nLOCALE_CHARS=''\n" > denylist.local )
  ( cd "$tmp" && ./check.sh --nonsense >/dev/null 2>&1 ); got=$?
  rm -rf "$tmp"
  if [ "$got" -eq 2 ]; then
    printf '  ok    %-52s exit %s\n' 'unknown argument is rejected' "$got"; pass=$((pass + 1))
  else
    printf '  FAIL  %-52s exit %s, wanted 2\n' 'unknown argument is rejected' "$got"; fail=$((fail + 1))
  fi
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
