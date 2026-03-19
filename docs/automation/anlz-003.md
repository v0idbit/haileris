# ANLZ-003: Domain Coverage

Fully mechanical consistency check. Verifies that every subspec referenced by primary scenario `@traces` tags has declared `Domains:` metadata. Source: [inscribe.md](../stages/inscribe.md) (ANLZ-003 section).

## Inputs

| Input | Path | Format |
|-------|------|--------|
| Primary spec | `tests/features/primary.feature` | Gherkin with `@traces` tags |
| Subspec files | `tests/features/{deliverable}.feature` | Gherkin with `Domains:` lines |

### Gherkin Metadata Formats

**`@traces` tag** on primary spec scenarios:
```gherkin
@BID-050 @traces:BID-003,BID-015,BID-024
Scenario: Full user workflow
```

**`Domains:` line** in subspec files (typically in a comment or description block):
```
Domains: src/users, src/auth
```

Multiple domains are comma-separated. The `Domains:` line may use singular or plural form (`Domain:` or `Domains:`).

## Algorithm

Five steps, exactly as specified in `inscribe.md`:

```
FUNCTION run_anlz003(spec_dir):
  findings ← empty list

  — STEP 1: Parse domains from all subspecs
  subspec_domains ← empty map of filepath → list of domain paths
  subspecs_without_domains ← empty set

  FOR EACH file IN glob(spec_dir, "*.feature"):
    IF file.name = "primary.feature":
      CONTINUE

    domains ← parse_domains_line(file)
    subspec_domains[file] ← domains

    IF domains is empty:
      subspecs_without_domains.add(file)
      ADD finding("N/A", check_type="MISSING",
                  detail="Subspec {file.name} has no Domains: declaration")

  — STEP 2: Parse traces from primary spec
  primary_path ← spec_dir / "primary.feature"
  IF primary_path does not exist:
    ADD finding("N/A", check_type="MISSING", detail="primary.feature not found")
    RETURN InspectionResult(pass=false, ...)

  traces ← parse_traces(primary_path)
  — traces: map of parent_bid → list of traced subspec BIDs

  — STEPS 3–5: Resolve and verify
  FOR EACH (parent_bid, traced_bids) IN traces:
    FOR EACH traced_bid IN traced_bids:
      — Step 3: Resolve BID to its parent subspec file
      subspec_file ← find file in spec_dir containing "@{traced_bid}"
      IF subspec_file is null:
        ADD finding(parent_bid, check_type="MISSING",
                    detail="Primary scenario {parent_bid} traces {traced_bid} but BID not found in any subspec")
        CONTINUE

      IF subspec_file.name = "primary.feature":
        CONTINUE    — skip primary self-references

      — Step 4–5: Check if resolved subspec has domains
      IF subspec_file IN subspecs_without_domains:
        ADD finding(parent_bid, check_type="MISSING",
                    detail="Primary scenario {parent_bid} traces through {subspec_file.name} via {traced_bid}, but that subspec has no Domains: declaration")

  pass ← findings is empty
  RETURN InspectionResult(timestamp=now_utc(), pass, [check_result], findings)
```

### parse_domains_line

```
FUNCTION parse_domains_line(file_path):
  content ← read(file_path)
  domains ← empty list

  FOR EACH match OF regex "^\s*Domains?:\s*(.+)" (multiline) IN content:
    raw ← match.group(1), trimmed
    FOR EACH part IN split(raw, ","):
      part ← trim(part)
      IF part is non-empty:
        domains.append(part)

  RETURN domains
```

### parse_traces

```
FUNCTION parse_traces(primary_path):
  content ← read(primary_path)
  lines ← split content into lines
  traces ← empty map of parent_bid → list of traced BIDs

  FOR EACH line IN lines:
    IF line contains regex "@traces:([\w,\s-]+)":
      raw_bids ← captured group, split on ","
      traced_bids ← [trim(b) for b in raw_bids if trim(b) is non-empty]

      — Find parent BID: scan this line and preceding lines for @BID-NNN
      parent_bid ← first "@(BID-\d+)" match found scanning backward from current line

      IF parent_bid found:
        traces[parent_bid] ← traced_bids

  RETURN traces
```

### resolve_bid_to_file

```
FUNCTION resolve_bid_to_file(bid, spec_dir):
  FOR EACH file IN glob(spec_dir, "*.feature"):
    content ← read(file)
    IF "@{bid}" IN content:
      RETURN file
  RETURN null
```

## Output

ANLZ-003 does not write a standalone inspection artifact. Its result is part of the Inscribe.Verify consistency check output. Implementations may emit the result to stdout for tooling use.

## Edge Cases

- **No subspecs:** If only `primary.feature` exists, Step 1 produces no findings (no subspecs to check). Steps 3–5 will produce MISSING findings for any traced BIDs that don't resolve.
- **Subspec with `Domains:` but empty value:** `Domains:   ` (whitespace only) is treated as no domains — same as missing the line.
- **BID in multiple files:** `resolve_bid_to_file` returns the first file found. BIDs should be unique across files; duplicate BIDs are a separate validation concern.
- **Primary scenario without `@traces`:** No entries in the traces map for that scenario. ANLZ-003 does not flag this — it only checks scenarios that *have* traces. Missing `@traces` tags are an ANLZ-004 concern.
- **Traced BID resolves to primary.feature:** Skip — primary self-references are not domain coverage issues. This happens when a primary scenario traces another primary BID.
