# Harvest — Greenfield Construction

## Stage inputs

- Repository working tree (empty or minimal for greenfield)
- User-provided feature details (description, acceptance criteria, related context, tech details)
- Optionally: constitution at `.haileris/project/constitution.md`

## Stage outputs

| Artifact | Path |
|----------|------|
| Decomposition | `.haileris/features/{feature_id}/decomposition.md` |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` |
| Harvest inspection | `.haileris/features/{feature_id}/harvest-inspection.yaml` |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` |
| Project standards | `.haileris/project/standards.md` |
| Project test conventions | `.haileris/project/test-conventions.md` |
| Harvest metadata | `.haileris/project/last-harvest.json` |

## Components to implement

### 1. Project artifact pre-check

Implement a check that scans `.haileris/project/` for `standards.md`, `test-conventions.md`, `constitution.md`, and `config.{ext}`. Returns which artifacts exist and which are missing.

For greenfield, standards and test-conventions are typically missing — the synthesizer (component 4) generates them. The constitution is opt-in — when missing, the implementation presents the user with the option to create one.

When `config.{ext}` is absent, all pipeline settings use defaults (0 for all retry limits, false for `auto_resolve_spec`).

### 2. Codebase explorer

Implement a component that, given a repository path, produces a structured summary of: file organization, dependency structure, test patterns, and coding conventions. It extracts from **explicitly stated** project files (configuration files, linter rules, README conventions) — not inferred patterns.

For greenfield with minimal files, the exploration yields limited results. The component handles this gracefully — it reports what it found and flags gaps. Standards trace to project artifacts; inferred conventions are flagged as assumptions.

### 3. Decomposition synthesizer

Implement a component that, given user-provided feature details and the exploration results, produces `decomposition.md` with two required sections:

- **Description** — what the feature does
- **Delivery Details** — blockers, story relations, external requirements

### 4. Technical details synthesizer

Implement a component that produces `technical-details.md` with three required sections:

- **Standards** — coding standards extracted from project files
- **Test Conventions** — test framework, naming patterns, file organization
- **Dependencies** — packages, APIs, external services

When `standards.md` or `test-conventions.md` are missing from `.haileris/project/`, this component also generates them from the extracted standards. Use constructive statements in generated content ("use X", "organize by Y") — downstream stages consume these files for decision-making.

### 5. Harvest inspection

Implement the 4-dimension validation defined in [harvest-inspection.md](../../automation/harvest-inspection.md). Three dimensions are fully mechanical (Tier 1); one (dependency doc coverage) is agent-evaluated (SKIP).

| Dimension | Algorithm |
|-----------|-----------|
| Decomposition template | Check Description and Delivery Details sections are present and populated |
| Technical details template | Check Standards, Test Conventions, and Dependencies sections are present and populated |
| Artifact preflight | Verify `standards.md` and `test-conventions.md` exist with >5 non-blank lines |
| Dependency doc coverage | Agent-evaluated (SKIP) |

Overall `pass: true` requires the first three dimensions to pass. Output conforms to the [inspection report schema](../../artifacts/inspection-reports.md).

### 6. Pipeline state initializer

Implement the Initialize operation from [pipeline-state.md](../../automation/pipeline-state.md). Creates `pipeline-state.yaml` with:
- `current_stage: harvest`, all stage statuses `pending`
- `subspec_statuses` as empty map (Layout populates entries later)
- `constitution_version` recorded when a constitution exists
- `loop_count: 0`, timestamps set

### 7. Feature size check

Implement a heuristic that flags when the decomposition suggests more than ~20 BIDs at Inscribe. Recommend splitting along natural boundaries: separate user-facing behaviors, independent integration points, or distinct data flows.

## Orchestration

**Sub-stage ordering:** Pre-check → Explore → Synthesize → Validate → Initialize → Size check.

**State transition:** On successful completion, advance pipeline state to Ascertain via the Advance operation.

## Scope boundaries

- All Harvest output lives in `.haileris/features/{feature_id}/` and `.haileris/project/`
- Spec files at `tests/features/` are Inscribe's responsibility
- Standards content traces to explicitly stated project rules

## Criteria reference

[Harvest correctness criteria](../criteria/harvest.md)
