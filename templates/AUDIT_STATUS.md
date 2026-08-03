# Audit status template

The standing record of where a codebase actually is. One file per project, kept
current — not one file per audit, accumulating in a folder nobody opens.

Its job is to answer a single question honestly: can this ship right now, and
if not, what exactly is in the way. Everything else in it serves that answer.

Replace the bracketed guidance as you fill it in.

---

# <Project> — audit status

**Last audit:** <date> · **Tier:** <T0-T4> · **Revision:** <commit or tag>
**Protocol version:** <which version of the protocol and which overlays ran>

## Release decision

<One of: SHIP · SHIP WITH CONDITIONS · DO NOT SHIP. Then two or three sentences
of why, in plain language. This is the line people read; make it survive being
quoted alone.>

<If SHIP WITH CONDITIONS, list the conditions here as a numbered list. Each one
must be checkable by someone who was not in the audit.>

## Scope

- **Audited:** <what was actually examined — the change, feature, module, or
  journey. Be narrow. A broad claim here is the most common way an audit
  status document becomes a lie.>
- **Phases run:** <numbers>
- **Phases skipped:** <numbers, each with the reason. "Not applicable" is a
  reason; "no time" is also a reason and belongs here too.>
- **Overlays run:** <which, or none>
- **Not audited:** <the areas deliberately outside this pass, and what would
  trigger auditing them>

## Automated evidence

<What ran, what it said. Commands and their results — not a claim that they
pass. A reader should be able to re-run these and compare.>

| Check | Result | Notes |
| --- | --- | --- |
| <test suite> | <n passed, n failed> | <anything a bare count hides> |
| <type check> | <clean / n errors> | |
| <linter> | <clean / n problems> | <noise level matters: a linter with 60 pre-existing warnings is not a signal> |
| <build> | <ok / failed> | |
| <coverage or mutation, if meaningful> | <figure> | <what it does not cover> |

## Open findings

<Ordered by severity. Link each to its full entry. Blockers first; if there are
none, say so explicitly rather than leaving the section empty.>

| ID | Severity | Status | Summary | Owner |
| --- | --- | --- | --- | --- |
| F<n> | <severity> | <status> | <one line> | <who> |

## Closed since last audit

<What was fixed and how it was verified. This section is what makes the
document trustworthy over time — a status file that only ever grows its open
list is not being used.>

| ID | Summary | Verified by |
| --- | --- | --- |
| F<n> | <one line> | <the named test or observation> |

## Accepted risks

<Findings that are understood and deliberately not being fixed. Each needs a
reason and a revisit trigger. An accepted risk with neither is an open finding
wearing a disguise.>

- **<risk>** — <why accepted> · revisit when <trigger>

## Interpretation notes

<The honest caveats. What this audit could not establish, where the evidence is
weaker than it looks, which numbers above would mislead someone reading quickly.
This section is the difference between a status document and a marketing
document.>

- <e.g. a suite that passes but exercises one path of three>
- <e.g. a check that only ran in one environment>
- <e.g. an area where the reviewer had no domain knowledge and said so>
