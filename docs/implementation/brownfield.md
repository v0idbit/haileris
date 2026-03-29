# Brownfield Implementation Guide

Audit-and-fix workflow for an existing HAILERIS implementation. Use this when an implementation exists but produces incorrect results, deadlocks, or violates stage boundaries.

The [correctness criteria](criteria/) define what each stage must satisfy. The [greenfield guide](greenfield.md) defines what components must exist. This guide tells you how to find what's broken and in what order to fix it.

## Audit methodology

### 1. Audit cross-cutting foundations first

Upstream problems cascade. A broken state machine or missing metadata parser affects every stage. Check the foundations described in [greenfield.md § Cross-cutting foundations](greenfield.md#cross-cutting-foundations) before auditing any stage:

| Foundation | What to check | Common failure |
|------------|---------------|----------------|
| Pipeline state machine | Does it implement all operations from [pipeline-state.md](../automation/pipeline-state.md)? Do transitions match the invariants? | Missing Loop or Scoped Loop operation; invalid transitions accepted; `_integration` not reset when subspecs reset |
| Pipeline config | Does it read `config.{ext}` and apply defaults when absent? | Hardcoded retry limits instead of reading config; absent file treated as error instead of defaults |
| Inspection report schema | Do all four inspections produce the [shared schema](../artifacts/inspection-reports.md)? | Inconsistent formats across inspections; missing `findings` aggregation; SKIP status treated as FAIL |
| BID pattern | Does the extractor match `@BID-\d+` and strip the `@`? | Regex mismatch; BIDs extracted from comments or prose instead of tags only |
| Gherkin metadata parser | Does it extract `Domains:`, `Requires:`, `Provides:`, `@traces:` from `.feature` files? | Parser fails on multi-value `Requires:` lines; field hints not extracted from parentheticals |
| Artifact paths | Do all stages write to the correct base paths? | Feature artifacts written to `.haileris/project/` instead of `.haileris/features/{id}/`; spec files written to `.haileris/` instead of `tests/features/` |

### 2. Audit stages in pipeline order

Work from Harvest forward. A stage that produces incorrect output makes every downstream stage suspect. For each stage:

1. **Check component existence** — does the implementation have all components listed in the stage's [greenfield construction file](greenfield.md#stages)?
2. **Check artifact correctness** — run the stage on a known input and verify outputs against the stage's [correctness criteria](criteria/) exit checks
3. **Check boundary discipline** — verify the stage reads only its declared inputs and writes only to its declared paths (the criteria files list exact read/write scope)

Stop at the first stage that fails. Fix it before auditing downstream stages — downstream failures may be symptoms of the upstream problem.

### 3. Audit mechanical checks

For each stage, verify that every referenced automation spec is implemented and produces correct results. Run each check against a known input and compare output to the expected behavior defined in the [automation specs](../automation/README.md).

Priority order for mechanical checks:
1. **Tier 1 (fully mechanical)** — deterministic algorithms; incorrect results here indicate a bug in the implementation
2. **Tier 2 (constraint-gated)** — verify the constraint check works (emits SKIP when the constraint is not met, runs the algorithm when it is)
3. **Tier 3 (judgment-verified)** — verify the mechanical verification layer catches errors in the judgment-dependent output

## Triage: where to start

When multiple stages are broken, use this decision tree:

**Does the state machine work?** (Initialize, Advance, Loop, Resume produce correct state)
- No → fix the state machine first. Nothing else works without it.

**Does Harvest produce valid artifacts?** (decomposition.md, technical-details.md, harvest-inspection.yaml all exist with correct structure)
- No → fix Harvest. Everything downstream reads its output.

**Does Layout deadlock or produce incorrect subspecs?**
- Deadlocks at `@traces` → the `@traces` deriver is looking for downstream artifacts (tests, source) that are produced by Etch. Fix: `@traces` derivation uses only the primary spec and the subspecs Layout just created. See [construction/layout.md § `@traces` deriver](construction/layout.md#2-traces-deriver-layoutdecompose).
- Subspecs missing `Requires:`/`Provides:` metadata → fix the subspec decomposer
- ANLZ-005/006 not running → fix the verification components

**Do Etch/Realize execute in the wrong order or skip subspecs?**
- Fix the subspec execution controller. It must enforce dependency edges from `delivery-order.yaml` and track per-subspec status.

**Does Settle loop infinitely or fail to route correctly?**
- Check the loop controller against `settle_loops` config. Verify domain-based routing (impl → Realize, test → Etch, spec → Ascertain).

## Fix strategy

**Patch vs. rebuild:** When a component exists but produces wrong output, patch it. When a component is missing or fundamentally misstructured, rebuild it using the [greenfield construction file](greenfield.md#stages) for that stage. The greenfield guide describes what each component takes as input, what it produces, and what spec to implement.

**Verify after each fix:** After fixing a stage, re-run its [correctness criteria](criteria/) exit checks before moving to the next stage. Downstream stages may now work without changes.

**Boundary violations are structural:** When a stage reads or writes artifacts outside its declared scope, the fix is architectural — not a parameter tweak. The criteria files list exact read/write scope per stage.

## Reference

| Resource | Purpose |
|----------|---------|
| [Greenfield guide](greenfield.md) | What components to build per stage |
| [Correctness criteria](criteria/) | What correct looks like per stage (exit checks) |
| [Automation specs](../automation/README.md) | Behavioral specifications for all mechanical checks |
| [Pipeline state machine](../automation/pipeline-state.md) | State schema, operations, invariants, edge cases |
| [Inspection report schema](../artifacts/inspection-reports.md) | Shared output format for all inspections |
