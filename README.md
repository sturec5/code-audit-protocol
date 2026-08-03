# The Audit Protocol

A 54-phase, technology-neutral audit taxonomy for finding the defects that
feature testing misses — plus a way to pin the failures that are specific to
*your* system, which is the part generic checklists structurally cannot cover.

Written for people who direct coding agents and need the review to be
repeatable rather than a matter of how the model felt that day.

> Community project. Not affiliated with or endorsed by Anthropic.

## The problem with audit checklists

They come in two kinds and both fail.

**Generic ones transfer but find nothing.** A list that applies to every
codebase asks about error handling and input validation. It never asks whether
this particular payment can charge twice, because it cannot know that.

**Project-specific ones find plenty but transfer to nothing.** They encode real
scars, which is why they work — and why they are useless to anyone else, and
useless to you the moment the project changes shape.

This repository splits the two apart.

| Layer | What it is | Does it transfer? |
| --- | --- | --- |
| [`AUDIT_PROTOCOL.md`](AUDIT_PROTOCOL.md) | 54 phases of failure classes, each tagged `[CORE]`, `[CONDITIONAL]`, or a scoped core tag, with tiers, a finding standard, and a change-triage table | Yes — unchanged, across languages and stacks |
| [`OVERLAY_TEMPLATE.md`](OVERLAY_TEMPLATE.md) | The six-to-eight invariants that are specific to your system | No — and that is the point |

An overlay runs **before** the generic phases, forces the change to **T3**
regardless of how small the diff looks, and its violations are **Blockers by
definition**. That inversion — domain first, generic second — is the whole
idea.

## Quick start

```bash
curl -O https://raw.githubusercontent.com/sturec5/claude-audit-protocol/main/AUDIT_PROTOCOL.md
```

Then, in your agent session:

```
Audit the current change against AUDIT_PROTOCOL.md.
Pick the tier and the phases from the change-triage table, tell me which
phases you skipped and why, and report findings in the finding standard.
```

As a Claude Code plugin, available in every project:

```
/plugin marketplace add sturec5/claude-audit-protocol
/plugin install audit-protocol@claude-audit-protocol
```

## Writing your overlay

Start from the failure, not the feature. "Checkout flow" is a feature.
"Money moved twice" is a failure class, and it survives the refactor that
renames checkout.

Three worked examples ship here — read them for the shape, then throw them away
and write your own:

- [`overlays/payments.md`](overlays/payments.md) — money moved twice, moved wrong, or not moved at all
- [`overlays/access-control.md`](overlays/access-control.md) — one principal reaching another's data or privileges
- [`overlays/data-pipeline.md`](overlays/data-pipeline.md) — leakage, non-determinism, and silent schema drift

Each invariant is a claim that can be proved yes or no with named evidence. If
the only proof is "I read it and it looked right", it is not an invariant yet.

## What is here

```
AUDIT_PROTOCOL.md        the 54 phases, tiers, finding standard, change triage
OVERLAY_TEMPLATE.md      how to write your own domain overlay
overlays/                three worked examples
templates/FINDING.md     one finding, every field, with a worked example
templates/AUDIT_STATUS.md   the standing "can this ship right now" record
check.sh                 denylist scanner used to keep this repo generic
denylist.example         template for the scanner's term list
.claude-plugin/, skills/    the Claude Code plugin wrapper
```

## Three rules that make the difference

**An unrun checklist is not evidence a system is safe.** The protocol is a list
of questions, not a certificate. Phases you skipped get recorded as skipped,
with the reason.

**A green suite does not prove the test is meaningful.** Phases 31 and 39 exist
to check the tests themselves, because a passing assertion that would also pass
against broken code is worse than no assertion.

**Never report a hunch as a defect.** Every finding carries evidence, a
confirmed-or-plausible status, impact, and the smallest reproduction. A
finding that is neither CONFIRMED nor labeled PLAUSIBLE is a rumor with an ID
number.

## Where this came from

Distilled from audit protocols used across several production codebases — a
user-facing web application, a real-time service, and a data-processing system.
The phases in the original grew one at a time, each added after something got
through that nothing on the list would have caught.

The expansion phases (47-54: security, authorization, storage and recovery,
privacy, accessibility, UX, observability, delivery) are grounded in public
standards rather than one project's habits — OWASP ASVS and API Top 10, the
NIST Privacy Framework and SSDF, WCAG 2.2, and the Google SRE material on
service level objectives. Sources are cited at the end of the protocol.

Nothing project-specific ships here. [`check.sh`](check.sh) is the gate that
keeps it that way; run it before every push. Its term list lives in an
untracked `denylist.local` rather than in the script — the names you are
keeping out of a public repository should not be published by the tool that
keeps them out. [`denylist.example`](denylist.example) shows the format.

## Contributing

Overlays for failure classes not yet covered are the most useful contribution —
see [CONTRIBUTING.md](CONTRIBUTING.md). New phases are a higher bar: a phase
earns its place only when a real failure class has no existing home.

MIT licensed. Use it, fork it, strip the parts you do not need.
