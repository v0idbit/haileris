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

Repeat until no ascertainments remain: identify ambiguities or gaps, output a list of ascertainment needs, receive an updated Engineered Context, and repeat.

#### Output

**Improved Context** - Plain English spec

---

### 3. Inscribe

#### Inputs

- Improved Context
- Constitution

#### Outputs


**Gherkin Spec** — Gherkin document with behavior IDs (BIDs).

---

### 4. Layout

#### Inputs

- Gherkin spec
- Constitution

#### Outputs

**Gherkin subspecs** — one per vertical delivery slice, each containing the relevant BIDs behaviors.

Gherkin subspecs must be non-intersecting and their union must equal the full Gherkin spec.

---

### 5. Etch

#### Inputs

- Gherkin subspecs
- Constitution

#### Output

**Red-phase test suite**
**Etch map** — BID → test function mapping

---

### 6. Realize

#### Inputs

- Gherkin subspecs
- Red-phase test suite
- Etch map
- Constitution

#### Output

**Green-phase implementation**
**Implementation map** — BID → source symbol mapping

---

### 7. Inspect

#### Inputs

- Gherkin spec
- Green-phase implementation
- Etch map
- Implementation map
- Constitution

#### Output

**Implementation failure details** (empty if all checks pass)

---

### 8. Settle

#### Inputs

- Gherkin spec
- Constitution
- Implementation failure details

#### Output

If failures are present, return to [Ascertain](stages/ascertain.md) with the Gherkin spec and failure details. Otherwise, **COMPLETE**.
