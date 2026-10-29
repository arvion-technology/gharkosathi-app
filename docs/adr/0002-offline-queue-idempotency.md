# ADR 0002: ordered queue with idempotency keys over fire-and-forget writes

**Status:** accepted.

## Context

Workers update job status from inside buildings with no signal. Our first
implementation retried the HTTP call in the background. Two failures followed:

1. A retry after a timeout applied the same status twice, producing duplicate
   wallet entries.
2. A queued "completed" update could overtake a queued "in progress" update after
   a reconnect, because each request retried independently.

## Decision

Every mutation becomes an `OfflineOperation` with a key, a type and a payload.
The queue is ordered and stops at the first failure. The same key is sent as the
`Idempotency-Key` header, so a retry of a request that actually succeeded is a
no-op on the server. The queue is persisted as JSON and restored before the first
screen paints.

## Consequences

- A later update never overtakes an earlier one, even if the server would accept
  it.
- A poison operation blocks the queue. After five attempts the UI marks it
  exhausted and offers to discard it; the alternative, silently dropping it.
  loses the user's action without telling them.
- The queue is not a sync engine. It handles this app's ordered job mutations,
  not arbitrary concurrent edits. A general conflict-resolution layer would be a
  separate project (see `sync-kit` in this series).
