# Data pipeline — leakage, non-determinism, and silent schema drift

> Runs on every change that could plausibly touch it, before any generic phase.
> Any such change is **T3** regardless of diff size. Violations are Blockers.
>
> Source of truth: your feature definitions and your split specification. Point
> at both; do not restate them here.

This is a worked example, not a library. Copy the shape, replace the content
with the invariants your own pipeline actually needs.

The failures in this class share one property that makes them worth an overlay:
they do not produce errors. They produce results that look better than reality,
which is the one kind of wrong nobody investigates.

## When this overlay runs

- any new or changed feature, transform, aggregation, or join
- any change to how the data is split, sampled, filtered, or ordered
- any change to a fitted object — scaler, encoder, imputer, vocabulary,
  feature selector, or the model itself
- any change to the evaluation path, including metrics and reporting
- any schema, source, or ingestion change, including one upstream of you
- ambiguous cases resolve to yes

## Invariants

### D1 — no feature sees data recorded after its own cutoff

For every row, every input must have been observable at the moment the
prediction would have been made. This includes the subtle carriers: an
aggregate computed over the full table, a join against a slowly-changing
dimension that has since been updated in place, a label-derived field, a
row-order that itself encodes the outcome.

**Prove it:** for one sampled row, trace every feature back to a source record
and compare its timestamp against the row's cutoff. Do this for a row near a
boundary, not a row in the middle. An assertion in the pipeline that fails when
the comparison is violated is stronger than a one-time manual trace.

**Violation looks like:** an aggregate with no time filter; a mean or normalizer
computed across the whole dataset; a dimension table joined on key alone with no
validity window; a target encoding fitted before the split.

### D2 — the split precedes every fit

Anything that learns from data — scalers, encoders, imputers, vocabularies,
feature selection, hyperparameter search — is fitted on the training partition
only, then applied to the others. Fitting first and splitting second is the most
common way a pipeline reports a number it cannot reproduce in production.

**Prove it:** show the call order. Then show it holds inside every
cross-validation fold, not only at the top level — a scaler fitted once outside
the loop leaks across all folds.

**Violation looks like:** a fit on the full frame before partitioning; a
transform reused across folds without refitting; feature selection run on the
combined set "just to see which columns matter".

### D3 — the same inputs produce the same outputs

Every seed is set and recorded. Every operation whose result depends on input
order is either ordered deterministically or provably order-independent. Two
runs of the same commit on the same data agree exactly, not approximately.

**Prove it:** run twice and compare outputs byte for byte. If they differ, find
the source before doing anything else — a pipeline you cannot reproduce cannot
be audited, and every other finding in this overlay becomes unverifiable.

**Violation looks like:** an unseeded shuffle, sampler, or initializer; a
parallel reduction over floating-point values with no fixed order; a set or
dictionary iteration feeding an ordered operation; wall-clock time entering a
feature.

### D4 — a schema change fails loudly

An upstream column that changes type, changes units, gains nulls, or disappears
must stop the pipeline. Silent coercion is worse than a crash: the run
completes, the numbers move slightly, and nobody knows why.

**Prove it:** point at the contract — an explicit schema, a validation step, or
typed ingestion — and show what happens when a column violates it. Then
actually violate one and confirm the failure.

**Violation looks like:** permissive parsing that coerces unparseable values to
null; a `select *` that silently absorbs new columns; a numeric column read as
text with no assertion; units changed upstream with no version pin.

### D5 — missingness is represented, never imputed into a plausible value

An absent value must remain distinguishable from a real one. Filling a gap with
zero, with the mean, or with the last observation makes absence indistinguishable
from measurement — and the model will learn the fill.

**Prove it:** show that either the model handles missingness natively or the
imputation is accompanied by an indicator column. Then confirm the fill value
cannot occur naturally in that column's range.

**Violation looks like:** a zero-fill on a column where zero is a legitimate
value; forward-fill across a gap longer than the sampling interval; an imputed
value carried into a downstream aggregate without its indicator.

### D6 — the held-out set is consumed once

Every decision made after looking at held-out performance spends that set.
Repeated evaluation against the same partition is selection, and selection
inflates the number reported.

**Prove it:** show how many times the held-out set has been evaluated and what
changed after each. If nobody can answer, the answer is too many.

**Violation looks like:** tuning against the test partition because the
validation partition was inconvenient; a leaderboard driven by the final set; a
model reselected after a disappointing evaluation with no new partition drawn.

### D7 — record identity survives the pipeline

Deduplication must not merge distinct entities, and joins must not multiply rows
undetected. A row count that changes across a step nobody expected to change it
is a defect until explained.

**Prove it:** assert row counts and key uniqueness at every stage boundary. A
join that can fan out gets an explicit cardinality assertion, not a comment
saying it is one-to-one.

**Violation looks like:** dedup on a subset of the true key; a many-to-many
join treated as one-to-many; a group-by whose key omits a dimension present in
the data.

## Explicitly not covered

- model architecture, capacity, and whether the chosen approach suits the
  problem — generic phase 18 (decision quality and algorithmic robustness)
- runtime cost and throughput of the pipeline — phase 8 and phase 30
- privacy and retention of the underlying records — phase 50
- statistical validity of the metric itself — a separate overlay if the
  reported number carries decision weight

## Triage additions

| Change type | Run |
| --- | --- |
| New or changed feature or transform | This overlay (T3) + 3, 6-7, 12, 16, 29, 40 |
| Split, sampling, or ordering change | This overlay (T3) + 6, 12, 29, 33, 40 |
| Fitted object or training path | This overlay (T3) + 3, 12, 18, 33, 41 |
| Schema, source, or ingestion change | This overlay (T3) + 10, 16, 28, 32, 34 |
| Evaluation or reporting change | This overlay (T3) + 12, 18, 20, 41 |

## Maintenance

Add an invariant when a pipeline produced a number that could not be reproduced
downstream and the cause was a class none of the above covers. Record the date
and the cause — in this overlay especially, an invariant without a documented
incident behind it reads as superstition and gets removed.
