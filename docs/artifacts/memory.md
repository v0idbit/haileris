# Memory Files

Persistent markdown files written by Harvest and maintained across runs. They give every stage stable access to the project's conventions, standards, and constitution without re-harvestning the codebase each time.

## What They Contain

| File | Contents |
|---|---|
| `standards.md` | Coding standards, linting rules, formatting conventions, language version |
| `test-conventions.md` | Test framework, naming patterns, fixture strategy, assertion style |
| `constitution.md` | Copy of the active constitution principles (if a constitution exists) |

## Lifecycle

Written by Harvest on the first run. Updated when Harvest runs with `--reharvest`. All downstream stages read from memory rather than re-harvestning source files. The constitution memory file is updated whenever the constitution changes.

## Paths

`.haileris/memory/standards.md`
`.haileris/memory/test-conventions.md`
`.haileris/memory/constitution.md`

## Committed

Yes. Memory files are committed. They are the stable source of project context for all stages.
