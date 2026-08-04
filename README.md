# The Audit Protocol

A checklist your coding agent runs before you ship — plus a way to write down
the two or three things that would be a genuine disaster **in your project
specifically**.

> Community project. Not affiliated with or endorsed by Anthropic.

## The 60-second version

You changed some code. Before it ships, something should ask *what did I miss?*

This repo gives your agent two things.

**1. A list of 54 ways software breaks.** A number that rounds the wrong way.
One user reading another user's data. A test that would pass even against
broken code. A migration that works on an empty database and locks up on a real
one. These are the same in every codebase, which is why the list is worth
keeping.

**2. A short file where you write down your own disasters.** The generic list
cannot know that in *your* app the thing that ends you is a payment charged
twice. So you write that down yourself — six to eight lines. That file is
called an **overlay**.

Then one rule connects them: **the overlay wins.** Any change that touches it
gets the full treatment, however small the change looks.

## Why `AUDIT_PROTOCOL.md` is 1,400 lines — and why you should not read it

**You are not the reader. Your agent is.**

It is long the way a dictionary is long: exhaustive on purpose, opened a few
entries at a time, never read front to back. Each of the 54 phases is a way
something actually broke for somebody. Writing them all down is the point.
Reading them all is not.

What you read is this page. Then you hand the file to your agent, and it uses
the triage table inside to pick the four or five phases your change actually
needs — an accessibility fix does not get the database phases.

**If you never open `AUDIT_PROTOCOL.md`, this still works.**

## Try it in one minute

```bash
curl -O https://raw.githubusercontent.com/sturec5/claude-audit-protocol/main/AUDIT_PROTOCOL.md
```

Then, in your agent session:

```
Audit the current change against AUDIT_PROTOCOL.md.
Pick the tier and the phases from the change-triage table, tell me which
phases you skipped and why, and report findings in the finding standard.
```

Or install it as a Claude Code plugin, available in every project:

```
/plugin marketplace add sturec5/claude-audit-protocol
/plugin install audit-protocol@claude-audit-protocol
```

**New here?** [`HOWTO.md`](HOWTO.md) walks through one real example end to end —
run an audit, read the output, write your first overlay, see what changes.
Fifteen minutes.

## The one idea worth understanding: overlays

Say you run a store. You change one line in the shipping-address form — a
label, basically. Trivial.

Except that form writes to the order record, and the order record is what the
payment retry reads. Your overlay says: *money must never move twice.* So this
one-line change is now a critical-path review — not because the diff is big,
but because of **what it touches**.

That inversion is the whole idea:

> Risk comes from what a change touches, not from how many lines it has.

A generic checklist cannot do this. It does not know what your disaster is.
You do — so you write it down once, and every future change gets measured
against it.

This is also why the two files are separate. The 54 phases transfer to any
project unchanged. Your overlay transfers to nobody, and that is exactly the
point: it is the part that knows something the generic list never can.

## What an overlay actually looks like

Each entry is a claim that can be proved yes or no. Not "review the payment
code" — that is a wish. This is an invariant:

> **A retried request must not create a second charge.**
>
> **Prove it:** send the same request twice with the same idempotency key and
> show one charge in the ledger.
>
> **Violation looks like:** the key is generated inside the retry loop; the
> ledger has no uniqueness constraint; a webhook handler that trusts delivery
> order.

Start from the failure, not the feature. "Checkout flow" is a feature. "Money
moved twice" is a failure class, and it survives the refactor that renames
checkout.

Three worked examples ship here — [payments](overlays/payments.md) (7
invariants), [access-control](overlays/access-control.md),
[data-pipeline](overlays/data-pipeline.md). Read one for the shape, then throw
them away and write yours, starting from
[`OVERLAY_TEMPLATE.md`](OVERLAY_TEMPLATE.md).

If the only proof you can offer is "I read it and it looked right", it is not
an invariant yet.

## What is in here

| File | Who reads it |
| --- | --- |
| `README.md` | You. What this is and why. |
| [`HOWTO.md`](HOWTO.md) | You. One worked example, start to finish. Read this second. |
| [`AUDIT_PROTOCOL.md`](AUDIT_PROTOCOL.md) | Your agent. 54 phases, tiers, finding standard, triage table. |
| [`OVERLAY_TEMPLATE.md`](OVERLAY_TEMPLATE.md) | You, once — when you write your first overlay. |
| [`overlays/`](overlays/) | Three worked examples, for reference. |
| [`templates/`](templates/) | Report formats: one finding, and the standing "can this ship?" record. |
| `check.sh`, `denylist.example` | Only if you fork this and publish your own version. |
| `.claude-plugin/`, `skills/` | The Claude Code plugin wrapper. |

## Three things that make it worth using

**An unrun checklist is not evidence that anything is safe.** This is a list of
questions, not a certificate. Phases you skip get recorded as skipped, with the
reason — so "we did not check that" never quietly becomes "that is fine".

**A green test suite does not prove the tests mean anything.** Two phases exist
to audit the tests themselves, because an assertion that would also pass
against broken code is worse than no assertion.

**A hunch is not a defect.** Every finding carries evidence, a reproduction,
and a status: CONFIRMED if it was reproduced, PLAUSIBLE if it was only reasoned
about. A finding with neither is a rumor with an ID number.

## Where this came from

Distilled from audit protocols used across several production codebases — a
user-facing web application, a real-time service, and a data-processing system.
The phase list grew one entry at a time, each added after something got through
that nothing on the list would have caught.

The last eight phases — security, authorization, storage and recovery, privacy,
accessibility, UX, observability, delivery — are grounded in public standards
rather than one team's habits: OWASP ASVS and API Top 10, the NIST Privacy
Framework and SSDF, WCAG 2.2, and the Google SRE material on service level
objectives. Every source is cited at the end of the protocol.

Nothing project-specific ships here. [`check.sh`](check.sh) is the gate that
keeps it that way; run it before every push. Its term list lives in an
untracked `denylist.local` rather than in the script — the names you are
keeping out of a public repository should not be published by the tool that
keeps them out. [`denylist.example`](denylist.example) shows the format.

## Contributing

An overlay for a failure class nobody has covered yet is the most useful
contribution — see [CONTRIBUTING.md](CONTRIBUTING.md). A new phase is a higher
bar: it earns its place only when a real failure class has no existing home.

MIT licensed. Use it, fork it, delete the parts you do not need.
