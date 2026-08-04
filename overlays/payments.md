# Payments — money moved twice, moved wrong, or not moved at all

> Runs on every change that could plausibly touch it, before any generic phase.
> Any such change is **T3** regardless of diff size. Violations are Blockers.
>
> Source of truth: your payment provider's API contract plus your own ledger
> schema. Point at both; do not restate their rules here.

This is a worked example, not a library. Copy the shape, replace the content
with the invariants your own payment path actually needs.

## When this overlay runs

- any code that creates, captures, voids, or refunds a charge
- any change to order state, fulfillment triggers, or the transition between them
- any change to how amounts are stored, converted, rounded, or displayed
- any webhook handler, retry policy, or queue consumer on the payment path
- schema or migration work touching money columns or the ledger
- ambiguous cases resolve to yes — a change that merely reads payment state
  still runs this overlay, because reads become writes one refactor later

## Invariants

### P1 — the same request never charges twice

Retries happen: the client resubmits, the network times out after the provider
already succeeded, the queue redelivers. Every one of those paths must converge
on a single charge.

**Prove it:** a test that submits the identical request twice and asserts one
charge exists, plus an exhaustive check that every charge-creating call site
passes an idempotency key derived from the order rather than generated per
attempt. A key generated inside the retry loop is the bug.

**Violation looks like:** an idempotency key built from a timestamp, a UUID
created at call time, or nothing at all; a retry wrapper sitting above the
key-generating code rather than below it.

### P2 — money never passes through a binary float

Amounts are integers in the smallest unit, or a decimal type. Never a float,
not even briefly, not even for display.

**Prove it:** a type-level check or grep across every money-carrying field,
argument, and column. Include serialization boundaries — JSON parsing is where
integers quietly become floats.

**Violation looks like:** `float`/`double` on a money field; a division that
produces a repeating decimal; a rounding step added to "fix" a total that was
already wrong.

### P3 — an amount is never separated from its currency

An amount without a currency is not a number, it is a bug waiting for a second
market. The pair travels together through storage, arithmetic, comparison, and
display.

**Prove it:** show that no function accepts a bare amount, and that arithmetic
on two amounts of differing currency raises rather than coerces.

**Violation looks like:** a currency defaulted at the edge; a total summed
across mixed-currency line items; a comparison that assumes both sides are the
same currency.

### P4 — a refund can never exceed what was captured

Including across partial refunds, across retries of the same refund, and when
the refund request arrives before the capture webhook.

**Prove it:** a test for the partial-refund sequence that ends one unit over
the captured total, and a test where the refund arrives first. Both must be
rejected by the same guard, not by two different ones.

**Violation looks like:** a refund guard that checks the order total rather
than the captured total; a check that runs in application code while a second
refund path bypasses it.

### P5 — the ledger and the provider are reconciled, and disagreement is detected

They will disagree. The invariant is not that they never diverge — it is that
divergence is found by the system rather than by a customer.

**Prove it:** point at the reconciliation job, its cadence, and what it does
when it finds a mismatch. A job that logs and continues is not detection.

**Violation looks like:** reconciliation that only runs manually; a mismatch
that raises an alert nobody owns; a job that silently reconciles by overwriting
the ledger with the provider's view.

### P6 — a failed capture never leaves a fulfilled order

Fulfillment follows a confirmed capture, never optimistic money. If the capture fails
after fulfillment triggered, there must be a compensating path that is tested.

**Prove it:** a test that fails the capture after the fulfillment call and
asserts the compensating action ran. If there is no compensating action, that
is the finding.

**Violation looks like:** fulfillment triggered from the request handler rather
than from a capture-succeeded event; an ordering where the side effect precedes
the confirmation.

### P7 — terminal states are terminal

A refunded charge does not become captured. A voided authorization does not
become charged. State transitions that must be one-way are enforced where the
state is written, not where it is read.

**Prove it:** enumerate the legal transitions and show the write path rejects
everything else — ideally in the database as a constraint, not only in
application code.

**Violation looks like:** state assigned by direct field write; a transition
table enforced in one service while another writes the same column.

## Explicitly not covered

- card data handling, PCI scope, and tokenization — those are generic phase 47
  (threat modeling) and phase 50 (privacy), and they need a specialist, not a
  checklist
- fraud scoring and chargeback strategy — business policy, not an invariant
- tax and invoicing correctness — a separate overlay if it matters to you

## Triage additions

| Change type | Run |
| --- | --- |
| Charge, capture, void, or refund path | This overlay (T3) + 3-5, 9, 16-17, 28, 32, 35, 37 |
| Money storage, schema, or migration | This overlay (T3) + 7, 16, 28, 35, 49 |
| Webhook, retry, or queue consumer | This overlay (T3) + 6, 9, 17, 29, 32-33 |
| Display or formatting of amounts | This overlay (T3) + 7, 27, 51-52 |

## Maintenance

Add an invariant when a payment incident reveals a class none of the above
would have caught. Record the date and the incident. Seven invariants that each
trace to something real beat fifteen that trace to caution.
