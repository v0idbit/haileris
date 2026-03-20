# 1. Harvest

Data munging the context funnel.

## Inputs

- Target source code
- Feature details
  - Description
  - Acceptance criteria
  - Related context (epics, stories, design docs, dependency docs, library/tool/platform docs, conversation notes)
  - Tech details (language requirements, repo standards, installed/external dependencies)

## Process

### Project Artifact Pre-Check

Before any stage runs (not just Harvest), the pipeline checks for required project-wide artifacts:

1. Check for `.haileris/project/standards.md` and `.haileris/project/test-conventions.md`
   - If missing: run Harvest.Explore and Harvest.Synthesize to generate them
2. Check for `.haileris/project/constitution.md`
   - If missing: prompt the user with the option to create one (opt-in)

This pre-check ensures every stage has stable access to project conventions without redundant exploration.

### Harvest.Explore

1. Explore the codebase and read project standards:
   - Find relevant files, patterns, and test structure
   - Read project standards and all referenced imports; extract coding standards, testing standards, git workflow rules
     - **NOTE**: Standards must be explicitly stated in the project's own files

### Harvest.Synthesize

1. Synthesize the decomposition; write to `.haileris/features/{feature_id}/decomposition.md`
2. Synthesize the technical details; write to `.haileris/features/{feature_id}/technical-details.md`

### Harvest.Validate

1. Validate the context across 4 dimensions; write `harvest-inspection.yaml`

### Harvest.Initialize

1. Record `constitution_version` in `pipeline-state.yaml` to lock the active constitution version for this feature run (if a constitution exists)

## Outputs

- Decomposition (tentative)
  - Description
  - Delivery details (blockers, story relations, external requirements)
- Technical details
  - Coding standards and test conventions
  - Dependency documentation
  - File path inventory

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Decomposition | `.haileris/features/{feature_id}/decomposition.md` | Stage output; ingested by Ascertain and Inscribe |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Stage output; ingested by Inscribe, Etch, and Realize |
| Project standards | `.haileris/project/standards.md` | Committed; refreshed by `--reharvest` |
| Project test conventions | `.haileris/project/test-conventions.md` | Committed |
| Harvest inspection | `.haileris/features/{feature_id}/harvest-inspection.yaml` | Traceability gate input for Inspect |
| Harvest metadata | `.haileris/project/last-harvest.json` | Used for incremental reharvest detection |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Tracks current stage, constitution version, and resume state |

## Harvest Inspection

Validates `decomposition.md` and `technical-details.md` across 4 dimensions:

| Dimension | Artifact | Pass condition |
|-----------|----------|---------------|
| Decomposition template compliance | `decomposition.md` | Description and Delivery Details sections present and non-empty |
| Technical details template compliance | `technical-details.md` | Standards, Test Conventions, and Dependencies sections present and non-empty |
| Artifact preflight | project standards | `.haileris/project/standards.md` and `test-conventions.md` both exist with >5 non-blank lines |
| Dependency doc coverage | `technical-details.md` | All referenced packages appear in project standards files (skip = not a failure) |

Overall `pass: true` requires the first three dimensions to pass; dependency doc coverage can be `skip`.

On FAIL: present findings to user with options to re-run, fix manually, or proceed. Requires user decision before retrying.

## Notes

- **Constructive framing**: project-wide artifacts (`standards.md`, `test-conventions.md`, `constitution.md`) are consumed by LLM agents at every downstream stage. Prefer constructive statements ("use X", "organize by Y") over negations ("avoid X", "do not Y"). Agents follow positive instructions more reliably than prohibitions.
- Project standards files are reused across runs unless `--reharvest` is passed; use `--reharvest` when project standards change
- `harvest-inspection.yaml` is the earliest inspection artifact and feeds the Traceability Gate at Inspect (stage 7)

> [!NOTE]
> `technical-details.md` (including its dependency documentation) remains available to all downstream stages — particularly Etch and Realize, where dependency APIs are needed to write tests and implementation. Stages should reference it rather than re-discovering dependency details independently.

### Feature Size Guidance

A feature that produces more than **~20 BIDs** at Inscribe should be considered for splitting. Large features cause:
- Massive specs that are hard to review at the Inscribe approval gate
- Many Layout subspecs with complex dependency chains
- Long Etch → Realize loops that delay feedback
- Broad Inspect reviews where findings are harder to triage

If the decomposition suggests a feature will exceed this threshold, recommend splitting at Harvest before proceeding to Ascertain. Split along natural boundaries: separate user-facing behaviors, independent integration points, or distinct data flows. Each sub-feature runs through the pipeline independently.
