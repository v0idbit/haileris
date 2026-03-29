# Pipeline Config

Project-wide pipeline configuration. Controls retry limits and auto-fix behavior. Lives alongside the constitution and project standards.

## What It Contains

Settings that govern automatic retry cycles and auto-resolution behavior. When a retry limit is 0, the pipeline escalates immediately on failure. When auto-resolution is off, spec-domain findings escalate to the user.

| Setting | Default | Governs |
|---------|---------|---------|
| `realize_retries` | 0 | Max retry cycles per subspec in Realize. When tests fail after implementation, Realize retries up to this many times before escalating. |
| `settle_loops` | 0 | Max Settle → re-entry loops. After this many cycles with remaining findings, Settle escalates. |
| `etch_corrections` | 0 | Max RED state correction passes in Etch. When a test passes before Realize, Etch applies diagnostic corrections up to this many times before escalating. |
| `inspection_fixes` | 0 | Max auto-revision passes for inspection failures (Layout inspection, Etch inspection). When an inspection fails with `--fix`, the pipeline retries up to this many times before escalating. |
| `auto_resolve_spec` | false | When true, Settle auto-resolves `domain: spec` findings: presents a default assumption, updates Gherkin spec wording, and appends the resolution to `ascertainments.md` with an `[AUTO-RESOLVED]` tag and rationale. When false (default), spec-domain findings escalate to the user for manual resolution. |

All retry defaults are 0 and auto-resolution defaults to off: escalate to user immediately. Automatic behavior is opt-in.

## Format

The config file format (JSON, YAML, TOML, INI, etc.) is left to the implementation. The file is optional — when absent, all settings use their defaults (0).

## Path

`.haileris/project/config.{ext}`

## Lifecycle

Created by the user or during Harvest (when absent, defaults apply). Read by every stage that has retry or auto-fix behavior (Etch, Realize, Settle, and any stage running inspections with `--fix`). The config is stable across a feature run — changes take effect on the next pipeline invocation.

## Committed

Yes.
