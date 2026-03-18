# Etch Map

A structured mapping from BIDs to the test functions that cover them. Written by Etch after tests are generated. Used by the etch inspection to verify coverage, and ingested by Realize and Inspect as the authoritative BID → test traceability record.

## What It Contains

For each BID in the subspec: a list of fully-qualified test function paths that cover it.

## Format

```yaml
bids:
  BID-001:
    tests:
      - tests/unit/test_feature#test_create_user
      - tests/unit/test_feature#test_create_user_duplicate
  BID-002:
    tests:
      - tests/unit/test_feature#test_delete_user
  BID-060:
    tests:
      - tests/integration/test_workflow#test_full_pipeline
```

The `#` separator delimits the file path from the function name.

Primary BIDs map to `tests/integration/`; subspec BIDs map to `tests/unit/`.

## Scenario Outline Mapping

A Scenario Outline with an Examples table carries one BID. Etch produces one test function per Examples row (if the framework supports parameterization) or one parameterized test function. Both are valid — the etch-map lists every resulting entry under the same BID:

```yaml
bids:
  BID-002:
    tests:
      - tests/unit/test_feature#test_parameterized[foo]
      - tests/unit/test_feature#test_parameterized[baz]
```

The parameterization suffix (e.g., `[foo]`) follows the project's test framework conventions. One BID, potentially multiple test entries — all mapping back to the same BID.

## Lifecycle

Written by Etch once all test functions are generated. Read by the etch inspection to validate coverage. Ingested by Realize to guide implementation scoping. Ingested by Inspect as input to the Traceability Gate. Stable after Etch.

## Path

`.haileris/features/{feature_id}/etch-map.yaml`

## Committed

Yes.
