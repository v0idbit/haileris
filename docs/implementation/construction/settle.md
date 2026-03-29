# Settle — Greenfield Construction

## Stage inputs

Everything from stages 1–7, plus the verify report:

| Artifact | Path | Source |
|----------|------|--------|
| Verify report (most recent) | `.haileris/features/{feature_id}/verify_{timestamp}.md` | Inspect |
| All spec, test, source, and map artifacts | Various | Stages 1–6 |
| Delivery order | `.haileris/features/{feature_id}/delivery-order.yaml` | Layout |
| Pipeline config (when present) | `.haileris/project/config.{ext}` | Governs `settle_loops`, `auto_resolve_spec` |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Tracks `loop_count`, `subspec_statuses`, `provides_hash` |

## Stage outputs

Settle modifies existing artifacts based on findings. When all findings are resolved: **COMPLETE**.

| Artifact | Condition |
|----------|-----------|
| Source code (`src/`) | `domain: impl` findings |
| Test files (`tests/`) | `domain: test` findings, via three-tier policy |
| Gherkin spec (`tests/features/`) | `domain: spec` findings, via auto-resolve (when enabled) |
| Etch map | When genuinely wrong test fixes change mappings |
| Ascertainments | When `auto_resolve_spec` enabled: resolutions appended with `[AUTO-RESOLVED]` tag |
| Delivery order | Regenerated from current declarations |
| Pipeline state | `rerun_scope`, `loop_count`, subspec statuses updated |

## Components to implement

### 1. Finding parser (Settle.Triage)

Implement a component that locates the most recent `verify_{timestamp}.md`, extracts findings, and filters:
- Parse Critical, High, and Medium findings only (Low and Nit are informational — pass over them)
- Identify owning subspec per finding via BID → subspec mapping (etch-map or realize-map)
- Group findings by owning subspec

### 2. Scope calculator (Settle.Scope)

Implement a component that determines the re-run scope:

1. Regenerate `delivery-order.yaml` from current `Requires:`/`Provides:` declarations (reuse the dependency order compiler from Layout)
2. Identify `target_subspecs` — subspecs owning failing BIDs
3. Compute `blast_radius` — transitive downstream dependents of target subspecs. Walk the dependency graph: if C requires B which requires target A, both B and C are in the blast radius.
4. Write `rerun_scope` to `pipeline-state.yaml`: `target_subspecs`, `blast_radius`, `provides_changed: false`
5. `_integration` is always included in the re-run scope

### 3. `impl` domain fixer (Settle.Fix)

Implement a component that applies targeted production code fixes for `domain: impl` findings. Fixes are scoped to the listed findings only — each fix targets specific production code identified by the finding.

### 4. `test` domain fixer — three-tier policy (Settle.Fix)

Implement a component that handles `domain: test` findings using three tiers of authority:

| Tier | What changes | Authority | Implementation requirement |
|------|-------------|-----------|---------------------------|
| 1. Structural refactors | How a test is written (fixture dedup, setup reorganization, assertion style) | Apply directly | Preserve test function names and count; test results are identical before and after |
| 2. Assertion corrections | Adding missing assertions or correcting expected values | Apply and notify user | **Closed derivation scope:** use only (a) the BID's Gherkin Then/And step and (b) the test's own Arrange data. Notify user with: BID reference, change made, Gherkin step, Arrange values used. Route to Etch when derivation requires knowledge beyond these two sources. |
| 3. Genuinely wrong tests | Wrong interface, unrealistic fixture, mismatched assertion granularity | Escalate to user | Present proposed correction (APPROVE / REJECT). When approved, update `etch-map.yaml` when mappings changed. |

For Tier 2 corrections, implement the second-reader verification defined in [second-reader.md](../../automation/second-reader.md). Tier 3 (J-v): mechanical verification of formulaic patterns when the Gherkin step contains a recognized relationship and operands are available in the Arrange section.

### 5. `spec` domain fixer (Settle.Fix)

Implement a component whose behavior is gated on `auto_resolve_spec` in [pipeline config](../../artifacts/config.md):

- **When enabled:** Present reasonable default assumption; update Gherkin spec wording when needed; append resolution to `ascertainments.md` with `[AUTO-RESOLVED]` tag and rationale
- **When disabled (default):** Escalate to user for manual resolution

### 6. Provides hash tracker (Settle.Fix)

Implement a component that, after all fixes, compares each target subspec's `Provides:` content against the stored `provides_hash` in `pipeline-state.yaml`. When changed → set `rerun_scope.provides_changed: true`. This determines blast radius execution in the next loop.

### 7. Re-Inspect trigger (Settle.Confirm)

Implement a component that re-runs Inspect (reuse the Inspect stage implementation) after all fixes are applied, producing a new `verify_{timestamp}.md`.

### 8. Loop controller (Settle.Confirm)

Implement a component that handles the loop-or-complete decision:

**When zero Critical/High/Medium findings remain:** Set status to **COMPLETE**. Advance pipeline state via the Advance operation.

**When findings remain and a loop is needed:**
1. Increment `loop_count` in `pipeline-state.yaml`
2. Check against `settle_loops` config (default: 0). When the limit is reached, escalate to user — the Loop operation in [pipeline-state.md](../../automation/pipeline-state.md) rejects the loop.
3. Determine re-run scope:
   - `provides_changed: false` → only `target_subspecs` re-run at the target stage
   - `provides_changed: true` → `target_subspecs` + all `blast_radius` re-run
4. Reset affected subspecs to `pending` via the Scoped Loop operation; unaffected subspecs retain `passed`
5. Route by domain to the correct re-entry stage:
   - `domain: impl` → Realize
   - `domain: test` → Etch
   - `domain: spec` → Ascertain
   - Mixed domains → earliest required stage

Use the Loop operation from [pipeline-state.md](../../automation/pipeline-state.md) for the state transition. Valid loop targets: `ascertain`, `etch`, `realize`.

## Orchestration

**Sub-stage ordering:** Triage → Scope → Fix (impl + test + spec in any order) → Provides hash check → Confirm (re-Inspect → loop decision).

**At default config (all 0s, auto_resolve_spec false):** Every failure escalates to user immediately. No loops execute. Spec-domain findings always escalate.

## Scope boundaries

- `impl` fixes are scoped to production code only
- `test` fixes follow the three-tier policy — each fix traces to a specific tier
- `spec` fixes are gated on `auto_resolve_spec` config
- Settle creates new BIDs, subspecs, and test functions only through stage re-entry (Etch/Inscribe), within scope
- Finding severity classifications match the verify report — Settle processes each finding at its reported severity

## Criteria reference

[Settle correctness criteria](../criteria/settle.md)
