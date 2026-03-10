# 8. Settle

Refactor and resolve failures. Gate on completeness.

## Inputs

- Gherkin spec
- Constitution
- Implementation failure details

## Process

1. Locate the most recent `verify_{timestamp}.md`; parse Critical, High, and Medium findings only (skip Low and Nit)
2. Classify each finding by `resolution_domain` from the report:
   - **`domain: test`** → fix structural quality only (fixture dedup, assertion patterns, missing assertions; MUST NOT change behavioral contracts or test count). If a test is genuinely wrong (wrong interface, unrealistic fixture, mismatched assertion granularity), escalate to user with a proposed correction rather than forcing a full spec loop.
   - **`domain: spec`** → resolve spec ambiguity (present reasonable default assumption; update Gherkin spec wording if needed)
   - **`domain: impl`** → apply targeted production code fixes (NEVER modify spec-driven test files; fix only the listed findings)
3. After all domain-specific fixes, re-run Inspect to confirm resolution

## Outputs

- If failures remain after re-Inspect, route by domain of remaining findings:
  - **`domain: impl`** → loop to **Realize** (re-implement against existing tests; skip Ascertain/Inscribe/Layout/Etch)
  - **`domain: test`** → loop to **Etch** (regenerate tests for affected BIDs; then Realize)
  - **`domain: spec`** → loop to **Ascertain** (spec needs clarification; full downstream re-run)
  - **Mixed domains** → loop to the earliest required stage (spec → Ascertain, test → Etch, impl → Realize)
- If no failures remain: **COMPLETE**

## Finding Severity Handling

| Severity | Is Failure? |
|----------|---------------------|
| Critical | Yes |
| High | Yes |
| Medium | Yes |
| Low | No — informational only |
| Nit | No — informational only |

## Notes

- Test quality fixes must not add, remove, or rename test functions; run tests before and after — results must be identical (except for additions from missing-assertion fixes)
- **Genuinely wrong tests** (wrong interface, unrealistic fixture, assertion that doesn't match the actual API): escalate to user with a proposed one-line or localized correction. If approved, apply the fix and update `etch-map.yaml` if mappings changed. This avoids a full pipeline re-run for minor test defects that don't indicate a spec problem.
- On completion with remaining failures: route to the earliest stage required by domain of remaining findings (see Outputs above). This avoids wasteful full-pipeline re-runs for findings that don't require spec changes.