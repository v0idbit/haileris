# Realize Map

A structured mapping from BIDs to the source symbols that implement them. Built incrementally by Realize after each task completes. Used by the realize inspection to verify completeness, scope, and symbol integrity.

## What It Contains

For each BID in the spec: a list of source symbols (in `path/to/file#Symbol.member` format) and the tasks that contributed them. Metadata: `feature_id`, `tasks_completed`, `tasks_total`, `last_updated`.

## Symbol Format

- Class method: `src/module#ClassName.method_name`
- Module-level function: `src/module#function_name`

The `#` separator delimits the file path from the symbol name.

Non-public helpers (language-private functions, internal methods) called only by mapped symbols may be omitted unless they are substantial standalone functions.

## Lifecycle

Created by Realize when the first task completes. Appended to after each subsequent task. Read by the realize inspection after all tasks complete. Stable after the realize inspection passes. A symbol may appear under multiple BIDs when shared logic legitimately satisfies multiple behaviors.

## Path

`.haileris/features/{feature_id}/realize-map.yaml`

## Committed

Yes.
