# Spec

The central artifact of the pipeline. The primary spec is produced by Inscribe; subspecs are decomposed from the primary spec by Layout. Consumed by every downstream stage. It is the source of truth for what must be built and the traceability anchor for all subspecs, tests, and implementation.

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

The primary spec is written by Inscribe. Its scenarios define the observable end-to-end behavior of the feature and force BIDs for effects that cross deliverable boundaries. Subspecs are decomposed from the primary spec by Layout — each owns one deliverable's behavioral contract. Layout distributes every primary BID to exactly one subspec; after Layout, the same BID set appears in both `primary.feature` and the union of all subspecs. A deliverable is a set of BIDs that share a delivery boundary — they can be implemented and verified as a unit, independent of other subspecs. The breaking points between deliverables are where one subspec's output becomes another's input. ANLZ-004 validates at Layout.Verify that subspecs compose back into the primary spec with no gaps. Subspecs declare explicit interface contracts via `Requires:` and `Provides:` metadata. These make inter-subspec data dependencies explicit and enable subspec-scoped re-runs when failures occur.

## Format

Standard Gherkin feature files (`.feature`). Plain Gherkin only.

### Primary Spec (`primary.feature`)

```gherkin
@status:approved @type:greenfield
Feature: {feature_name} — Primary Spec
  End-to-end workflow scenarios for the feature.

  @BID-001
  Scenario: {behavior A}
    Given {initial state}
    When {action}
    Then {expected outcome}

  @BID-002
  Scenario: {behavior B}
    Given {initial state}
    When {action}
    Then {expected outcome}

  @BID-005 @traces:BID-001,BID-003,BID-004
  Scenario: {end-to-end workflow description}
    Given {full system precondition}
    When {user-facing action}
    Then {observable end-to-end outcome}

  @BID-006 @traces:BID-002,BID-004
  Scenario: {another workflow}
    Given {precondition}
    When {action}
    Then {outcome}
```

Every primary scenario has a BID. Scenarios with `@traces` tags are integration-level — they define end-to-end workflows composed from other BIDs. Layout adds `@traces` tags after distributing all BIDs to subspecs. Every BID in `primary.feature` also appears in exactly one subspec (verified by the layout inspection's MISSING and DUPLICATED checks).

### Subspecs (`{deliverable}.feature`)

```gherkin
@status:approved @type:greenfield
Feature: {deliverable_name}
  {plain-English description of what this deliverable covers}
  Domains: path/to/domain (role), path/to/other (role)
  Requires: {upstream}.feature -> {ContractName} (field1, field2 — description)
  Provides: {ContractName} (field1, field2, field3 — description)

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

## Interface Contract Metadata

Subspecs declare inter-subspec data dependencies via `Requires:` and `Provides:` lines in the Feature description block.

| Field | Requirement | Format |
|-------|------------|--------|
| `Requires:` | Optional on subspecs | `{file}.feature -> {ContractName} (field1, field2 — description)`, comma-separated |
| `Provides:` | Required on subspecs | `{ContractName} (field1, field2 — description)`, comma-separated |

The arrow syntax (`->`) connects the source subspec file to the contract name it provides. Multiple entries are comma-separated on a single line.

**Field hint format:** The parenthetical after each `ContractName` contains comma-separated field hint identifiers before an em dash (`—` or ASCII `---`), followed by a prose description. Field hints are language-agnostic identifiers naming the data fields the contract carries — not language-specific types. At least one field hint is required per `Provides:` entry (ANLZ-006). `Requires:` field hints, when present, must be a subset of the corresponding `Provides:` fields (ANLZ-006). A `Requires:` entry with no field hints (description only) is valid — it consumes the full contract without narrowing.

Every `ContractName` appearing in a `Requires:` must be satisfied by a matching `Provides:` in some subspec. ANLZ-005 validates this at Layout.Verify. ANLZ-006 validates field hint completeness. A subspec with no `Requires:` is a dependency root. `Requires:` implies the dependency edge — there is no separate `Depends-on:` mechanism.

See also the [Pipeline Metadata](#pipeline-metadata) table for a summary of all feature-level metadata fields.

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

`BID-{NNN}` — sequentially numbered from `001`. Every Scenario carries exactly one BID as a tag (`@BID-001`). BIDs are the unit of traceability: every subspec, test, and derivation in the pipeline is traced back to a BID.

## Pipeline Metadata

Carried as Feature-level tags and the Feature description block — no separate metadata file.

| Metadata | How it appears |
|----------|---------------|
| Status | `@status:inscribing`, `@status:ascertaining`, `@status:approved` |
| Type | `@type:greenfield`, `@type:modification`, `@type:refactor` |
| Domains | Required on subspecs. `Domains:` line in the Feature description block. Format: `path/to/domain (role)`, comma-separated. Declares which domains the deliverable's BIDs will touch. Serves as the shared import contract between Etch (derives test import paths) and Realize (creates source at these paths). Validated mechanically by ANLZ-003. |
| Requires | Optional on subspecs. `Requires:` line in Feature description block. Format: `{file}.feature -> {ContractName} (field1, field2 — description)`, comma-separated. Declares what this subspec needs from upstream subspecs. Implies a dependency edge. A subspec with no `Requires:` is a dependency root. Validated by ANLZ-005 (contract name consistency) and ANLZ-006 (field hint subset). |
| Provides | Required on subspecs. `Provides:` line in Feature description block. Format: `{ContractName} (field1, field2 — description)`, comma-separated. Declares what this subspec makes available to downstream subspecs. At least one field hint required. Validated by ANLZ-005 (contract name consistency) and ANLZ-006 (field hint completeness). |

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
