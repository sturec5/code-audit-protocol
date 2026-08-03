# Contributing

The most useful contribution is an overlay for a failure class nobody has
covered yet. The second most useful is deleting something that does not earn
its place.

## Before anything else

```bash
cp denylist.example denylist.local   # first time only, then fill it in
./check.sh
```

This repository has to stay generic to be worth anything. `check.sh` scans for
project names, domain vocabulary, real file paths, measured figures, and —
when configured — non-English text. Run it before every push; it has to
exit 0.

The terms it scans for live in `denylist.local`, which is gitignored — a
denylist committed to a public repository publishes exactly what it was
written to protect. Keep yours untracked.

If your contribution trips it on a genuine false positive, narrow the pattern
rather than deleting it, and say why in the pull request.

## Contributing an overlay

Overlays are the growth area. A good one covers a failure class that is
catastrophic in its domain and unremarkable outside it.

Start from [`OVERLAY_TEMPLATE.md`](OVERLAY_TEMPLATE.md), then check yours
against this before opening a pull request:

- **Named after the failure, not the feature.** "Session handling" is a
  feature. "A logged-out user still acting" is a failure class.
- **Six to eight invariants.** Fifteen means you wrote a specification.
- **Every invariant is provable yes or no.** "Input is validated" has no
  answer. "No write path reaches storage before the validator returns" does.
- **Every invariant names its evidence.** A specific test, query, trace, or
  exhaustive call-site check — something that can fail. Not "review the code".
- **Violations are Blockers by definition.** If a violation could ever be
  acceptable, it belongs in a generic phase instead.
- **The scope boundary is stated.** An overlay that appears to cover everything
  gets treated as covering nothing.
- **Every example is invented.** Do not paste a real incident from a codebase
  you do not have permission to publish. Write the minimal illustrative case
  instead — it reads better anyway.

Domains that would be genuinely useful and are not here yet: scheduling and
time zones, multi-step workflows with compensation, real-time and presence,
file upload and processing, rate limiting and quota, regulated record-keeping.

## Contributing a phase

Higher bar. The 54 phases are meant to be exhaustive at the level of failure
*classes*, so a new one has to be a class with no existing home — not a
variation on an existing phase.

Open an issue first, describing:

1. the failure, concretely, with the shape of a real occurrence
2. which existing phase you would expect to catch it, and why it does not
3. whether it belongs as an overlay instead — most proposals do

A phase that says "and be careful about X" is a comment, not a phase.

## Contributing a fix

Corrections to wording, broken links, contradictions between the protocol and
the templates, and phases whose guidance has gone stale are all welcome and
need no issue first.

Match the existing voice: second person, imperative, no hedging, no
exclamation. The protocol tells someone what to inspect and why — it does not
motivate them.

## What will not be merged

- Tool-specific or framework-specific instructions in `AUDIT_PROTOCOL.md`. The
  protocol is WHAT and WHY; commands rot at a different rate and belong in your
  own runbook.
- Vendor recommendations, product mentions, or links to commercial services.
- Content generated wholesale without a stated failure class behind it. Every
  line here should trace to something that actually went wrong somewhere.
- Anything that makes the protocol longer without making an audit better.
