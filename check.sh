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
# It reads four surfaces, because publishing a repository publishes all four:
# working-tree contents, commit messages, ref names, and commit authorship. A
# term scrubbed from the files still ships if it sits in a commit message, and
# no diff will ever show it to you. That is not hypothetical — it is how this
# check came to exist.
#
# Authorship is checked differently from the rest. A denylist cannot catch an
# identity nobody thought to list, and the leak that prompted this was another
# machine's username, denylisted only by luck. So authorship is compared against
# EXPECTED_IDENTITY and anything else fails, whether or not it is on the list.
#
# What it does NOT look at, stated so the pass is not read as wider than it is:
#   - binary files. grep -I skips them, so a project name in PDF text or image
#     metadata passes.
#   - anything gitignored, which includes denylist.local itself.
#   - a commit's diff. Only the message, the author, and the current file text.
#   - three files excluded by name: check.sh and denylist.example, which
#     document the format with placeholders and would fail on their own
#     examples, and LICENSE, which has to carry a real copyright holder. That
#     last one is the only shipped file holding an identity on purpose, so it
#     is the one exclusion worth remembering when you fork this.
#
#   ./check.sh          scan the repo
#   ./check.sh --list   print the patterns and exit

set -uo pipefail
cd "$(dirname "$0")" || exit 2

# Bracket expressions match bytes rather than characters under a non-UTF-8
# locale, so a multi-byte punctuation mark can match a single-byte class. Set
# unconditionally: `${LC_ALL:-...}` leaves an inherited LC_ALL=C in place, which
# is exactly the CI case this guard exists for. C.UTF-8 is present on macOS,
# glibc, and musl; en_US.UTF-8 is not.
export LC_ALL=C.UTF-8

# The terms themselves are the sensitive part, so they are not in this file.
# denylist.local is gitignored; denylist.example shows the format.
if [ ! -f denylist.local ]; then
  printf 'check.sh: denylist.local not found.\n\n'
  printf '  cp denylist.example denylist.local\n\n'
  printf 'Then fill it in with the terms that must not ship. It stays untracked.\n'
  exit 2
fi

INSENSITIVE='' SENSITIVE='' NUMBERS='' LOCALE_CHARS='' EXPECTED_IDENTITY=''
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

case "${1:-}" in
  --list)
    # Prints the real terms. Never run this where the output is captured — a
    # CI log is read by more people than the repository is.
    printf 'case-insensitive:\n  %s\n\ncase-sensitive:\n  %s\n\nnumbers:\n  %s\n\nlocale:\n  %s\n' \
      "$PAT_I" "$PAT_S" "$PAT_N" "$PAT_L"
    exit 0
    ;;
  '') ;;
  *)
    printf 'check.sh: unknown argument %s\n\n  ./check.sh          scan\n  ./check.sh --list   print the patterns\n' "$1"
    exit 2
    ;;
esac

# Every pattern empty means nothing was configured. Reporting that as a pass is
# the same lie as passing over zero files.
if [ -z "$PAT_I$PAT_S$PAT_N$PAT_L" ]; then
  printf 'check.sh: denylist.local configures no patterns. Nothing would be checked.\n'
  exit 2
fi

# denylist.example is excluded for the same reason check.sh itself is: it
# documents the format with placeholders, and scanning it would make the
# documented first-run flow fail on its own examples.
# Untracked-but-not-ignored files are included: work you have written but not
# staged yet is exactly when a leak is most likely, and denylist.local stays
# out because it is gitignored.
# core.quotePath=false: by default git C-quotes any non-ASCII path, producing a
# string that names no file. The scan would then fail on exactly the files a
# non-English-text check most needs to read.
FILES=$(git -c core.quotePath=false ls-files --cached --others --exclude-standard 2>/dev/null \
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
    printf '\n  %s — SCAN DID NOT RUN (bad pattern, or a listed file could not be read)\n' "$label"
    fail=2
    return
  fi
  if [ -n "$hits" ]; then
    printf '\n  %s\n' "$label"
    printf '%s\n' "$hits" | sed 's/^/    /'
    fail=1
  fi
}

