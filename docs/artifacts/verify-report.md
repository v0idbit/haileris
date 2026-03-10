# Verify Report

The user-readable output of Inspect. Produced at the end of the review phase, it summarises every finding raised by the four reviews and records the overall pass/fail status of the feature.

## What It Contains

- Overall status: `PASSED` or `FAILED`
- Sections: Architecture Review, Code Review, Security Review, Performance Review
- Each finding entry: severity (Critical / High / Medium / Low), domain (`impl` / `test` / `spec`), BID (if applicable), description, and recommended fix
- A summary count of findings by severity and domain
- Timestamp of the review run

## Lifecycle

Created by Inspect after all four reviews complete. If the status is `FAILED`, Settle reads the report to determine its fix plan. The report is not overwritten — each review run produces a new timestamped file. Multiple verify reports may exist for a feature if Settle triggers a re-inspect.

## Path

`.haileris/features/{feature_id}/verify_{timestamp}.md`

## Committed

Yes. Every verify report is committed as part of the inspection trail, including re-inspect reports generated after Settle cycles.
