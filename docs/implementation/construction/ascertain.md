# Ascertain — Greenfield Construction

## Stage inputs

| Artifact | Path | Source |
|----------|------|--------|
| Decomposition | `.haileris/features/{feature_id}/decomposition.md` | Harvest |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Harvest |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Harvest |
| Project standards | `.haileris/project/standards.md` | Harvest |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |

## Stage outputs

| Artifact | Path |
|----------|------|
| Ascertainments | `.haileris/features/{feature_id}/ascertainments.md` |
| Decomposition (updated) | `.haileris/features/{feature_id}/decomposition.md` |

## Components to implement

### 1. Ambiguity analyzer

Implement a component that, given `decomposition.md`, identifies genuine ambiguities — cases where two reasonable developers would implement differently. The bar is high: clear requirements pass through without flagging.

### 2. User interaction loop

Implement a component that presents identified ambiguities to the user, each with a default assumption as a selectable option. The component collects user answers before proceeding. Every resolution traces to user input or explicit user confirmation — the user is the authority.

### 3. Assumption checkpoint

Implement a fallback for when the ambiguity analyzer finds no ambiguities. The component lists the assumptions made during analysis and presents them for user confirmation. This prevents silent assumptions from propagating downstream.

### 4. Ascertainments recorder

Implement a component that writes entries to `ascertainments.md`. Each entry records the ambiguity, the default assumption offered, and the answer received. The file is append-only — entries accumulate as a decision log.

### 5. Decomposition updater

Implement a component that updates `decomposition.md` to reflect all resolved ambiguities. The decomposition remains consistent with all recorded resolutions.

### 6. Iteration controller

Implement a loop that repeats ambiguity analysis → user interaction → recording until all ascertainments are resolved. Each iteration may surface new questions based on prior answers.

## Orchestration

**State transition:** On completion (all ascertainments resolved), advance pipeline state to Inscribe.

When Ascertain is re-entered via a Settle loop (domain: spec), the iteration controller resumes with the new ambiguities from the spec-domain findings.

## Scope boundaries

- All Ascertain output lives in `.haileris/features/{feature_id}/`
- Spec files (`tests/features/`), BIDs, and Gherkin scenarios are Inscribe's responsibility
- Project-wide artifacts (`standards.md`, `test-conventions.md`, `constitution.md`) are untouched

## Criteria reference

[Ascertain correctness criteria](../criteria/ascertain.md)
