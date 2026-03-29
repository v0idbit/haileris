# Harvest — Correctness Criteria

## Input Manifest

### Available at Harvest entry

| Artifact | Path | Source |
|----------|------|--------|
| Target source code | Repository working tree | Pre-existing codebase (empty for greenfield) |
| Feature details | User-provided | Description, acceptance criteria, related context, tech details |
| Project standards (when present) | `.haileris/project/standards.md` | Previous Harvest run or `--reharvest` |
| Project test conventions (when present) | `.haileris/project/test-conventions.md` | Previous Harvest run or `--reharvest` |
| Constitution (when present) | `.haileris/project/constitution.md` | User-created; opt-in |

### Artifacts created by this stage

| Artifact | Path | Sub-stage |
|----------|------|-----------|
| Decomposition | `.haileris/features/{feature_id}/decomposition.md` | Harvest.Synthesize |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Harvest.Synthesize |
| Harvest inspection | `.haileris/features/{feature_id}/harvest-inspection.yaml` | Harvest.Validate |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Harvest.Initialize |
| Project standards | `.haileris/project/standards.md` | Harvest.Synthesize (when absent) |
| Project test conventions | `.haileris/project/test-conventions.md` | Harvest.Synthesize (when absent) |
| Harvest metadata | `.haileris/project/last-harvest.json` | Harvest.Synthesize |

### Read scope

Harvest reads the repository working tree and user-provided feature details. Standards extraction uses rules explicitly stated in the project's own files (configuration, linter rules, README conventions).

### Write scope

Harvest writes to `.haileris/features/{feature_id}/` and `.haileris/project/`. Spec files (`tests/features/`) are Inscribe's responsibility; Harvest's output stays in the metadata tree.

## Behavioral Constraints

### Project Artifact Pre-Check

Before Harvest begins, the pipeline checks for project-wide artifacts:

1. `.haileris/project/standards.md` and `.haileris/project/test-conventions.md` — when missing, Harvest.Explore and Harvest.Synthesize generate them
2. `.haileris/project/constitution.md` — when missing, prompt user with option to create one (opt-in)

This pre-check runs before every stage, ensuring all stages have stable access to project conventions.

### Constructive framing

Project-wide artifacts (`standards.md`, `test-conventions.md`, `constitution.md`) are consumed by LLM agents at every downstream stage. Use constructive statements ("use X", "organize by Y"). Agents follow positive instructions more reliably.

### Greenfield projects

For a greenfield project, the repository is empty or minimal. Harvest still runs — it explores whatever exists and synthesizes from user-provided feature details. The decomposition and technical details are authored from feature details and whatever project configuration is present.

### Feature size

When the decomposition suggests more than ~20 BIDs at Inscribe, recommend splitting at Harvest before proceeding to Ascertain. Split along natural boundaries: separate user-facing behaviors, independent integration points, or distinct data flows.

## Sub-stage Ordering

```
Project Artifact Pre-Check → Harvest.Explore → Harvest.Synthesize → Harvest.Validate → Harvest.Initialize
```

### Harvest.Explore

1. Explore the codebase: find relevant files, patterns, test structure
2. Read project standards and all referenced imports; extract coding standards, testing standards, git workflow rules

### Harvest.Synthesize

1. Synthesize the decomposition → `.haileris/features/{feature_id}/decomposition.md`
2. Synthesize the technical details → `.haileris/features/{feature_id}/technical-details.md`

### Harvest.Validate

1. Validate context across 4 dimensions; write `harvest-inspection.yaml`

| Dimension | Artifact | Pass condition |
|-----------|----------|---------------|
| Decomposition template compliance | `decomposition.md` | Description and Delivery Details sections present and are populated |
| Technical details template compliance | `technical-details.md` | Standards, Test Conventions, and Dependencies sections present and are populated |
| Artifact preflight | project standards | `.haileris/project/standards.md` and `test-conventions.md` both exist with >5 lines of content |
| Dependency doc coverage | `technical-details.md` | All referenced packages appear in project standards files (skip = acceptable) |

Overall `pass: true` requires the first three dimensions to pass; dependency doc coverage can be `skip`.

### Harvest.Initialize

1. Record `constitution_version` in `pipeline-state.yaml` (when a constitution exists)
2. Initialize `subspec_statuses` as empty map in `pipeline-state.yaml`

## Exit Checks

### Artifact existence

- [ ] `decomposition.md` exists at `.haileris/features/{feature_id}/decomposition.md`
- [ ] `technical-details.md` exists at `.haileris/features/{feature_id}/technical-details.md`
- [ ] `harvest-inspection.yaml` exists at `.haileris/features/{feature_id}/harvest-inspection.yaml`
- [ ] `pipeline-state.yaml` exists at `.haileris/features/{feature_id}/pipeline-state.yaml`
- [ ] `.haileris/project/standards.md` exists with >5 lines of content
- [ ] `.haileris/project/test-conventions.md` exists with >5 lines of content

### Content integrity

- [ ] `decomposition.md` contains Description and Delivery Details sections, both populated
- [ ] `technical-details.md` contains Standards, Test Conventions, and Dependencies sections, all populated
- [ ] `pipeline-state.yaml` has `current_stage` set and `subspec_statuses` initialized as empty map
- [ ] When a constitution exists: `constitution_version` is recorded in `pipeline-state.yaml`

### Inspection result

- [ ] `harvest-inspection.yaml` records results for all 4 dimensions
- [ ] Overall result is `pass: true`, or user acknowledged findings before proceeding

### Boundary discipline

- [ ] All Harvest output lives in `.haileris/features/{feature_id}/` and `.haileris/project/`
- [ ] Spec files (`tests/features/`) are untouched — Inscribe owns that path
- [ ] Standards content traces to explicitly stated project rules (configuration files, linter rules, README conventions)