# The same failure handling as scan(), reading a blob on stdin instead of a file
# list. Commit messages and ref names are text that ships; they just do not live
# in the working tree.
scan_text() { # label, pattern, grep-flags, text
  local label="$1" pattern="$2" flags="$3" text="$4" hits rc
  hits=$(printf '%s\n' "$text" | grep -n $flags -E -- "$pattern"); rc=$?
  if [ "$rc" -ge 2 ]; then
    printf '\n  %s — SCAN DID NOT RUN (bad pattern)\n' "$label"
    fail=2
    return
  fi
  if [ -n "$hits" ]; then
    printf '\n  %s\n' "$label"
    printf '%s\n' "$hits" | sed 's/^/    /'
    fail=1
  fi
}

# Every message line carries its own short sha, so a hit names the commit to fix
# rather than a line number in a blob nobody can navigate.
history_messages() {
  git log --all --format='%h%x1f%B%x1e' 2>/dev/null \
    | awk -v RS='\036' -F'\037' 'NF>1 { n=split($2, L, "\n"); for (i=1;i<=n;i++) if (L[i] != "") print $1 " " L[i] }'
}

RAN='' SKIPPED=''
ran()  { RAN="$RAN${RAN:+, }$1"; }
skip() { SKIPPED="$SKIPPED${SKIPPED:+, }$1"; }

printf 'check.sh — scanning %s files\n' "$(printf '%s\n' "$FILES" | grep -c .)"

if [ -n "$PAT_I" ]; then scan 'project / agent / domain names' "$PAT_I" '-Ii'; ran 'names'; else skip 'names'; fi
if [ -n "$PAT_S" ]; then scan 'case-sensitive terms'           "$PAT_S" '-I';  ran 'case-sensitive'; else skip 'case-sensitive'; fi
if [ -n "$PAT_N" ]; then scan 'measured figures'               "$PAT_N" '-Ii'; ran 'figures'; else skip 'figures'; fi
if [ -n "$PAT_L" ]; then scan 'non-English letters'            "$PAT_L" '-I';  ran 'non-English'; else skip 'non-English'; fi

# --- what a push transfers besides the files -------------------------------
if git rev-parse --git-dir >/dev/null 2>&1 && [ -n "$(git rev-list -n1 --all 2>/dev/null)" ]; then
  TERMS=$(printf '%s\n%s' "$PAT_I" "$PAT_S" | grep -v '^$' | paste -sd'|' - | sed 's/||*/|/g; s/^|//; s/|$//')
  if [ -n "$TERMS" ]; then
    scan_text 'commit messages' "$TERMS" '-i' "$(history_messages)"
    scan_text 'ref names'       "$TERMS" '-i' "$(git for-each-ref --format='%(refname)' 2>/dev/null)"
    ran 'messages, refs'
  else
    skip 'messages, refs'
  fi

  if [ -n "$EXPECTED_IDENTITY" ]; then
    # Not a denylist check. Anything that is not a declared identity fails,
    # because the identity you never thought to list is the one that leaks.
    STRAY=$(git log --all --format='%an <%ae>%n%cn <%ce>' 2>/dev/null | sort -u | grep -vxF "$EXPECTED_IDENTITY")
    if [ -n "$STRAY" ]; then
      printf '\n  commit authorship — not in EXPECTED_IDENTITY\n'
      printf '%s\n' "$STRAY" | sed 's/^/    /'
      fail=1
    fi
    ran 'authorship'
  else
    skip 'authorship'
  fi
else
  skip 'messages, refs, authorship (no git history here)'
fi

if [ "$fail" -eq 2 ]; then
  printf '\nERROR — a pattern in denylist.local is not valid regex, so that scan\n'
  printf 'never ran. Nothing here was verified. Fix the pattern and run again.\n'
  exit 2
fi

if [ "$fail" -eq 0 ]; then
  printf '\nPASS — no denylisted term found.\n'
  printf '  checked      : %s\n' "${RAN:-nothing}"
  [ -n "$SKIPPED" ] && printf '  not configured: %s\n' "$SKIPPED"
  printf 'This is the mechanical gate only. Read the diff before publishing.\n'
  exit 0
fi

printf '\nFAIL — remove or rewrite the lines above, then run again.\n'
printf 'If a hit is a genuine false positive, narrow the pattern rather than\n'
printf 'deleting it, and say why in the commit.\n'
exit 1
