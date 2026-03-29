# Realize — Correctness Criteria

## Input Manifest

### Available at Realize entry (per subspec)

| Artifact | Path | Source |
|----------|------|--------|
| Gherkin subspec (current) | `tests/features/{feature_id}/{deliverable}.feature` | Written by Layout |
| Red-phase tests for this subspec | `tests/unit/` (subspec BIDs) | Written by Etch |
| Source stubs for this subspec | `src/` at `Domains:` paths | Written by Etch |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | Written by Etch |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Written by Harvest |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |
| Pipeline config (when present) | `.haileris/project/config.{ext}` | Project-wide; governs `realize_retries` |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Shows `etch: running` |
| Prior subspec implementations (when current subspec has upstream dependencies) | `src/` paths from earlier Realize passes | Available for subsequences after the first |

### Artifacts created by this stage

| Artifact | Path | Sub-stage |
|----------|------|-----------|
| Implemented source code (within stubs) | `src/` at `Domains:` paths | Per-subspec pass |
| Realize map entries | `.haileris/features/{feature_id}/realize-map.yaml` | Per-subspec pass (incremental) |
| Realize inspection | `.haileris/features/{feature_id}/realize-inspection.yaml` | After all subspecs complete |

### Read scope

Realize reads the current subspec's `.feature` file (for BIDs, `Domains:`, `Provides:` contract), red-phase tests (source of truth for what must pass), source stubs (the structure and contracts to implement within), `etch-map.yaml` (BID → test mapping), `technical-details.md` (project conventions, dependency APIs), `constitution.md` (violation checks), and upstream subspec implementations (when the current subspec has `Requires:` dependencies).

### Write scope

Realize writes to `src/` (implementing within Etch's stubs) and `.haileris/features/{feature_id}/` (realize-map, realize-inspection). Test files and stub signatures are read-only from Etch forward — Realize reads them as fixed inputs.

## Behavioral Constraints

### Implement within stubs

Etch provides source stubs with data contract type definitions and function signatures. Realize fills in the implementations — replacing placeholder bodies with behavioral code that makes tests pass. The module structure, type definitions, and function signatures are already established by Etch. Realize works within this structure.

Realize may add private helper functions, internal methods, and supporting logic as needed to implement the behavior. The public interface (signatures, types, module paths) is defined by the stubs.

### Test files and stubs are read-only

From Etch forward, test files are fixed inputs. Stub signatures (function names, parameter types, return types, data contract type definitions) are also fixed — Realize implements within them. When tests fail, Realize adjusts its implementation logic. (Settle has a controlled three-tier fix policy for test-domain findings, but that is Settle's responsibility.)

### Source module placement

Source modules are already in place at the `Domains:` paths — Etch created them as stubs. Realize implements within these existing modules. The shared import contract with Etch is satisfied by the stubs from the start.

### `Provides:` contract

The subspec's `Provides:` metadata defines the output contract this implementation satisfies. The data contract types are already defined in the stubs. Realize ensures the behavioral implementation correctly produces and consumes data through these contracts. Downstream subspecs `Requires:` this contract.

### Retry policy

Up to `realize_retries` cycles per subspec (see [pipeline config](../../artifacts/config.md); default: 0). When retries are exhausted, escalate to user. At default (0), every failure escalates immediately.

### Re-entry behavior (Settle loop)

1. Read `rerun_scope` from `pipeline-state.yaml`
2. Preserve realize-map entries and implementation for subspecs outside the re-run scope
3. Re-run for in-scope subspecs — new realize-map entries replace old (merge semantics)
4. After each subspec completes, update `provides_hash` in `subspec_statuses`. When the hash changed → set `provides_changed: true` (triggers downstream re-runs)
5. `_integration` always re-runs

## Sub-stage Ordering

Realize executes per subspec, respecting dependency edges. A subspec's Realize pass runs only after all subspecs it `Requires:` have completed Realize. Independent subspecs may run concurrently; sequential is a valid default.

1. **Per subspec (respecting dependency order):**
   a. Implement behavioral code within Etch's stubs — replace placeholder bodies with production logic
   b. When tests fail: analyze, retry (up to `realize_retries`), or escalate
   c. After tests pass: write BID → derivation entries to `realize-map.yaml`
   d. Validate map entries for this subspec (every derivation exists, every BID mapped)
2. **After all subspecs complete:**
   a. Run full test suite to confirm GREEN state
   b. Validate full realize-map; write `realize-inspection.yaml`

## Exit Checks

### Artifact existence

- [ ] Source code at `src/` paths matching `Domains:` declarations contains implemented behavior (stub placeholders replaced)
- [ ] `realize-map.yaml` exists at `.haileris/features/{feature_id}/realize-map.yaml`
- [ ] `realize-inspection.yaml` exists at `.haileris/features/{feature_id}/realize-inspection.yaml`

### GREEN state

- [ ] All subspec tests pass (unit tests)
- [ ] All primary BID tests pass (integration tests)
- [ ] Full test suite is GREEN

### Map integrity

- [ ] Every Gherkin spec BID has at least one derivation entry in `realize-map.yaml` (Completeness)
- [ ] Every derivation discovered by static analysis appears in the map (Scope/AST)
- [ ] Every derivation in the map resolves to an existing source entity (Broken refs)
- [ ] `subspecs_completed` equals `subspecs_total`

### Contract compliance

- [ ] Source modules are importable at `Domains:` paths (shared import contract with Etch — satisfied by stubs from the start)
- [ ] Each subspec's implementation satisfies its `Provides:` contract through the data contract types defined in stubs
- [ ] `provides_hash` is recorded in `subspec_statuses` for each completed subspec

### Boundary discipline

- [ ] Realize's write scope is `src/` (within stub structure) and `.haileris/features/{feature_id}/`
- [ ] Test files are untouched — read-only from Etch forward
- [ ] Stub signatures (function names, parameter types, return types, data contract types) are preserved — Realize implements within them
- [ ] Gherkin spec files are untouched
- [ ] Etch-map, delivery order, and upstream artifacts are untouched
