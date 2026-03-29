# Stage Specifications

Per-stage detail for each of the eight pipeline stages. Each spec defines the stage's inputs, process (with sub-stages), outputs, artifacts written, and inspection gates. Together they describe the full feature lifecycle from initial context gathering through final resolution.

## Stage Flow

```mermaid
flowchart TD
    H[1. Harvest]
    A[2. Ascertain]
    I[3. Inscribe]
    L[4. Layout]
    E[5. Etch]
    R[6. Realize]
    IN[7. Inspect]
    S[8. Settle]

    H --> A
    A -->|ascertainments needed| A
    A --> I
    I --> L
    L -->|user approves subspecs| E
    E --> R
    R --> IN
    IN --> S
    S -->|"domain: spec (full)"| A
    S -->|"domain: test (scoped)"| E
    S -->|"domain: impl (scoped)"| R
    S -->|no failures| DONE([COMPLETE])
```

## Stages

Stages execute in order. Each row links to the full spec, summarizes the stage's role, and lists its sub-stages.

| # | Stage | Purpose | Sub-Stages |
|---|-------|---------|------------|
| 1 | [Harvest](harvest.md) | Gather and validate project context, standards, and feature requirements | Explore, Synthesize, Validate, Initialize |
| 2 | [Ascertain](ascertain.md) | Clarify ambiguities, contradictions, and gaps in the decomposition | Iterative user-confirmation loop |
| 3 | [Inscribe](inscribe.md) | Author the primary Gherkin spec from the improved decomposition | Author, Verify, Approve |
| 4 | [Layout](layout.md) | Decompose the primary spec into ordered delivery subspecs | Decompose, Verify |
| 5 | [Etch](etch.md) | Write red-phase tests for each subspec | Per-subspec test generation, red-state confirmation |
| 6 | [Realize](realize.md) | Implement each subspec to make its red-phase tests pass | Per-subspec implementation in dependency order |
| 7 | [Inspect](inspect.md) | Review finished implementation against the spec and upstream inspections | Gate, Review (5 parallel reviews), Synthesize |
| 8 | [Settle](settle.md) | Resolve findings and gate on completeness | Triage, Scope, Fix, Confirm |

## Artifact Flow

Each stage reads artifacts from upstream and writes artifacts consumed downstream. The table below shows the primary artifacts each stage produces.

| Stage | Artifacts Written | Location |
|-------|-------------------|----------|
| Harvest | decomposition, technical-details, standards, test-conventions, constitution | `.haileris/features/`, `.haileris/project/` |
| Ascertain | ascertainments (Q&A outcomes) | `.haileris/features/` |
| Inscribe | primary.feature (Gherkin spec with BID tags) | `tests/features/{feature_id}/` |
| Layout | subspec .feature files, delivery-order.yaml | `tests/features/{feature_id}/`, `.haileris/features/` |
| Etch | integration + unit tests, etch-map.yaml | `tests/`, `.haileris/features/` |
| Realize | production code, realize-map.yaml | `src/`, `.haileris/features/` |
| Inspect | verify report | `.haileris/features/` |
| Settle | fixed code/tests/specs, updated ascertainments | Various |

## Inspection Gates

Five stages produce inspection artifacts that feed the traceability gate at Inspect. Each inspection is a machine-readable YAML report conforming to the schema in [inspection-reports.md](../artifacts/inspection-reports.md).

| Inspection | Stage | Checks |
|------------|-------|--------|
| [Harvest Inspection](../automation/harvest-inspection.md) | Harvest.Validate | 3 mechanical, 1 agent-evaluated |
| [Layout Inspection](../automation/layout-inspection.md) | Layout.Verify | 4 mechanical, 1 agent-evaluated |
| [Etch Inspection](../automation/etch-inspection.md) | Etch | 3 mechanical, 2 agent-evaluated |
| [Realize Inspection](../automation/realize-inspection.md) | Realize | 2 mechanical, 1 constraint-gated |
| [Traceability Gate](../automation/traceability-gate.md) | Inspect.Gate | 5 checks across all upstream inspections |

## Complete Pipeline

```mermaid
flowchart TD
    RAW["Raw Inputs<br>(source, feature details, context, tech)"]

    RAW --> H

    subgraph H["1. Harvest"]
        H_E["Explore"] --> H_S["Synthesize"] --> H_V["Validate"] --> H_I["Initialize"]
    end

    H --> DEC(["Decomposition (tentative)"])
    DEC --> A

    subgraph A["2. Ascertain"]
        A_P["Clarify ambiguities, contradictions, gaps"]
        A_P -->|needs ascertainment| A_OUT_Q["Ascertainment needs"]
        A_OUT_Q -->|answers fed back in| A_P
    end

    A --> ID(["Improved Decomposition"])
    ID --> I

    subgraph I["3. Inscribe + Constitution"]
        I_A["Author"] --> I_V["Verify"] --> I_AP["Approve"]
    end

    I --> PS2(["Primary Spec<br>(end-to-end workflow BIDs)"])
    PS2 --> L

    subgraph L["4. Layout + Constitution"]
        L_D["Decompose"] --> L_V["Verify"] --> L_AP["Approve"]
    end

    L --> CS2(["Deliverable Subspecs<br>(per-deliverable BIDs)"])
    CS2 --> E

    subgraph E["5. Etch + Constitution"]
        E_P["Write red-phase tests per subspec"]
    end

    E --> RT(["Red-phase Tests (per subspec)"])
    E --> ETM2(["Etch Map"])
    CS2 --> R
    RT --> R
    ETM2 --> R

    subgraph R["6. Realize + Constitution"]
        R_P["Green-phase implementation per subspec"]
    end

    R --> GI(["Green-phase Implementation (per subspec)"])
    R --> RM2(["Realize Map"])
    PS2 --> IN
    CS2 --> IN
    GI --> IN
    ETM2 --> IN
    RM2 --> IN

    subgraph IN["7. Inspect + Constitution"]
        IN_G["Gate"] --> IN_R["Review"] --> IN_S["Synthesize"]
    end

    IN --> IF(["Implementation Failure Details"])
    PS2 --> S
    CS2 --> S
    IF --> S
    ETM2 --> S
    RM2 --> S

    subgraph S["8. Settle + Constitution"]
        S_T["Triage"] --> S_SC["Scope"] --> S_F["Fix"] --> S_C["Confirm"]
    end

    S -->|"domain: spec (full)"| A
    S -->|"domain: test (scoped)"| E
    S -->|"domain: impl (scoped)"| R
    S -->|no failures| DONE(["COMPLETE"])
```

## Conventions

- Sub-stages use dot notation: `Stage.SubStage` (e.g., `Harvest.Explore`)
- Stage names are proper nouns: Harvest, Ascertain, Inscribe, Layout, Etch, Realize, Inspect, Settle
- Each stage spec follows the section order: Inputs, Process, Outputs (or Iteration), Artifacts Written, Inspection (if applicable), Notes
- Settle can trigger scoped re-runs of upstream stages (Etch, Realize, Inspect) based on failure domain triage and blast-radius analysis
