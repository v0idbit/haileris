# 2. Ascertain

Clarify ambiguities, contradictions, and gaps in the decomposition.

## Inputs

- Decomposition

## Process

1. Analyze the decomposition for genuine ambiguities
2. If ambiguities are found: surface each with a default assumption as a selectable option
3. If the decomposition is unambiguous: list the assumptions made during analysis and present them to the user for confirmation. This ensures all assumptions are visible before they propagate through the pipeline.
4. Present questions or assumptions to user; wait for answers before proceeding
5. Record answered ascertainments in `.haileris/features/{feature_id}/ascertainments.md`
6. Update `decomposition.md` with resolved ambiguities so it reflects Q&A outcomes
7. Repeat until all ascertainments are resolved (see Iteration below)

## Iteration

Repeat until all ascertainments are resolved:

1. Identify gaps, contradictions, or ambiguities
2. Output detailed ascertainment needs
3. Receive answers; update `ascertainments.md` and `decomposition.md`

## Outputs

- Improved decomposition

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Ascertainments | `.haileris/features/{feature_id}/ascertainments.md` | Ingested by Inscribe |
| Decomposition (updated) | `.haileris/features/{feature_id}/decomposition.md` | Updated in place with resolved ambiguities; ensures Inscribe reads the refined version |

## Notes

- This stage surfaces only genuine ambiguities — things where two reasonable developers would implement differently. Keep the bar high.
- Ambiguities are presented with default assumptions and selectable alternatives
