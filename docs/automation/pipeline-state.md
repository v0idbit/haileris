# Pipeline State Machine

State management operations for tracking feature progress through the pipeline. Source: [pipeline-state.md](../artifacts/pipeline-state.md), [Pipeline.md](../Pipeline.md).

## State Schema

```yaml
feature_id: "{feature_id}"
current_stage: "harvest"
constitution_version: null
started_at: "2026-03-18T14:30:00Z"
last_updated: "2026-03-18T14:30:00Z"
stage_statuses:
  harvest: pending
  ascertain: pending
  inscribe: pending
  layout: pending
  etch: pending
  realize: pending
  inspect: pending
  settle: pending
etch_realize_progress:
  current_subspec: 1
  total_subspecs: 0
  subspecs_completed: []
loop_count: 0
last_loop_target: null
```

## Constants

```
STAGE_ORDER ← [harvest, ascertain, inscribe, layout, etch, realize, inspect, settle]

VALID_TRANSITIONS:
  harvest    → [ascertain]
  ascertain  → [inscribe]
  inscribe   → [layout]
  layout     → [etch]
  etch       → [realize]
  realize    → [inspect]
  inspect    → [settle]
  settle     → [ascertain, etch, realize]    — loop re-entry targets

MAX_LOOPS ← 3
```

## Operations

### 1. Initialize

Create a new pipeline state when a feature is first registered at Harvest.

```
FUNCTION init_state(feature_id, state_dir, constitution_version=null):
  now ← current UTC timestamp in ISO 8601

  state ← {
    feature_id:             feature_id,
    current_stage:          "harvest",
    constitution_version:   constitution_version,
    started_at:             now,
    last_updated:           now,
    stage_statuses:         { stage: "pending" FOR EACH stage IN STAGE_ORDER },
    etch_realize_progress:  { current_subspec: 1, total_subspecs: 0, subspecs_completed: [] },
    loop_count:             0,
    last_loop_target:       null,
  }

  write_yaml(state, state_dir / "pipeline-state.yaml")
  RETURN state
```

### 2. Load

Read existing pipeline state from disk.

```
FUNCTION load_state(state_dir):
  path ← state_dir / "pipeline-state.yaml"
  IF path does not exist: RETURN null
  data ← load_yaml(path)
  IF data is null or not a valid state object: RETURN null
  RETURN data as PipelineState
```

### 3. Save

Write pipeline state to disk, updating the `last_updated` timestamp.

```
FUNCTION save_state(state, state_dir):
  state.last_updated ← current UTC timestamp in ISO 8601
  create state_dir if it does not exist
  write_yaml(state, state_dir / "pipeline-state.yaml")
```

### 4. Advance Stage

Record a stage result and move the pipeline forward.

```
FUNCTION advance_stage(state, stage, status, state_dir):
  PRECONDITIONS:
    — status must be "passed" or "failed"
    — stage must be in STAGE_ORDER
    — transition from state.current_stage to stage must be valid,
      OR stage must equal state.current_stage

  state.stage_statuses[stage] ← status

  IF status = "passed":
    stage_idx ← index of stage in STAGE_ORDER
    IF stage_idx + 1 < length(STAGE_ORDER):
      next_stage ← STAGE_ORDER[stage_idx + 1]
      state.current_stage ← next_stage
      state.stage_statuses[next_stage] ← "running"
    ELSE:
      — Last stage (settle) passed; pipeline complete
      state.current_stage ← stage

  save_state(state, state_dir)
  RETURN state
```

**Transition validation:** The advance function verifies that the requested stage is either the current stage or a valid forward transition from the current stage. Invalid transitions are rejected with an error.

### 5. Loop (Settle Re-entry)

Handle a Settle → re-entry loop. Increments the loop counter, records the target, and resets downstream stages.

```
FUNCTION increment_loop(state, target, state_dir):
  PRECONDITIONS:
    — target must be one of: ascertain, etch, realize
    — state.loop_count < MAX_LOOPS

  IF state.loop_count ≥ MAX_LOOPS:
    ERROR "Loop count already at maximum ({MAX_LOOPS}); escalate to user"

  state.loop_count ← state.loop_count + 1
  state.last_loop_target ← target

  — Reset stages from target onward (inclusive) to pending
  target_idx ← index of target in STAGE_ORDER
  FOR i FROM target_idx TO length(STAGE_ORDER) - 1:
    state.stage_statuses[STAGE_ORDER[i]] ← "pending"

  — Set current stage to the loop target
  state.current_stage ← target
  state.stage_statuses[target] ← "running"

  save_state(state, state_dir)
  RETURN state
```

**Reset scope:** On a loop to `etch`, the stages `etch`, `realize`, `inspect`, and `settle` are all reset to `pending`. Stages before the target retain their `passed` status.

### 6. Resume

Determine where to resume an interrupted pipeline run.

```
FUNCTION get_resume_point(state):
  RETURN state.current_stage
```

The `current_stage` field always holds the next stage to run (set by `advance_stage` on the previous stage's success) or the stage that was running when interrupted.

### 7. Show

Display the current pipeline state. Read-only — no state mutation.

```
FUNCTION show_state(state):
  emit state as YAML to stdout
```

## Subspec Progress Tracking

During Etch/Realize sequential execution, `etch_realize_progress` tracks which subspecs have completed:

```
FUNCTION advance_subspec(state, state_dir):
  progress ← state.etch_realize_progress
  progress.subspecs_completed.append(progress.current_subspec)

  IF length(progress.subspecs_completed) < progress.total_subspecs:
    progress.current_subspec ← progress.current_subspec + 1
  — else: all subspecs complete; proceed to Inspect

  save_state(state, state_dir)
  RETURN state
```

The `total_subspecs` field is set by Layout when the task list is finalized.

## State File Path

`.haileris/features/{feature_id}/pipeline-state.yaml`

## State Lifecycle

1. **Created** by Harvest when the feature is first registered
2. **Updated** after each stage transition via `advance_stage`
3. **Reset** (partially) on Settle loops via `increment_loop`
4. **Read** by Inspect.Gate to verify constitution version
5. **Read** on resume to determine where to continue
6. **Never rolled back** — the state reflects the most recent completed transition

## Invariants

- `current_stage` is always a valid stage name from `STAGE_ORDER`
- `stage_statuses` always contains exactly the 8 pipeline stages
- `loop_count` never exceeds `MAX_LOOPS` (3)
- `last_loop_target` is `null` or one of `ascertain`, `etch`, `realize`
- After a loop, all stages from the target onward have status `pending`, and stages before the target retain their prior status
- `constitution_version` is immutable after initialization (set once at Harvest)
- `started_at` is immutable after initialization

## Edge Cases

- **Advance on a failed stage:** Setting a stage to `failed` does not advance `current_stage`. The pipeline stays at the failed stage until the issue is resolved and the stage is re-run.
- **Double advance:** Advancing the same stage twice (e.g., calling advance with `harvest` / `passed` when harvest is already `passed`) is idempotent if the stage matches `current_stage`. If the stage has already been advanced past, the transition validation rejects it.
- **Loop at maximum:** If `loop_count` equals `MAX_LOOPS`, `increment_loop` returns an error. The caller must escalate to the user.
- **Resume after loop:** `current_stage` points to the loop target with status `running`. Resume picks up from there.
- **Settle passes (no loop):** `advance_stage` with `settle` / `passed` leaves `current_stage` at `settle`. The pipeline is complete.
