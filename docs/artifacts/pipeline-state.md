# Pipeline State

A machine-readable record of where a feature currently sits in the pipeline. Written and updated as each stage completes. Used to resume an interrupted run and to drive inspection tooling.

## What It Contains

- `feature_id` — the feature being tracked
- `current_stage` — the stage currently running or last completed
- `stage_statuses` — a map of stage name → `pending` / `running` / `passed` / `failed`
- `retry_counts` — a map of stage name → number of retries consumed
- `last_updated` — ISO timestamp of the most recent write

## Failure State

When a stage exhausts its retry budget without passing, a `stage-failure.md` file is written alongside the pipeline state. The pipeline state records `failed` for that stage and halts; no further stages run.

## Lifecycle

Created by Harvest when the feature is first registered. Updated after each stage transition. Remains in place until the feature is closed. Never rolled back — the state reflects the most recent completed transition.

## Path

`.haileris/features/{feature_id}/pipeline-state.yaml`

## Committed

Yes. The state file is committed after each stage so that the pipeline can be resumed from an external process or a new session.
