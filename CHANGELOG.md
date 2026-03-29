# Changelog

## 2026-03-28

### Added
- **Greenfield implementation guide** — `docs/implementation/greenfield.md` (index) + `docs/implementation/construction/` (per-stage construction specs). Describes the three implementation layers (agent logic, mechanical verification, orchestration), cross-cutting foundations to build first, and per-stage component lists with automation spec references and tier classifications. Form-agnostic: constrains behavior, not architecture.
- **Brownfield implementation guide** — `docs/implementation/brownfield.md`. Audit-and-fix workflow for existing implementations: audit foundations first, then stages in pipeline order, then mechanical checks by tier. Includes triage decision tree and names the `@traces` deadlock pattern explicitly.
- **Etch creates source stubs** — Etch generates source modules at `src/` (via `Domains:` paths) alongside tests. Stubs contain data contract type definitions (fully specified, reused in test fixtures) and function/method signatures with placeholder bodies. Realize implements within these stubs rather than creating source from scratch.
- **Implementation criteria** — per-stage correctness criteria in `docs/implementation/criteria/` defining input manifests, read/write scope, behavioral constraints, and exit checks for each pipeline stage. Foundation for greenfield and brownfield implementation guides.
- **Pipeline config** — new project-wide config file at `.haileris/project/config.{ext}` controlling retry limits (`realize_retries`, `settle_loops`, `etch_corrections`, `inspection_fixes`) and auto-resolution behavior (`auto_resolve_spec`). All retry limits default to 0, auto-resolution defaults to false — escalate to user immediately. Format left to implementation.

### Changed
- **RED state semantics** — tests fail on assertions against stub placeholder returns (imports resolve immediately since stubs exist). RED diagnostic protocol handles passing tests via assertion correction only; import-based diagnostics are retired.
- **Realize implements within stubs** — Realize reads Etch stubs as fixed input and replaces placeholder bodies with behavioral implementations. Stub signatures and type definitions are read-only from Etch forward. Realize may add private helpers; the public interface is fixed by Etch.
- **ANLZ-007 scope expanded** — data contract compliance checks both test function signatures and source stub signatures for bare generics
- **Subspec execution model relaxed** — Etch/Realize execution per subspec respects dependency edges (`Requires:`) as the correctness requirement. Independent subspecs (no dependency path between them) may execute concurrently. Sequential execution remains a valid default strategy.
- **Feature-scoped spec directories** — spec files moved from flat `tests/features/` to `tests/features/{feature_id}/`, preventing filename collisions when the pipeline runs multiple times on the same project. Each feature's primary spec and subspecs live in their own directory, mirroring the `.haileris/features/{feature_id}/` scoping of pipeline metadata.

## 2026-03-22

### Added
- **Interface contracts on subspecs** — subspecs now carry `Requires:` and `Provides:` metadata alongside `Domains:`, declaring the data contracts between subspecs; Layout.Verify validates that every `Requires:` entry is satisfied by a corresponding `Provides:` entry
- **ANLZ-005 interface contract check** — new mechanical check at Layout.Verify: verifies that all inter-subspec `Requires:`/`Provides:` pairs are consistent (no unsatisfied requirement, no declaration mismatch)
- **`_integration` pseudo-subspec** — a reserved subspec entry in `delivery-order.yaml` that groups cross-cutting integration scenarios not owned by any single delivery subspec; Etch uses it to place integration-level tests
- **Per-subspec status tracking in pipeline-state** — `pipeline-state.yaml` now records pass/fail status per subspec so Settle can identify exactly which subspecs need re-processing

### Changed
- **`delivery-order.yaml` is a derived (compiled) artifact** — the delivery order is compiled from subspec `Requires:`/`Provides:` declarations at Layout.Decompose rather than hand-authored; the file reflects the resolved dependency ordering
- **Subspec-scoped re-runs at Settle** — Settle re-runs target only the failing subspec(s) and their downstream dependents (determined via `delivery-order.yaml` dependency edges), leaving passing subspecs untouched

## 2026-03-19

