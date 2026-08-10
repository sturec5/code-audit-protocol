# Security policy

## Reporting a problem

Open a [security advisory](https://github.com/sturec5/claude-audit-protocol/security/advisories/new)
for anything that should not be discussed in public. Anything else — a broken
link, a wrong phase number, guidance that is simply mistaken — belongs in a
normal issue.

This is a personal project, not a staffed one. Expect a reply in days rather
than hours, and no bounty.

## What is actually in scope

Almost all of this repository is prose. Two files execute:

- `check.sh` — a local grep over the working tree, plus a read of commit
  messages, ref names and commit authorship, run by the maintainer before
  publishing. It *sources* `denylist.local` as shell, so treat that file as
  code you wrote rather than as data. `check.sh` writes nothing itself and runs
  no git command that alters a repository.
- `.github/verify.py` — a link, manifest, and structure check. Standard library
  only, no network, no writes.

Neither takes untrusted input in normal use, and there are no dependencies to
update. If you find a way to make either write, execute, or exfiltrate
something, that is a real finding and worth reporting.

The Claude Code plugin manifests define no hooks and no commands. Installing
the plugin adds a skill that reads a markdown file — it grants nothing.

## What is not a vulnerability

**A phase that misses a defect class.** The protocol is a list of questions,
not a guarantee. Gaps are worth an issue, and a genuinely uncovered failure
class is a welcome contribution — but a checklist being incomplete is its
normal condition, not a security problem.

**Running the protocol and shipping a bug anyway.** Nothing here certifies
software. It makes the gaps visible and named; it does not close them.

**Advice you disagree with.** Argue it in an issue. That is what issues are
for.

## One thing worth repeating

If you fork this repository and adapt `check.sh` to guard your own work, keep
your term list in `denylist.local`. It is gitignored for a reason: a denylist
committed to a public repository publishes exactly what it was written to
protect.
