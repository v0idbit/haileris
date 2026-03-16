# Pipeline State

A machine-readable record of where a feature currently sits in the pipeline. Written and updated as each stage completes. Used to resume an interrupted run and to drive inspection tooling.

## What It Contains

- `feature_id` — the feature being tracked
- `current_stage` — the stage currently running or last completed
- `constitution_version` — locked at Harvest; checked at Inspect
- `started_at` — ISO timestamp of when the feature run began
- `last_updated` — ISO timestamp of the most recent write
- `stage_statuses` — a map of stage name → `pending` / `running` / `passed` / `failed`
- `etch_realize_progress` — subset tracking for Etch/Realize sequential execution
- `loop_count` — number of Settle → re-entry loops (max 3; escalate to user if exceeded)
- `last_loop_target` — which stage the most recent Settle loop re-entered (`ascertain` / `etch` / `realize` / `null`)

```yaml
feature_id: "{feature_id}"
current_stage: "realize"
constitution_version: "1.2.0"
started_at: "2026-03-10T14:30:00Z"
last_updated: "2026-03-10T16:45:00Z"
stage_statuses:
  harvest: passed
  ascertain: passed
  inscribe: passed
  layout: passed
  etch: running
  realize: pending
  inspect: pending
  settle: pending
etch_realize_progress:
  current_subset: 2
  total_subsets: 3
  subsets_completed: [1]
loop_count: 0
last_loop_target: null
```

## Lifecycle

Created by Harvest when the feature is first registered. Updated after each stage transition. On a Settle loop, downstream stage statuses reset to `pending` from the loop target onward. Remains in place until the feature is closed. Never rolled back — the state reflects the most recent completed transition.

## Path

`.haileris/features/{feature_id}/pipeline-state.yaml`

## Committed

Yes. The state file is committed after each stage so that the pipeline can be resumed from an external process or a new session.
