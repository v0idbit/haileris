# 8. Settle

Refactor and resolve failures. Gate on completeness.

## Inputs

- Gherkin spec
- Constitution
- Implementation failure details
- Etch map (`etch-map.yaml`) — BID → test function mapping from Etch
- Realize map (`realize-map.yaml`) — BID → derivation mapping from Realize

## Process

`Settle.Triage → Settle.Scope → Settle.Fix → Settle.Confirm`

### Settle.Triage

1. Locate the most recent `verify_{timestamp}.md`; parse Critical, High, and Medium findings only (skip Low and Nit)
2. For each finding, identify the owning subspec via BID → subspec mapping (etch-map.yaml or realize-map.yaml)
3. Group findings by owning subspec

### Settle.Scope

1. Regenerate `delivery-order.yaml` from current subspec `Requires:` and `Provides:` declarations.
2. From grouped findings, identify `target_subspecs` — subspecs owning failing BIDs.
3. Compute `blast_radius` — downstream dependents of target subspecs. Walk the dependency graph transitively: if C requires B which requires target A, both B and C are in the blast radius.
4. Write `rerun_scope` to `pipeline-state.yaml`: `target_subspecs`, `blast_radius`, `provides_changed: false`.
5. `_integration` is always included in the re-run scope.

### Settle.Fix

1. Classify each finding by `resolution_domain` from the report:
   - **`domain: test`** → three tiers of test-domain fixes, each with different authority:
     1. **Structural refactors** — changes to *how* a test is written that preserve what it verifies: deduplicating fixtures, reorganizing setup, changing assertion style. Apply directly.
     2. **Assertion-level corrections** — adding a missing assertion or correcting a wrong expected value. The derivation scope is **closed**: use only (a) the BID's Gherkin Then/And step and (b) the test's own Arrange section (fixture data written by Etch). Derive the expected value by applying the relationship stated in the Gherkin step to the concrete data in the Arrange section. **Verification test:** a second reader, given the same step and Arrange data, independently arrives at the same assertion. Apply the fix and **notify the user** with: the BID reference, the change made, the Gherkin step, and the Arrange values used in the derivation. Route to Etch for regeneration when the derivation requires knowledge beyond these two sources.
     3. **Genuinely wrong tests** (wrong interface, unrealistic fixture, mismatched assertion granularity) — escalate to user with a proposed correction (APPROVE / REJECT).
   - **`domain: spec`** → resolve spec ambiguity (present reasonable default assumption; update Gherkin spec wording if needed); append the resolution to `ascertainments.md` with an `[AUTO-RESOLVED]` tag and rationale
   - **`domain: impl`** → apply targeted production code fixes (test files are read-only; fix only the listed findings in production code)
2. After all fixes, check whether any target subspec's `Provides:` line changed compared to the stored `provides_hash`. If changed, set `rerun_scope.provides_changed` to `true`.

### Settle.Confirm

1. After all domain-specific fixes, re-run Inspect to confirm resolution.
2. If failures remain and a loop is needed:
   a. If `provides_changed` is `false`: only `target_subspecs` re-run at the target stage; `blast_radius` subspecs are skipped.
   b. If `provides_changed` is `true`: `target_subspecs` and all `blast_radius` subspecs re-run.
   c. In `pipeline-state.yaml`, reset only the affected subspecs to `pending`. Unaffected subspecs retain `passed`.
3. Route by domain as before, but execution at the target stage is scoped to the identified subspecs.

## Outputs

- If failures remain after re-Inspect, route by domain of remaining findings:
  - **`domain: impl`** → loop to **Realize** (scoped: only affected subspecs and blast radius)
  - **`domain: test`** → loop to **Etch** (scoped: only affected subspecs and blast radius)
  - **`domain: spec`** → loop to **Ascertain** (full re-run from Ascertain; Layout regenerates delivery-order)
  - **Mixed domains** → loop to earliest required stage; scoping applies to Etch/Realize targets
- If no failures remain: **COMPLETE**

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Green-phase implementation (updated) | `src/` (repo) | Updated by domain:impl fixes |
| Test files (updated) | `tests/` (repo) | Updated by three-tier test-domain fix policy (structural refactors, assertion corrections, genuinely wrong test fixes) |
| Gherkin spec (updated) | `tests/features/*.feature` | Updated by domain:spec auto-resolve; append resolution to ascertainments |
| Etch map (updated) | `.haileris/features/{feature_id}/etch-map.yaml` | Updated if genuinely wrong test fixes change mappings |
| Ascertainments (appended) | `.haileris/features/{feature_id}/ascertainments.md` | Auto-resolved spec findings appended with [AUTO-RESOLVED] tag |

## Finding Severity Handling

| Severity | Is Failure? |
|----------|---------------------|
| Critical | Yes |
| High | Yes |
| Medium | Yes |
| Low | No — informational only |
| Nit | No — informational only |

## Notes

- "Test count" refers to test functions; assertion count is a separate measure. Structural refactors preserve test function names and count; run tests before and after — results must be identical. Assertion-level corrections (tier 2) add assertions within existing functions or correct expected values; they preserve the set of test functions.
- **Genuinely wrong tests** (wrong interface, unrealistic fixture, assertion that mismatches the actual API): escalate to user with a proposed one-line or localized correction (APPROVE / REJECT). If approved, apply the fix and update `etch-map.yaml` if mappings changed. This keeps the pipeline moving for minor test defects that are independent of the spec.
- On completion with remaining failures: route to the earliest stage required by domain of remaining findings (see Outputs above). This targets re-runs to the stage that can resolve the finding.
- **Max 3 Settle loops.** If findings remain after 3 cycles (tracked by `loop_count` in `pipeline-state.yaml`), stop looping and escalate to the user with the unresolved findings. The user decides whether to continue, restructure, or abort.