# Pipeline State Machine

State management operations for tracking feature progress through the pipeline. Source: [pipeline-state.md](../artifacts/pipeline-state.md), [pipeline.md](../pipeline.md).

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
```

## Constants

Stage order: harvest → ascertain → inscribe → layout → etch → realize → inspect → settle.

Valid transitions from Settle on loop: ascertain, etch, realize.

Maximum loops: governed by `settle_loops` in [pipeline config](../artifacts/config.md) (default: 0).

## Behavior

```gherkin
Feature: Pipeline State Machine
  State management operations for tracking feature progress through the pipeline.

  Rule: Initialize — create a new pipeline state at Harvest

    Scenario: A new feature is registered
      Given no pipeline state exists for "feature-123"
      When the state is initialized for "feature-123"
      Then the current stage is "harvest"
      And all stage statuses are "pending"
      And the loop count is 0
      And the last loop target is null
      And started_at and last_updated are set to the current UTC timestamp

    Scenario: A new feature is registered with a constitution version
      Given no pipeline state exists for "feature-123"
      And a constitution exists with version "1.0"
      When the state is initialized for "feature-123" with constitution version "1.0"
      Then the constitution version is "1.0"

  Rule: Advance — record a stage result and move the pipeline forward

    Scenario: A stage passes and the pipeline advances to the next stage
      Given the current stage is "harvest" with status "running"
      When "harvest" is advanced with status "passed"
      Then the stage status for "harvest" is "passed"
      And the current stage is "ascertain"
      And the stage status for "ascertain" is "running"

    Scenario: The last stage (settle) passes — pipeline is complete
      Given the current stage is "settle" with status "running"
      When "settle" is advanced with status "passed"
      Then the stage status for "settle" is "passed"
      And the current stage is "settle"

    Scenario: A stage fails — pipeline stays at the failed stage
      Given the current stage is "etch" with status "running"
      When "etch" is advanced with status "failed"
      Then the stage status for "etch" is "failed"
      And the current stage is "etch"

    Scenario: An invalid transition is rejected
      Given the current stage is "harvest"
      When "layout" is advanced with status "passed"
      Then the transition is rejected with an error

    Scenario: Advancing the same stage twice is idempotent
      Given the current stage is "harvest" with status "running"
      When "harvest" is advanced with status "passed"
      And "harvest" is advanced with status "passed" again
      Then the state reflects the first advance

  Rule: Loop — handle Settle re-entry by resetting downstream stages

    Scenario: A loop to etch resets etch and all downstream stages
      Given the current stage is "settle"
      And the loop count is 0
      When a loop is initiated with target "etch"
      Then the loop count is 1
      And the last loop target is "etch"
      And the stage statuses for "etch", "realize", "inspect", "settle" are "pending"
      And the current stage is "etch"
      And the stage status for "etch" is "running"
      And stages before "etch" retain their prior statuses

    Scenario: A loop to ascertain resets ascertain and all downstream stages
      Given the current stage is "settle"
      And the loop count is 0
      When a loop is initiated with target "ascertain"
      Then the loop count is 1
      And the last loop target is "ascertain"
      And the stage statuses for "ascertain" through "settle" are "pending"
      And the current stage is "ascertain"
      And the stage status for "ascertain" is "running"

    Scenario: A loop at maximum count is rejected
      Given the settle_loops config is set to 3
      And the loop count is 3
      When a loop is initiated with target "etch"
      Then the loop is rejected with error "Loop count already at maximum (3); escalate to user"

    Scenario: A loop with an invalid target is rejected
      Given the current stage is "settle"
      When a loop is initiated with target "layout"
      Then the loop is rejected with an error

  Rule: Resume — determine where to continue an interrupted pipeline

    Scenario: Resume returns the current stage
      Given the current stage is "etch"
      When the resume point is requested
      Then the resume point is "etch"

    Scenario: Resume after a loop returns the loop target
      Given a loop was initiated with target "realize"
      And the current stage is "realize" with status "running"
      When the resume point is requested
      Then the resume point is "realize"

  Rule: Subspec Progress — track sequential Etch/Realize execution

    Scenario: A subspec completes and the next one begins
      Given the total subspecs count is 3
      And the current subspec is 1
      And subspecs completed is empty
      When the current subspec is advanced
      Then subspecs completed contains 1
      And the current subspec is 2

    Scenario: The last subspec completes
      Given the total subspecs count is 2
      And the current subspec is 2
      And subspecs completed contains [1]
      When the current subspec is advanced
      Then subspecs completed contains [1, 2]

  Rule: Subspec Initialize — populate subspec statuses after Layout

    Scenario: Layout completes and subspec statuses are populated
      Given Layout has just completed
      And the layout produced subspecs "users.feature", "auth.feature", and an integration entry "_integration"
      When subspec statuses are initialized
      Then subspec_statuses contains an entry for "users.feature" with status "pending"
      And subspec_statuses contains an entry for "auth.feature" with status "pending"
      And subspec_statuses contains an entry for "_integration" with status "pending"
      And provides_hash is null for all entries
      And last_completed_at is null for all entries

  Rule: Subspec Advance — track per-subspec completion

    Scenario: A subspec passes and its status is recorded
      Given subspec_statuses contains an entry for "users.feature" with status "running"
      When "users.feature" completes with provides_hash "a1b2c3"
      Then the status for "users.feature" is "passed"
      And the provides_hash for "users.feature" is "a1b2c3"
      And the last_completed_at for "users.feature" is set to the current UTC timestamp

  Rule: Scoped Loop — Settle loop resets only affected subspecs

    Scenario: A scoped loop resets only targeted and blast-radius subspecs
      Given subspec_statuses contains "users.feature" with status "passed"
      And subspec_statuses contains "auth.feature" with status "passed"
      And subspec_statuses contains "_integration" with status "passed"
      When a scoped loop is initiated with target_subspecs ["auth.feature"] and blast_radius ["auth.feature"]
      Then the status for "auth.feature" is "pending"
      And the status for "_integration" is "pending"
      And the status for "users.feature" remains "passed"

    Scenario: A domain:spec loop to Ascertain resets all subspec statuses
      Given subspec_statuses contains "users.feature" with status "passed"
      And subspec_statuses contains "auth.feature" with status "passed"
      And subspec_statuses contains "_integration" with status "passed"
      When a loop is initiated with target "ascertain"
      Then the status for "users.feature" is "pending"
      And the status for "auth.feature" is "pending"
      And the status for "_integration" is "pending"
