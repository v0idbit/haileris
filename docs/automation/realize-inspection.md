# Realize Inspection

Validates the implementation map after all tasks complete. Source: [realize.md](../stages/realize.md) (Realize Inspection table).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Gherkin spec files | `tests/features/*.feature` | Gherkin with `@BID-NNN` tags |
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` | YAML per [realize-map.md](../artifacts/realize-map.md) |
| Source files | Referenced by realize-map derivations | Source code files |

### Realize Map Structure

```yaml
feature_id: "{feature_id}"
tasks_completed: 3
tasks_total: 3
bids:
  BID-001:
    derivations:
      - src/module#MyClass.my_method
    tasks: [TASK-1]
  BID-002:
    derivations:
      - src/module#function_name
    tasks: [TASK-2]
```

### Derivation Format

- Class method: `src/module#ClassName.method_name`
- Module-level function: `src/module#function_name`

The `#` separator delimits the file path from the derivation name.

## Checks

### 1. Completeness

Every Gherkin spec BID has at least one derivation entry in the realize-map.

```
FUNCTION check_completeness(spec_bids, map_bids):
  missing ← spec_bids − map_bids

  FOR EACH bid IN sorted(missing):
    ADD finding(bid, check_type="MISSING",
                detail="{bid} has no derivation in realize-map")

  RETURN PASS if missing is empty, FAIL otherwise
```

### 2. Broken Refs

Every derivation in the realize-map resolves to an existing source entity.

```
FUNCTION check_broken_refs(realize_map_data, project_root):
  FOR EACH (bid, entry) IN realize_map_data.bids:
    IF bid does not match "^BID-\d+$":
      CONTINUE

    FOR EACH ref IN entry.derivations:
      IF "#" NOT IN ref:
        ADD finding(bid, check_type="BROKEN_REF",
                    detail="{bid} derivation '{ref}' has invalid format (missing #)")
        CONTINUE

      (file_part, entity_part) ← split ref at last "#"
      file_path ← resolve(project_root, file_part)
      — Append language-appropriate extension if file_path has none

      IF file_path does not exist:
        ADD finding(bid, check_type="BROKEN_REF",
                    detail="{bid} derivation file not found: {file_part}")
        CONTINUE

      — Extract top-level entity name (before any dot)
      entity_name ← entity_part split at "." → first element

      source ← read(file_path)
      IF entity_name NOT IN source:
        ADD finding(bid, check_type="BROKEN_REF",
                    detail="{bid} entity '{entity_name}' not found in {file_part}")

  RETURN PASS if no findings, FAIL otherwise
```

**Entity resolution strategy:** Split derivation at `#`, verify file exists, then search the file text for the top-level entity name (the part before any `.`). This is a grep-level check, not full AST resolution. It catches missing files and renamed entities but does not validate member access (e.g., `ClassName.method_name` only checks that `ClassName` appears in the file, not that `method_name` exists on it). Full member validation requires AST tooling (deferred to Tier 2 — Realize Scope check).

### 3. Scope — SKIP

Deferred (M-c: requires language-specific AST tooling to discover all derivations in source files and compare against the realize-map). Returns `status: SKIP`.

## Aggregation

```
FUNCTION run_realize_inspection(feature_dir, spec_dir, project_root):
  spec_bids    ← extract_spec_bids(spec_dir)
  realize_map  ← load_yaml(feature_dir / "realize-map.yaml")

  IF realize_map is null or invalid:
    RETURN InspectionResult(pass=false, single FAIL check: "realize-map.yaml not found or invalid")

  map_bids ← set of keys in realize_map.bids matching "^BID-\d+$"

  checks ← [
    check_completeness(spec_bids, map_bids),
    check_broken_refs(realize_map, project_root),
  ]

  pass ← all active checks have status PASS
  RETURN InspectionResult(timestamp=now_utc(), pass, checks, flatten(findings))
```

## Output Path

`.haileris/features/{feature_id}/realize-inspection.yaml`

## Edge Cases

- **Derivation with nested member access:** `src/module#Class.SubClass.method` — `entity_name` is `Class`. Only the top-level entity is checked. Nested member validation is deferred to the Scope check.
- **File path without extension:** Implementations should append the appropriate source file extension.
- **Entity name appears in comment/string:** The grep-level check does not distinguish entity name occurrences in code vs. comments vs. strings. This is a known false-negative risk (entity renamed in code but still referenced in a comment). Acceptable for Tier 1; full AST resolution in Tier 2.
- **Empty derivations list:** A BID with `derivations: []` is caught by Completeness (the BID exists in the map but has no derivations, which is equivalent to having the BID key without meaningful content). Implementations should treat an empty derivations list as equivalent to the BID being absent from the map for Completeness purposes, or flag it separately as a structural issue.
