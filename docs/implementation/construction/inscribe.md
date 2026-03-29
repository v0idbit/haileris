# Inscribe — Greenfield Construction

## Stage inputs

| Artifact | Path | Source |
|----------|------|--------|
| Improved decomposition | `.haileris/features/{feature_id}/decomposition.md` | Updated by Ascertain |
| Ascertainments | `.haileris/features/{feature_id}/ascertainments.md` | Ascertain |
| Technical details | `.haileris/features/{feature_id}/technical-details.md` | Harvest |
| Constitution (when present) | `.haileris/project/constitution.md` | Project-wide |

## Stage outputs

| Artifact | Path |
|----------|------|
| Primary spec | `tests/features/{feature_id}/primary.feature` |

Inscribe produces exactly one file. Subspecs, `@traces` tags, delivery order, and subspec metadata (`Domains:`, `Requires:`, `Provides:`) are all Layout's responsibility.

## Components to implement

### 1. Primary spec author (Inscribe.Author)

Implement a component that, given the improved decomposition, ascertainments, and technical details, produces `primary.feature`. The spec contains:

- **Feature-level tags:** `@status:inscribing` and `@type:greenfield`
- **Scenarios:** End-to-end workflow scenarios covering the feature's observable behavior
- **BID tags:** Each scenario carries exactly one `@BID-NNN` tag, sequentially numbered from `001`
- **Steps:** Standard Gherkin Given/When/Then

**Behavioral level:** Scenarios describe observable behavior — user actions, system responses, state changes visible at the feature boundary. Domain language only ("When the user submits the form"). Implementation decisions (data contract types, function signatures, concrete data shapes) begin at Etch.

**What belongs here:** BID tags and status/type metadata only. Subspec-specific metadata (`Domains:`, `Requires:`, `Provides:`, `@traces`) belongs to Layout.

When a constitution exists, the component checks all scenarios against it. Constitution violations are Critical severity.

### 2. ANLZ-001: Contradiction detection (Inscribe.Verify)

Implement the typed proposition verification defined in [anlz-001.md](../../automation/anlz-001.md). Tier 3 (J-v): the translation of Gherkin steps into typed propositions requires judgment; the contradiction detection algorithm (pairwise state contradictions, numeric bound contradictions, transitive contradictions) is mechanical.

### 3. ANLZ-002: Standards compliance (Inscribe.Verify)

Implement the keyword-level rule matching defined in [anlz-002.md](../../automation/anlz-002.md). Tier 2 (M-c): fully mechanical when `standards.md` uses the structured `RULE:`/`SCOPE:` format. Emits SKIP when the format constraint is not met.

### 4. User approval gate (Inscribe.Approve)

Implement a user gate with three options and corresponding status tag management:

| User choice | Action | Status tag |
|-------------|--------|------------|
| Approve | Proceed to Layout | `@status:approved` |
| Request changes (minor) | Edit in place; re-run Inscribe.Verify; present again | `@status:inscribing` |
| Request changes (needs ascertainment) | Return to Ascertain | `@status:ascertaining` |

## Orchestration

**Sub-stage ordering:** Author → Verify (ANLZ-001 + ANLZ-002) → Approve.

On FAIL from verification checks: present which checks failed; let the user decide whether to fix or proceed.

**State transitions:**
- Approve → advance pipeline state to Layout
- Needs ascertainment → loop back to Ascertain (no pipeline state loop — Ascertain is upstream)

## Scope boundaries

- Inscribe produces exactly one file: `tests/features/{feature_id}/primary.feature`
- The primary spec contains BID tags and status/type metadata only
- Subspec-specific metadata belongs to Layout
- Implementation directories (`src/`, `tests/unit/`, `tests/integration/`) are downstream stages' responsibility

## Criteria reference

[Inscribe correctness criteria](../criteria/inscribe.md)
