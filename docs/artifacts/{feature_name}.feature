# Spec

The central artifact of the pipeline. Produced by Inscribe, consumed by every downstream stage. It is the source of truth for what must be built and the traceability anchor for all tests, tasks, and implementation.

## What It Contains

- **YAML frontmatter** — `feature`, `type` (greenfield / modification / refactor), `modules` (list of file paths with roles), `status` (inscribing / ascertaining / approved)
- **Behaviors** — a list of BIDs in Gherkin format, grouped by module or concern
- **Optional sections** — for modification specs: Unchanged / Modified / New; for large features: Implementation Order; for non-behavioral requirements: Constraints

## BID Format

`BID-{NNN}` — sequentially numbered from 001. Every behavior in the spec has one. BIDs are the unit of traceability: every task, test, and source symbol in the pipeline is traced back to a BID.

## Status Lifecycle

`inscribing` → `ascertaining` (if NEEDS ASCERTAINMENT markers exist) → `approved` (after user gate at Inscribe)

## Lifecycle

Stable after user approval. Must not be modified by any downstream stage except through the Settle spec auto-resolve mechanism (domain: spec findings). If the spec must change, it changes through Ascertain → Inscribe with that change as the goal.

## Path

`.haileris/features/{feature_id}/{feature_name}.feature`

## Committed

Yes. The approved spec is committed as part of the feature's artifact set.
