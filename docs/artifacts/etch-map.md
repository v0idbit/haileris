# Etch Map

A structured mapping from BIDs to the test functions that cover them. Written by Etch after tests are generated. Used by the etch inspection to verify coverage, and ingested by Realize and Inspect as the authoritative BID → test traceability record.

## What It Contains

For each BID in the subspec: a list of fully-qualified test function paths that cover it.

## Format

```yaml
bids:
  BID-001:
    tests:
      - tests/unit/test_feature.py::test_create_user
      - tests/unit/test_feature.py::test_create_user_duplicate
  BID-002:
    tests:
      - tests/unit/test_feature.py::test_delete_user
  BID-060:
    tests:
      - tests/integration/test_workflow.py::test_full_pipeline
```

Primary spec BIDs map to `tests/integration/`; subspec BIDs map to `tests/unit/` or `tests/features/`.

## Lifecycle

Written by Etch once all test functions are generated. Read by the etch inspection to validate coverage. Ingested by Realize to guide implementation scoping. Ingested by Inspect as input to the Traceability Gate. Not modified after Etch.

## Path

`.haileris/features/{feature_id}/etch-map.yaml`

## Committed

Yes.
