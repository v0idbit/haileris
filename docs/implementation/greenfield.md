# Greenfield Implementation Guide

Construction specifications for building a HAILERIS pipeline implementation from scratch. Each stage file describes the components to implement, the mechanical checks to build, and the orchestration logic to wire up. The guide is form-agnostic — it constrains behavior, not architecture.

## What a HAILERIS implementation is

A HAILERIS implementation has three layers:

| Layer | What it does | Examples |
|-------|-------------|---------|
| **Agent logic** | Stage-specific reasoning: exploring codebases, writing specs, generating tests, fixing failures | Decomposition synthesis, primary spec authoring, stub generation, test generation, domain-specific fixing |
| **Mechanical verification** | Deterministic checks with specified algorithms | ANLZ-001 through ANLZ-007, TEST-001, four inspection reports, traceability gate, RED diagnostics, mutation testing, second-reader test |
| **Orchestration** | State machine, retry loops, user gates, subspec execution, file I/O | Pipeline state transitions, `settle_loops` enforcement, dependency-edge scheduling, approval workflows |

The [automation specifications](../automation/README.md) provide behavioral specs (Gherkin scenarios) for every mechanical check. Each check is classified by tier — see [tier definitions](../automation/README.md#tier-1-fully-mechanical-m).

## Cross-cutting foundations

Build these before any stage-specific logic. They are consumed by multiple stages.

### Pipeline state machine

Manages 8-stage progression with loop-back from Settle. Implement the operations defined in [pipeline-state.md](../automation/pipeline-state.md): Initialize, Advance, Loop, Resume, Subspec Initialize, Subspec Advance, Scoped Loop. The state schema, invariants, and edge cases are fully specified there.

State file: `.haileris/features/{feature_id}/pipeline-state.yaml`

### Pipeline config

Read `.haileris/project/config.{ext}` ([config spec](../artifacts/config.md)). Five settings:

| Setting | Default | Consumed by |
|---------|---------|-------------|
| `realize_retries` | 0 | Realize |
| `settle_loops` | 0 | Settle |
| `etch_corrections` | 0 | Etch |
| `inspection_fixes` | 0 | Layout, Etch (inspections with `--fix`) |
| `auto_resolve_spec` | false | Settle |

When the config file is absent, all settings use defaults. Format (JSON, YAML, TOML, etc.) is an implementation choice.

### Inspection report schema

All four inspection reports share the `InspectionResult` schema defined in [inspection-reports.md](../artifacts/inspection-reports.md): timestamp, pass boolean, ordered checks array, flat findings list. Each `Finding` carries `bid`, `check_type`, and `detail`. Implement a shared report writer/reader.

### BID pattern

Canonical format: `BID-\d+`. Extracted from Gherkin `@BID-NNN` tags (strip the `@` prefix). Implement a shared BID extractor that parses Gherkin files and returns BID sets.

### Gherkin metadata parsing

`Domains:`, `Requires:`, `Provides:`, and `@traces:` are HAILERIS conventions, not standard Gherkin. They appear as comments or tags in `.feature` files. Implement a metadata parser that extracts these declarations from subspec files. The [spec artifact doc](../artifacts/spec.md) defines the format.

### Artifact path conventions

Three base paths, all relative to project root:

| Base | Purpose |
|------|---------|
| `.haileris/features/{feature_id}/` | Feature-scoped pipeline artifacts (maps, inspections, state, delivery order) |
| `.haileris/project/` | Project-wide artifacts (standards, test-conventions, constitution, config) |
| `tests/features/{feature_id}/` | Gherkin spec files (primary + subspecs) — repo source, not pipeline intermediates |

Plus repo source paths: `src/` (source stubs → implementations), `tests/unit/`, `tests/integration/`.

## Construction order

Build stages in pipeline order (Harvest → Settle). Earlier stages are simpler and establish patterns reused by later stages. Each stage file is self-contained — it lists the components to implement and references the detailed specs for each.

## Stages

| # | Stage | Construction file | Correctness criteria |
|---|-------|-------------------|----------------------|
| 1 | Harvest | [construction/harvest.md](construction/harvest.md) | [criteria/harvest.md](criteria/harvest.md) |
| 2 | Ascertain | [construction/ascertain.md](construction/ascertain.md) | [criteria/ascertain.md](criteria/ascertain.md) |
| 3 | Inscribe | [construction/inscribe.md](construction/inscribe.md) | [criteria/inscribe.md](criteria/inscribe.md) |
| 4 | Layout | [construction/layout.md](construction/layout.md) | [criteria/layout.md](criteria/layout.md) |
| 5 | Etch | [construction/etch.md](construction/etch.md) | [criteria/etch.md](criteria/etch.md) |
| 6 | Realize | [construction/realize.md](construction/realize.md) | [criteria/realize.md](criteria/realize.md) |
| 7 | Inspect | [construction/inspect.md](construction/inspect.md) | [criteria/inspect.md](criteria/inspect.md) |
| 8 | Settle | [construction/settle.md](construction/settle.md) | [criteria/settle.md](criteria/settle.md) |

## Stage ownership boundaries

Each stage's implementation is responsible for specific artifact paths:

- **Harvest**: `.haileris/features/{feature_id}/` (decomposition, technical details, harvest-inspection, pipeline-state) + `.haileris/project/` (standards, test-conventions)
- **Ascertain**: `.haileris/features/{feature_id}/` (ascertainments, decomposition update)
- **Inscribe**: `tests/features/{feature_id}/primary.feature`
- **Layout**: `tests/features/{feature_id}/` (subspecs, `@traces`) + `.haileris/features/{feature_id}/` (delivery-order, layout-inspection)
- **Etch**: `tests/unit/`, `tests/integration/`, `src/` at `Domains:` paths + `.haileris/features/{feature_id}/` (etch-map, etch-inspection)
- **Realize**: `src/` (within stubs) + `.haileris/features/{feature_id}/` (realize-map, realize-inspection)
- **Inspect**: `.haileris/features/{feature_id}/verify_{timestamp}.md`
- **Settle**: Modifies `src/`, `tests/`, `tests/features/`, and pipeline metadata based on finding domain

## Subspec execution model (Etch/Realize)

Etch and Realize execute **per subspec**, respecting dependency edges in `delivery-order.yaml`. The correctness requirement: a subspec's Etch/Realize cycle runs only after all subspecs it `Requires:` have completed Realize. Independent subspecs may run concurrently; sequential execution is a valid default strategy.

After all subspec cycles complete, a final Etch pass writes integration tests for primary BIDs before Inspect runs. Implement a subspec execution controller that enforces these dependency constraints and tracks per-subspec status in `pipeline-state.yaml`.
