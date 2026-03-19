# Changelog

## 2026-03-18

### Changed
- **Settle test-domain fix boundary** — three-tier policy replaces blanket "structural quality only": (1) structural refactors apply directly, (2) assertion-level corrections use a closed derivation scope (Gherkin Then/And step + test Arrange data) with user notification, (3) genuinely wrong tests escalate for approval. "Test count" clarified as function count; assertion count is a separate measure adjusted by tier 2.
- **Etch RED state confirmation** — structured diagnostic protocol for passing tests replaces "fix it" handwave. Three mechanical detections (existing import, default-value assertion, tautological assertion) with prescribed corrections. One correction pass, then escalate. Assertion corrections reuse the closed-derivation-scope principle.
- **Constructivist framing audit** — reframed ~30 prose negations across 15 files in `docs/` to constructive statements ("append-only" instead of "never overwritten", "are compatible" instead of "do not contradict", etc.). Gherkin BDD step language kept as-is.

## 2026-03-15

### Added
- **Primary spec and two-level spec hierarchy** — Inscribe now produces `primary.feature` (integration-level workflow scenarios) before decomposing into `{concern}.feature` subspecs (unit-level contracts)
- **ANLZ-006 composition validation** — new consistency check in Inscribe.Verify ensures subspecs collectively cover all primary spec scenarios with no unowned data transformations
- **`@traces` tags** — each primary spec scenario carries `@traces:BID-xxx,...` listing the subspec BIDs it traces through
- **Project artifact pre-check** — before any stage runs, the pipeline checks for `.haileris/project/` artifacts (standards, test-conventions, constitution) and generates missing ones
- **Ascertain assumption checkpoint** — when no ambiguities are found, Ascertain lists assumptions for user confirmation to prevent silent assumptions propagating
- **Inscribe three approval options** — Approve, Request changes (minor edits), Request changes (needs ascertainment)
- **Realize per-task map validation** — validates map entries immediately after each task completes (broken refs, missing BID mappings) before proceeding to the next task
- **Settle max 3 loops** — prevents infinite Settle loops; escalates to user after 3 cycles

### Changed
- **Spec files** moved from `.haileris/features/{id}/spec/` to `tests/features/` — feature files are permanent repo source artifacts, not pipeline intermediates
- **Project-wide artifacts** consolidated under `.haileris/project/` (was `.haileris/memory/` and `.haileris/constitution/`)
- **Constitution** — single path at `.haileris/project/constitution.md`; archive removed (git history handles versioning); no duplicate memory copy
- **Ascertain** — explicitly updates `decomposition.md` with resolved ambiguities (was implied but not called out)
- **Etch test placement** — distinguishes integration tests (`tests/integration/`) from unit tests (`tests/unit/`) based on primary vs subspec BIDs
