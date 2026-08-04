# How to use this

One example, followed from start to finish. Fifteen minutes, and you will have
run an audit and written your first overlay.

The example: **you run an online store, and you just added discount codes.**
`SAVE20` gives 20% off and is limited to 100 uses. That is the change we audit.

---

## Step 1 — Run your first audit

You need the protocol file where your agent can read it:

```bash
curl -O https://raw.githubusercontent.com/sturec5/claude-audit-protocol/main/AUDIT_PROTOCOL.md
```

Then type this to your agent. This is the whole command — there is nothing to
configure:

```
Audit the current change against AUDIT_PROTOCOL.md.
Pick the tier and the phases from the change-triage table, tell me which
phases you skipped and why, and report findings in the finding standard.
```

## Step 2 — What comes back

Three things, in this order.

**First, what it decided to check:**

```
Tier: T2 (new user-facing behavior)
Phases run: 3 (business rules), 4 (input boundaries), 16 (data integrity),
            17 (concurrency), 20 (test logic), 28 (data contracts)
Phases skipped: 51-52 (no UI change), 49 (no migration), 47-48 (no auth change)
```

That "skipped" line matters as much as the rest. It is the difference between
*we checked and it was fine* and *nobody looked*. If your agent does not tell
you what it skipped, ask again.

**Second, the findings.** Each one looks like this:

```
### F1 · High · CONFIRMED · Two people redeeming the last discount code at the
same moment both succeed

Location — the redeem path of the discount handler.

Impact — a code limited to 100 uses can be redeemed 101 or more times. With a
code that is worth real money, every extra redemption is a direct loss.

Evidence — two concurrent redemptions of a code at 99/100 uses both succeed.
Both read the count as 99 before either write lands. Reproduces on every
attempt with a 50 ms offset.

Root cause — the count is read, checked, and incremented as three separate
steps. Nothing stops a second request from reading between the first request's
read and its write.

Fix direction — make the increment conditional in a single statement, or put a
constraint on the redemption table so the 101st insert fails.

Verification — a test that fires two redemptions at 99/100 and asserts exactly
one succeeds. It fails before the fix.

Residual risk — codes that were already over-redeemed are not corrected by
this fix and need a separate cleanup.
```

**Third, the verdict** — whether this is safe to ship, and what is still
unknown.

## Step 3 — A note before you continue

The agent found a real bug. Good. But this is a generic audit — it found a
concurrency problem because concurrency problems are on the list of 54.

It did **not** know that in your store a double-redeemed discount is a direct
loss of money, while a double-viewed product page is nothing. It treated both
as ordinary code.

That is what an overlay fixes.

## Step 4 — Write your first overlay

Ask yourself one question:

> **What could go wrong here that would make me sick to my stomach?**

Not "what could break". Things break all the time. What would be a *disaster*.

For a store, the answers are usually about money and about access. Write down
two or three — not eight. You can add more later, when something bites you.

Create `overlays/discounts.md`:

```markdown
# Discounts — a code redeemed more times or for more value than it allows

> Runs on every change that could plausibly touch it, before any generic phase.
> Any such change is T3 regardless of diff size. Violations are Blockers.
>
> Source of truth: the discount rules in the product spec.

## When this overlay runs

- any code that validates, applies, or records a discount
- any change to how the redemption count is stored or read
- any change to the checkout total calculation
- if you are unsure whether a change touches discounts, it does

## Invariants

### D1 — a code is never redeemed more times than its limit

If this stops being true, we hand out money we did not intend to. The loss is
proportional to how popular the code is, so the worst case is also the most
likely one.

**Prove it:** fire two redemptions at once against a code with one use left,
and show exactly one succeeds.

**Violation looks like:** a read of the count, then a check, then a write, as
three separate steps. Anything that trusts the count it read a moment ago.

### D2 — a discount never produces a negative total

**Prove it:** apply the largest code to the cheapest item and show the total is
never below zero.

**Violation looks like:** subtraction with no floor. A percentage and a fixed
amount stacking without a combined limit.

### D3 — an expired code cannot be redeemed

**Prove it:** set a code's expiry to one second ago and show the redemption is
refused at the server, not only hidden in the interface.

**Violation looks like:** the expiry checked in the browser only. A comparison
against a client-supplied timestamp.

## Explicitly not covered

- payment capture itself — that is a separate concern, phases 16-17 and 28
- fraud and abuse patterns — accepted risk for now, revisit at scale

## Triage additions

| Change type | Run |
| --- | --- |
| Any discount logic | This overlay (T3) + 3-5, 16-17, 28 |

## Maintenance

Add an invariant when something actually goes wrong, and write down what caused
it. Do not add invariants because they sound prudent.
```

That is a complete overlay. Three invariants, each one provable.

## Step 5 — Audit the same change again

Same command, one extra line:

```
Audit the current change against AUDIT_PROTOCOL.md.
Apply overlays/discounts.md first.
Pick the tier and the phases from the change-triage table, tell me which
phases you skipped and why, and report findings in the finding standard.
```

Now the answer is different:

```
Overlay: discounts — applies (the change touches redemption logic)
Tier: T3 (forced by overlay, not by diff size)
Overlay invariants checked first: D1 FAIL, D2 pass, D3 pass
```

The same bug is now a **Blocker** instead of a High, and the change is treated
as critical path even though it is the same handful of lines.

Nothing about the code changed. What changed is that you told the system what
matters to you.

## What to run when

| Situation | What to say |
| --- | --- |
| Small fix, nothing risky | `Audit this change, T1. Run the core phases and tell me what you skipped.` |
| New feature | The full command from Step 1. |
| Anything near money, login, or user data | Add `Apply overlays/<yours>.md first.` |
| Before a release | `Run a T4 release audit against AUDIT_PROTOCOL.md, phases 47-54 included.` |
| After a bug is fixed | `Audit this fix. Run phase 38 and check for the same pattern elsewhere.` |

## Four mistakes worth avoiding

**Writing eight invariants on day one.** Start with two or three real ones. An
overlay that grows without incidents behind it becomes a list people skip.

**Writing invariants you cannot prove.** "Discounts are validated properly" has
no answer. "Two simultaneous redemptions of the last use produce one success"
has an answer, and someone can go get it.

**Accepting a clean report without the skip list.** "No findings" from an agent
that quietly checked three phases is not the same as "no findings" from one
that checked twenty and told you which eight it skipped and why.

**Treating the protocol as a certificate.** It is a list of questions. Running
it does not make software safe; it makes the gaps visible and named. That is a
much smaller claim, and it is the only honest one.

## If you want to go deeper

[`AUDIT_PROTOCOL.md`](AUDIT_PROTOCOL.md) has all 54 phases. You still do not
need to read it — but the change-triage table near the top is worth one look,
because it shows how your agent decides what to run.

[`OVERLAY_TEMPLATE.md`](OVERLAY_TEMPLATE.md) is the blank version of what you
wrote in Step 4. [`overlays/`](overlays/) has three fuller examples —
[payments](overlays/payments.md), [access-control](overlays/access-control.md),
and [data-pipeline](overlays/data-pipeline.md).
