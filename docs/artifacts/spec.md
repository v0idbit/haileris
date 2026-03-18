# Spec

The central artifact of the pipeline. Produced by Inscribe, consumed by every downstream stage. It is the source of truth for what must be built and the traceability anchor for all tests, tasks, and implementation.

The spec is a set of `.feature` files written directly to the repo's test tree (`tests/features/`). It contains a **primary spec** and one or more **subspecs**. The primary spec defines end-to-end workflow scenarios (integration-level contract). The subspecs define per-deliverable behavioral scenarios (unit-level contracts). Their union, when composed, must cover all primary spec behaviors.

```
tests/features/
├── primary.feature          # integration-level workflow scenarios
├── {deliverable_1}.feature   # unit-level behavioral contract
├── {deliverable_2}.feature
└── steps/                   # step definitions (language-specific)
```

Feature files are source artifacts — permanent repo fixtures committed alongside unit tests. Pipeline metadata (etch-map, inspections, pipeline-state) stays in `.haileris/features/{feature_id}/`.

## Two-Level Hierarchy

| Level | File | Contains | Role |
|-------|------|----------|------|
| Primary | `primary.feature` | End-to-end workflow scenarios | Integration-level contract |
| Subspec | `{deliverable}.feature` | Per-deliverable behavioral scenarios | Unit-level contracts |

The primary spec is written first. Its scenarios define the observable end-to-end behavior of the feature and force BIDs for effects that cross deliverable boundaries. Subspecs are decompositions of the primary spec — each owns one deliverable's behavioral contract. A deliverable is a set of BIDs that share a delivery boundary — they can be implemented and verified as a unit, independent of other subspecs. The breaking points between deliverables are where one subspec's output becomes another's input. ANLZ-004 validates that subspecs compose back into the primary spec with no gaps.

## Format

Standard Gherkin feature files (`.feature`). Plain Gherkin only.

### Primary Spec (`primary.feature`)

```gherkin
@status:approved @type:greenfield
Feature: {feature_name} — Primary Spec
  End-to-end workflow scenarios for the feature.

  @BID-060 @traces:BID-003,BID-015,BID-024
  Scenario: {end-to-end workflow description}
    Given {full system precondition}
    When {user-facing action}
    Then {observable end-to-end outcome}

  @BID-061 @traces:BID-007,BID-031
  Scenario: {another workflow}
    Given {precondition}
    When {action}
    Then {outcome}
```

Each primary scenario has a BID and a `@traces` tag listing the subspec BIDs it traces through. The `@traces` tag makes composition explicit and auditable.

### Subspecs (`{deliverable}.feature`)

```gherkin
@status:approved @type:greenfield
Feature: {deliverable_name}
  {plain-English description of what this deliverable covers}
  Domains: path/to/domain (role), path/to/other (role)

  Background:
    Given {shared precondition for all scenarios in this file}

  @BID-001
  Scenario: {behavior description}
    Given {initial state}
    When {action}
    Then {expected outcome}
    And {additional outcome}

  @BID-002
  Scenario Outline: {parameterized behavior description}
    Given {initial state with <param>}
    When {action with <param>}
    Then {expected outcome with <result>}

    Examples:
      | param | result |
      | foo   | bar    |
      | baz   | qux    |
```

Feature-level tags (`@status:...`, `@type:...`) live on **every file's** `Feature` keyword. `Background` is per-file — each `.feature` file defines its own if needed; each file's Background is self-contained.

## `@traces` Tag

Format: `@traces:BID-003,BID-015,BID-024` — a comma-separated list of subspec BIDs that the primary scenario traces through.

Each primary spec scenario must have a `@traces` tag. ANLZ-004 validates:
- Every primary BID has a `@traces` tag
- All referenced BIDs exist in subspecs
- The referenced BIDs collectively cover every effect in the scenario's steps

## Keywords

| Keyword | Role |
|---------|------|
| `Feature` | Top-level container; name and free-text description go here |
| `Background` | Steps run before every Scenario in the file |
| `Scenario` | One behavior (one BID) |
| `Scenario Outline` | Parameterized behavior; paired with an `Examples` table |
| `Given` | Establishes initial system state |
| `When` | Describes the action under test |
| `Then` | Asserts the expected outcome |
| `And` / `But` | Continuation of any step type |
| `@tag` | Metadata — used for BIDs, status, type, and traces (see below) |
| `#` | Comment |
| `"""` | Docstring (multi-line step argument) |
| `\|` | Data table delimiter |

## BID Format

`BID-{NNN}` — sequentially numbered from `001`. Every Scenario carries exactly one BID as a tag (`@BID-001`). BIDs are the unit of traceability: every task, test, and derivation in the pipeline is traced back to a BID.

## Pipeline Metadata

Carried as Feature-level tags and the Feature description block — no separate metadata file.

| Metadata | How it appears |
|----------|---------------|
| Status | `@status:inscribing`, `@status:ascertaining`, `@status:approved` |
| Type | `@type:greenfield`, `@type:modification`, `@type:refactor` |
| Domains | Required on subspecs. `Domains:` line in the Feature description block. Format: `path/to/domain (role)`, comma-separated. Declares which domains the deliverable's BIDs will touch. Serves as the shared import contract between Etch (derives test import paths) and Realize (creates source at these paths). Validated mechanically by ANLZ-003. |

## Status Lifecycle

`@status:inscribing` → `@status:ascertaining` (if NEEDS ASCERTAINMENT markers exist) → `@status:approved` (after user gate at Inscribe)

## Lifecycle

Stable after user approval. Read-only for all downstream stages except the Settle spec auto-resolve mechanism (domain: spec findings). Spec changes go through Ascertain → Inscribe.

## Path

- Directory: `tests/features/`
- Primary spec: `tests/features/primary.feature`
- Subspecs: `tests/features/{deliverable}.feature`

## Committed

Yes. The approved spec is committed as part of the repo's test tree.
