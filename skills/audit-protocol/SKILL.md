---
name: audit-protocol
description: Audit a code change against a 54-phase failure taxonomy. Use when asked to audit, review before shipping, check a change for defects, decide whether something is safe to release, or investigate a class of failure that ordinary testing missed. Also use when writing a domain overlay of project-specific invariants.
license: MIT
---

# Audit Protocol

The taxonomy is `AUDIT_PROTOCOL.md` at the plugin root — two directories above
the base directory Claude Code states when it loads this skill. If your harness
expands `${CLAUDE_PLUGIN_ROOT}`, then `${CLAUDE_PLUGIN_ROOT}/AUDIT_PROTOCOL.md`
is the same file by a shorter name.

Read it before auditing — do not audit from memory of it, and do not restate
its phases back to the user. If you cannot read it, say so and stop: an audit
run from memory of the taxonomy is not this protocol and must not be reported
as one.

If the project under audit keeps its own `AUDIT_PROTOCOL.md`, read that one
instead and say which copy you used. A repository copy is pinned to that project
and may have been amended; the plugin's is identical everywhere.

The phase numbers are a catalog, not a running order. Select through the
triage table, and prefer the shallow member of a paired phase at T2 over
running both.

## Running an audit

**1. Establish scope before looking at anything.**

Audit one bounded change, feature, module, or user journey. A large codebase
declared "reviewed" after a scan is the failure this protocol exists to prevent.
Record: what is under review, the revision, the intended outcome, the data
classifications involved, and the trust boundaries crossed.

**2. Check for a domain overlay first, labeled or not.**

Look in the project's own `overlays/` and for a file named `OVERLAY*.md`. When
neither exists, the invariants are often still written down somewhere else: a
contributor guide, an agent instructions file, an architecture note, a
house-rules document. Recognize them by shape rather than filename — imperative
rules about this project's own concepts, which would be meaningless in another
repository. Treat that file as the overlay and run it before any generic phase.

A change touching an overlay invariant is T3 regardless of diff size, and an
overlay violation is a Blocker even when the code is correct and the tests pass.

If the project has no overlay and the change touches a domain where one is
warranted, say so and offer to write one from `OVERLAY_TEMPLATE.md` at the
plugin root. Do not invent invariants unilaterally. The examples in `overlays/`
beside it show the shape; they are nobody's actual invariants.

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
the record. State what the audit could not establish. If the project keeps an
`AUDIT_STATUS.md`, update it. If it does not, offer one from `templates/` at the
plugin root rather than writing it uninvited.

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
