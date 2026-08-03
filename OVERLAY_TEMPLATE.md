# Overlay Template

Copy this file, fill it in, and keep it next to your audit protocol. Delete
every instruction line as you replace it — an overlay with template text still
in it has not been written yet.

An overlay exists to catch what a generic taxonomy structurally cannot: the
failures that are specific to what your system does. If you cannot name a
failure that would be catastrophic here and unremarkable elsewhere, you do not
need an overlay yet.

---

## Anatomy

**Name it after the failure, not the feature.** "The upload pipeline" is a
feature. "A file that reaches the wrong account" is a failure class. The second
one survives the refactor that renames the feature.

**Six to eight invariants.** More than that and you have written a
specification. A specification describes what the system does; an overlay
lists the small number of things that must never stop being true.

**Every invariant is a claim, provable yes or no.** "Input is validated" is not
an invariant — there is no answer to it. "No write path reaches the database
before the validator returns" is, and someone can go prove it.

**Proof is not reading the happy path.** Name the evidence that settles each
invariant: a test that fails when the invariant is broken, a query, a trace, a
grep across every write path. If the only proof is "I read the code and it
looked right", the invariant is not yet auditable.

**Violations are Blockers by definition.** Not "Blocker if severe". If a
violation could ever be acceptable, it is a phase concern, not an overlay
invariant — move it.

---

## Template

Everything below the line is what you copy.

---

# <Overlay name> — <the failure class in one clause>

> Runs on every change that could plausibly touch it, before any generic phase.
> Any such change is **T3** regardless of diff size. Violations are Blockers.
>
> Source of truth: `<the file or system that actually defines this — point at
> it, never restate it here, or the two will drift>`

## When this overlay runs

List the concrete triggers. Be specific enough that someone can answer "does
this apply to my change?" without judgment.

- <path, module, table, endpoint, or job that is in scope>
- <a change class, e.g. "any new write path", "any change to the ordering of X">
- <the ambiguous case, and which way it resolves — ambiguity defaults to "yes, it runs">

## Invariants

### <ID>1 — <the claim, stated as something that is true>

<One or two sentences on what breaks if this stops being true, in user terms
rather than code terms.>

**Prove it:** <the specific evidence. A named test, a query, a trace, an
exhaustive check across call sites. Something that can fail.>

**Violation looks like:** <the concrete shape of the bug — what a reviewer
would actually see in a diff or a log.>

### <ID>2 — <claim>

...repeat for each invariant...

## Explicitly not covered

State the boundary. An overlay that seems to cover everything gets treated as
covering nothing.

- <adjacent concern that belongs to a generic phase instead, and which one>
- <a risk you have accepted, and why>

## Triage additions

How this overlay changes phase selection. Add rows to your protocol's change
triage table.

| Change type | Run |
| --- | --- |
| <change class> | This overlay (T3) + <generic phase numbers> |

## Maintenance

Add an invariant when an audit or an incident reveals a failure class that no
existing invariant would have caught. Do not add one because it sounds prudent —
an overlay that grows without incidents becomes a checklist people skip.

Record the date an invariant was added and what caused it. An invariant with no
cause behind it is the first one someone deletes.
