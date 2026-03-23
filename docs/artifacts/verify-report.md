# Verify Report

The user-readable output of Inspect. Produced at the end of the review phase, it summarises every finding raised by the five reviews and records the overall pass/fail status of the feature.

In pipeline input/output tables, this artifact appears as "Implementation failure details."

## What It Contains

- Overall status: `PASS` or `FAIL`
- Sections: Standards Compliance, Architecture Review, Complexity and Scope, Mutation Testing, Interface Contract Compliance
- Each finding entry: severity (Critical / High / Medium / Low / Nit), domain (`impl` / `test` / `spec`), BID (if applicable), description, and recommended fix
- A summary count of findings by severity and domain
- Timestamp of the review run

## Lifecycle

Created by Inspect after all five reviews complete. If the status is `FAIL`, Settle reads the report to determine its fix plan. Each review run produces a new timestamped file (append-only). Multiple verify reports may exist for a feature if Settle triggers a re-inspect.

## Path

`.haileris/features/{feature_id}/verify_{timestamp}.md`

## Committed

Yes. Every verify report is committed as part of the inspection trail, including re-inspect reports generated after Settle cycles.
