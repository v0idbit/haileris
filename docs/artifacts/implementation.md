# Implementation

The green-phase production code. Source stubs (data contract type definitions and function signatures with placeholder bodies) are created by Etch at `Domains:` paths. Realize implements within these stubs — replacing placeholder bodies with behavioral code that makes tests pass. Updated by Settle when implementation-domain findings are fixed.

## What It Contains

Production code that makes all red-phase tests pass. Module structure, data contract type definitions, and function signatures are established by Etch's stubs. Realize fills in the implementations and may add private helpers; the public interface is fixed by Etch. Scoped strictly to the BIDs in the spec.

## Lifecycle

Stubs written by Etch. Implemented by Realize subspec-by-subspec within the stub structure. Updated by Settle (via implementation fixes) when Inspect finds Critical, High, or Medium `domain: impl` findings. The test suite must be fully green after each update. Changes are scoped strictly to the spec's BIDs.

## Path

`src/` (written directly to the project repo)

## Committed

Yes, as part of normal project source.
