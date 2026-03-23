# Realize Map

A derivation is any named callable or type that static analysis can discover: functions, methods, classes, and their equivalents in the target language.

A structured mapping from BIDs to the derivations that implement them. Built incrementally by Realize after each subspec completes. Used by the realize inspection to verify completeness, scope, and derivation integrity.

## What It Contains

For each BID in the spec: a list of derivations (in `path/to/file#Class.member` format) and the subspec that owns them. Metadata: `feature_id`, `subspecs_completed`, `subspecs_total`, `last_updated`.

## Derivation Format

- Class method: `src/module#ClassName.method_name`
- Module-level function: `src/module#function_name`

The `#` separator delimits the file path from the derivation name.

All derivations — including private helpers and internal methods — must be mapped to a BID. If a helper exists, it serves a BID.

## Lifecycle

Created by Realize when the first subspec completes. Appended to after each subsequent subspec. Read by the realize inspection after all subspecs complete. Stable after the realize inspection passes. A derivation may appear under multiple BIDs when shared logic legitimately satisfies multiple behaviors. On re-entry after a Settle loop, merge semantics apply: entries for re-running subspecs are replaced; entries for skipped subspecs are preserved verbatim.

## Path

`.haileris/features/{feature_id}/realize-map.yaml`

## Committed

Yes.
