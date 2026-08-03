---
name: audit-protocol
description: Audit a code change against a 54-phase failure taxonomy. Use when asked to audit, review before shipping, check a change for defects, decide whether something is safe to release, or investigate a class of failure that ordinary testing missed. Also use when writing a domain overlay of project-specific invariants.
license: MIT
---

# Audit Protocol

The taxonomy lives in `AUDIT_PROTOCOL.md` at the root of this plugin. Read it
before auditing — do not audit from memory of it, and do not restate its phases
back to the user.

## Running an audit

**1. Establish scope before looking at anything.**

Audit one bounded change, feature, module, or user journey. A large codebase
declared "reviewed" after a scan is the failure this protocol exists to prevent.
Record: what is under review, the revision, the intended outcome, the data
classifications involved, and the trust boundaries crossed.

**2. Check for a domain overlay first.**

If the project has one — `OVERLAY*.md`, or invariants named in its own docs —
run it before any generic phase. A change touching an overlay invariant is T3
regardless of diff size, and an overlay violation is a Blocker even when the
code is correct and the tests pass.

If the project has no overlay and the change touches a domain where one is
warranted, say so and offer to write one from `OVERLAY_TEMPLATE.md`. Do not
invent invariants unilaterally.

**3. Pick the tier, then the phases.**

Tiers T0 (documentation) through T4 (release audit) are defined in the
protocol. Use its change-triage table to select phases. Bias toward the higher
tier when the change touches authentication, money, data loss, privacy,
permissions, migrations, or a security boundary.

**4. Run the phases against evidence, not against the happy path.**

Read code, configuration, tests, deployment definitions, and observed behavior
together. Run what can be run. A green suite does not prove the test is
meaningful; a passing linter does not prove the logic is correct.

**5. Report in the finding standard.**

Every finding carries ID, severity, status, location, impact, evidence, root
cause, fix direction, verification, and residual risk. Severity follows impact
and exploitability, never the size of the diff.

Mark a finding CONFIRMED only when it is reproduced. Anything reasoned but not
reproduced is PLAUSIBLE, and say which. Never present a hunch as a defect.

**6. Close honestly.**

State which phases ran, which were skipped, and why each was skipped — "not
applicable" and "out of time" are both legitimate reasons and both belong in
the record. State what the audit could not establish. If the templates are in
use, update `AUDIT_STATUS.md`.

## When fixing what the audit found

Before considering a fix complete, look for the same defect in parallel
implementations and at every call site. A fix that closes one instance of a
pattern while its siblings survive is the most common way a finding reopens.

Remove only what the fix orphans. Pre-existing dead code found along the way
gets reported, not deleted.

## What not to do

Do not treat the checklist as the work. Running every phase shallowly is worse
than running five deeply, because it produces a document that says a system was
audited when it was not.

Do not widen scope silently. Record what was deferred and the trigger that
makes it due.

Do not report volume. Twenty findings that are all style observations bury the
one Blocker; rank by severity and lead with what actually blocks.
