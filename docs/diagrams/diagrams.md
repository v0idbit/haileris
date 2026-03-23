# Pipeline Diagrams

## 1. Stage Flow

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

---

## 2. Artifact File Paths

Concrete paths for each artifact (substituting `{feature_id}` = `{YYYY-MM-DD}-{branch-slug}`):

| Artifact | Concrete path | Committed? |
|----------|--------------|------------|
| Decomposition | `.haileris/features/{feature_id}/decomposition.md` | Yes |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Yes |
| Ascertainments | `.haileris/features/{feature_id}/ascertainments.md` | Yes |
| Primary spec | `tests/features/primary.feature` | Yes |
| Subspecs | `tests/features/{deliverable}.feature` | Yes |
| Delivery order | `.haileris/features/{feature_id}/delivery-order.yaml` | Yes |
| Red-phase tests | `tests/` (repo) | Yes |
| Green-phase implementation | `src/` (repo) | Yes |
| Implementation failure details | `.haileris/features/{feature_id}/verify_{timestamp}.md` | Yes |
| Project standards | `.haileris/project/standards.md` | Yes |
| Project test conventions | `.haileris/project/test-conventions.md` | Yes |
| Constitution | `.haileris/project/constitution.md` | Yes |
| **Harvest inspection** | `.haileris/features/{feature_id}/harvest-inspection.yaml` | Yes |
| **Layout inspection** | `.haileris/features/{feature_id}/layout-inspection.yaml` | Yes |
| Etch map | `.haileris/features/{feature_id}/etch-map.yaml` | Yes |
| **Etch inspection** | `.haileris/features/{feature_id}/etch-inspection.yaml` | Yes |
| Realize map | `.haileris/features/{feature_id}/realize-map.yaml` | Yes |
| **Realize inspection** | `.haileris/features/{feature_id}/realize-inspection.yaml` | Yes |
| Harvest metadata | `.haileris/project/last-harvest.json` | Yes |
| Pipeline state | `.haileris/features/{feature_id}/pipeline-state.yaml` | Yes |

Inspection artifacts (bold) all converge at stage 7 (Inspect) as the **Traceability Gate**.

---

## 3. Artifact Creation and Ingestion

```mermaid
flowchart TD
    DEC([Decomposition])
    ID([Improved Decomposition])
    ASC([Ascertainments])
    PS([Primary Spec<br>primary.feature])
    CS([Deliverable Subspecs<br>deliverable.feature])
    RT([Red-phase Tests])
    ETM([Etch Map])
    GI([Green-phase Implementation])
    RM([Realize Map])
    IF([Implementation Failure Details])
    CON([Constitution])

    H[1. Harvest] -->|creates| DEC
    H -->|creates| TD([Technical Details])
    DEC -->|ingested by| A[2. Ascertain]
    A -->|creates| ID
    A -->|creates| ASC
    ID -->|ingested by| I[3. Inscribe]
    ASC -->|ingested by| I
    TD -->|ingested by| I
    CON -->|ingested by| I

    I -->|creates| PS
    PS -->|ingested by| L[4. Layout]
    CON -->|ingested by| L

    L -->|creates| CS
    L -->|"compiles (derived from Requires/Provides)"| DO([Delivery Order])
    CS -->|ingested by| E[5. Etch]
    TD -->|ingested by| E
    CON -->|ingested by| E

    E -->|creates| RT
    E -->|creates| ETM
    CS -->|ingested by| R[6. Realize]
    TD -->|ingested by| R
    RT -->|ingested by| R
    ETM -->|ingested by| R
    CON -->|ingested by| R

    R -->|creates| GI
    R -->|creates| RM
    PS -->|ingested by| IN[7. Inspect]
    CS -->|ingested by| IN
    GI -->|ingested by| IN
    ETM -->|ingested by| IN
    RM -->|ingested by| IN
    CON -->|ingested by| IN

    IN -->|creates| IF
    PS -->|ingested by| S[8. Settle]
    CS -->|ingested by| S
    IF -->|ingested by| S
    CON -->|ingested by| S
```

---

## 3a. Spec Composition Flow

Inscribe creates the primary spec. Layout decomposes it into subspecs and adds `@traces` tags. ANLZ-004 validates at Layout.Verify that subspecs compose back into the primary spec.

```mermaid
flowchart LR
    PS_IN["primary.feature<br>(from Inscribe)"] --> DEC["Layout.Decompose"]

    DEC -->|"step 2"| CS["{deliverable}.feature<br>(per-deliverable BIDs)"]
    DEC -->|"step 3"| RP["Requires/Provides<br>per BID"]
    DEC -->|"step 4"| TR["@traces tags<br>added to primary.feature"]

    CS --> V["Layout.Verify<br>ANLZ-003, ANLZ-004, ANLZ-005"]
    RP --> V
    TR --> V

    V -->|"validates composition"| RESULT{"Subspecs cover<br>all primary steps?"}
    RESULT -->|PASS| AP["Layout.Approve"]
    RESULT -->|FAIL| FIX["Show uncovered steps;<br>user fixes or proceeds"]
```

---

## 4. Complete Pipeline

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

    subgraph S["8. Settle + Constitution"]
        S_T["Triage"] --> S_SC["Scope"] --> S_F["Fix"] --> S_C["Confirm"]
    end

    S -->|"domain: spec (full)"| A
    S -->|"domain: test (scoped)"| E
    S -->|"domain: impl (scoped)"| R
    S -->|no failures| DONE(["COMPLETE"])
```

---

## 5. Inspection Artifact Flow (Traceability Gate)

Each of stages 1, 4, 5, and 6 produces an inspection artifact. All four converge at stage 7 (Inspect) as the Traceability Gate — Inspect verifies BID coverage end-to-end before reviews begin.

```mermaid
flowchart LR
    H[1. Harvest] -.->|produces| SAUD["harvest-inspection.yaml"]
    L[4. Layout] -.->|produces| PAUD["layout-inspection.yaml"]
    E[5. Etch] -.->|produces| DAUD["etch-inspection.yaml"]
    R[6. Realize] -.->|produces| IAUD["realize-inspection.yaml"]

    SAUD --> IN["7. Inspect<br>(Traceability Gate)"]
    PAUD --> IN
    DAUD --> IN
    IAUD --> IN
```

### What each inspection verifies

| Inspection | Validates |
|-------|-----------|
| `harvest-inspection.yaml` | decomposition.md and technical-details.md across 4 dimensions: template compliance (×2), artifact preflight, dependency doc coverage |
| `layout-inspection.yaml` | subspec BID coverage: MISSING / HALLUCINATED / DUPLICATED / INSUFFICIENT / PARTIAL* |
| `etch-inspection.yaml` | etch-map.yaml BID → test mapping: MISSING / HALLUCINATED / DUPLICATED* / INSUFFICIENT / PARTIAL* |
| `realize-inspection.yaml` | Realize map: completeness (BID → derivation), scope† (unmapped derivations via AST), broken refs (ghost derivations) |

*Agent-evaluated — no mechanical verification; inspection records SKIP. See [automation specs](../automation/README.md).
†Constraint-gated — has a mechanical algorithm but requires AST tooling; records SKIP when unavailable.

Missing or `pass: false` on any inspection artifact = **Critical** finding at Inspect.

On-demand re-inspection is available for layout, etch, and realize inspections (all support `--fix` except realize).
