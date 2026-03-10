# 2. Ascertain

Clarify ambiguities, contradictions, and gaps in the decomposition.

## Inputs

- Decomposition

## Process

1. Analyze the decomposition for genuine ambiguities
2. Surface each ambiguity with a default assumption as a selectable option (not open-ended questions)
3. Present questions to user; wait for answers before proceeding
4. Record answered ascertainments in `.haileris/features/{feature_id}/ascertainments.md`
5. Repeat until no ascertainments are needed (see Iteration below)

## Iteration

Repeat until no ascertainments are needed:

1. Identify gaps, contradictions, or ambiguities
2. Output detailed ascertainment needs
3. Receive answers and update decomposition

## Outputs

- Improved decomposition

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Ascertainments | `.haileris/features/{feature_id}/ascertainments.md` | Ingested by Inscribe |

## Notes

- This stage surfaces only genuine ambiguities — things where two reasonable developers would implement differently. It does not nitpick.
- Ambiguities are presented with default assumptions with selectable alternatives, not open-ended questions
