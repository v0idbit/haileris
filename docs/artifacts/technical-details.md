# Technical Details

The synthesized technical context for a feature. Produced by Harvest alongside the Decomposition. Contains all implementation-relevant information — standards, conventions, dependencies, and file inventory — consumed by Inscribe and subsequent stages.

## What It Contains

- **Coding standards and test conventions** — project standards, testing patterns, fixture inventory, git workflow, and any conflicts with pipeline defaults
- **Dependency documentation** — relevant packages and what documentation is available for them
- **File path inventory** — files to create or modify (with paths), patterns from real files in the codebase, critical constraints

## Lifecycle

Written by Harvest. Read by Inscribe as supplementary context for spec writing. Also consulted by Etch and Realize via standards memory. Stable after Harvest; refreshed by `--reharvest` when project standards change.

## Path

`.haileris/features/{feature_id}/technical-details.md`

## Committed

Yes.
