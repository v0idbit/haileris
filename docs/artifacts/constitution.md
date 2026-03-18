# Constitution

A document of architectural principles that governs the entire pipeline. When present, every stage reads it and enforces it. Constitution violations are always Critical findings.

## What It Contains

A versioned set of named principles, each with a rule, a rationale, and a scope. Principles define what the pipeline must do and what it must preserve at an architectural level — things that apply regardless of which feature is being built. Principles should use constructive framing — state what to do and what to preserve, rather than listing prohibitions. Agents follow positive instructions more reliably.

## Lifecycle

The constitution is created and managed independently, before or alongside pipeline runs. It is a stable project-wide input, external to the pipeline's stage lifecycle.

Version numbers follow semver:
- **PATCH** — wording clarification only; no behavioral change
- **MINOR** — new principle or substantive expansion
- **MAJOR** — removal or fundamental change to a principle

Git history serves as the version record.

## Path

`.haileris/project/constitution.md`

## Which Stages Read It

Inscribe, Layout, Etch, Realize, Inspect, Settle — every stage from spec writing through completion.

## Committed

Yes.
