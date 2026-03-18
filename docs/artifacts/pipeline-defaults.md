# Pipeline Defaults

Baseline conventions the pipeline applies when project-level artifacts (standards, test-conventions, constitution) are absent. Every default is overridden by the corresponding project-level artifact when one exists.

## What They Cover

| Area | What the default governs | Overridden by |
|------|-------------------------|---------------|
| Code organization | Domain > layer structure (domains as top-level directories, layers as internal organization within each domain) | `standards.md` |
| Test placement | Test directories mirror domain structure | `test-conventions.md` |
| Naming conventions | Language-idiomatic defaults for files, functions, classes | `standards.md` |
| Assertion style | One logical assertion per test, AAA structure | `test-conventions.md` |

## Override Precedence

Project artifacts take full precedence — they replace pipeline defaults entirely. When `standards.md` exists, it replaces the coding defaults. When `test-conventions.md` exists, it replaces the testing defaults.

## Where They Live

Pipeline defaults are implementation details of the pipeline. They are built into the pipeline's stage logic and documented here for reference. They live in the pipeline implementation, separate from project artifacts.

## Which Stages Use Them

Etch, Realize, and Inspect — the stages that produce or validate code. Earlier stages (Harvest through Layout) operate on the spec and are independent of code conventions. Settle inherits whatever conventions the earlier stages applied.

## Relationship to Other Artifacts

- **`standards.md`** — project coding standards discovered by Harvest. If present, fully overrides coding defaults.
- **`test-conventions.md`** — project test conventions discovered by Harvest. If present, fully overrides testing defaults.
- **Constitution** — architectural principles. Operates at a higher level than defaults; constitution violations are Critical regardless of what defaults say.
