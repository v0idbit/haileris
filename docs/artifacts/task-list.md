# Task List

The ordered breakdown of the spec into discrete implementation units. Produced by Layout, consumed by Etch and Realize.

## What It Contains

A list of tasks, each with:
- `TASK-{NNN}` identifier (sequential)
- Description of what the task implements
- The BIDs it covers
- Dependencies on other tasks (if any)
- Acceptance criteria

Tasks are grouped so that each covers a coherent set of BIDs with a shared implementation boundary and is independently implementable.

## Lifecycle

Written once by Layout after the complexity gate approves the breakdown. Read by Etch (for test grouping) and Realize (for implementation order). Stable after writing — not modified by downstream stages. Kept after the feature completes as an inspection record of how the spec was decomposed.

## Path

`.haileris/features/{feature_id}/tasks.md`

## Committed

Yes. Kept for inspection reference.
