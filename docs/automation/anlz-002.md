# ANLZ-002: Standards Compliance

Checks each BID's Gherkin steps against project standards extracted from `standards.md`. A step that asserts behavior contradicting a project standard produces a finding. Source: [inscribe.md](../stages/inscribe.md) (ANLZ-002 section).

## Constraint

**Condition:** `standards.md` uses structured rule format — parseable (rule, scope) pairs.

The structured format uses one entry per rule:

```
RULE: <rule text>
SCOPE: <file glob or domain path>
```

When `standards.md` does not use this format (prose-only, unstructured), the check emits SKIP:

```
status: SKIP
detail: "standards.md does not use structured rule format; mechanical compliance check unavailable"
```

The structured format is the pipeline's mechanization lever: a one-time format decision that permanently enables mechanical checking.

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Standards file | `.haileris/project/standards.md` | Structured rule format (see above) |
| Gherkin spec files | `tests/features/{feature_id}/*.feature` | Gherkin with `@BID-NNN` tags |
| Subspec metadata | `tests/features/{feature_id}/*.feature` | `Domains:` lines per subspec |

### Standards Parsing

Standards are parsed as (rule_text, scope_glob) pairs. Lines matching `RULE:\s*(.+)` begin a rule; the next line matching `SCOPE:\s*(.+)` completes the pair. A `RULE:` without a subsequent `SCOPE:` before the next `RULE:` is dropped. Implementations should warn about unpaired rules.

### Assertion Keyword Extraction

For a given BID, find the scenario tagged with `@{bid}`. Collect all Then/And step text lines within that scenario (until the next Scenario or tag block). Tokenize step text into individual words (lowercased) to form the assertion keyword set.

### Contradiction Detection

Keyword-level contradiction detection compares a rule's directive and subject against assertion keywords:

- **Positive rules** (use, require, enforce, include, enable): the assertion contradicts the rule if assertion keywords include both the rule's subject and a negation indicator (not, no, without, absent, missing, excludes, omits).
- **Negative rules** (prohibit, avoid, disable, exclude): the assertion contradicts the rule if assertion keywords include both the rule's subject and an affirmation indicator (uses, includes, enables, creates, returns).

## Behavior

```gherkin
Feature: ANLZ-002 Standards Compliance
  Checks each BID's Gherkin steps against project standards.

  Rule: Constraint gate — standards.md must use structured rule format

    Scenario: standards.md does not exist
      Given "standards.md" does not exist in the project directory
      When the standards compliance check runs
      Then the check status is SKIP
      And the detail is "standards.md not found"

    Scenario: standards.md exists but contains no RULE: entries
      Given "standards.md" exists but contains no lines matching "RULE:"
      When the standards compliance check runs
      Then the check status is SKIP
      And the detail is "standards.md does not use structured rule format; mechanical compliance check unavailable"

    Scenario: standards.md has RULE: lines but no complete RULE/SCOPE pairs
      Given "standards.md" contains RULE: lines but no corresponding SCOPE: lines
      When the standards compliance check runs
      Then the check status is SKIP
      And the detail is "No parseable RULE/SCOPE pairs found in standards.md"

  Rule: Violation detection — BID assertions must comply with applicable standards

    Scenario: A BID's domain matches a rule scope and assertions are consistent
      Given a standard "RULE: use TLS for all connections" with "SCOPE: src/network"
      And "BID-001" is in a subspec with Domains: "src/network"
      And "BID-001" Then-step keywords include "connection" and "encrypted"
      When the standards compliance check runs
      Then no finding is produced for "BID-001"

    Scenario: A BID's assertions contradict a positive rule
      Given a standard "RULE: use TLS for all connections" with "SCOPE: src/network"
      And "BID-001" is in a subspec with Domains: "src/network"
      And "BID-001" Then-step keywords include "connection" and "without"
      When the standards compliance check runs
      Then a finding is produced for "BID-001" with check_type "STANDARDS_VIOLATION"
      And the finding detail contains "contradicts standard" and "use TLS for all connections"

    Scenario: A BID's assertions contradict a negative rule
      Given a standard "RULE: prohibit plaintext passwords" with "SCOPE: src/auth"
      And "BID-002" is in a subspec with Domains: "src/auth"
      And "BID-002" Then-step keywords include "passwords" and "creates"
      When the standards compliance check runs
      Then a finding is produced for "BID-002" with check_type "STANDARDS_VIOLATION"
      And the finding detail contains "contradicts standard" and "prohibit plaintext passwords"

    Scenario: A BID's domain does not match any rule scope
      Given a standard "RULE: use TLS for all connections" with "SCOPE: src/network"
      And "BID-003" is in a subspec with Domains: "src/auth"
      When the standards compliance check runs
      Then no finding is produced for "BID-003"

    Scenario: A BID has no Domains: declaration — no rules apply
      Given a standard with "SCOPE: src/network"
      And "BID-004" is in a subspec with no Domains: line
      When the standards compliance check runs
      Then no finding is produced for "BID-004"

    Scenario: A wildcard scope matches all BIDs
      Given a standard "RULE: require logging" with "SCOPE: **/*"
      And "BID-001" is in a subspec with Domains: "src/users"
      And "BID-001" Then-step keywords include "logging" and "not"
      When the standards compliance check runs
      Then a finding is produced for "BID-001" with check_type "STANDARDS_VIOLATION"

    Scenario: Multiple rules with overlapping scopes produce independent findings
      Given a standard "RULE: use TLS" with "SCOPE: src/network"
      And a standard "RULE: require auth" with "SCOPE: src/network"
      And "BID-001" contradicts both rules
      When the standards compliance check runs
      Then two findings are produced for "BID-001"
```

## Output

ANLZ-002 does not write a standalone inspection artifact. Its result is part of the Inscribe.Verify consistency check output, alongside ANLZ-001. Implementations may emit the result to stdout for tooling use.

Results follow the standard Finding format:

```
Finding:
  bid          — the BID whose steps contradict the standard
  check_type   — "STANDARDS_VIOLATION"
  detail       — rule text, scope, and contradiction description
```

## Edge Cases

- **No `standards.md`:** If the file is absent, emit SKIP with detail "standards.md not found." This is not a FAIL — the project may not have defined standards yet.
- **Rule with wildcard scope:** `SCOPE: *` or `SCOPE: **/*` matches all domains. Every BID is checked against this rule.
- **BID with no `Domains:` line:** The BID has an empty domain set; all rules are outside scope; ANLZ-002 produces zero findings for this BID. (Missing domains is an ANLZ-003 concern.)
- **Multiple rules with overlapping scopes:** Each rule is checked independently. A BID can violate multiple rules, producing multiple findings.
- **Contradiction detection false negatives:** Keyword-based contradiction detection catches only contradictions that manifest as direct negation patterns. This is an accepted limitation of the M-c boundary — semantic analysis requires judgment.
- **Rule without SCOPE line:** A `RULE:` line not followed by a `SCOPE:` line before the next `RULE:` is dropped. Implementations should warn about unpaired rules.
