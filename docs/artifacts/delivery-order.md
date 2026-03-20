# Delivery Order

The sequenced list of subspecs for implementation. Produced by Layout, consumed by the pipeline orchestration layer to sequence Etch and Realize execution.

## What It Contains

A YAML file listing subspecs in implementation order with dependency edges:

```yaml
feature_id: "{feature_id}"
subspecs:
  - file: "users.feature"
    depends_on: []
  - file: "auth.feature"
    depends_on: ["users.feature"]
```

Subspecs are identified by filename. Each entry declares its dependencies on other subspecs.

## Lifecycle

Written once by Layout after subspecs are created and validated. Read by Etch (for test ordering) and Realize (for implementation order). Stable after writing — downstream stages treat it as a fixed input. Kept after the feature completes as an inspection record of how the spec was decomposed.

## Path

`.haileris/features/{feature_id}/delivery-order.yaml`

## Committed

Yes. Kept for inspection reference.
