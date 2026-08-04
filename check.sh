#!/usr/bin/env bash
# check.sh — publication gate.
#
# This protocol is distilled from audit practice on private codebases. Nothing
# specific to those codebases may ship: no project names, no domain vocabulary,
# no real file paths, no measured numbers, and — when configured — no
# non-English text.
#
# Run before every push. Exit 0 means the mechanical check passed — it does not
# mean the text is clean. A human still reads it.
#
#   ./check.sh          scan the repo
#   ./check.sh --list   print the patterns and exit

set -uo pipefail
cd "$(dirname "$0")" || exit 2

# Bracket expressions match bytes rather than characters under a non-UTF-8
# locale, so a multi-byte punctuation mark can match a single-byte class.
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# The terms themselves are the sensitive part, so they are not in this file.
# denylist.local is gitignored; denylist.example shows the format.
if [ ! -f denylist.local ]; then
  printf 'check.sh: denylist.local not found.\n\n'
  printf '  cp denylist.example denylist.local\n\n'
  printf 'Then fill it in with the terms that must not ship. It stays untracked.\n'
  exit 2
fi

INSENSITIVE='' SENSITIVE='' NUMBERS='' LOCALE_CHARS=''
# shellcheck source=denylist.example
. ./denylist.local

# Trim each line, drop empties, join with |. Interior spaces survive — terms
# like "legacy service name" are multi-word and deleting spaces would silently
# disable them.
flatten() {
  printf '%s\n' "$1" \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | grep -v '^$' \
    | paste -sd'|' - \
    | sed 's/||*/|/g; s/^|//; s/|$//'
}

PAT_I=$(flatten "$INSENSITIVE")
PAT_S=$(flatten "$SENSITIVE")
PAT_N=$(flatten "$NUMBERS")
PAT_L=$(flatten "$LOCALE_CHARS")

if [ "${1:-}" = "--list" ]; then
  printf 'case-insensitive:\n  %s\n\ncase-sensitive:\n  %s\n\nnumbers:\n  %s\n\nlocale:\n  %s\n' \
    "$PAT_I" "$PAT_S" "$PAT_N" "$PAT_L"
  exit 0
fi

# denylist.example is excluded for the same reason check.sh itself is: it
# documents the format with placeholders, and scanning it would make the
# documented first-run flow fail on its own examples.
# Untracked-but-not-ignored files are included: work you have written but not
# staged yet is exactly when a leak is most likely, and denylist.local stays
# out because it is gitignored.
FILES=$(git ls-files --cached --others --exclude-standard 2>/dev/null \
        | grep -vE '^(check\.sh|LICENSE|denylist\.example)$')
if [ -z "$FILES" ]; then
  printf 'check.sh: not a git checkout — falling back to *.md and *.json only\n'
  FILES=$(find . -type f \( -name '*.md' -o -name '*.json' \) -not -path './.git/*' | sed 's|^\./||')
fi
if [ -z "$FILES" ]; then
  printf 'check.sh: nothing to scan. Refusing to report a pass over zero files.\n'
  exit 2
fi

fail=0
# Files go in as an array rather than through xargs, which on some systems
# strips the locale and re-triggers the byte-matching problem above.
IFS=$'\n' read -r -d '' -a FILE_LIST < <(printf '%s\0' "$FILES" | tr -d '\0'; printf '\0')

scan() { # label, pattern, grep-flags
  local label="$1" pattern="$2" flags="$3" hits rc
  # grep: 0 = matched, 1 = no match, >=2 = bad pattern or unreadable file.
  # Treating >=2 as "no match" would turn a broken pattern into a silent pass,
  # which is the one failure this gate must never produce.
  hits=$(grep -n $flags -E -- "$pattern" "${FILE_LIST[@]}"); rc=$?
  if [ "$rc" -ge 2 ]; then
    printf '\n  %s — SCAN DID NOT RUN (grep rejected the pattern)\n' "$label"
    fail=2
    return
  fi
  if [ -n "$hits" ]; then
    printf '\n  %s\n' "$label"
    printf '%s\n' "$hits" | sed 's/^/    /'
    fail=1
  fi
}

printf 'check.sh — scanning %s files\n' "$(printf '%s\n' "$FILES" | grep -c .)"

[ -n "$PAT_I" ]        && scan 'project / agent / domain names' "$PAT_I" '-Ii'
[ -n "$PAT_S" ]        && scan 'case-sensitive terms'           "$PAT_S" '-I'
[ -n "$PAT_N" ]        && scan 'measured figures'               "$PAT_N" '-Ii'
[ -n "$PAT_L" ]        && scan 'non-English letters'            "$PAT_L" '-I'

if [ "$fail" -eq 2 ]; then
  printf '\nERROR — a pattern in denylist.local is not valid regex, so that scan\n'
  printf 'never ran. Nothing here was verified. Fix the pattern and run again.\n'
  exit 2
fi

if [ "$fail" -eq 0 ]; then
  printf '\nPASS — no denylisted term found.\n'
  printf 'This is the mechanical gate only. Read the diff before publishing.\n'
  exit 0
fi

printf '\nFAIL — remove or rewrite the lines above, then run again.\n'
printf 'If a hit is a genuine false positive, narrow the pattern rather than\n'
printf 'deleting it, and say why in the commit.\n'
exit 1
