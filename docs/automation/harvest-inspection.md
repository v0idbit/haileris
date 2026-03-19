# Harvest Inspection

Validates `decomposition.md` and `technical-details.md` across 4 dimensions. Source: [harvest.md](../stages/harvest.md) (Harvest Inspection table).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Decomposition | `.haileris/features/{feature_id}/decomposition.md` | Markdown with section headings |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Markdown with section headings |
| Standards memory | `.haileris/project/standards.md` | Markdown |
| Test conventions memory | `.haileris/project/test-conventions.md` | Markdown |

## Checks

### 1. Decomposition Template Compliance

**Pass condition:** `decomposition.md` contains both a "Description" section and a "Delivery Details" section, each with at least one non-blank line of content below the heading.

```
FUNCTION check_decomposition_template(feature_dir):
  path ← feature_dir / "decomposition.md"
  IF path does not exist:
    RETURN FAIL with finding("decomposition.md not found")

  content ← read(path)
  required_sections ← ["Description", "Delivery Details"]

  FOR EACH section IN required_sections:
    IF NOT has_non_empty_section(content, section):
      ADD finding(check_type="INSUFFICIENT", detail="missing or empty section: {section}")

  RETURN PASS if no findings, FAIL otherwise
```

`has_non_empty_section(content, name)`: scan for a markdown heading (any level) whose text contains `name` (case-insensitive). Return true if at least one non-blank line exists between that heading and the next heading (or end of file).

### 2. Technical Details Template Compliance

**Pass condition:** `technical-details.md` contains "Standards", "Test Conventions", and "Dependencies" sections, each with at least one non-blank line of content.

```
FUNCTION check_technical_details_template(feature_dir):
  path ← feature_dir / "technical-details.md"
  IF path does not exist:
    RETURN FAIL with finding("technical-details.md not found")

  content ← read(path)
  required_sections ← ["Standards", "Test Conventions", "Dependencies"]

  FOR EACH section IN required_sections:
    IF NOT has_non_empty_section(content, section):
      ADD finding(check_type="INSUFFICIENT", detail="missing or empty section: {section}")

  RETURN PASS if no findings, FAIL otherwise
```

### 3. Artifact Preflight

**Pass condition:** Both `standards.md` and `test-conventions.md` exist in the project directory and each has more than 5 non-blank lines.

```
FUNCTION check_artifact_preflight(project_dir):
  threshold ← 5

  FOR EACH name IN ["standards.md", "test-conventions.md"]:
    path ← project_dir / name
    IF path does not exist:
      ADD finding(check_type="MISSING", detail="{name} not found")
    ELSE:
      count ← count_non_blank_lines(path)
      IF count ≤ threshold:
        ADD finding(check_type="INSUFFICIENT", detail="{name} has {count} non-blank lines (need >{threshold})")

  RETURN PASS if no findings, FAIL otherwise
```

`count_non_blank_lines(path)`: read file, count lines where `strip(line)` is non-empty.

### 4. Dependency Doc Coverage — SKIP

Deferred. Returns `status: SKIP` with detail "Dependency doc coverage check deferred (requires package resolution)".

## Aggregation

```
FUNCTION run_harvest_inspection(feature_dir, project_dir):
  checks ← [
    check_decomposition_template(feature_dir),
    check_technical_details_template(feature_dir),
    check_artifact_preflight(project_dir),
    check_dependency_coverage()          — always SKIP
  ]

  pass ← checks[1].status = PASS
      AND checks[2].status = PASS
      AND checks[3].status = PASS

  findings ← flatten all check findings
  RETURN InspectionResult(timestamp=now_utc(), pass, checks, findings)
```

Overall `pass: true` requires checks 1–3 to pass. Check 4 (SKIP) does not affect the result.

## Output Path

`.haileris/features/{feature_id}/harvest-inspection.yaml`

## Edge Cases

- **Empty file:** A file that exists but contains only whitespace has 0 non-blank lines. Treated as insufficient for both template checks and artifact preflight.
- **Heading-only section:** A section heading with no content lines before the next heading fails `has_non_empty_section`.
- **Missing feature directory:** If the feature directory itself does not exist, all checks fail with MISSING findings.