### Fixed
- **Cross-reference coherence across docs/** — added missing Technical Details edges to Etch and Realize in artifact creation diagram; added Delivery Order as Layout output; distinguished constraint-gated (†) from agent-evaluated (*) footnotes in inspection-reports.md and diagrams.md; corrected Tier 1 heading overclaim in automation/README.md; aligned harvest.md artifacts table with pipeline.md TD input listings

### Changed
- **Subspec creation moved from Inscribe to Layout** — Inscribe now produces only the primary spec (`primary.feature`); Layout decomposes it into ordered delivery subspecs (`{deliverable}.feature`), adds `@traces` tags, and validates composition (ANLZ-003, ANLZ-004)
- **Task concept eliminated** — `tasks.md` with `TASK-{NNN}` identifiers replaced by `delivery-order.yaml` listing subspecs in implementation order with dependency edges; subspecs are identified by filename
- **Layout gains sub-stages** — Layout.Decompose → Layout.Verify → Layout.Approve, mirroring Inscribe's pattern
- **`@traces` tags authored by Layout** — primary spec scenarios receive `@traces` tags after subspec creation, when the referenced BIDs exist
- **Realize map field changes** — `tasks_completed`/`tasks_total` → `subspecs_completed`/`subspecs_total`; per-BID `tasks: [TASK-1]` → `subspec: "users.feature"`

## 2026-03-18

### Changed
- **Settle test-domain fix boundary** — three-tier policy replaces blanket "structural quality only": (1) structural refactors apply directly, (2) assertion-level corrections use a closed derivation scope (Gherkin Then/And step + test Arrange data) with user notification, (3) genuinely wrong tests escalate for approval. "Test count" clarified as function count; assertion count is a separate measure adjusted by tier 2.
- **Etch RED state confirmation** — structured diagnostic protocol for passing tests replaces "fix it" handwave. Three mechanical detections (existing import, default-value assertion, tautological assertion) with prescribed corrections. One correction pass, then escalate. Assertion corrections reuse the closed-derivation-scope principle.
- **Constructivist framing audit** — reframed ~30 prose negations across 15 files in `docs/` to constructive statements ("append-only" instead of "never overwritten", "are compatible" instead of "do not contradict", etc.). Gherkin BDD step language kept as-is.

## 2026-03-15

### Added
- **Primary spec and two-level spec hierarchy** — Inscribe now produces `primary.feature` (integration-level workflow scenarios) before decomposing into `{concern}.feature` subspecs (unit-level contracts)
- **ANLZ-004 composition validation** — new consistency check in Inscribe.Verify ensures subspecs collectively cover all primary spec scenarios with no unowned data transformations
- **`@traces` tags** — each primary spec scenario carries `@traces:BID-xxx,...` listing the subspec BIDs it traces through
- **Project artifact pre-check** — before any stage runs, the pipeline checks for `.haileris/project/` artifacts (standards, test-conventions, constitution) and generates missing ones
- **Ascertain assumption checkpoint** — when no ambiguities are found, Ascertain lists assumptions for user confirmation to prevent silent assumptions propagating
- **Inscribe three approval options** — Approve, Request changes (minor edits), Request changes (needs ascertainment)
- **Realize per-subspec map validation** — validates map entries immediately after each subspec completes (broken refs, missing BID mappings) before proceeding to the next subspec
- **Settle max 3 loops** — prevents infinite Settle loops; escalates to user after 3 cycles

### Changed
- **Spec files** moved from `.haileris/features/{id}/spec/` to `tests/features/` — feature files are permanent repo source artifacts, not pipeline intermediates
- **Project-wide artifacts** consolidated under `.haileris/project/` (was `.haileris/memory/` and `.haileris/constitution/`)
- **Constitution** — single path at `.haileris/project/constitution.md`; archive removed (git history handles versioning); no duplicate memory copy
- **Ascertain** — explicitly updates `decomposition.md` with resolved ambiguities (was implied but not called out)
- **Etch test placement** — distinguishes integration tests (`tests/integration/`) from unit tests (`tests/unit/`) based on primary vs subspec BIDs
