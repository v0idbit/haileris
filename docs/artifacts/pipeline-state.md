# Pipeline State

A machine-readable record of where a feature currently sits in the pipeline. Written and updated as each stage completes. Used to resume an interrupted run and to drive inspection tooling.

## What It Contains

- `feature_id` — the feature being tracked
- `current_stage` — the stage currently running or last completed
- `constitution_version` — locked at Harvest; checked at Inspect
- `started_at` — ISO timestamp of when the feature run began
- `last_updated` — ISO timestamp of the most recent write
- `stage_statuses` — a map of stage name → `pending` / `running` / `passed` / `failed`
- `etch_realize_progress` — subspec tracking for Etch/Realize sequential execution
- `subspec_statuses` — per-subspec tracking: `pending` / `running` / `passed` / `failed`. Each entry includes `provides_hash` (hash of the Provides line, used to detect contract changes during re-runs) and `last_completed_at` (ISO timestamp).
- `rerun_scope` — default-empty; populated by Settle.Scope when a loop is initiated: `target_subspecs` (subspecs owning failing BIDs), `blast_radius` (downstream dependents), `provides_changed` (set to `true` if any target subspec's Provides line changed after fix).
- `loop_count` — number of Settle → re-entry loops (max governed by `settle_loops` in [pipeline config](config.md); default: 0; escalate to user if exceeded)
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
  current_subspec: 2
  total_subspecs: 3
  subspecs_completed: [1]
subspec_statuses:
  "users.feature":
    status: passed
    provides_hash: "a1b2c3"
    last_completed_at: "2026-03-10T15:30:00Z"
  "auth.feature":
    status: running
    provides_hash: null
    last_completed_at: null
  "_integration":
    status: pending
    provides_hash: null
    last_completed_at: null
rerun_scope:
  target_subspecs: []
  blast_radius: []
  provides_changed: false
loop_count: 0
last_loop_target: null
```

## Lifecycle

Created by Harvest when the feature is first registered. Updated after each stage transition. On a Settle loop, downstream stage statuses reset to `pending` from the loop target onward. Remains in place until the feature is closed. Append-forward — the state always reflects the most recent completed transition.

Per-subspec statuses are initialized when Layout completes (all subspecs set to `pending`). Updated after each subspec's Etch/Realize cycle. On a Settle loop with subspec-scoped re-run, only targeted subspecs and their blast radius are reset to `pending`; unaffected subspecs retain `passed`. `rerun_scope` carries default-empty values except during Settle-initiated loops.

## Path

`.haileris/features/{feature_id}/pipeline-state.yaml`

## Committed

Yes. The state file is committed after each stage so that the pipeline can be resumed from an external process or a new session.
