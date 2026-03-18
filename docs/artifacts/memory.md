# Memory Files

Persistent markdown files written by Harvest and maintained across runs. They give every stage stable access to the project's conventions and standards without re-harvesting the codebase each time.

## What They Contain

| File | Contents |
|---|---|
| `standards.md` | Coding standards, linting rules, formatting conventions, language version |
| `test-conventions.md` | Test framework, naming patterns, fixture strategy, assertion style |

## Lifecycle

Written by Harvest on the first run. Updated when Harvest runs with `--reharvest`. All downstream stages read from memory rather than re-harvesting source files. Memory files should use constructive framing — state what to do, how to organize, and what patterns to follow, rather than listing prohibitions. Agents follow positive instructions more reliably.

## Paths

`.haileris/project/standards.md`
`.haileris/project/test-conventions.md`

## Committed

Yes. Memory files are committed. They are the stable source of project context for all stages.
