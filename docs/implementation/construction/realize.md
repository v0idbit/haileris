# Realize — Greenfield Construction

## Stage inputs (per subspec)

| Artifact | Path | Source |
|----------|------|--------|
| Current subspec | `tests/features/{feature_id}/{deliverable}.feature` | Layout |
| Red-phase tests | `tests/unit/` (subspec BIDs) | Etch |
| Source stubs | `src/` at `Domains:` paths | Etch |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | Etch |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Harvest |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |
| Pipeline config (when present) | `.haileris/project/config.{ext}` | Governs `realize_retries` |
| Prior subspec implementations | `src/` from earlier Realize passes | Available after the first subspec cycle |

## Stage outputs

| Artifact | Path |
|----------|------|
| Implemented source code | `src/` at `Domains:` paths (within Etch's stubs) |
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` |
| Realize inspection | `.haileris/features/{feature_id}/realize-inspection.yaml` |

## Subspec execution model

Same dependency-edge pattern as Etch. A subspec enters Realize after its Etch pass and after all upstream Realize passes complete. Independent subspecs may run concurrently; sequential is a valid default. Reuse or share the subspec execution controller with Etch.

## Components to implement (per subspec)

### 1. Stub implementer

Implement a component that replaces placeholder bodies in Etch's source stubs with production logic that makes the subspec's tests pass.

Constraints the implementation must enforce:
- **Gherkin spec = intent, tests = source of truth**
- Test files and stub signatures are read-only from Etch forward
- The public interface (function names, parameter types, return types, data contract types, module paths) is fixed by Etch
- The implementation may add private helper functions and internal logic as needed
- The subspec's `Provides:` metadata defines the output contract — downstream subspecs `Requires:` this contract

### 2. Test runner with retry

Implement a component that runs the subspec's tests and handles failures:
- On failure: analyze root cause, adjust implementation logic, retry
- Retry up to `realize_retries` cycles (read from pipeline config; default: 0)
- When retries are exhausted: escalate to user with failure details

### 3. Realize-map writer

Implement a component that, after tests pass, writes BID → derivation entries to `realize-map.yaml`:

```yaml
BID-001:
  derivations:
    - src/module#MyClass.my_method
  subspec: "users.feature"
```

When processing multiple subspecs, the writer appends entries — implement merge semantics that preserve existing entries from prior subspec passes.

### 4. Per-subspec map validator

Implement a component that validates map entries immediately after each subspec completes:
- Every mapped derivation resolves to an existing source entity
- Every BID in the subspec has at least one derivation entry

Fix or escalate before proceeding to the next subspec.

### 5. Provides hash recorder

Implement a component that, after each subspec completes, computes and records a hash of the subspec's `Provides:` content in `pipeline-state.yaml` via the Subspec Advance operation ([pipeline-state.md](../../automation/pipeline-state.md)). This hash is used by Settle's scope calculator for blast-radius determination on re-entry.

## Post-completion components (after all subspecs)

### 6. Full suite runner

Implement a component that runs the complete test suite (unit + integration) after all subspecs complete. All tests must pass (GREEN state). Failures at this point indicate cross-subspec integration issues.

### 7. Realize inspection

Implement the 3-dimension validation defined in [realize-inspection.md](../../automation/realize-inspection.md):

| Check | Tier | Algorithm |
|-------|------|-----------|
| Completeness | 1 (M) | Every spec BID has ≥1 derivation in the realize-map |
| Broken refs | 1 (M) | Every derivation resolves to an existing source entity |
| Scope | 2 (M-c) | AST-based discovery of all derivations; unmapped derivations = SCOPE_CREEP. Defined in [realize-scope.md](../../automation/realize-scope.md). SKIP when AST tooling is unavailable. |

Output conforms to the [inspection report schema](../../artifacts/inspection-reports.md).

## Orchestration

**Per subspec:** Implement within stubs → Run tests (with retry) → Write realize-map → Validate map → Record provides hash.

**After all subspecs:** Full suite runner → Realize inspection → advance pipeline state to Inspect.

## Scope boundaries

- Realize writes to `src/` (within stub structure) and `.haileris/features/{feature_id}/`
- Test files are read-only from Etch forward
- Stub signatures (function names, parameter types, return types, data contract types) are preserved — Realize implements within them
- Gherkin spec files, etch-map, and delivery order are untouched

## Criteria reference

[Realize correctness criteria](../criteria/realize.md)
