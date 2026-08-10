## What this changes, and why

<!-- One or two sentences. If it fixes something, say what was wrong rather than
what you did — the diff already shows what you did. -->

## Gates

<!-- CONTRIBUTING has the setup. check.sh cannot run in CI, so it is on you. -->

- [ ] `./check.sh` exits 0
- [ ] `python3 .github/verify.py` exits 0
- [ ] `./check_test.sh` passes
- [ ] Version bumped, **if** this touches `skills/`, `AUDIT_PROTOCOL.md`,
      `OVERLAY_TEMPLATE.md`, `overlays/` or `templates/` — the plugin cache is
      keyed on version, so payload that moves without it reaches nobody. CI
      fails this for you if you forget.

## If this is an overlay

- [ ] Named after the failure, not the feature
- [ ] Six to eight invariants, each provable yes or no
- [ ] Each one names its evidence — a test, query, trace, or call-site check
      that can actually fail
- [ ] Violations are Blockers by definition
- [ ] The scope boundary is stated
- [ ] Every example is invented, not pasted from a codebase you cannot publish

## If this is a new phase

A new phase is the highest bar here. Name the real failure class it covers, and
say which existing phase you expected to catch it and why it did not. "It would
be good to also check X" is not enough — the list stays useful by staying short.

## If a gate flagged a false positive

Narrow the pattern rather than deleting it, and say why here. A gate that gets
loosened without a reason on the record is a gate on its way out.
