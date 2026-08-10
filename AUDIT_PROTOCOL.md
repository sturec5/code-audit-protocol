# The Audit Protocol

> A technology-neutral audit taxonomy for web, mobile, desktop, backend, API,
> CLI, data-processing, and distributed applications. Fifty-four phases, each
> tagged for when it applies.
>
> This file explains WHAT to inspect and WHY. It deliberately contains no
> commands. Keep your executable runbook — linters, scripts, fixtures, test
> recipes — in a separate file beside this one, because commands rot at a
> different rate than failure classes do.
>
> Most applications also have one or two failure classes that no generic
> taxonomy can catch. Those belong in a domain overlay, which runs before the
> generic phases — see [§5 Domain Overlays](#5-domain-overlays) and
> [OVERLAY_TEMPLATE.md](OVERLAY_TEMPLATE.md).
>
> Do not treat an unrun checklist as evidence that a system is safe.

## 1. Purpose And Boundaries

This protocol is an audit framework, not a guarantee that software is free of
defects. It is designed to make reviews repeatable, evidence-based, and broad
enough to find failures that are missed by ordinary feature testing.

It applies to:

- browser applications, progressive web apps, and mobile applications
- APIs, background workers, serverless functions, and services
- desktop applications, CLIs, libraries, and automation tools
- monoliths, modular applications, and distributed systems

It deliberately separates three things:

1. **Taxonomy:** the failure classes to investigate.
2. **Runbook:** the commands, fixtures, environments, and tools used to
   investigate them.
3. **Evidence:** the findings, tests, traces, measurements, and decisions
   recorded for one specific audit.

The protocol must be tailored to the application under review. A phase tag
says when the phase runs. `[CORE]` phases apply to any code change unless the
change map rules them out. `[CONDITIONAL]` phases run only when the
application has the relevant behavior — a static site has no server-side
concurrency path, while an API with payments may require very deep review of
it. A scoped tag such as `[CORE FOR BUG FIXES]`, `[CORE FOR USER
INTERFACES]`, or `[CORE FOR RELEASES]` marks a phase that is core whenever
the change is of that kind and optional otherwise.

## 2. Operating Rules

- Audit one bounded change, feature, module, service, or user journey at a
  time. Do not label a large codebase "reviewed" after a superficial scan.
- Start with the highest-risk execution path: user input, authentication,
  persistence, payments, destructive actions, background work, and release
  boundaries.
- Read code, configuration, tests, deployment definitions, and observed
  behavior together. Source code alone is not the whole system.
- Use real evidence. A green test suite does not prove the test is meaningful;
  a passing linter does not prove business logic is correct.
- Treat comments, docs, telemetry labels, API examples, migrations, and
  deployment configuration as contracts when other code or people rely on
  them.
- Do not report a speculative concern as a confirmed defect. State the
  evidence, confidence, impact, and the smallest reproduction.
- Do not silently widen scope. Record deferred areas and the trigger that
  makes them due.
- When fixing a defect, audit parallel implementations and callers before
  considering the fix complete.

### Audit Tiers

| Tier | When to use it | Minimum work |
| --- | --- | --- |
| T0 Documentation | Docs, comments, or formatting only | Spot-check links, examples, and claims; record a one-line verdict. |
| T1 Small change | Isolated low-risk code or styling change | Targeted tests plus relevant core phases. |
| T2 Feature | New or changed user behavior, API, integration, or state | Change map, core phases, journey test, and regression coverage. |
| T3 Critical path | Auth, money, data loss, privacy, permissions, production migration, or security boundary | Full relevant phase battery, adversarial tests, rollback review, and manual verification. |
| T4 Release audit | Material release or incident follow-up | Cross-cutting audit, production readiness review, and explicit residual-risk sign-off. |

Tier is based on the roster of files a change touches, not on what most of its
lines look like. A commit that is almost all documentation is not T0 if the
same commit also changes code, tests, or tooling.

### Required Audit Context

Before running phases, record:

- application name, repository revision, environment, and audit date
- change under review and intended user/business outcome
- supported clients, platforms, browsers, runtimes, and deployment targets
- data classifications: public, internal, personal, confidential, regulated
- trust boundaries: browser, API, worker, database, queue, third-party service
- data stores, retention requirements, backup/restore owners, and migration path
- privileged operations and destructive operations
- test commands, runtime commands, and relevant observability sources
- known constraints, unavailable environments, and explicit exclusions
- evidence sources this audit has, and which it does not: the repository, a
  running test seat, read access to the deployed environment, production
  telemetry

Record the sources before selecting phases, not after. Several phases ask for
evidence a repository cannot produce — a restore exercise, the privileges a
deployed environment currently holds, whether the artifact that shipped is the
one that was reviewed. A phase whose checks depend on a source this audit does
not have is reported **PARTIAL**, never passed, naming the missing source and
what was covered without it. PARTIAL is not `[CONDITIONAL]`: conditional means
the phase did not apply, partial means it applied and could not be finished.

Skip accounting is per phase, so without this a check that was never possible
disappears inside a phase that reports as clean, and the audit claims coverage
it never had.

## 3. Finding Standard

Every finding should include:

- **ID and severity:** Blocker, Critical, High, Medium, Low, or Observation.
- **Location:** file, function, endpoint, screen, configuration, or workflow.
- **User/system impact:** what fails, who is affected, and how severe it is.
- **Evidence:** reproduction, trace, test, screenshot, log, query, or code path.
- **Status and confidence:** CONFIRMED (reproduced) or PLAUSIBLE (reasoned but
  not reproduced), with the confidence behind the claim.
- **Root cause:** not just the visible symptom.
- **Fix direction:** smallest safe correction and any compatibility concern.
- **Verification:** test or observation that proves the correction.
- **Residual risk:** what is still unknown or deliberately deferred.

Severity is based on impact and exploitability, not the number of lines changed.
A small authorization condition can be a Blocker; a large internal refactor can
be Low risk.

## 4. Change Triage

Choose relevant phases based on the change before reviewing details. Any domain
overlay the change could plausibly touch runs on top of whatever this table
selects, and runs first — see §5.

Three phases run regardless of which row matches: Phase 24 (Smoke Test), which
also runs before the rest for the reason given under "How to read this file";
Phase 19 (Known Bug Patterns), on every code change; and Phase 42 (Audit
Registry And Finding Hygiene), whenever findings are recorded. Not every row
below lists 24 — it is selected by this paragraph, not by the table. A core
phase not named by any matching row is not waived either; it still runs at
Release.

| Change type | Always consider |
| --- | --- |
| Anything an overlay covers | That overlay first, at T3, then the rows below |
| API or worker behavior | 1-5, 9-10, 15-17, 20, 24-28, 32, 34-35, 37 |
| Shared model, engine, or contract | 3-7, 12, 15-16, 20, 22, 25-28, 32, 35, 37, 40, 43 |
| Auth, permissions, or privacy | 1-5, 9-10, 14-17, 20-21, 24-28, 32, 35, 37-38, 43, 47-48, 50 |
| Security-sensitive feature or public API | 1-5, 9-10, 14-17, 20, 24-28, 32, 35, 37-38, 43, 47-50, 53-54 |
| Performance or memory fix | 5, 8-9, 12, 17, 20, 24, 30-31, 39, 44-46 |
| Serialization or app-level persistence logic | 3-5, 9, 14-17, 20, 24-28, 32, 35, 37, 43 |
| Database, storage, or migration | 3-5, 8-10, 14-17, 20, 24-28, 32, 35, 37, 43, 49-50, 53-54 |
| New UI flow, mobile, or accessibility change | 1-5, 8, 11-12, 15, 20-21, 24, 26, 31, 36-37, 51-52 |
| File or directory relocation and reference rewriting | 1-2, 10, 14-15, 20, 24, 26-28, 32, 35, 37, 41, 43 |
| Refactor | 1-3, 5, 11-12, 15, 20, 24, 26-28, 31, 37, 41, 43-44 |
| Bug fix | Original defect phases plus 20, 37-38, and affected regression tests |
| Release | All applicable core phases plus 47-54, observability, rollback, and platform checks |

## 5. Domain Overlays

A generic taxonomy finds generic failures. Every application also has one or two
failure classes specific to what it does, and those are usually the ones that
actually hurt: the payment that charges twice, the record one tenant can read
from another, the model trained on data from after the prediction date.

An overlay is a short document that pins those classes as named invariants. It
differs from a phase in three ways:

1. **It runs first** — before any generic phase, on every change that could
   plausibly touch it.
2. **It forces the tier** — a change touching an overlay invariant is T3
   regardless of how small the diff looks.
3. **Its violations are Blockers by definition** — not "Blocker if severe". A
   reintroduced overlay violation blocks the release even when the diff is
   small, reviews are clean, and every test passes.

Write each invariant as a claim that must be proved yes or no with evidence,
never by reading the happy path. Keep overlays short: more than about eight
invariants means you have written a specification, not an overlay.

Not every overlay is filed as one. A contributor guide, an agent instructions
file, or an architecture note is often where a project's invariants are
already written down — take them from there and run them first.

**An overlay ages with the project, and it is the one document in the loop that
nobody audits.** Before running it, read its own scoping: the invariants it
declares out of scope, the phases it defers, the conditions it says do not apply
here, and the evidence each "prove it" clause points at. Every one of those was
a true statement about a system that has since changed. A deferral whose stated
reason has expired is a finding against the overlay, and the phase it was
deferring runs. A proof procedure that names code no longer in the repository is
an invariant that has quietly stopped being checked, however green the audit
looks.

This matters more than it sounds. Overlays are what make an audit specific to a
project, so an overlay that describes a system the project has outgrown makes
the audit confidently wrong rather than merely generic — and it does so while
reporting that your own rules were honored.

Build your own with [OVERLAY_TEMPLATE.md](OVERLAY_TEMPLATE.md). Four worked
examples ship alongside this protocol:

| Overlay | Failure class it pins |
| --- | --- |
| [payments](overlays/payments.md) | money moved twice, moved wrong, or not moved at all |
| [access-control](overlays/access-control.md) | one principal reaching another's data or privileges |
| [data-pipeline](overlays/data-pipeline.md) | leakage, non-determinism, and silent schema drift |
| [evidence-chain](overlays/evidence-chain.md) | a sealed result that no longer proves what it claims |

They are illustrations, not a library to install. Yours should name your
invariants, not theirs.

---

## How to read this file

The numbers are a **catalog, not a running order.** Nobody runs 54 phases.
Your change selects a handful through the triage table in §4, and the tier in
§2 sets how deep each one goes.

Three things about the order:

- **Phase 24 (smoke test) runs first**, whatever else you selected. A build
  that does not start makes every later phase a guess.
- **Some phases deepen an earlier one** rather than covering new ground. They
  are separate because they cost more and are not always worth it: 22 deepens
  14, 23 and 36 deepen 4, 29 adds regressions for 6, 39 triages what 31 found,
  43 and 44 extend 26. Run the shallow one at T2, add the deep one at T3.
- **Everything else is unordered.** Start with the highest-risk execution path,
  not with phase 1.

## Phase index

`core` runs on any code change · `cond` runs only when the application has
that behavior · `scoped` is core for one kind of change, named in the phase's
own tag.

**Engineering phases**

1. [Syntax, Build, And Immediate Runtime Failures](#1-syntax-build-and-immediate-runtime-failures-core) · core
2. [Static Analysis, Types, And Dead Code](#2-static-analysis-types-and-dead-code-core) · core
3. [Business Logic, Rules, And Formula Correctness](#3-business-logic-rules-and-formula-correctness-core) · core
4. [Input Boundaries And Edge Cases](#4-input-boundaries-and-edge-cases-core) · core
5. [State, Mutation, Lifecycle, And Caching](#5-state-mutation-lifecycle-and-caching-core) · core
6. [Time, Ordering, And Temporal Correctness](#6-time-ordering-and-temporal-correctness-conditional) · cond
7. [Numerical, Units, And Precision Hygiene](#7-numerical-units-and-precision-hygiene-conditional) · cond
8. [Resource, Memory, And Performance Behavior](#8-resource-memory-and-performance-behavior-core) · core
9. [Errors, Recovery, And Failure Modes](#9-errors-recovery-and-failure-modes-core) · core
10. [Dependencies, Build, Configuration, And Environment](#10-dependencies-build-configuration-and-environment-core) · core
11. [Architecture, Boundaries, And Maintainability](#11-architecture-boundaries-and-maintainability-core) · core
12. [Testability, Determinism, And Reproducibility](#12-testability-determinism-and-reproducibility-core) · core
13. [Domain-Specific Rules And Regulated Behavior](#13-domain-specific-rules-and-regulated-behavior-conditional) · cond
14. [Implicit Coupling And Hidden Dependencies](#14-implicit-coupling-and-hidden-dependencies-core) · core
15. [Integration And End-To-End Data Flow](#15-integration-and-end-to-end-data-flow-core) · core
16. [Data Integrity And Semantic Validity](#16-data-integrity-and-semantic-validity-core) · core
17. [Concurrency, Parallelism, And Serialization](#17-concurrency-parallelism-and-serialization-conditional) · cond
18. [Decision Quality, Heuristics, And Algorithmic Robustness](#18-decision-quality-heuristics-and-algorithmic-robustness-conditional) · cond
19. [Known Bug Patterns](#19-known-bug-patterns-core) · core
20. [Unit, Integration, And End-To-End Test Logic](#20-unit-integration-and-end-to-end-test-logic-core) · core
21. [Cross-Feature And Configuration Interaction](#21-cross-feature-and-configuration-interaction-core) · core
22. [Deep Implicit-Coupling Audit](#22-deep-implicit-coupling-audit-core-for-shared-state-and-contract-changes) · scoped
23. [Advanced Boundary And Data Validation](#23-advanced-boundary-and-data-validation-conditional) · cond
24. [Smoke Test](#24-smoke-test-core) · core
25. [Configuration, Parameter, And Option Validation](#25-configuration-parameter-and-option-validation-core) · core
26. [Call Site And Execution-Path Verification](#26-call-site-and-execution-path-verification-core) · core
27. [Constant, Identifier, And Format Consistency](#27-constant-identifier-and-format-consistency-core) · core
28. [Strict Contract And Schema Validation](#28-strict-contract-and-schema-validation-core) · core
29. [Temporal Correctness Regression](#29-temporal-correctness-regression-conditional) · cond
30. [Operational Cost, Capacity, And Budget Validation](#30-operational-cost-capacity-and-budget-validation-core) · core
31. [Mutation Testing And Test-Quality Probes](#31-mutation-testing-and-test-quality-probes-conditional) · cond
32. [Producer-To-Consumer Contract Audit](#32-producer-to-consumer-contract-audit-core) · core
33. [Randomized And Probabilistic Behavior](#33-randomized-and-probabilistic-behavior-conditional) · cond
34. [Third-Party Platform And Library Behavior](#34-third-party-platform-and-library-behavior-core) · core
35. [Write-Read And Persistence Identity](#35-write-read-and-persistence-identity-conditional) · cond
36. [Boundary Fuzzing](#36-boundary-fuzzing-conditional) · cond
37. [Differential Parity](#37-differential-parity-core) · core
38. [Scope-Narrow Fix Detection](#38-scope-narrow-fix-detection-core-for-bug-fixes) · scoped
39. [Deep Mutation Survival Review](#39-deep-mutation-survival-review-conditional) · cond
40. [Property And Invariant Coverage](#40-property-and-invariant-coverage-conditional) · cond
41. [Snapshot And Golden Baseline Coverage](#41-snapshot-and-golden-baseline-coverage-conditional) · cond
42. [Audit Registry And Finding Hygiene](#42-audit-registry-and-finding-hygiene-core) · core
43. [Caller Parity And Centralized-Contract Drift](#43-caller-parity-and-centralized-contract-drift-core) · core
44. [Call Relocation And Side-Effect Timing](#44-call-relocation-and-side-effect-timing-conditional) · cond
45. [Resource-Lifecycle Placement And Cadence](#45-resource-lifecycle-placement-and-cadence-conditional) · cond
46. [Instrumentation And Non-Critical Side-Effect Resilience](#46-instrumentation-and-non-critical-side-effect-resilience-core) · core

**Platform and delivery phases**

47. [Threat Modeling And Application/API Security](#47-threat-modeling-and-applicationapi-security-conditional) · cond
48. [Identity, Authorization, Session, And Abuse Controls](#48-identity-authorization-session-and-abuse-controls-conditional) · cond
49. [Database, Storage, Migration, And Recovery](#49-database-storage-migration-and-recovery-conditional) · cond
50. [Privacy, Consent, And Data Lifecycle](#50-privacy-consent-and-data-lifecycle-conditional) · cond
51. [Accessibility And Inclusive Interaction](#51-accessibility-and-inclusive-interaction-core-for-user-interfaces) · scoped
52. [UX, Responsive Layout, Mobile Platform, And User Trust](#52-ux-responsive-layout-mobile-platform-and-user-trust-core-for-user-interfaces) · scoped
53. [Observability, Reliability, Incident Readiness, And SLOs](#53-observability-reliability-incident-readiness-and-slos-conditional) · cond
54. [Delivery, Deployment, Infrastructure, And Supply-Chain Integrity](#54-delivery-deployment-infrastructure-and-supply-chain-integrity-core-for-releases) · scoped

---

# Core Audit Phases

## 1. Syntax, Build, And Immediate Runtime Failures [CORE]

Check whether the application can be built, loaded, initialized, and execute
its smallest meaningful path.

**Focus on:**

- syntax, parse, compilation, bundling, and import failures
- missing exports, modules, assets, environment values, and registrations
- invalid function signatures, wrong argument counts, and unsupported calls
- startup crashes, blank screens, broken routes, and worker initialization
- circular dependency behavior and import-time side effects

**Also verify:**

- the production build, not only development mode
- the entry point for each supported execution environment
- error consoles, server logs, and build diagnostics are clean

**Output:**

- exact failing path, location, and reproduction command
- whether the failure is development-only, production-only, or universal

## 2. Static Analysis, Types, And Dead Code [CORE]

Check the static contracts the language and project tooling can enforce.

**Focus on:**

- undefined, unused, shadowed, or implicitly global values
- type mismatches, unsafe casts, nullability errors, and unchecked results
- stale imports, unreachable branches, dead feature flags, and obsolete APIs
- signature mismatch between declaration, implementation, and callers
- lint suppressions that hide real risk

**Also verify:**

- generated code and serverless/worker code are included in analysis
- project type settings reflect runtime reality rather than silence errors
- warnings treated as acceptable have a documented rationale

**Output:**

- violations grouped by crash risk, correctness risk, and maintainability risk

## 3. Business Logic, Rules, And Formula Correctness [CORE]

Check whether the system produces the intended outcome for normal, boundary,
and adversarial scenarios.

**Focus on:**

- comparison errors (`>` vs `>=`), inversion, bad precedence, and off-by-one
- invalid state transitions and incorrectly ordered operations
- formulas, unit conversion, rounding rules, scoring, quotas, and eligibility
- rule exceptions, overrides, retry limits, and expiration behavior
- assumptions encoded in conditionals but absent from the product requirement

**Also verify:**

- expected behavior against written acceptance criteria or approved product rules
- boundary values immediately below, at, and above each threshold
- manual calculations for representative high-impact examples

**Output:**

- wrong path, smallest failing scenario, expected outcome, and actual outcome

## 4. Input Boundaries And Edge Cases [CORE]

Check every entry point for malformed, missing, unexpected, or extreme input.

**Focus on:**

- empty, null, undefined, absent, duplicated, and single-item inputs
- zero, negative, maximum, minimum, huge, fractional, infinity, and NaN values
- malformed text, Unicode, whitespace, encoding, locale, and timezone inputs
- invalid enum values, unknown keys, wrong object shape, and stale client data
- file, network, URL, form, CLI, webhook, and inter-service inputs

**Also verify:**

- validation happens at every trust boundary, not only in the UI
- error messages are actionable without exposing secrets or internal structure
- rejected input leaves no partial state, reservation, or side effect behind

**Output:**

- breaking inputs, validation gap, and post-failure state

## 5. State, Mutation, Lifecycle, And Caching [CORE]

Check that state belongs to the correct owner, changes predictably, and is
reset, persisted, invalidated, or disposed at the correct time.

**Focus on:**

- shared mutable state, accidental singleton state, and mutable defaults
- stale UI state, stale closures, stale caches, and missed invalidation
- state leakage across users, tenants, requests, sessions, tabs, jobs, or tests
- duplicate events, non-idempotent retries, partial updates, and lost updates
- cleanup of timers, subscriptions, listeners, observers, sockets, and workers

**Also verify:**

- refresh, back/forward navigation, reconnect, retry, logout, and restart paths
- optimistic updates can recover after a failed server operation
- state recovery is deterministic after crash or process restart

**Output:**

- state owner, mutation path, lifecycle expectation, and leakage/corruption risk

## 6. Time, Ordering, And Temporal Correctness [CONDITIONAL]

Check behavior whose correctness depends on order, timing, clocks, expiration,
or event sequencing.

**Focus on:**

- timestamp units, timezone conversion, daylight-saving boundaries, and UTC use
- expiration, cooldown, debounce, throttle, scheduling, and retry timing
- out-of-order delivery, duplicated events, late events, and clock skew
- race between UI, API, queue, worker, and persistence updates
- future data or future state accidentally used to decide present behavior

**Also verify:**

- time is injectable or controllable in tests when behavior depends on it
- server is authoritative for security, billing, competition, and expiration
- end-of-day, week, month, and leap-year behavior follows the stated product rule

**Output:**

- event timeline, incorrect ordering, and expected authoritative clock/source

## 7. Numerical, Units, And Precision Hygiene [CONDITIONAL]

Check calculations, counters, measurements, currency, percentages, and unit
conversion for stability and semantic correctness.

**Focus on:**

- floating-point equality, rounding mode, overflow, underflow, and accumulation
- precision loss through serialization, display, parsing, or integer conversion
- unit mismatch: bytes vs kilobytes, seconds vs milliseconds, ratio vs percent
- division by zero, NaN/Infinity propagation, and conversion before validation
- currency minor units, tax/fee rounding, and locale-formatted number parsing

**Also verify:**

- invariants such as conservation, non-negativity, boundedness, and totals
- displayed values use the same rounding policy as decisions and persistence
- exact decimal/fixed-point approaches where domain requirements demand them

**Output:**

- numerical reproduction, correct value, observed value, and tolerance policy

## 8. Resource, Memory, And Performance Behavior [CORE]

Check peak as well as average cost under realistic inputs, devices, and run
duration.

**Focus on:**

- unbounded collections, retained references, memory leaks, and listener leaks
- repeated work, N+1 calls, nested loops, polling, and expensive rendering paths
- CPU, battery, network, storage, startup, interaction, and background cost
- continuous animation or polling while idle, hidden, or offscreen
- resource limits in serverless, worker, mobile, browser, and container runtimes

**Also verify:**

- shallow vs deep copy cost; state the payload and peak-memory implication
- release/flush/cleanup timing happens before the next allocation can exceed a
  budget, not merely eventually
- performance budgets exist for the critical experience and are enforced in CI
- low-end device, slow network, and long-running workload behavior where relevant

**Output:**

- measured bottleneck, workload, baseline, budget, and recommended correction

## 9. Errors, Recovery, And Failure Modes [CORE]

Check that failures are contained, visible to the right audience, recoverable,
and never converted into silent corruption.

**Focus on:**

- swallowed exceptions, broad catches, misleading fallback values, and blank UI
- retries without backoff, retry storms, duplicate side effects, and bad limits
- partial writes, partial uploads, interrupted jobs, and compensation behavior
- user-facing errors that do not state whether an action completed
- fatal errors from non-critical telemetry, analytics, or housekeeping work

**Also verify:**

- error paths leave state consistent and release resources
- retried operations are idempotent or protected by an idempotency key
- logs retain a correlation identifier without recording sensitive data

**Output:**

- failure trigger, blast radius, recovery behavior, and observable evidence

## 10. Dependencies, Build, Configuration, And Environment [CORE]

Check the application outside the happy-path developer machine.

**Focus on:**

- missing, vulnerable, incompatible, deprecated, or unpinned dependencies
- runtime/version drift between local, CI, preview, and production
- build-time vs runtime configuration confusion and missing environment values
- platform, filesystem, path, locale, browser, device, and architecture variance
- unsafe default configuration, exposed source maps, debug modes, and test keys

**Also verify:**

- secrets are not bundled, logged, committed, or exposed through client config
- deployment output uses the intended branch, artifact, environment, and region
- feature flags have ownership, default, expiration, and rollback behavior

**Output:**

- environment matrix, reproducible incompatibility, and deployment risk

## 11. Architecture, Boundaries, And Maintainability [CORE]

Check whether the design permits safe change, testing, operation, and ownership.

**Focus on:**

- oversized modules, unclear responsibility, circular ownership, and hidden IO
- mixing rendering, state, domain rules, persistence, auth, and transport logic
- undocumented singleton services, duplicate models, and fragile shared helpers
- abstraction that leaks implementation details or adds indirection without value
- missing seams for testing, replacement, observability, and fault isolation

**Also verify:**

- modules reflect stable product/domain boundaries rather than current file size
- critical rules have a single authoritative implementation
- refactor proposals reduce risk without changing behavior unintentionally

**Output:**

- boundary issue, change cost, coupling path, and incremental refactor option

## 12. Testability, Determinism, And Reproducibility [CORE]

Check whether behavior can be reproduced and tests can reliably isolate failures.

**Focus on:**

- uncontrolled time, randomness, network, process state, and external services
- hardcoded values that make tests fragile or prevent alternate scenarios
- hidden dependencies, global setup, test-order dependency, and shared fixtures
- flaky asynchronous waits, real sleeps, arbitrary retries, and timing races
- tests that cannot inject a clock, seed, transport, store, or failure mode

**Also verify:**

- a failing test produces enough context to reproduce locally
- deterministic seeds are logged for randomized failures
- tests can run in isolation and in a clean process

**Output:**

- nondeterministic source, reproduction strategy, and missing test seam

## 13. Domain-Specific Rules And Regulated Behavior [CONDITIONAL]

Most applications have domain rules that generic engineering checks cannot
prove. Create a domain overlay rather than burying them in unrelated phases.

**Examples:**

- commerce: price, inventory, tax, refunds, promotion, and fulfillment rules
- health: clinical safety, consent, audit trail, and data-handling rules
- finance: authorization, ledger, settlement, rounding, and compliance rules
- games: fairness, matchmaking, scoring, anti-cheat, and progression rules
- education: assessment validity, accessibility, moderation, and age safeguards
- AI products: model behavior, prompt safety, data provenance, and evaluation

**Focus on:**

- authoritative business source and conflict resolution rules
- policy versions, eligibility, exceptions, and approval boundaries
- legal, contractual, safety, and fairness requirements specific to the domain
- server-side enforcement for outcomes that must not be client-controlled

**Output:**

- domain rule matrix, source of truth, and unverified/high-risk decision paths

## 14. Implicit Coupling And Hidden Dependencies [CORE]

Check for behavior controlled by incidental structure instead of explicit contracts.

**Focus on:**

- behavior keyed on a field, string, route, CSS class, filename, or import order
- optional values that silently select a destructive default
- shared global/config state used by distant modules without ownership
- dependency on creation order, cache warmth, environment variable presence, or UI structure and render order
- error paths that leave hidden state affecting the next request or user action

**Also verify:**

- every implicit condition has an explicit contract or a deliberate documented rule
- feature flags and defaults cannot silently change security or persistence behavior
- a missing field is distinguished from an empty, false, zero, and invalid field

**Output:**

- hidden trigger, producer, consumers, and silent behavior-change scenario

## 15. Integration And End-To-End Data Flow [CORE]

Trace data and intent across all components that participate in a user journey.

**Focus on:**

- request/response mismatch, version mismatch, serialization failure, and retries
- client/server/worker disagreement about validation, authorization, or state
- missing propagation of correlation IDs, locale, tenant, permissions, or version
- webhook, queue, cache, file, storage, and third-party integration contracts
- fallback paths that differ materially from the primary path

**Also verify:**

- an action has a clear outcome across UI, API, persistence, events, and analytics
- idempotency and deduplication work at integration boundaries
- mock/stub behavior does not hide production contract differences

**Output:**

- journey diagram, contract mismatch, owner, and failure/retry semantics

## 16. Data Integrity And Semantic Validity [CORE]

Check that data remains accurate, complete, correctly ordered, and meaningful
through its lifecycle.

**Focus on:**

- missing, duplicate, stale, unordered, malformed, and impossible records
- incorrect tenant/user ownership, timezone, locale, version, or source metadata
- orphaned references, invalid state combinations, and broken invariants
- destructive updates, overwrite behavior, retention, deletion, and restoration
- discrepancy between derived/cache data and its authoritative source

**Also verify:**

- data validation defines what to reject, repair, quarantine, and alert on
- historical data is compatible with current application interpretation
- reconciliation can detect and correct drift where the domain needs it

**Output:**

- invariant, violating record/path, detection gap, and repair/containment plan

## 17. Concurrency, Parallelism, And Serialization [CONDITIONAL]

Check concurrent readers, writers, jobs, requests, processes, and devices.

**Focus on:**

- read-modify-write races, lost updates, duplicate work, and conflicting retries
- lock scope, lock release, timeout, deadlock, starvation, and priority inversion
- queue ordering, at-least-once delivery, message visibility, and poison messages
- serialization/deserialization compatibility and versioned payload handling
- inconsistent state during concurrent deploys, migrations, or worker execution

**Also verify:**

- concurrency control is appropriate for the data and operation, not accidental
- operations are atomic or have a defined compensation/reconciliation path
- parallel execution produces equivalent results when the contract requires it

**Output:**

- interleaving schedule, lost/duplicated result, and synchronization strategy

## 18. Decision Quality, Heuristics, And Algorithmic Robustness [CONDITIONAL]

Check automated decisions, rankings, recommendations, classifications, and
heuristics for meaningful use of available data and stable behavior.

**Focus on:**

- decisions that ignore relevant input fields or use stale derived values
- arbitrary thresholds, binary gates, unstable ordering, and tie-break behavior
- sensitivity to small input changes, start state, ordering, or sampling
- feedback loops, bias, starvation, unfairness, and disparate outcomes
- objectives that do not match user value, safety, or stated product policy

**Also verify:**

- score/rank/selection definitions are explained and reproducible
- deterministic tie-breaking exists where output order matters
- offline evaluation, simulation, or historical validation does not overstate reality

**Output:**

- decision path, missing signal, sensitivity evidence, and safer rule/design

## 19. Known Bug Patterns [CORE]

Maintain a project-independent library of recurring failures and apply the
relevant patterns to every meaningful change.

**Baseline patterns:**

- null/default confusion and truthiness misuse
- unit, encoding, timezone, and locale mismatch
- stale cache/state and missing invalidation
- duplicate side effects after retry or navigation
- client-only enforcement of server-authoritative rules
- authorization based on untrusted identity or object ownership
- unsafe string matching, path construction, or serialization
- missing pagination, unbounded query/result, and N+1 access patterns
- generated output diverging from source-of-truth contracts
- comments/tests/documentation drifting from behavior

**Output:**

- matches, non-matches, and newly discovered patterns added to the local catalog

## 20. Unit, Integration, And End-To-End Test Logic [CORE]

Check that tests validate the intended behavior rather than merely execute code.

**Focus on:**

- assertions that are too weak, tautological, or disconnected from requirements
- fixtures that cannot trigger the intended branch or failure condition
- mocks that assert implementation details while hiding contract failures
- missing negative, boundary, cancellation, timeout, retry, and recovery tests
- coverage that is broad but does not exercise high-risk decisions

**Also verify:**

- each fixed defect has a regression test that failed before the correction
- integration tests use realistic serialization, auth, persistence, and timing
- E2E tests cover critical user journeys at the actual release boundary

**Output:**

- false confidence risk, missing scenario, and discriminating test proposal

## 21. Cross-Feature And Configuration Interaction [CORE]

Check combinations of features, flags, permissions, devices, and states.

**Focus on:**

- partial rollout, disabled feature, rollback, and stale client combinations
- permission plus feature-flag, locale plus currency, and platform plus browser
- import/export, offline/online, anonymous/authenticated, and new/returning users
- conflicting modals, routes, keyboard shortcuts, background tasks, and caches
- default settings that only fail when another feature is active

**Also verify:**

- critical configuration pairs/triples are selected by risk, not by exhaustive enumeration or at random
- test matrix includes upgrade and downgrade paths when stored data is involved

**Output:**

- incompatible combination, affected users, and required compatibility rule

## 22. Deep Implicit-Coupling Audit [CORE FOR SHARED-STATE AND CONTRACT CHANGES]

> Deepens [phase 14](#14-implicit-coupling-and-hidden-dependencies-core). Run 14 at T2; add this at T3.

Perform a deeper producer/consumer investigation when a change touches shared
state, contracts, defaults, or conventions.

**Focus on:**

- all writers and readers of a shared field, cache key, event, label, or setting
- defaults that produce valid-looking but unsafe behavior
- format and protocol assumptions encoded in separate modules
- partial state after an exception, cancellation, or process restart
- hidden requirements communicated only by examples or historical behavior

**Output:**

- complete dependency map and prioritized decoupling/contract recommendations

## 23. Advanced Boundary And Data Validation [CONDITIONAL]

> Deepens [phase 4](#4-input-boundaries-and-edge-cases-core). Run 4 at T2; add this at T3.

Stress transformations and calculations near their practical and semantic limits.

**Focus on:**

- warm-up/initialization behavior, first and last item behavior, and empty streams
- repeated conversion, pagination boundary, maximum payload, and large batch paths
- malformed historical data, version transitions, missing fields, and partial records
- behavior after reconnect, resume, resume-from-cache, and partial synchronization

**Also verify:**

- bounds are explicit and independently enforced at the trust boundary
- error behavior is safe and does not quietly coerce bad data into accepted data

**Output:**

- adversarial case, invariant, actual behavior, and regression test requirement

## 24. Smoke Test [CORE]

Perform a fast, realistic first pass before deeper review.

**Focus on:**

- install/build/start succeeds from documented steps
- primary application route, service endpoint, or command initializes
- minimal create/read/update/delete or primary workflow executes
- required registrations, assets, routes, and configuration are present

**Output:**

- immediate crash, missing wiring, or minimal-path failure

## 25. Configuration, Parameter, And Option Validation [CORE]

Check that declared options have one meaning from configuration through runtime.

**Focus on:**

- inconsistent option names, aliases, defaults, values, and precedence
- input accepted but ignored, silently coerced, or replaced by a fallback
- values applied in UI but not server, worker, or persisted state
- unsupported combinations and deprecated options without migration behavior

**Also verify:**

- changing an option changes the intended observable behavior
- configuration source and precedence are documented and testable

**Output:**

- dead/miswired option, source of default, and end-to-end evidence

## 26. Call Site And Execution-Path Verification [CORE]

Check that important code is reached, called with correct data, and not bypassed.

**Focus on:**

- defined but unused functions, handlers, validators, migration hooks, or jobs
- required calls missing from alternate flows, retry paths, or feature branches
- wrong arguments, wrong order, wrong return-value handling, or ignored errors
- guarded calls that never run due to impossible condition or stale flag

**Also verify:**

- critical policy/auth/validation code runs before the protected operation
- traces or tests demonstrate the expected path rather than inference alone

**Output:**

- execution map, missing/bad call site, and proof requirement

## 27. Constant, Identifier, And Format Consistency [CORE]

Check values and identifiers expected to agree across boundaries.

**Focus on:**

- duplicated thresholds, magic values, routes, event names, keys, and error codes
- inconsistent casing, formatting, locale, date, identifier, and URL conventions
- UI labels, analytics events, log labels, schema keys, and documentation examples
- encode/decode, parse/format, and display/store asymmetry

**Also verify:**

- central constants are imported rather than copied into callers
- telemetry labels consumed by exact-match parsers retain compatibility or versioning

**Output:**

- divergence, source of truth, affected consumers, and consolidation plan

## 28. Strict Contract And Schema Validation [CORE]

Check public and internal contracts at API, event, storage, configuration, and
component boundaries.

**Focus on:**

- required/optional fields, types, allowed values, defaults, and unknown fields
- response and event compatibility across application versions
- contract documentation/examples drifting from runtime behavior
- schema validation omitted on internal boundaries because callers are "trusted"

**Also verify:**

- contracts are versioned or compatibility-tested when independent deployment exists
- errors distinguish malformed input, unauthorized action, missing resource, and conflict
- consumers safely handle absent optional fields and newer producer versions

**Output:**

- contract definition, producer/consumer mismatch, and compatibility result

## 29. Temporal Correctness Regression [CONDITIONAL]

> Adds regression coverage for [phase 6](#6-time-ordering-and-temporal-correctness-conditional). Run 6 first.

Add targeted regressions for time-sensitive behavior rather than relying on one
happy-path clock test.

**Focus on:**

- use of only past/authorized state when making a decision
- same-event ordering: create then authorize, update then notify, charge then fulfill
- expiration, retry, scheduled-job, and date-boundary behavior
- client/server time disagreement and clock-skew fallback

**Output:**

- normal timeline, adversarial timeline, and proof that ordering is enforced

## 30. Operational Cost, Capacity, And Budget Validation [CORE]

Validate that the product remains useful and economically/operationally safe at
expected and adverse scale.

**Focus on:**

- cost per request/job/user, third-party quota, rate, and storage growth
- degradation under load, large account/project, slow network, and offline conditions
- hard limits, graceful rejection, backpressure, pagination, and user messaging
- whether a small increase in volume causes timeout, memory exhaustion, or quota failure

**Also verify:**

- capacity assumptions are documented and observable in production
- budgets are tested for the critical path where practical

**Output:**

- workload, observed limit, safe operating budget, and mitigation

## 31. Mutation Testing And Test-Quality Probes [CONDITIONAL]

Check whether tests fail when behavior is intentionally made wrong.

**Focus on:**

- comparison inversion, off-by-one, boolean swap, removed validation, and bad return
- altered constants, error handling, default, and serialization behavior
- tests that execute code but do not distinguish correct and incorrect outcomes

**Also verify:**

- mutations are scoped to high-risk, stable modules to avoid noisy vanity metrics
- surviving mutations are triaged as equivalent, irrelevant, or a test gap

**Output:**

- killed/survived mutation evidence and strengthened assertion proposal

## 32. Producer-To-Consumer Contract Audit [CORE]

Map every important value from origin to all consumers.

**Focus on:**

- who creates, validates, transforms, stores, and consumes each critical field
- schema, semantic, unit, ownership, privacy, and version expectations at each hop
- consumers that assume values are present, trusted, or already normalized
- producer changes that silently affect analytics, exports, jobs, integrations, or UI

**Also verify:**

- logs and telemetry use stable, documented values where downstream tooling depends on them
- a changed label value is not mistaken for an unchanged schema

**Output:**

- lineage map, broken handoff, and correct contract owner

## 33. Randomized And Probabilistic Behavior [CONDITIONAL]

Check randomness, sampling, distribution, and fairness where outputs are not
expected to be identical on every run.

**Focus on:**

- seeded/reproducible behavior in tests and investigation mode
- expected distribution, probability bounds, and bias/fairness requirements
- randomness sourced from an appropriate entropy source for the risk level
- accidental dependence on array order, process timing, or non-secure random APIs

**Also verify:**

- users cannot predict or manipulate outcomes that must be fair or secure
- statistical tests have sufficient sample size and an explicit tolerance

**Output:**

- distribution evidence, seed policy, and bias/manipulation risk

## 34. Third-Party Platform And Library Behavior [CORE]

Validate assumptions about frameworks, SDKs, browsers, operating systems, and
external APIs rather than trusting names or common behavior.

**Focus on:**

- version-specific behavior, defaults, edge cases, and deprecations
- browser/platform differences, mobile lifecycle, permission behavior, and storage rules
- pagination, rate limits, webhook signatures, retries, and error semantics of APIs
- security boundaries delegated to a library but misconfigured by the application

**Also verify:**

- primary documentation or a controlled integration test supports each critical assumption
- the app can observe and handle upstream partial outage or incompatible response

**Output:**

- assumption, verified behavior, version scope, and fallback plan

## 35. Write-Read And Persistence Identity [CONDITIONAL]

Check that persisted, cached, exported, encrypted, or transmitted data returns
with its required meaning intact.

**Focus on:**

- write then read equality for values, types, ordering, precision, ownership, and version
- serialization/deserialization, compression, encryption, upload/download, and import/export
- partial write, interrupted save, duplicate submit, conflict resolution, and recovery
- data written by old versions and read by new versions, and the reverse where supported

**Also verify:**

- saved data is durable when the UI says it is saved
- cache data is distinguishable from authoritative persisted data

**Output:**

- round-trip fixture, mismatch, migration/recovery behavior, and regression test

## 36. Boundary Fuzzing [CONDITIONAL]

> Automates what [phase 4](#4-input-boundaries-and-edge-cases-core) does by hand. Neither replaces the other.

Use generated adversarial input to test parsers, validators, state machines,
transformations, and public entry points.

**Focus on:**

- empty, malformed, huge, nested, duplicate, encoded, and partially valid inputs
- Unicode, binary, JSON, URL, file, date, numeric, and protocol edge cases
- invariants: no crash, bounded resource use, valid result or explicit rejection
- client/server equivalence for inputs accepted by both sides

**Also verify:**

- generated cases are reproducible with a saved seed/counterexample
- fuzzing has guards to avoid destructive production effects

**Output:**

- invariant, counterexample, reproducer, and minimal regression test

## 37. Differential Parity [CORE]

Detect drift among two or more implementations of the same intended rule.

**Focus on:**

- browser/server/worker versions of validation, scoring, pricing, or authorization
- old/new engines during migration, vectorized/reference paths, and native/web paths
- encode/decode, serialize/deserialize, parser/formatter, and read/write pairs
- duplicated adapters, implementation-specific optimizations, and fallback paths

**Method:**

- define canonical inputs and compare observable outputs across each pair
- use generated inputs for high-risk invariants where practical
- use a discrimination probe: deliberately alter one side and confirm the parity test fails

**Output:**

- pair catalog, parity status, drift reproduction, and source-of-truth decision

## 38. Scope-Narrow Fix Detection [CORE FOR BUG FIXES]

After fixing a defect, search for siblings of the same failure pattern before
declaring the fix complete.

**Focus on:**

- same-file functions, alternate branches, platform variants, and parallel services
- paired implementations and all call sites of the corrected helper/contract
- repeated comparisons, defaults, parsing, authorization, or cleanup patterns
- generated code/configuration that mirrors the corrected source

**Output:**

- sibling search evidence, additional fixes, or explicit scope rationale

## 39. Deep Mutation Survival Review [CONDITIONAL]

> Triages the output of [phase 31](#31-mutation-testing-and-test-quality-probes-conditional). Run 31 first or this has no input.

Use mutation results and targeted manual changes to improve tests on the most
critical code paths.

**Focus on:**

- high-risk policy, authorization, persistence, arithmetic, and state-transition code
- surviving comparisons, booleans, return values, constants, and error branches
- whether survivors are equivalent changes or meaningful untested behavior

**Output:**

- survival rate by critical module, triage decision, and test-improvement backlog

## 40. Property And Invariant Coverage [CONDITIONAL]

Translate documented and implicit invariants into generative/property tests.

**Focus on:**

- determinism, idempotence, round-trip identity, monotonicity, boundedness, and conservation
- permissions never broadening after normalization or retry
- state-machine transitions always remaining valid
- canonicalization producing stable output over equivalent representations

**Also verify:**

- properties are true product invariants, not accidental implementation details
- failing generated examples are minimized and retained as regression fixtures

**Output:**

- invariant catalog, property tests, discovered counterexamples, and corrected claims

## 41. Snapshot And Golden Baseline Coverage [CONDITIONAL]

Lock high-value behavior with approved representative inputs and expected output
when refactors or version upgrades create drift risk.

**Focus on:**

- critical user journeys, API responses, engine output, exports, rendering, and migrations
- stable fixtures with versioned input, expected output, and tolerance policy
- review of intentional baseline changes rather than automatic replacement

**Also verify:**

- snapshots supplement semantic tests and must not degrade into massive unreadable diffs that conceal real changes
- sensitive data is removed from fixtures and snapshots

**Output:**

- baseline scope, observed diff, intentional/defect decision, and update evidence

## 42. Audit Registry And Finding Hygiene [CORE]

Maintain visibility of what was reviewed, what changed, and what remains open.

**Focus on:**

- last audit date and revision for critical files/services/journeys
- open findings, owner, severity, evidence, and re-evaluation trigger
- deferred tests, unsupported platforms, unavailable tooling, and accepted risk
- parity-pair catalog, invariant catalog, and known-bug-pattern catalog freshness

**Also verify:**

- closing a finding records verification, not only a code-change reference
- stale audits are surfaced when a relevant component materially changes

**Output:**

- audit registry update and a prioritized residual-risk list

## 43. Caller Parity And Centralized-Contract Drift [CORE]

> Extends [phase 26](#26-call-site-and-execution-path-verification-core) across every caller of a shared contract.

Detect inline copies of centralized rules that may not change with their source
of truth.

**Focus on:**

- copied thresholds, defaults, validation predicates, and error mapping
- callers importing a module but recreating the important behavior locally
- route guards, client validations, and worker logic that shadow central policy
- hand-written code that mirrors generated schemas or API contracts

**Method:**

- identify the authoritative contract and all importers/consumers
- search for equivalent predicates, literals, payload shapes, and helper calls
- refactor shadows to the source of truth or document intentional divergence

**Output:**

- drift candidates, confirmed divergence, and centralization/compatibility plan

## 44. Call Relocation And Side-Effect Timing [CONDITIONAL]

> Extends [phase 26](#26-call-site-and-execution-path-verification-core) to when a call runs, not just whether it does.

Check changes that move a correct call to a different point in control flow.

**Focus on:**

- ordering against validation, authorization, persistence, rendering, and cleanup
- once-per-operation vs once-per-item vs once-per-batch invocation count
- moved calls capturing an incorrect loop variable or stale outer value
- resource release, cache invalidation, event emission, transaction boundary, and notification timing

**Also verify:**

- tests distinguish old and new timing rather than only confirming final output
- moved side effects remain idempotent and correct on retries and errors

**Output:**

- before/after timeline, changed multiplicity/ordering, and regression test

## 45. Resource-Lifecycle Placement And Cadence [CONDITIONAL]

Check that cleanup, flushing, batching, checkpointing, and backpressure run at a
granularity that actually bounds the deepest accumulating operation.

**Focus on:**

- nested loops, streams, pagination, batch jobs, uploads, and long-lived sessions
- retained work per iteration multiplied by iterations between cleanup points
- checkpoint/release cadence relative to timeout, memory, rate, or storage limits
- mutation in place versus replacement when shared references depend on identity

**Also verify:**

- post-cleanup telemetry demonstrates bounded sawtooth behavior where applicable
- downstream consumers can safely reconstruct intentionally discarded transient data

**Output:**

- nesting-level map, cleanup cadence, peak resource evidence, and safe bound

## 46. Instrumentation And Non-Critical Side-Effect Resilience [CORE]

Ensure observability, analytics, diagnostics, and housekeeping do not corrupt
state or take down a primary operation when they fail.

**Focus on:**

- analytics, logging, metrics, tracing, screenshots, snapshots, and cleanup hooks
- partial mutation if a diagnostic batch fails halfway through
- missing isolation around non-critical work inside request, job, or render loops
- sensitive data leaks through instrumentation and error reporting

**Also verify:**

- failures are logged safely, rate-limited where needed, and do not hide primary failures
- genuinely critical audit/security events are explicitly classified as critical instead of silently fail-soft

**Output:**

- side-effect classification, failure behavior, partial-state risk, and containment plan

---

# Platform And Delivery Phases

The core taxonomy above applies broadly. The following phases close audit gaps
that are especially important in modern web and mobile applications. They are
separate so they cannot be dismissed as a small sub-bullet under integration or
data integrity.

## 47. Threat Modeling And Application/API Security [CONDITIONAL]

Perform a lightweight threat model before implementation review, then verify the
controls in code, configuration, and deployed behavior. This phase is required
for any application that accepts untrusted input, exposes a network endpoint,
or handles data that should not be public.

**Focus on:**

- assets, actors, trust boundaries, entry points, and privileged operations
- attack paths through browser, API, worker, storage, queue, admin tooling, and vendors
- input validation, injection prevention, output encoding, and unsafe deserialization
- XSS, CSRF, CORS, SSRF, open redirect, path traversal, file upload, and command execution
- API inventory, deprecated endpoints, undocumented routes, and unprotected debug surfaces
- security headers, transport security, cookie flags, CSP, origin policy, and cache policy
- security configuration drift between development, preview, staging, and production

**Also verify:**

- sensitive actions are enforced server-side, not only hidden or disabled in a client
- threat mitigations are tested with negative/adversarial cases, not only reviewed visually
- third-party integrations validate signatures, origins, redirects, and response shape
- security findings are mapped to an owner, severity, and remediation deadline

**Output:**

- threat model diagram, attack path, control owner, missing mitigation, and proof of fix

## 48. Identity, Authorization, Session, And Abuse Controls [CONDITIONAL]

Audit who can act, what they can act on, how long that authority lasts, and how
the system resists automation, replay, enumeration, and resource abuse.

**Focus on:**

- registration, login, logout, password reset, account recovery, linking, and account deletion
- session/token lifetime, rotation, revocation, storage, transport, and replay behavior
- authentication strength appropriate to risk, including MFA or step-up verification where needed
- object-level, property-level, function-level, role, tenant, and ownership authorization
- server-side ownership checks on every read, write, export, upload, and destructive action
- anonymous/guest behavior versus verified-account behavior and upgrade path
- rate limits, quotas, bot controls, idempotency, replay protection, and abuse monitoring
- enumeration of accounts/resources through timing, errors, pagination, IDs, or search

**Also verify:**

- authorization decisions are deny-by-default and do not depend on client-provided roles
- a user cannot access a peer's object by changing an identifier or request body field
- privilege changes, logout, password reset, and account linking invalidate old authority correctly
- abuse limits are enforced at the real public boundary and scale with the deployment topology

**Output:**

- identity flow, authorization matrix, abuse scenario, and negative-test evidence

## 49. Database, Storage, Migration, And Recovery [CONDITIONAL]

Audit the persistence layer as a first-class product and security boundary. Run
this phase for relational, document, key-value, object, cache, search, or
managed backend stores whenever they contain production state.

**Focus on:**

- schema constraints, foreign keys/references, ownership, uniqueness, and state invariants
- query correctness, parameterization, pagination, index use, N+1 patterns, and query limits
- transaction boundaries, isolation level, concurrent upserts, lost updates, and idempotent writes
- migrations: ordering, reversibility, backfill, lock duration, compatibility, and deploy sequence
- least-privilege roles, per-row and per-column access policies, separation of privileged backend credentials, and tenant separation
- encryption in transit and at rest, credential/secrets handling, connection exposure, and rotation
- backup schedule, restore testing, recovery point/recovery time objectives, and backup access controls
- data deletion, retention, export, archive, purge, cache invalidation, and orphan cleanup
- database logs, slow queries, capacity, connection pool exhaustion, and quota behavior

**Also verify:**

- client applications never receive a database-admin or other privileged backend credential
- direct client access is limited by authenticated, least-privilege policies and tested from another user
- production migrations are tested against realistic existing data, not just an empty database
- a restore exercise proves that the application can use restored data safely

**Output:**

- store inventory, data-owner/role matrix, migration plan, rollback/restore proof, and open risks

## 50. Privacy, Consent, And Data Lifecycle [CONDITIONAL]

Audit how personal and sensitive data is collected, understood, used, shared,
retained, and removed. This is an engineering audit and does not replace legal
advice or jurisdiction-specific compliance review.

**Focus on:**

- data inventory and classification, including identifiers, telemetry, content, location, and device data
- purpose limitation, data minimization, consent/notice, and user control appropriate to the product
- collection by analytics, advertising, crash reporting, support, session replay, and third-party SDKs
- access, correction, export, deletion, anonymization, and retention behavior where applicable
- privacy of logs, traces, screenshots, backups, test fixtures, exports, and support tools
- vendor/subprocessor data transfer, access, retention, breach notification, and contract assumptions
- child/age-sensitive flows, sensitive categories, and cross-border/region requirements where relevant

**Also verify:**

- privacy controls describe actual data flow, not only ideal product intent
- revoking consent stops the relevant future processing and has a defined historical-data policy
- production observability has redaction, access control, retention, and auditability
- developers can reproduce privacy behavior without using real personal data in local fixtures

**Output:**

- data-flow inventory, processing purpose, user control, retention rule, and unresolved privacy risk

## 51. Accessibility And Inclusive Interaction [CORE FOR USER INTERFACES]

Audit actual experience with keyboard, screen reader, zoom, reduced motion, and
assistive technologies. Automated scanners help, but do not establish conformance
on their own.

**Focus on:**

- semantic structure, headings, landmarks, labels, names, roles, values, and accessible descriptions
- full keyboard operation, logical focus order, visible focus, focus trap/return, and escape behavior
- screen-reader announcements for async updates, validation, errors, dialogs, status, and live content
- text alternatives, captions/transcripts, non-text controls, color independence, and contrast
- responsive text, zoom/reflow, orientation, target size, pointer/gesture alternatives, and touch access
- forms, errors, required fields, validation timing, timeout/cancellation, and recovery instructions
- reduced motion, flashing, autoplay audio/video, high contrast, and system preference behavior
- equivalent accessible alternatives for canvas, charts, maps, drag/drop, games, and custom widgets

**Also verify:**

- every supported responsive layout is tested, not only the widest desktop view
- manual checks include a real screen reader on at least one target platform for critical journeys
- target conformance level is explicit, commonly WCAG 2.2 AA unless the product requires another standard
- accessibility regressions are covered by semantic tests plus manual release checks

**Output:**

- journey, assistive technology/path tested, barrier, affected users, and verified correction

## 52. UX, Responsive Layout, Mobile Platform, And User Trust [CORE FOR USER INTERFACES]

Audit the product as a person experiences it across supported screens, inputs,
network conditions, and lifecycle events. A technically correct feature that is
hard to discover, impossible to recover from, or misleading is a product defect.

**Focus on:**

- first-use onboarding, feature discovery, terminology, empty state, loading state, and next action
- hierarchy, readability, visual stability, touch target size, accidental tap risk, and feedback timing
- responsive layouts across small phones, large phones, tablets, desktop, split view, and rotation
- safe areas, virtual keyboard, browser chrome, dynamic viewport, zoom, text scaling, and localization expansion
- back/forward, close, cancel, undo, destructive confirmation, persistence of drafts, and recovery from interruption
- offline, slow/flaky network, reconnect, background/foreground, sleep/lock, app switch, and resumed work
- browser/platform support, permission denial, install/update, share, deep link, and notification behavior
- honest status, progress, error, price, ranking, and submission feedback; no fake success or fake competition

**Also verify:**

- test devices represent the lowest practical hardware and viewport tier, not only a developer desktop
- interaction patterns follow platform conventions where the application targets a native/mobile platform
- visual acceptance checks compare key flows at every supported breakpoint
- core user tasks can be completed without hover, precision pointer, or a specific device posture

**Output:**

- journey map, device/layout matrix, usability failure, user impact, and acceptance evidence

## 53. Observability, Reliability, Incident Readiness, And SLOs [CONDITIONAL]

Audit whether a production problem can be detected, understood, contained, and
recovered before users experience prolonged harm.

**Focus on:**

- service-level indicators for availability, latency, errors, throughput, durability, and correctness
- measurable objectives, error budgets, client-side and server-side signals, and meaningful alert thresholds
- structured logs, traces, metrics, correlation IDs, dashboards, health checks, and synthetic critical journeys
- distinction between user-visible failure, expected rejection, retry, dependency outage, and internal defect
- alert ownership, escalation, rate limiting, noise control, runbooks, and on-call/release responsibility
- dependency inventory, graceful degradation, circuit breaking, feature kill switch, and fallback behavior
- incident timeline, communication, rollback, data repair, post-incident action, and verification of closure

**Also verify:**

- monitoring measures user-relevant behavior rather than only server resource averages
- telemetry does not leak secrets or personal data and remains available during partial outages
- critical flows have a tested manual recovery/rollback procedure
- reliability targets are explicit enough to influence release decisions

**Output:**

- SLI/SLO inventory, alert/runbook gap, incident scenario, and recovery evidence

## 54. Delivery, Deployment, Infrastructure, And Supply-Chain Integrity [CORE FOR RELEASES]

Audit the path from source change to running production artifact, including
configuration, permissions, migrations, rollback, and dependency provenance.

**Focus on:**

- source branch, review, CI gates, test evidence, artifact identity, and environment promotion path
- dependency lockfiles, update policy, vulnerability response, build scripts, generated artifacts, and provenance
- secrets scanning, credential rotation, least-privilege CI/deploy access, and protected production environments
- infrastructure/configuration as code, drift, domain/DNS/TLS, headers, storage, queues, and serverless permissions
- feature flags, staged rollout, canary, kill switch, backward compatibility, and rollback criteria
- migration coordination, deploy ordering, zero-downtime assumptions, cache invalidation, and post-deploy verification
- backup/restore readiness, disaster recovery ownership, incident communication, and release audit trail

**Also verify:**

- the deployed artifact is demonstrably the reviewed artifact, not a mutable rebuild with different dependencies
- production environment variables and third-party credentials are complete, scoped, and never exposed to the client
- rollback has been tested or deliberately redesigned when data changes make a simple rollback unsafe
- release gates use current evidence from performance, security, accessibility, and reliability phases

**Output:**

- release checklist, artifact/environment traceability, rollback plan, and remaining deployment risks

## Research Basis

Phases 47-54 are grounded in stable, primary guidance rather than a single
product-specific checklist:

- [OWASP Application Security Verification Standard 5.0](https://owasp.org/www-project-application-security-verification-standard/) for application security verification requirements.
- [OWASP API Security Top 10](https://owasp.org/API-Security/editions/2023/en/0x10-api-security-risks/) for object authorization, authentication, resource consumption, inventory, and unsafe API consumption risks.
- [OWASP Database Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html) for transport protection, least privilege, credential protection, hardening, and backups.
- [NIST Privacy Framework](https://www.nist.gov/privacy-framework) for privacy risk management across identification, governance, control, communication, and protection.
- [WCAG 2.2](https://www.w3.org/TR/wcag/) for current web accessibility conformance, full-page conformance scope, and reflow/responsive requirements.
- [Android Core App Quality Guidelines](https://developer.android.com/docs/quality-guidelines/archive/core/core-app-quality-2026-03-20) for adaptive layouts, lifecycle, navigation, touch targets, contrast, and platform quality.
- [Google SRE Service Level Objectives](https://sre.google/sre-book/service-level-objectives/) for user-centered indicators, objectives, and error budgets.
- [NIST Secure Software Development Framework](https://csrc.nist.gov/pubs/sp/800/218/final) for embedding secure development practices into the software lifecycle.

---

# Audit Completion Standard

An audit is complete only when it records:

- scope and tier
- evidence sources the audit had, and which it lacked
- overlay invariants checked and the evidence for each, or an explicit
  statement that no overlay applies
- phases run, phases skipped, phases PARTIAL, and the reason for every skip and
  every PARTIAL
- commands/tests/measurements run and their results
- confirmed findings, fixed findings, accepted risks, and deferred work
- verification evidence for every fix
- production/release prerequisites where relevant
- residual risks that require manual, device, security, accessibility, or production validation

# Protocol Maintenance

This protocol combines a broad engineering taxonomy with a researched
web/mobile application expansion. Treat it as a living document, reviewed
after real audits: add a new phase only when an important failure class lacks
an existing home; add a new recurring failure pattern, invariant, parity pair,
or conditional phase when an audit reveals one; and add new examples or
runbook commands only when they are technology-appropriate and
evidence-based. Do not turn a historical incident into forgotten tribal
knowledge.
