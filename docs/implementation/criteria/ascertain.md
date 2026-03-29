# Ascertain — Correctness Criteria

## Input Manifest

### Available at Ascertain entry

| Artifact | Path | Source |
|----------|------|--------|
| Decomposition | `.haileris/features/{feature_id}/decomposition.md` | Written by Harvest |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Written by Harvest (available for reference) |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Shows `harvest: passed` |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |
| Project standards | `.haileris/project/standards.md` | Written by Harvest |

### Artifacts created by this stage

| Artifact | Path |
|----------|------|
| Ascertainments | `.haileris/features/{feature_id}/ascertainments.md` |
| Decomposition (updated) | `.haileris/features/{feature_id}/decomposition.md` |

### Read scope

Ascertain reads `decomposition.md` as its sole primary input, plus user responses to ascertainment questions.

### Write scope

Ascertain writes to `.haileris/features/{feature_id}/` only: `ascertainments.md` (new) and `decomposition.md` (updated in place). Spec files, BIDs, and Gherkin scenarios are Inscribe's responsibility.

## Behavioral Constraints

### Scope of analysis

Ascertain surfaces only genuine ambiguities — cases where two reasonable developers would implement differently. The bar is high: clear requirements pass through.

### Interaction model

- When ambiguities are found: surface each with a default assumption as a selectable option
- When the decomposition is unambiguous: list assumptions made during analysis and present them for user confirmation
- Wait for user answers before proceeding
- Iterate until all ascertainments are resolved

### Resolution authority

Every ambiguity resolution traces to user input or explicit user confirmation of a default. Ascertain presents options and records decisions; the user is the authority.

## Sub-stage Ordering

Ascertain is an iterative loop (terminates when all ascertainments are resolved):

```
Analyze → Surface questions/assumptions → Receive answers → Update artifacts → Repeat when needed
```

Each iteration:
1. Identify gaps, contradictions, or ambiguities in the decomposition
2. Output detailed ascertainment needs (with default assumptions)
3. Receive answers from user
4. Update `ascertainments.md` and `decomposition.md`

## Exit Checks

### Artifact existence

- [ ] `ascertainments.md` exists at `.haileris/features/{feature_id}/ascertainments.md`
- [ ] `decomposition.md` reflects all resolved ambiguities

### Content integrity

- [ ] Every surfaced ambiguity has a recorded resolution in `ascertainments.md`
- [ ] `decomposition.md` is consistent with all recorded resolutions
- [ ] When the decomposition was unambiguous: assumptions are listed and user-confirmed

### Boundary discipline

- [ ] All Ascertain output lives in `.haileris/features/{feature_id}/`
- [ ] Spec files (`tests/features/`) are untouched — Inscribe owns that path
- [ ] Project-wide artifacts (`standards.md`, `test-conventions.md`, `constitution.md`) are untouched
- [ ] Every resolution traces to user input or user-confirmed default
