# Evidence chain — a sealed result that no longer proves what it claims

> Runs on every change that could plausibly touch it, before any generic phase.
> Any such change is **T3** regardless of diff size. Violations are Blockers.
>
> Source of truth: your register of sealed artifacts. Point at it; do not
> restate what it records here.

This is a worked example, not a library. Copy the shape, replace the content
with the invariants your own evidence chain actually needs.

The failures in this class break nothing. Every test passes, no number moves,
every file still opens. What changed is that a pointer under a sealed decision
stopped naming what it used to name, and the decision goes on being cited as
though it still did.

## When this overlay runs

- any move, rename, or deletion of a document, directory, or artifact that
  something else cites
- any bulk rewrite of paths, links, or references, however mechanical it looks
- any change to a producer that writes a committed artifact — the script, the
  query, the export
- any change to a seal, a recorded hash, or the register itself
- any change to how artifacts are named, versioned, or located
- ambiguous cases resolve to yes — reorganizing files is exactly the change
  that looks incapable of breaking anything

## Invariants

### E1 — the sealed set is enumerable

A chain whose links are found by opening files and noticing cannot be audited.
The list is what makes "nothing is broken" a claim rather than a report on
which files somebody happened to open.

**Prove it:** reconcile the register against the repository in both directions
— every sealed artifact appears in the list, every entry in the list still
exists at the path it names. A discrepancy either way is the finding.

**Violation looks like:** sealed status inferred from a directory name; an
artifact carrying a seal that no register mentions; a register entry pointing
at a file that was moved out from under it.

### E2 — every citation into and out of the sealed set resolves

A sealed decision rests on what it cites, and is worth sealing only while
others can still reach it. Both directions count: a rewrite that re-aims every
link into a moved document, and nothing inside it, leaves the document citing
neighbors it no longer has.

**Prove it:** resolve mechanically in both directions — every reference a
sealed artifact makes, and every reference anywhere in the repository that
names one — and assert none is unresolved. By eye is not proof across a bulk
move; the broken ones are exactly the ones nobody re-read.

**Violation looks like:** a document moved with the links to it repaired and
its own left alone; a path that resolves from the author's working directory
and nowhere else; a citation to a heading renamed in some other commit.

### E3 — a rewrite never breaks a reference that already worked

The dangerous half of a bulk fix is the references it should have left alone. A
rule written for the broken ones runs over the correct ones too, and the result
is a diff in which every line looks like the intended change.

**Prove it:** resolve the full reference set before and after. Every reference
the change touched resolves after; every reference it did not touch resolves
exactly as before. A count of rewritten lines is not this check.

**Violation looks like:** a repository-root prefix prepended to a path that was
already rooted; a pattern matching a substring that occurs in more places than
the one it was written for; a change described by how many lines it touched
rather than by which references it repaired.

### E4 — what a reference says and what it points at agree

A reference has two halves and they can be updated separately. Repairing the
visible text and leaving the target stale is worse than repairing neither: it
reads as current, it resolves, and the next reader has no reason to check.

**Prove it:** for every reference the change touched, compare the displayed
text against the target and assert both name the same artifact. Resolution
alone does not settle this — a link can resolve perfectly to the wrong
document.

**Violation looks like:** link text renamed while the path keeps the old
location; a citation whose version or section number disagrees with the file it
opens; an index hand-edited while the headings moved.

### E5 — a committed artifact still reproduces from its own producer

A sealed measurement makes two claims: this was the result, and this is what
produced it. The second decays silently. Re-running the producer over the
recorded inputs must still yield the committed file.

**Prove it:** re-run the producer for one sealed artifact against its recorded
inputs and diff the output against the committed bytes. Choose an artifact in
the neighborhood the change touched, not the newest one.

**Violation looks like:** a producer whose output embeds a path that has since
moved; an artifact whose recorded inputs no longer exist under those names; a
re-run that differs only in a field everyone agrees is cosmetic — the
divergence is the evidence, not the field.

### E6 — a citation is either prose or data, and the repository knows which

Some strings live in two worlds. A reference that reads like a comment can also
be a value a producer serializes into a committed artifact. Edit it as prose
and the artifact stops matching the tool that made it, while the diff shows
nothing but documentation.

**Prove it:** intersect the strings the change touched with the literal values
producers emit into committed files. The check runs against the diff — a
string's second life is invisible at the place it is written.

**Violation looks like:** a path constant swept up by a documentation-wide
rewrite; a producer that embeds the same literal a link-fixer is allowed to
rewrite; a value declared beside the prose describing it, with nothing marking
which is which.

### E7 — a stale pointer is repaired at the producer, never in the seal

Finding a broken citation inside a sealed artifact is not permission to edit
it; the seal exists so that nobody can. The repair is to fix the producer and
issue a superseding artifact, or to record a mapping from the old pointer to
the new location and leave the original untouched. Here the fix is more
dangerous than the finding.

**Prove it:** show that no sealed artifact's bytes changed in the diff. If one
did, the finding is the edit, not the stale pointer it corrected.

**Violation looks like:** a bulk path rewrite that ran across the sealed
directory too; a recorded hash updated in the same commit as the content it
covers; a typo fix inside a sealed file with no superseding record.

## Explicitly not covered

- values and identifiers that must agree across boundaries — phase 27, which
  asks whether two copies of a value match, not whether a pointer resolves
- producer-to-consumer contracts in code — phase 32, which audits the handoff,
  not whether a committed artifact is still the evidence it claims to be
- test baselines and golden files — phase 41. A baseline is replaced when
  behavior legitimately changes; a sealed artifact is not
- a single write-read round trip — phase 35. The span here is months, not one
  pass through storage
- whether the measurement was right when it was taken — this overlay asks only
  whether the record still means what it recorded

## Triage additions

| Change type | Run |
| --- | --- |
| Move, rename, or deletion of a cited artifact | This overlay (T3) + 11, 14-15, 26-27, 32, 43 |
| Bulk path or reference rewrite | This overlay (T3) + 26-27, 32, 37-38, 43 |
| Producer of a committed artifact | This overlay (T3) + 12, 32, 35, 37, 41 |
| Seal, hash, or register change | This overlay (T3) + 14, 16, 28, 42 |
| Naming, versioning, or layout convention | This overlay (T3) + 11, 22, 27, 43 |

## Maintenance

Add an invariant when a sealed decision turned out to rest on something that
had moved and no invariant above would have caught it. Record the date and what
the citation used to point at. Every reorganization feels like it might have
broken something; only the ones that did are evidence.
