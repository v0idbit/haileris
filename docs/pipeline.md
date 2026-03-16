# Pipeline

## Stages

| # | Stage | Purpose |
|---|-------|---------|
| 1 | [Harvest](stages/harvest.md) | Harvest the codebase and distill all relevant context |
| 2 | [Ascertain](stages/ascertain.md) | Resolve ambiguities, contradictions, and gaps |
| 3 | [Inscribe](stages/inscribe.md) | Author the formal spec with enumerated BIDs |
| 4 | [Layout](stages/layout.md) | Partition the spec into vertical delivery slices |
| 5 | [Etch](stages/etch.md) | Write red-phase tests for each delivery slice |
| 6 | [Realize](stages/realize.md) | Implement green-phase code against each test module |
| 7 | [Inspect](stages/inspect.md) | Review each completed slice for correctness and traceability |
| 8 | [Settle](stages/settle.md) | Evaluate failures; loop back or declare completion |

---

## Inputs and Outputs

### 1. Harvest

**Sub-stages:** Harvest.Explore → Harvest.Synthesize → Harvest.Validate → Harvest.Initialize

#### Inputs

**Target source code** and **feature details**, including:

| Category | Examples |
|----------|---------|
| Description | Who the story helps, business value, details of the ask, blockers, dependencies, related repos, external requirements |
| Acceptance criteria | Conditions that define done |
| Related context | Epic/story docs, design docs, dependency docs, library/tool/platform docs, conversation notes |
| Technical details | Language requirements, repository standards, installed and external dependencies |

> More context is better, but keep signal-to-noise high.

#### Outputs

**Decomposed Context** (tentative) — a distillation covering description and delivery details (blockers, story relations, external requirements). Plain English spec
**Technical Details**

---

### 2. Ascertain

#### Input

Decomposed Context

#### Process

Repeat until no ascertainments remain: identify ambiguities or gaps, output a list of ascertainment needs, receive answers, update `ascertainments.md` and `decomposition.md`, and repeat. If no ambiguities are found, list assumptions for user confirmation before proceeding.

#### Output

**Improved decomposition** — refined plain English spec with resolved ambiguities

---

### 3. Inscribe

**Sub-stages:** Inscribe.Author → Inscribe.Verify → Inscribe.Approve

#### Inputs

- Improved Context
- Constitution

#### Outputs

**Gherkin spec** — end-to-end workflow scenarios with BIDs and `@traces` tags.
**Gherkin subspecs** — per-concern behavioral contracts with BIDs. Subspecs compose into the primary spec; ANLZ-006 validates this.

---

### 4. Layout

#### Inputs

- Gherkin spec (primary spec + concern subspecs)
- Constitution

#### Outputs

**Gherkin subspecs** — one per vertical delivery slice, each containing the relevant BIDs. All BIDs (both primary and subspec) are grouped into tasks; integration BIDs naturally land in later tasks due to cross-concern dependencies.

Gherkin subspecs must be non-intersecting and their union must equal the full Gherkin spec.

---

### 5–6. Etch → Realize (per subset)

Etch and Realize execute **sequentially per subset** in the dependency order established by Layout:

```
Etch(subset 1) → Realize(subset 1) → Etch(subset 2) → Realize(subset 2) → ...
```

This ensures later subsets can depend on earlier subsets' implementations.

#### 5. Etch

**Inputs:** Gherkin subspec (current subset), Constitution
**Outputs:** Red-phase test suite, Etch map (BID → test function mapping)

#### 6. Realize

**Inputs:** Gherkin subspec (current subset), Red-phase tests, Etch map, Constitution
**Outputs:** Green-phase implementation, Implementation map (BID → source symbol mapping)

---

### 7. Inspect

**Sub-stages:** Inspect.Gate → Inspect.Review → Inspect.Synthesize

#### Inputs

- Gherkin spec
- Green-phase implementation
- Etch map
- Implementation map
- Constitution

#### Output

**Implementation failure details** (empty if all checks pass)

---

## Pipeline State (`pipeline-state.yaml`)

Each feature run tracks its execution state in `.haileris/features/{feature_id}/pipeline-state.yaml`. This file is written at Harvest and updated as stages complete.

```yaml
feature_id: "{feature_id}"
current_stage: "realize"
constitution_version: "1.2.0"
started_at: "2026-03-10T14:30:00Z"
last_updated: "2026-03-10T16:45:00Z"
stage_statuses:
  harvest: passed
  ascertain: passed
  inscribe: passed
  layout: passed
  etch: running
  realize: pending
  inspect: pending
  settle: pending
etch_realize_progress:
  current_subset: 2
  total_subsets: 3
  subsets_completed: [1]
loop_count: 0
last_loop_target: null
```

### Resume Semantics

- If execution is interrupted, the pipeline resumes from `current_stage` using the progress fields.
- For Etch/Realize interruptions: `etch_realize_progress` tracks which subsets are complete. Completed subsets are not re-run; the pipeline resumes at the current subset.
- After a Settle loop, `loop_count` increments and `last_loop_target` records where the loop re-entered. Downstream stages reset to `pending` in `stage_statuses` from the loop target onward.

---

## Cross-Feature Dependencies

Each feature runs in its own `.haileris/features/{id}/` directory. When Feature B depends on Feature A's implementation:

1. **At Harvest**: note the dependency in the decomposition under Delivery Details (blockers section)
2. **At Inscribe**: reference Feature A's BIDs in Given preconditions where applicable (e.g., `Given Feature A's BID-003 behavior is available`)
3. **Ordering**: Feature A must reach COMPLETE before Feature B enters Etch. Earlier stages (Harvest through Layout) can run in parallel.

The pipeline does not enforce cross-feature ordering automatically — it is the user's responsibility to sequence dependent features correctly.

---

### 8. Settle

**Sub-stages:** Settle.Triage → Settle.Fix → Settle.Confirm

#### Inputs

- Gherkin spec
- Constitution
- Implementation failure details

#### Output

If failures are present, route by domain of remaining findings (see [Settle](stages/settle.md)). Max 3 Settle loops; escalate to user if unresolved. Otherwise, **COMPLETE**.
