# 8. Settle

Refactor and resolve failures. Gate on completeness.

## Inputs

- Gherkin spec
- Constitution
- Implementation failure details

## Process

1. Locate the most recent `verify_{timestamp}.md`; parse Critical, High, and Medium findings only (skip Low and Nit)
2. Classify each finding by `resolution_domain` from the report:
   - **`domain: test`** → fix structural quality only (fixture dedup, assertion patterns, missing assertions; MUST NOT change behavioral contracts or test count)
   - **`domain: spec`** → resolve spec ambiguity (present reasonable default assumption; update Gherkin spec wording if needed)
   - **`domain: impl`** → apply targeted production code fixes (NEVER modify spec-driven test files; fix only the listed findings)
3. After all domain-specific fixes, re-run Inspect to confirm resolution

## Outputs

- If failures remain: back to Ascertain with Gherkin spec + failure details
- Otherwise: COMPLETE

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
- On completion with remaining failures: route back to Ascertain with Gherkin spec + failure details (see Outputs above)