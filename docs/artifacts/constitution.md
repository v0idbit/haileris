# Constitution

A document of architectural principles that governs the entire pipeline. When present, every stage reads it and enforces it. Constitution violations are always Critical findings.

## What It Contains

A versioned set of named principles, each with a rule, a rationale, and a scope. Principles define what the pipeline must and must not do at an architectural level — things that apply regardless of which feature is being built.

## Lifecycle

The constitution is not produced by any pipeline stage. It is created and managed independently, before or alongside pipeline runs. It is a stable project-wide input.

Version numbers follow semver:
- **PATCH** — wording ascertainment only; no behavioral change; updated in place with no archive
- **MINOR** — new principle or substantive expansion; prior version archived before update
- **MAJOR** — removal or fundamental change to a principle; prior version archived before update

## Paths

| Path | Purpose |
|------|---------|
| `.haileris/constitution/constitution.md` | Canonical read path |
| `.haileris/constitution/archive/v{semver}.md` | Prior versions; read-only after being written |
| `.haileris/memory/constitution.md` | Committed copy for stable access |

## Which Stages Read It

Inscribe, Layout, Etch, Realize, Inspect, Settle — every stage from spec writing through completion.

## Committed

Yes. Archive entries are immutable once written.
