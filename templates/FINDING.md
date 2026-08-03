# Finding template

One finding per block. Copy the block, fill every field, delete nothing.

A field you cannot fill is itself information: no reproduction means the finding
is not yet confirmed, and no verification means the fix is not yet done. Leave
the field and write what is missing rather than removing the line.

---

### F<n> · <Severity> · <Status> · <one-line claim in plain language>

**Severity** — Blocker, Critical, High, Medium, Low, or Observation. Based on
impact and exploitability, never on the number of lines involved.

**Status** — CONFIRMED (reproduced), PLAUSIBLE (reasoned, not yet reproduced),
CLOSED (fixed and verified), ACCEPTED (understood, deliberately not fixed).
A finding that is neither confirmed nor labeled plausible is a rumor.

**Location** — file, function, endpoint, screen, table, configuration key, or
workflow step.

**Impact** — what fails, who is affected, under what conditions. Written so a
reader who does not know the code understands what goes wrong for a person.

**Evidence** — the reproduction. Input and state in, wrong output or crash out.
A stack trace, a query result, a failing assertion, a log excerpt. If the only
evidence is a reading of the code, say so and mark the finding PLAUSIBLE.

**Root cause** — the actual mechanism, not the visible symptom. "Returns null"
is a symptom. "The lookup runs before the record is committed, so it returns
null for anything created in the same request" is a cause.

**Fix direction** — the smallest correction that removes the cause, plus any
compatibility, migration, or ordering concern it raises.

**Verification** — the test or observation that proves the correction, and
which would fail if the defect returned. Name it specifically. "Tests pass" is
not verification; a named test that fails before the fix and passes after is.

**Residual risk** — what remains unknown, unverified, or deliberately deferred,
and what would trigger revisiting it.

---

## Worked example

The example below is invented for illustration.

### F1 · High · CONFIRMED · A retried submission creates a second record because the uniqueness check runs outside the transaction

**Location** — the create path of the submission handler.

**Impact** — a user who double-taps, or whose client retries after a timeout,
gets two records. Downstream counts and any per-user limit are wrong from that
point on. Observed on mobile, where the timeout is short enough to be common.

**Evidence** — two concurrent identical requests produce two rows. The
uniqueness query returns empty for both because neither insert has committed
when the other checks. Reproduces on every attempt with a 50 ms offset between
the two requests.

**Root cause** — the check-then-insert pair is not atomic. The uniqueness
constraint exists in application code only; the table has no unique index, so
nothing serializes the two writers.

**Fix direction** — add the unique constraint at the database level and let the
insert fail, then translate the constraint violation into the existing
duplicate response. The application-level check can stay as a fast path but is
no longer the guarantee.

**Verification** — a concurrency test that fires two identical requests with a
small offset and asserts exactly one row plus one duplicate response. It fails
before the constraint is added.

**Residual risk** — existing duplicate rows are untouched by the fix and need a
separate cleanup with its own verification. Deferred, triggered before the
constraint can be added without an error.
