# 3. Inscribe

Create the primary spec from the improved decomposition.

## Inputs

- Improved decomposition
- Ascertainments
- Constitution

## Process

### Inscribe.Author

1. Write `primary.feature` — end-to-end workflow scenarios covering the feature's observable behavior. Each scenario gets a BID tag.
2. Read constitution if present; flag constitution violations.
3. Write `primary.feature` to `tests/features/`.

### Inscribe.Verify

1. Run read-only consistency checks (ANLZ-001..002)

#### Consistency Checks (ANLZ-001..002)

| ID | Check |
|----|-------|
| ANLZ-001 | All behaviors are mutually consistent |
| ANLZ-002 | All behaviors comply with project standards |

If any check returns FAIL: show which checks failed; ask user to fix or proceed anyway.

##### ANLZ-001: Contradiction Detection

Extract logical propositions (preconditions, actions, expected outcomes) from each BID's Gherkin steps. Check whether all propositions are mutually satisfiable. Conflicting BIDs = FAIL.

Implementation may use an SMT solver (e.g., Z3): the agent translates Gherkin steps into typed constraints, the solver checks satisfiability, and conflicts are reported as BID pairs with the contradicting constraints. This is optional — LLM-only contradiction detection is acceptable, but a solver provides mechanical verification.

##### ANLZ-002: Standards Compliance

Extract rules from `standards.md` and compare each BID's Gherkin steps against them. A step that asserts behavior contradicting a project standard = FAIL.

If `standards.md` uses structured rules (e.g., rule + scope pairs), comparison can be mechanical — match Then-step assertions against rule scopes. For free-form prose standards, the agent extracts structured rules first, then checks. The extraction is judgment; the comparison is mechanical.

### Inscribe.Approve

1. Present primary spec + consistency check results to user; wait for user gate:
   - **Approve** — set `status: approved`; proceed to Layout
   - **Request changes (minor edits)** — apply edits in place within Inscribe; re-run Inscribe.Verify; present again
   - **Request changes (needs ascertainment)** — set `status: ascertaining`; return to Ascertain with the user's feedback

## Outputs

- Primary spec
  - End-to-end workflow scenarios with BIDs

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Primary spec | `tests/features/primary.feature` | Integration-level workflow scenarios |

## Notes

- BID format: `BID-{NNN}` (sequentially numbered, e.g. `BID-001`)
- Gherkin spec status lifecycle: `inscribing` → `ascertaining` (if markers exist) → `approved` (after user gate)
- `tests/features/` is the canonical location for `primary.feature` — Layout and downstream stages read it. Read-only after user approval
- Constitution violations are always **Critical** severity
- Gherkin spec types: `greenfield` (all new), `modification` (unchanged / modified / new sections), `refactor` (behaviors are preserved)
