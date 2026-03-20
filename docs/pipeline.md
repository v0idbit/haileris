# Pipeline

## Stages

| # | Stage | Purpose |
|---|-------|---------|
| 1 | [Harvest](stages/harvest.md) | Harvest the codebase and distill all relevant context |
| 2 | [Ascertain](stages/ascertain.md) | Resolve ambiguities, contradictions, and gaps |
| 3 | [Inscribe](stages/inscribe.md) | Author the primary spec with enumerated BIDs |
| 4 | [Layout](stages/layout.md) | Decompose the primary spec into ordered delivery subspecs |
| 5 | [Etch](stages/etch.md) | Write red-phase tests for each subspec |
| 6 | [Realize](stages/realize.md) | Implement green-phase code to make each subspec's tests pass |
| 7 | [Inspect](stages/inspect.md) | Review the finished implementation for correctness and traceability |
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

**Decomposition** (tentative) — a distillation covering description and delivery details (blockers, story relations, external requirements). Plain English spec
**Technical Details** — synthesized technical context (standards, conventions, dependencies, file inventory) consumed by downstream stages

---

### 2. Ascertain

#### Input

Decomposition

#### Process

Repeat until all ascertainments are resolved: identify ambiguities or gaps, output a list of ascertainment needs, receive answers, update `ascertainments.md` and `decomposition.md`, and repeat. If the decomposition is unambiguous, list assumptions for user confirmation before proceeding.

#### Output

**Improved decomposition** — refined plain English spec with resolved ambiguities

---

### 3. Inscribe

**Sub-stages:** Inscribe.Author → Inscribe.Verify → Inscribe.Approve

#### Inputs

- Improved decomposition
- Ascertainments
- Technical details
- Constitution

#### Outputs

**Primary spec** — end-to-end workflow scenarios with BIDs.

---

### 4. Layout

**Sub-stages:** Layout.Decompose → Layout.Verify → Layout.Approve

#### Inputs

- Primary spec (`primary.feature`)
- Constitution

#### Outputs

**Ordered delivery subspecs** — per-deliverable behavioral contracts with BIDs, listed in implementation order with dependency edges. Layout decomposes the primary spec into subspecs, adds `@traces` tags, and validates composition (ANLZ-003, ANLZ-004).

---

### 5–6. Etch → Realize (per subspec)

Etch and Realize execute **sequentially per subspec** in the dependency order established by Layout:

```
Etch(subspec 1) → Realize(subspec 1) → Etch(subspec 2) → Realize(subspec 2) → ...
```

This ensures later subspecs can depend on earlier subspecs' implementations. After all subspec cycles complete, a final Etch pass writes integration tests for primary BIDs; Realize then ensures those pass.

#### 5. Etch

**Inputs:** Gherkin subspec (current subspec), Constitution
**Outputs:** Red-phase test suite, Etch map (BID → test function mapping)

#### 6. Realize

**Inputs:** Gherkin subspec (current subspec), Red-phase tests, Etch map, Constitution
**Outputs:** Green-phase implementation, Realize map (BID → derivation mapping)

---

### 7. Inspect

**Sub-stages:** Inspect.Gate → Inspect.Review → Inspect.Synthesize

#### Inputs

- Gherkin spec
- Green-phase implementation
- Etch map
- Realize map
- Constitution

#### Output

**Implementation failure details** (empty if all checks pass)

---

### 8. Settle

**Sub-stages:** Settle.Triage → Settle.Fix → Settle.Confirm

#### Inputs

- Gherkin spec
- Constitution
- Implementation failure details

#### Output

If failures are present, route by domain of remaining findings (see [Settle](stages/settle.md)). Max 3 Settle loops; escalate to user if unresolved. Otherwise, **COMPLETE**.

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
  current_subspec: 2
  total_subspecs: 3
  subspecs_completed: [1]
loop_count: 0
last_loop_target: null
```

### Resume Semantics

- If execution is interrupted, the pipeline resumes from `current_stage` using the progress fields.
- For Etch/Realize interruptions: `etch_realize_progress` tracks which subspecs are complete. The pipeline resumes at the current subspec; completed subspecs are skipped.
- After a Settle loop, `loop_count` increments and `last_loop_target` records where the loop re-entered. Downstream stages reset to `pending` in `stage_statuses` from the loop target onward.

---

## Cross-Feature Dependencies

Each feature runs in its own `.haileris/features/{feature_id}/` directory. When Feature B depends on Feature A's implementation:

1. **At Harvest**: note the dependency in the decomposition under Delivery Details (blockers section)
2. **At Inscribe**: reference Feature A's BIDs in Given preconditions where applicable (e.g., `Given Feature A's BID-003 behavior is available`)
3. **Ordering**: Feature A must reach COMPLETE before Feature B enters Etch. Earlier stages (Harvest through Layout) can run in parallel.

Cross-feature ordering is the user's responsibility — the pipeline trusts the user to sequence dependent features correctly.
