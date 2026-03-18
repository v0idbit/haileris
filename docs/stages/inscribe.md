# 3. Inscribe

Create the Gherkin spec from the improved decomposition.

## Inputs

- Improved decomposition
- Constitution

## Process

### Inscribe.Author

1. Write `primary.feature` — end-to-end workflow scenarios covering the feature's observable behavior. Each scenario gets a BID tag and a `@traces` tag listing the subspec BIDs it will trace through.
2. Decompose into deliverable subspecs (`{deliverable}.feature`) — unit-level behavioral contracts. Each subspec scenario gets a BID tag.
3. If a primary scenario requires behavior that falls outside existing subspecs, add a BID to the appropriate subspec. The primary spec drives what BIDs must exist in subspecs.
4. Read constitution if present; flag constitution violations.
5. Write all feature files to `tests/features/`.

### Inscribe.Verify

1. Run read-only consistency checks (ANLZ-001..004)

#### Consistency Checks (ANLZ-001..004)

| ID | Check |
|----|-------|
| ANLZ-001 | All behaviors are mutually consistent |
| ANLZ-002 | All behaviors comply with project standards |
| ANLZ-003 | Integration behaviors reference domains listed in the Gherkin spec |
| ANLZ-004 | Subspecs compose into primary spec — every primary scenario's Given/When/Then steps are collectively covered by subspec BIDs (every effect is owned) |

If any check returns FAIL: show which checks failed; ask user to fix or proceed anyway.

##### ANLZ-001: Contradiction Detection

Extract logical propositions (preconditions, actions, expected outcomes) from each BID's Gherkin steps. Check whether all propositions are mutually satisfiable. Conflicting BIDs = FAIL.

Implementation may use an SMT solver (e.g., Z3): the agent translates Gherkin steps into typed constraints, the solver checks satisfiability, and conflicts are reported as BID pairs with the contradicting constraints. This is optional — LLM-only contradiction detection is acceptable, but a solver provides mechanical verification.

##### ANLZ-002: Standards Compliance

Extract rules from `standards.md` and compare each BID's Gherkin steps against them. A step that asserts behavior contradicting a project standard = FAIL.

If `standards.md` uses structured rules (e.g., rule + scope pairs), comparison can be mechanical — match Then-step assertions against rule scopes. For free-form prose standards, the agent extracts structured rules first, then checks. The extraction is judgment; the comparison is mechanical.

##### ANLZ-003: Domain Coverage

Fully mechanical. Parsing and set operations only.

1. Parse each subspec's `Domains:` line → set of declared domain paths per subspec. A subspec with no `Domains:` line = FAIL.
2. Parse each primary scenario's `@traces` tag → set of referenced subspec BIDs.
3. Resolve each referenced BID to its parent subspec file.
4. Collect the declared domains from those parent subspecs.
5. Verify every referenced subspec has declared domains. A primary scenario tracing through a subspec with no `Domains:` declaration = FAIL.

##### ANLZ-004: Composition Validation

For each primary spec scenario:
1. Verify the scenario has a `@traces` tag listing subspec BIDs
2. Verify all referenced BIDs exist in subspecs
3. Identify the effects required by the scenario's steps. An effect is any observable consequence of a step: state created, state changed, data passed between deliverables, or output produced. Only steps that produce observable consequences count as effects; Given preconditions restating already-covered state are context, and context is excluded.
4. Verify each effect is covered by a referenced subspec BID

Every effect must have a covering subspec BID. An uncovered effect = gap. On FAIL: show which primary scenarios have uncovered steps.

### Inscribe.Approve

1. Present Gherkin spec + consistency check results to user; wait for user gate:
   - **Approve** — set `status: approved`; proceed to Layout
   - **Request changes (minor edits)** — apply edits in place within Inscribe; re-run Inscribe.Verify; present again
   - **Request changes (needs ascertainment)** — set `status: ascertaining`; return to Ascertain with the user's feedback

## Outputs

- Primary spec
  - End-to-end workflow scenarios (BIDs with `@traces` tags)
- Gherkin subspecs
  - Per-deliverable behavioral scenarios (BIDs)
  - Delivery details per BID as needed
- Technical details
  - Common details across BIDs
  - Per BID details as needed

## Artifacts Written

| Artifact | Path | Notes |
|----------|------|-------|
| Primary spec | `tests/features/primary.feature` | Integration-level workflow scenarios; drives subspec completeness |
| Gherkin subspecs | `tests/features/{deliverable}.feature` | Unit-level behavioral contracts; must compose into primary spec |

## Notes

- BID format: `BID-{NNN}` (sequentially numbered, e.g. `BID-001`)
- Gherkin spec status lifecycle: `inscribing` → `ascertaining` (if markers exist) → `approved` (after user gate)
- Authoring order: primary spec first, then subspecs — the primary spec drives what BIDs must exist
- `@traces` tag format: `@traces:BID-003,BID-015,BID-024` — lists subspec BIDs the integration scenario traces through
- `tests/features/` is the canonical location for all `.feature` files — every downstream stage reads them. Read-only after user approval
- Constitution violations are always **Critical** severity
- Gherkin spec types: `greenfield` (all new), `modification` (unchanged / modified / new sections), `refactor` (behaviors are preserved)
