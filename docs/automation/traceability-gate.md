# Traceability Gate (Inspect.Gate)

Pre-review verification that all upstream inspection artifacts exist and passed. Source: [inspect.md](../stages/inspect.md) (Inspect.Gate section).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | YAML per [pipeline-state.md](../artifacts/pipeline-state.md) |
| Constitution | `.haileris/project/constitution.md` | Markdown (optional) |
| Harvest inspection | `.haileris/features/{feature_id}/harvest-inspection.yaml` | YAML per [audit-reports.md](../artifacts/audit-reports.md) |
| Layout inspection | `.haileris/features/{feature_id}/layout-inspection.yaml` | YAML per [audit-reports.md](../artifacts/audit-reports.md) |
| Etch inspection | `.haileris/features/{feature_id}/etch-inspection.yaml` | YAML per [audit-reports.md](../artifacts/audit-reports.md) |
| Realize inspection | `.haileris/features/{feature_id}/realize-inspection.yaml` | YAML per [audit-reports.md](../artifacts/audit-reports.md) |

## Checks

### 1. Constitution Version

Verify the constitution version matches the version recorded in `pipeline-state.yaml` at Harvest.

```
FUNCTION check_constitution_version(state_path, constitution_path):
  state ← load_yaml(state_path)
  IF state is null:
    RETURN FAIL with finding("pipeline-state.yaml not found")

  recorded ← state.constitution_version

  — Case 1: No constitution recorded and none exists
  IF recorded is null AND constitution_path does not exist:
    RETURN PASS ("No constitution recorded or present")

  — Case 2: Constitution exists but wasn't recorded
  IF recorded is null AND constitution_path exists:
    RETURN FAIL with finding("Constitution exists but no version recorded in pipeline-state.yaml")

  — Case 3: Constitution was recorded but file is gone
  IF recorded is not null AND constitution_path does not exist:
    RETURN FAIL with finding("constitution.md not found but version was recorded")

  — Case 4: Both exist — compare versions
  constitution ← load(constitution_path)
  current_version ← extract version from constitution

  IF current_version ≠ recorded:
    RETURN FAIL with finding("Constitution changed since Harvest: recorded={recorded}, current={current_version}")

  RETURN PASS ("Constitution version matches: {recorded}")
```

**Version extraction:** The constitution version can be stored as YAML frontmatter, a heading, or a metadata field. The implementation must match the project's constitution format. If the constitution is plain markdown without machine-readable version, this check verifies file existence only.

### 2–5. Inspection Artifact Checks (×4)

For each of the four inspection artifacts, verify existence and `pass: true`.

```
FUNCTION check_artifact_exists_and_passed(artifact_path, artifact_name):
  data ← load_yaml(artifact_path)

  IF data is null:
    RETURN FAIL with finding(
      check_type="MISSING",
      detail="Critical: {artifact_name} not found; traceability unverified")

  passed ← data["pass"]

  IF NOT passed:
    finding_count ← length(data["findings"]) if "findings" in data else 0
    RETURN FAIL with finding(
      check_type="FAILED",
      detail="Critical: {artifact_name} failed with {finding_count} finding(s)")

  RETURN PASS ("{artifact_name} exists and passed")
```

The four artifacts and their expected error messages on absence:

| Artifact | Critical message |
|----------|-----------------|
| `harvest-inspection.yaml` | "harvest-inspection.yaml not found; context coverage unverified" |
| `layout-inspection.yaml` | "layout-inspection.yaml not found; BID coverage for task list unverified" |
| `etch-inspection.yaml` | "etch-inspection.yaml not found; test BID mapping unverified" |
| `realize-inspection.yaml` | "realize-inspection.yaml not found; build BID mapping unverified" |

## Aggregation

```
FUNCTION run_traceability_gate(feature_dir, project_dir):
  checks ← [
    check_constitution_version(
      feature_dir / "pipeline-state.yaml",
      project_dir / "constitution.md"),

    check_artifact_exists_and_passed(
      feature_dir / "harvest-inspection.yaml",  "harvest-inspection.yaml"),
    check_artifact_exists_and_passed(
      feature_dir / "layout-inspection.yaml",   "layout-inspection.yaml"),
    check_artifact_exists_and_passed(
      feature_dir / "etch-inspection.yaml",     "etch-inspection.yaml"),
    check_artifact_exists_and_passed(
      feature_dir / "realize-inspection.yaml",  "realize-inspection.yaml"),
  ]

  pass ← all checks have status PASS
  RETURN InspectionResult(timestamp=now_utc(), pass, checks, flatten(findings))
```

## Output

The traceability gate does not write its own inspection artifact. Its result is incorporated into the Inspect stage's verify report. Implementations may optionally write the result for debugging purposes.

## Edge Cases

- **All artifacts missing:** Each produces an independent Critical finding. The gate fails with 4 MISSING findings (plus any constitution finding).
- **Artifact exists but malformed YAML:** Treated as missing. The gate cannot distinguish "file not found" from "file unreadable" — both are gate blockers.
- **`pass` field absent from artifact:** If the YAML loads but has no `pass` key, treat as `pass: false`.
- **Constitution version is `null` in state:** This is the expected state when no constitution was present at Harvest. Only a problem if a constitution file now exists (Case 2).
