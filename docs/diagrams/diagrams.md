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
    L --> E
    E --> R
    R --> IN
    IN --> S
    S -->|failures remain| A
    S -->|no failures| DONE([COMPLETE])
```

---

## 2. Artifact File Paths

Concrete paths for each artifact (substituting `{id}` = `{YYYY-MM-DD}-{branch-slug}`):

| Artifact | Concrete path | Committed? |
|----------|--------------|------------|
| Decomposition | `.haileris/features/{id}/decomposition.md` | Yes |
| Technical details | `.haileris/features/{id}/technical-details.md` | Yes |
| Ascertainments | `.haileris/features/{id}/ascertainments.md` | Yes |
| Spec | `.haileris/features/{id}/{feature_name}.feature` | Yes |
| Task list | `.haileris/features/{id}/tasks.md` | Yes |
| Red-phase tests | `tests/` (repo) | Yes |
| Green-phase implementation | `src/` (repo) | Yes |
| Implementation failure details | `.haileris/features/{id}/verify_{ts}.md` | Yes |
| Standards memory | `.haileris/memory/standards.md` | Yes |
| Test conventions memory | `.haileris/memory/test-conventions.md` | Yes |
| Constitution | `.haileris/constitution/constitution.md` | Yes |
| **Harvest inspection** | `.haileris/features/{id}/harvest-inspection.yaml` | Yes |
| **Layout inspection** | `.haileris/features/{id}/layout-inspection.yaml` | Yes |
| **Etch map** | `.haileris/features/{id}/etch-map.yaml` | Yes |
| **Etch inspection** | `.haileris/features/{id}/etch-inspection.yaml` | Yes |
| **Realize map** | `.haileris/features/{id}/realize-map.yaml` | Yes |
| **Realize inspection** | `.haileris/features/{id}/realize-inspection.yaml` | Yes |

Inspection artifacts (bold) all converge at stage 7 (Inspect) as the **Traceability Gate**.

---

## 3. Artifact Creation and Ingestion

```mermaid
flowchart TD
    DEC([Decomposition])
    IEC([Improved Engineered Context])
    SP([Spec])
    SS([Spec Subsets])
    RT([Red-phase Tests])
    ETM([Etch Map])
    GI([Green-phase Implementation])
    IM([Implementation Map])
    IF([Implementation Failure Details])
    CON([Constitution])

    H[1. Harvest] -->|creates| DEC
    DEC -->|ingested by| A[2. Ascertain]

    A -->|creates| IEC
    IEC -->|ingested by| I[3. Inscribe]
    CON -->|ingested by| I

    I -->|creates| SP
    SP -->|ingested by| L[4. Layout]
    CON -->|ingested by| L

    L -->|creates| SS
    SS -->|ingested by| E[5. Etch]
    CON -->|ingested by| E

    E -->|creates| RT
    E -->|creates| ETM
    SS -->|ingested by| R[6. Realize]
    RT -->|ingested by| R
    ETM -->|ingested by| R
    CON -->|ingested by| R

    R -->|creates| GI
    R -->|creates| IM
    SP -->|ingested by| IN[7. Inspect]
    GI -->|ingested by| IN
    ETM -->|ingested by| IN
    IM -->|ingested by| IN
    CON -->|ingested by| IN

    IN -->|creates| IF
    SP -->|ingested by| S[8. Settle]
    IF -->|ingested by| S
    CON -->|ingested by| S
```

---

## 3. Complete Pipeline

```mermaid
flowchart TD
    RAW["Raw Inputs<br>(source, feature details, context, tech)"]

    RAW --> H

    subgraph H["1. Harvest"]
        H_P["Data munging / context funnel"]
    end

    H --> DEC(["Decomposition (tentative)"])
    DEC --> A

    subgraph A["2. Ascertain"]
        A_P["Clarify ambiguities, contradictions, gaps"]
        A_P -->|needs ascertainment| A_OUT_Q["Ascertainment needs"]
        A_OUT_Q -->|answers fed back in| A_P
    end

    A --> IEC(["Improved Engineered Context"])
    IEC --> I

    subgraph I["3. Inscribe + Constitution"]
        I_P["Write spec with BIDs"]
    end

    I --> SP(["Spec<br>(BIDs + tech + delivery details)"])
    SP --> L

    subgraph L["4. Layout + Constitution"]
        L_P["Break spec into vertical<br>non-overlapping subsets"]
    end

    L --> SS(["Spec Subsets (BID groups)"])
    SS --> E

    subgraph E["5. Etch + Constitution"]
        E_P["Write red-phase tests per subset"]
    end

    E --> RT(["Red-phase Tests (per subset)"])
    E --> ETM2(["Etch Map"])
    SS --> R
    RT --> R
    ETM2 --> R

    subgraph R["6. Realize + Constitution"]
        R_P["Green-phase implementation per subset"]
    end

    R --> GI(["Green-phase Implementation (per subset)"])
    R --> IM2(["Implementation Map"])
    SP --> IN
    GI --> IN
    ETM2 --> IN
    IM2 --> IN

    subgraph IN["7. Inspect + Constitution"]
        IN_P["Review finished work against spec"]
    end

    IN --> IF(["Implementation Failure Details"])
    SP --> S
    IF --> S

    subgraph S["8. Settle + Constitution"]
        S_P["Refactor / resolve failures"]
    end

    S -->|failures remain| A
    S -->|no failures| DONE(["COMPLETE"])
```

---

## 4. Inspection Artifact Flow (Traceability Gate)

Each of stages 1, 4, 5, and 6 produces an inspection artifact. All four converge at stage 7 (Inspect) as the Traceability Gate — Inspect verifies BID coverage end-to-end before reviews begin.

```mermaid
flowchart LR
    H[1. Harvest] -.->|produces| SAUD["harvest-inspection.yaml"]
    L[4. Layout] -.->|produces| PAUD["layout-inspection.yaml"]
    E[5. Etch] -.->|produces| DAUD["etch-inspection.yaml"]
    R[6. Realize] -.->|produces| IAUD["realize-inspection.yaml"]

    SAUD --> IN["7. Inspect\n(Traceability Gate)"]
    PAUD --> IN
    DAUD --> IN
    IAUD --> IN
```

### What each inspection verifies

| Inspection | Validates |
|-------|-----------|
| `harvest-inspection.yaml` | decomposition.md and technical-details.md across 4 dimensions: template compliance (×2), artifact preflight, dependency doc coverage |
| `layout-inspection.yaml` | task list BID coverage: MISSING / HALLUCINATED / DUPLICATED / INSUFFICIENT / PARTIAL |
| `etch-inspection.yaml` | etch-map.yaml BID → test mapping: MISSING / HALLUCINATED / DUPLICATED / INSUFFICIENT / PARTIAL |
| `realize-inspection.yaml` | implementation map: completeness (BID → symbol), scope (unmapped symbols via AST), broken refs (ghost symbols) |

Missing or `pass: false` on any inspection artifact = **Critical** finding at Inspect.

On-demand re-inspection is available for layout, etch, and realize inspections (all support `--fix` except realize).