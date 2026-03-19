# Etch Inspection

Validates `etch-map.yaml` BID → test function mapping. Source: [etch.md](../stages/etch.md) (Etch Inspection table).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Gherkin spec files | `tests/features/*.feature` | Gherkin with `@BID-NNN` tags |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | YAML per [etch-map.md](../artifacts/etch-map.md) |
| Test source files | Referenced by etch-map entries | Source code files |

### Etch Map Structure

```yaml
bids:
  BID-001:
    tests:
      - tests/unit/test_feature#test_create_user
      - tests/unit/test_feature#test_create_user_duplicate
  BID-002:
    tests:
      - tests/integration/test_workflow#test_full_pipeline
```

The `#` separator delimits the file path from the function name. Parameterization suffixes (e.g., `[foo]`) may follow the function name.

## Prerequisite: Extract Map BIDs

```
FUNCTION extract_map_bids(etch_map):
  RETURN set of keys in etch_map.bids that match regex "^BID-\d+$"
```

## Checks

### 1. MISSING

A Gherkin spec BID is absent from the etch-map.

```
FUNCTION check_missing(spec_bids, map_bids):
  missing ← spec_bids − map_bids

  FOR EACH bid IN sorted(missing):
    ADD finding(bid, check_type="MISSING", detail="{bid} has no entry in etch-map")

  RETURN PASS if missing is empty, FAIL otherwise
```

### 2. HALLUCINATED

A BID in the etch-map has no corresponding Gherkin spec entry.

```
FUNCTION check_hallucinated(spec_bids, map_bids):
  hallucinated ← map_bids − spec_bids

  FOR EACH bid IN sorted(hallucinated):
    ADD finding(bid, check_type="HALLUCINATED", detail="{bid} is in etch-map but not in spec")

  RETURN PASS if hallucinated is empty, FAIL otherwise
```

### 3. INSUFFICIENT

A mapped test function body is fewer than 3 non-trivial lines.

**Non-trivial line:** A line in the function body that is not blank, not a comment, not a docstring, and not a decorator/annotation.

```
FUNCTION check_insufficient(etch_map, project_root):
  threshold ← 3

  FOR EACH (bid, entry) IN etch_map.bids:
    FOR EACH test_ref IN entry.tests:
      IF "#" NOT IN test_ref:
        CONTINUE

      (file_part, func_name) ← split test_ref at last "#"

      — Strip parameterization suffix
      IF "[" IN func_name:
        func_name ← func_name up to first "["

      file_path ← resolve(project_root, file_part)
      — Append language-appropriate extension if file_path has none

      IF file_path does not exist:
        CONTINUE    — file absence is an etch-map structural issue, not INSUFFICIENT

      source ← read(file_path)
      line_count ← count_function_body_lines(source, func_name)

      IF line_count is null:
        CONTINUE    — function not found

      IF line_count < threshold:
        ADD finding(bid, check_type="INSUFFICIENT",
                    detail="{bid} test function '{func_name}' in {file_part} has {line_count} body line(s) (need ≥{threshold})")

  RETURN PASS if no findings, FAIL otherwise
```

### count_function_body_lines

Counts non-trivial body lines of a named function. Language-agnostic algorithm:

```
FUNCTION count_function_body_lines(source, func_name):
  — Step 1: Find the function definition line
  Scan source lines for a function definition whose name matches func_name.
  Detection is language-dependent:
    — Indentation-based languages: "def func_name(" at some indentation level
    — Brace-based languages: function/method signature containing func_name
  IF not found: RETURN null
  Record the indentation level of the definition line.

  — Step 2: Extract body lines
  Starting from the line after the definition:
    — Indentation-based: collect lines until a non-blank line at the same
      or lesser indentation as the definition (or a new definition/class)
    — Brace-based: track brace nesting; collect until closing brace

  — Step 3: Filter trivial lines
  Remove from collected lines:
    — Blank lines (whitespace only)
    — Comment lines (language-appropriate comment syntax)
    — Docstring/documentation blocks (language-appropriate)
    — Decorator/annotation lines (language-appropriate)

  RETURN count of remaining lines
```

### 4. DUPLICATED — SKIP

Deferred (J-v: requires test similarity analysis). Returns `status: SKIP`.

### 5. PARTIAL — SKIP

Deferred (J-v: requires semantic Then-step coverage analysis). Returns `status: SKIP`.

## Aggregation

```
FUNCTION run_etch_inspection(feature_dir, spec_dir, project_root):
  spec_bids ← extract_spec_bids(spec_dir)
  etch_map  ← load_yaml(feature_dir / "etch-map.yaml")

  IF etch_map is null or invalid:
    RETURN InspectionResult(pass=false, single FAIL check: "etch-map.yaml not found or invalid")

  map_bids ← extract_map_bids(etch_map)

  checks ← [
    check_missing(spec_bids, map_bids),
    check_hallucinated(spec_bids, map_bids),
    check_insufficient(etch_map, project_root),
  ]

  pass ← all active checks have status PASS
  RETURN InspectionResult(timestamp=now_utc(), pass, checks, flatten(findings))
```

## Output Path

`.haileris/features/{feature_id}/etch-inspection.yaml`

## Edge Cases

- **Empty tests list:** A BID with `tests: []` is structurally valid but has no test coverage. This is caught by [TEST-001](test-001.md), not by INSUFFICIENT (which only examines functions that exist).
- **Parameterized tests:** `test_func[param_value]` — strip the `[...]` suffix before looking up the function definition. The parameterization is a test framework convention; the function body is the same for all parameter values.
- **File path without extension:** The etch-map may use extensionless paths (e.g., `tests/unit/test_feature`). Implementations should append the appropriate source file extension for the project's language.
- **Missing file:** If the test file does not exist, INSUFFICIENT skips it. A missing file is a structural issue in the etch-map, not an insufficiency of the function body.
- **Function not found in file:** If the named function does not exist in the file, INSUFFICIENT skips it. This is also a structural issue.
