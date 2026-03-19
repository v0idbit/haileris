# Automation Specifications

Precise, language-agnostic behavioral specifications for the pipeline's mechanical operations. Each spec defines inputs, behavioral specifications, outputs, and edge cases with enough precision that any implementation — in any language — produces identical results on identical inputs.

## Tier 1: Fully Mechanical (M)

High frequency, high error cost, low implementation difficulty. All operations classified **M** (fully mechanical). Source: [investment map](../../.notes/mechanical/investment-map.md) items 1–5.

| Spec | Operations | Source |
|------|-----------|--------|
| [Harvest Inspection](harvest-inspection.md) | 3 active checks + 1 SKIP | [harvest.md](../stages/harvest.md) |
| [Layout Inspection](layout-inspection.md) | 4 active checks + 1 SKIP | [layout.md](../stages/layout.md) |
| [Etch Inspection](etch-inspection.md) | 3 active checks + 2 SKIP | [etch.md](../stages/etch.md) |
| [Realize Inspection](realize-inspection.md) | 2 active checks + 1 SKIP | [realize.md](../stages/realize.md) |
| [Traceability Gate](traceability-gate.md) | 5 checks | [inspect.md](../stages/inspect.md) |
| [ANLZ-003](anlz-003.md) | 1 check (5-step algorithm) | [inscribe.md](../stages/inscribe.md) |
| [TEST-001](test-001.md) | 1 check | [etch.md](../stages/etch.md) |
| [Pipeline State](pipeline-state.md) | State machine + 5 operations | [pipeline-state.md](../artifacts/pipeline-state.md), [Pipeline.md](../Pipeline.md) |

## Tier 2: Mechanical with Constraints (M-c)

Medium ROI operations that become fully mechanical under a stated constraint. Each spec documents the constraint boundary: what condition must hold for the algorithm to apply, and what happens outside that condition (SKIP or graceful degradation). Source: [investment map](../../.notes/mechanical/investment-map.md) items 6–10.

| Spec | Operation | Constraint | Source |
|------|-----------|-----------|--------|
| [ANLZ-002](anlz-002.md) | Standards compliance | `standards.md` uses structured rule format | [inscribe.md](../stages/inscribe.md) |
| [Realize Scope](realize-scope.md) | AST-based derivation discovery + scope creep | AST tooling available for target language | [realize.md](../stages/realize.md) |
| [RED Diagnostics](red-diagnostics.md) | Default-value + tautological assertion detection | Per-language default value tables; AAA structure | [etch.md](../stages/etch.md) |
| [Mutation Testing](mutation-testing.md) | BID-targeted mutation generation and kill rate | Standard mutation operators + realize-map traceability | [inspect.md](../stages/inspect.md) |

## Conventions

Each spec uses Gherkin (Feature/Rule/Scenario) to define observable behaviors. Scenarios describe what the check does, not how.

### Output Format

All inspection checks produce results conforming to the schema in [audit-reports.md](../artifacts/audit-reports.md):

```
InspectionResult:
  timestamp    — ISO 8601 UTC
  pass         — boolean
  checks       — ordered list of CheckResult
  findings     — flat list of all Finding objects (aggregated from checks)

CheckResult:
  name         — check identifier (e.g., "MISSING", "Completeness")
  status       — PASS | FAIL | SKIP
  detail       — human-readable summary
  findings     — list of Finding for this check

Finding:
  bid          — BID identifier or "N/A" for non-BID findings
  check_type   — same as parent CheckResult name
  detail       — human-readable description of the specific issue
```

### Exit Semantics

When run as a CLI tool:

| Exit code | Meaning |
|-----------|---------|
| 0 | PASS — all active checks passed |
| 1 | FAIL — one or more checks failed |
| 2 | Error — invalid input, missing files, or internal error |

### Deferred Checks

Checks classified J-v that require judgment are marked SKIP. A SKIP check always produces `status: SKIP` with an explanatory detail string and zero findings. SKIP does not affect the overall pass/fail result.

### M-c Constraint Convention

Tier 2 specs include a **Constraint** section documenting the condition under which the algorithm is fully mechanical. When the constraint is not met, the check emits SKIP with a detail string explaining why mechanical checking is unavailable. This is distinct from Tier 1 deferred checks: M-c checks *have* an algorithm but require a precondition; deferred checks have no algorithm yet.

### Path Conventions

All paths in these specs use forward slashes and are relative to the project root unless stated otherwise. The two standard base paths:

- **Feature directory**: `.haileris/features/{feature_id}/`
- **Project directory**: `.haileris/project/`
- **Spec directory**: `tests/features/`

### BID Pattern

The canonical BID format is `BID-{NNN}` where `{NNN}` is one or more digits. The regex `BID-\d+` matches all valid BIDs. When extracting BIDs from Gherkin files, match on the tag form `@BID-\d+` and strip the `@` prefix.

## What These Specs Do Not Cover

| Deferred item | Reason | Spec produces |
|---------------|--------|---------------|
| Layout PARTIAL | J-v — requires semantic coverage analysis | SKIP |
| Etch PARTIAL | J-v — requires semantic coverage analysis | SKIP |
| Etch DUPLICATED | J-v — requires test similarity analysis | SKIP |
| Harvest dependency coverage | M-c — requires package resolution | SKIP |
| TEST-002 (RED state) | Language-specific test runner | Out of scope |
| Etch RED import detection | Language-specific import resolution | Out of scope |

Items previously listed here that now have Tier 2 specs: Realize Scope (see [realize-scope.md](realize-scope.md)).
