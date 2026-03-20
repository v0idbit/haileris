# 8. Settle

Refactor and resolve failures. Gate on completeness.

## Inputs

- Gherkin spec
- Constitution
- Implementation failure details

## Process

### Settle.Triage

1. Locate the most recent `verify_{timestamp}.md`; parse Critical, High, and Medium findings only (skip Low and Nit)

### Settle.Fix

1. Classify each finding by `resolution_domain` from the report:
   - **`domain: test`** → three tiers of test-domain fixes, each with different authority:
     1. **Structural refactors** — changes to *how* a test is written that preserve what it verifies: deduplicating fixtures, reorganizing setup, changing assertion style. Apply directly.
     2. **Assertion-level corrections** — adding a missing assertion or correcting a wrong expected value. The derivation scope is **closed**: use only (a) the BID's Gherkin Then/And step and (b) the test's own Arrange section (fixture data written by Etch). Derive the expected value by applying the relationship stated in the Gherkin step to the concrete data in the Arrange section. **Verification test:** a second reader, given the same step and Arrange data, independently arrives at the same assertion. Apply the fix and **notify the user** with: the BID reference, the change made, the Gherkin step, and the Arrange values used in the derivation. Route to Etch for regeneration when the derivation requires knowledge beyond these two sources.
     3. **Genuinely wrong tests** (wrong interface, unrealistic fixture, mismatched assertion granularity) — escalate to user with a proposed correction (APPROVE / REJECT).
   - **`domain: spec`** → resolve spec ambiguity (present reasonable default assumption; update Gherkin spec wording if needed); append the resolution to `ascertainments.md` with an `[AUTO-RESOLVED]` tag and rationale
   - **`domain: impl`** → apply targeted production code fixes (test files are read-only; fix only the listed findings in production code)

### Settle.Confirm

1. After all domain-specific fixes, re-run Inspect to confirm resolution

## Outputs

- If failures remain after re-Inspect, route by domain of remaining findings:
  - **`domain: impl`** → loop to **Realize** (re-implement against existing tests; skip Ascertain/Inscribe/Layout/Etch)
  - **`domain: test`** → loop to **Etch** (regenerate tests for affected BIDs; then Realize)
  - **`domain: spec`** → loop to **Ascertain** (spec needs clarification; full downstream re-run)
  - **Mixed domains** → loop to the earliest required stage (spec → Ascertain, test → Etch, impl → Realize)
- If no failures remain: **COMPLETE**

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Green-phase implementation (updated) | `src/` (repo) | Updated by domain:impl fixes |
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