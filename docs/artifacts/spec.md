# Spec

The central artifact of the pipeline. Produced by Inscribe, consumed by every downstream stage. It is the source of truth for what must be built and the traceability anchor for all tests, tasks, and implementation.

The spec is a **directory** (`spec/`) of `.feature` files — one per concern or module. Each `.feature` file contains a single `Feature` block scoped to that concern.

```
.haileris/features/{feature_id}/spec/
├── {concern_1}.feature
├── {concern_2}.feature
└── ...
```

## Format

Standard Gherkin feature files (`.feature`), as used by [behave](https://github.com/behave/behave). No YAML frontmatter. Plain Gherkin only.

Each `.feature` file contains one `Feature` block scoped to a single concern or module:

```gherkin
@status:approved @type:greenfield
Feature: {concern_name}
  {plain-English description of what this concern delivers}
  Modules: path/to/module.py (role), path/to/other.py (role)

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

Feature-level tags (`@status:...`, `@type:...`) live on **every file's** `Feature` keyword. `Background` is per-file — each `.feature` file defines its own if needed; no shared Background across files.

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
| `@tag` | Metadata — used for BIDs, status, and type (see below) |
| `#` | Comment |
| `"""` | Docstring (multi-line step argument) |
| `\|` | Data table delimiter |

## BID Format

`BID-{NNN}` — sequentially numbered from `001`. Every Scenario carries exactly one BID as a tag (`@BID-001`). BIDs are the unit of traceability: every task, test, and source symbol in the pipeline is traced back to a BID.

## Pipeline Metadata

Carried as Feature-level tags and the Feature description block — no separate metadata file.

| Metadata | How it appears |
|----------|---------------|
| Status | `@status:inscribing`, `@status:ascertaining`, `@status:approved` |
| Type | `@type:greenfield`, `@type:modification`, `@type:refactor` |
| Modules | Free text in the Feature description block |

## Status Lifecycle

`@status:inscribing` → `@status:ascertaining` (if NEEDS ASCERTAINMENT markers exist) → `@status:approved` (after user gate at Inscribe)

## Lifecycle

Stable after user approval. Must not be modified by any downstream stage except through the Settle spec auto-resolve mechanism (domain: spec findings). If the spec must change, it changes through Ascertain → Inscribe with that change as the goal.

## Path

- Directory: `.haileris/features/{feature_id}/spec/`
- Individual files: `.haileris/features/{feature_id}/spec/{concern}.feature`

## Committed

Yes. The approved spec is committed as part of the feature's artifact set.