```

Load and Save are implementation concerns — the state is read from and written to `.haileris/features/{feature_id}/pipeline-state.yaml` with the `last_updated` timestamp refreshed on each write.

Show is a read-only operation that emits the current pipeline state as YAML to stdout.

## State File Path

`.haileris/features/{feature_id}/pipeline-state.yaml`

## State Lifecycle

1. **Created** by Harvest when the feature is first registered
2. **Updated** after each stage transition via advance
3. **Reset** (partially) on Settle loops
4. **Read** by Inspect.Gate to verify constitution version
5. **Read** on resume to determine where to continue
6. **Append-forward** — the state always reflects the most recent completed transition

## Invariants

- `current_stage` is always a valid stage name from the stage order
- `stage_statuses` always contains exactly the 8 pipeline stages
- `loop_count` has a maximum governed by `settle_loops` in pipeline config (default: 0)
- `last_loop_target` is `null` or one of `ascertain`, `etch`, `realize`
- After a loop, all stages from the target onward have status `pending`, and stages before the target retain their prior status
- `constitution_version` is immutable after initialization (set once at Harvest)
- `started_at` is immutable after initialization
- `subspec_statuses` is empty before Layout completes; populated after
- `rerun_scope` carries default-empty values except during Settle-initiated loops
- `_integration` is always reset when any subspec is reset
- `provides_hash` is null until a subspec completes its first Etch/Realize cycle

## Edge Cases

- **Advance on a failed stage:** Setting a stage to `failed` does not advance `current_stage`. The pipeline stays at the failed stage until the issue is resolved and the stage is re-run.
- **Double advance:** Advancing the same stage twice (e.g., calling advance with `harvest` / `passed` when harvest is already `passed`) is idempotent if the stage matches `current_stage`. If the stage has already been advanced past, the transition validation rejects it.
- **Loop at maximum:** If `loop_count` equals the `settle_loops` config value (default: 0), the loop is rejected. The caller must escalate to the user.
- **Resume after loop:** `current_stage` points to the loop target with status `running`. Resume picks up from there.
- **Settle passes (no loop):** Advancing `settle` with `passed` leaves `current_stage` at `settle`. The pipeline is complete.
