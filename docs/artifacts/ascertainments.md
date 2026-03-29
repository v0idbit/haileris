# Ascertainments

The record of ambiguities surfaced during Ascertain and the answers that resolved them. Also records any spec ambiguities auto-resolved by Settle.

## What It Contains

A list of ascertainment entries, each with the ambiguity, the default assumption offered, and the answer received. During Settle, when `auto_resolve_spec` is enabled in [pipeline config](config.md), auto-resolved entries are appended with an `[AUTO-RESOLVED]` tag and include the rationale for the chosen default. When `auto_resolve_spec` is false (default), spec-domain findings escalate to the user.

## Lifecycle

Created by Ascertain when the first ascertainment is recorded. Appended to as each round of ascertainment completes. When `auto_resolve_spec` is enabled, appended to by Settle when spec-domain findings are auto-resolved. Append-only — entries accumulate as a decision log.

## Path

`.haileris/features/{feature_id}/ascertainments.md`

## Which Stages Read It

Inscribe reads ascertainments as input to spec writing. Settle reads and appends to ascertainments when `auto_resolve_spec` is enabled (auto-resolved spec findings with `[AUTO-RESOLVED]` tag).

## Committed

Yes.
