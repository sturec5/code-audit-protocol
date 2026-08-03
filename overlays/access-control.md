# Access control — one principal reaching another's data or privileges

> Runs on every change that could plausibly touch it, before any generic phase.
> Any such change is **T3** regardless of diff size. Violations are Blockers.
>
> Source of truth: your authorization model — the roles, the tenancy boundary,
> and the policy layer that enforces them. Point at it; do not restate it here.

This is a worked example, not a library. Copy the shape, replace the content
with the invariants your own authorization model actually needs.

## When this overlay runs

- any new or changed endpoint, route handler, resolver, or server action
- any query that reads or writes a table containing per-principal data
- any change to roles, permissions, group membership, or session lifetime
- any admin, support, or internal tool that can act on behalf of a user
- any change to caching, since a cache is a copy of data with the
  authorization stripped off
- ambiguous cases resolve to yes

## Invariants

### A1 — authorization is decided on the server, every time

The client may hide a button. It may not decide whether the action is allowed.
Every enforcement point lives behind the trust boundary, and a request that
skips the UI entirely gets the same answer.

**Prove it:** call the endpoint directly, without the client, as a principal
who should be denied. A test that only exercises the UI proves nothing about
this invariant.

**Violation looks like:** a permission check in a component; a flag sent from
the client and trusted; an endpoint whose only guard is that nothing links to it.

### A2 — every object access is scoped by owner, not merely by identifier

Knowing an identifier is not authorization. The query that fetches the object
carries the principal's scope in its predicate — it does not fetch first and
compare afterwards, because the fetch is already the leak in a system with
side effects or timing signals.

**Prove it:** enumerate every read and write of per-principal tables and show
the scope is in the query. Then request a valid identifier belonging to another
principal and assert the result is empty rather than filtered.

**Violation looks like:** `findById(id)` followed by an ownership `if`; a scope
applied in a service layer that a second call site bypasses; a list endpoint
scoped correctly while its detail endpoint is not.

### A3 — the default is deny

A new table, a new route, a new field is inaccessible until something grants
access. Adding a feature must not silently widen the surface because the
policy layer failed open.

**Prove it:** create a new resource with no policy attached and confirm access
is refused. If the answer depends on which layer you ask, that is the finding.

**Violation looks like:** a policy engine that returns "allow" when no rule
matches; a middleware allowlist of protected routes rather than a denylist of
public ones; row-level security enabled on some tables and forgotten on the
newest one.

### A4 — revocation takes effect on the next request

Removing a role, ending a membership, or disabling an account must not wait for
a token to expire or a session to end. Anything cached — permissions, group
membership, a decoded token's claims — needs a path that invalidates it.

**Prove it:** revoke while an active session is open, then make a request.
Measure the actual window, do not assume it.

**Violation looks like:** permissions baked into a long-lived token with no
revocation list; a permission cache with a TTL and no invalidation hook.

### A5 — the error surface does not enumerate

Whether an object exists is itself information. Distinguishing "not found" from
"not yours" tells an attacker which identifiers are real, and response timing
tells them the same thing more quietly.

**Prove it:** compare responses and timings for a non-existent identifier
against one that exists but belongs to another principal.

**Violation looks like:** 404 for one case and 403 for the other; an error
message naming the resource; a validation error that fires before the
authorization check and reveals the shape of real data.

### A6 — privileged and destructive actions are re-authenticated

Authorization says the principal may do it. Re-authentication says the
principal is present right now. Account deletion, permission grants, payout
changes, and data export need the second one, because sessions get borrowed.

**Prove it:** name the actions that require it and show the check is on the
server path, not a client confirmation dialog.

**Violation looks like:** a confirm modal treated as the control; a re-auth
that stamps a session flag with no expiry.

### A7 — the privileged path is not a bypass

Admin tools, support impersonation, and internal scripts run through the same
authorization layer with a wider scope — not around it with none. Every
privileged action is attributable to a human, and impersonation is visible in
the audit trail as impersonation.

**Prove it:** trace one admin write end to end and show it passes the same
enforcement point. Then confirm the log records who acted and on whose behalf.

**Violation looks like:** an admin client using a service key directly; an
impersonation session indistinguishable from the user's own; a maintenance
script with credentials that bypass row-level policy.

## Explicitly not covered

- authentication strength — password policy, MFA, session fixation, credential
  stuffing all belong to generic phase 48
- transport and infrastructure security — phase 47 and phase 54
- what should be logged for compliance — phase 50; this overlay only requires
  that privileged action is attributable

## Triage additions

| Change type | Run |
| --- | --- |
| New or changed endpoint | This overlay (T3) + 1-5, 15, 20, 28, 48 |
| Role, permission, or membership change | This overlay (T3) + 5, 14, 21, 48, 50 |
| Query touching per-principal data | This overlay (T3) + 16, 28, 32, 49 |
| Caching, session, or token change | This overlay (T3) + 5, 6, 29, 48 |
| Admin or support tooling | This overlay (T3) + 14, 22, 42, 50 |

## Maintenance

Add an invariant when an audit or incident reveals a bypass none of the above
would have caught. Record the date and the cause. An overlay that grows on
speculation is one people learn to skip.
