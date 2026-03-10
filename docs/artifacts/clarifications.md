# Ascertainments

The record of ambiguities surfaced during Ascertain and the answers that resolved them. Also records any spec ambiguities auto-resolved by Settle.

## What It Contains

A list of ascertainment entries, each with the ambiguity, the default assumption offered, and the answer received. During Settle, auto-resolved entries are appended with an `[AUTO-RESOLVED]` tag and include the rationale for the chosen default.

## Lifecycle

Created by Ascertain when the first ascertainment is recorded. Appended to as each round of ascertainment completes. Appended to again by Settle when spec-domain findings are auto-resolved. Never overwritten — entries accumulate as a decision log.

## Path

`.haileris/features/{feature_id}/ascertainments.md`

## Which Stages Read It

Inscribe reads ascertainments as input to spec writing.

## Committed

Yes.
