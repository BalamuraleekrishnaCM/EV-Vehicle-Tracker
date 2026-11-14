# ADR-0001: Local-first ownership with optional cloud sync

Status: Accepted as design direction; implementation pending.

## Context
The app must work without internet, subscription or mandatory account. EV data includes sensitive routes, finance and vehicle identifiers.

## Decision
SQLite is canonical for user-entered records. Flutter repositories abstract storage. Optional Supabase provides authenticated sync and private document storage with per-user RLS; a user may never enable it. A versioned outbox reconciles changes and explicitly surfaces conflicts.

## Consequences
More sync complexity, but offline resilience and user control. Tests must cover conflict, deletion, authorization and restore.
