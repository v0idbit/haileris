# TEST-001: BID Coverage Gate

Verifies every spec BID has at least one test function mapped in the etch-map. Source: [etch.md](../stages/etch.md) (step 3).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Gherkin spec files | `tests/features/*.feature` | Gherkin with `@BID-NNN` tags |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | YAML per [etch-map.md](../artifacts/etch-map.md) |

## Algorithm

```
FUNCTION run_test001(feature_dir, spec_dir):
  spec_bids ← extract_spec_bids(spec_dir)
  etch_map  ← load_yaml(feature_dir / "etch-map.yaml")

  IF etch_map is null or invalid:
    RETURN InspectionResult(pass=false, finding: "etch-map.yaml not found or invalid")

  map_bids ← set of keys in etch_map.bids matching "^BID-\d+$"

  — Check 1: Every spec BID must be in the map
  missing ← spec_bids − map_bids
  FOR EACH bid IN sorted(missing):
    ADD finding(bid, check_type="MISSING",
                detail="{bid} has no test function in etch-map")

  — Check 2: Every mapped BID must have a non-empty tests list
  FOR EACH (bid, entry) IN etch_map.bids:
    IF bid IN map_bids AND entry.tests is empty:
      ADD finding(bid, check_type="MISSING",
                  detail="{bid} is in etch-map but has an empty tests list")

  pass ← findings is empty
  RETURN InspectionResult(timestamp=now_utc(), pass, [check_result], findings)
```

## Relationship to Etch Inspection

TEST-001 overlaps with the etch inspection's MISSING check. The distinction:

- **TEST-001** runs *during* Etch (step 3) as a gate before proceeding to RED state confirmation. It is a go/no-go signal: if any BID lacks a test, Etch must add the missing tests before continuing.
- **Etch Inspection MISSING** runs *after* Etch completes (step 5) as part of the full inspection report that feeds the Traceability Gate.

Both use the same BID set comparison. An implementation may share the underlying logic.

## Output

TEST-001 does not write a standalone inspection artifact. Its result determines whether Etch proceeds to TEST-002 (RED state confirmation). Implementations should emit the result to stdout and use exit codes (0 = PASS, 1 = FAIL) for gate enforcement.

## Edge Cases

- **Empty spec directory:** `spec_bids` is empty. TEST-001 passes vacuously (no BIDs to cover).
- **BID with empty tests list vs. absent BID:** Both are MISSING findings. An empty `tests: []` entry is functionally equivalent to the BID being absent — neither provides test coverage.
- **Extra BIDs in etch-map:** BIDs in the map that are not in the spec are not flagged by TEST-001. That is the etch inspection's HALLUCINATED check.
