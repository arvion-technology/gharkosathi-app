# ADR 0001: the lifecycle lives in a pure class, not in screens

**Status:** accepted.

## Context

The job status is touched by the customer app, the worker app and the admin
dispute queue. Our first implementation kept `if (status == ...)` checks inside
each screen. Three copies of the rules appeared within a month, and the worker app
and customer app disagreed about whether a completed job could be cancelled.

## Decision

All twenty-three legal edges and eight guards live in `JobStateMachine`
(`lib/core/state_machine.dart`). The class imports no Flutter code. Screens call
`transition()` and render the result; they never decide an edge themselves.

Every transition appends a `JobEvent` to an immutable history, so the customer
timeline and the audit record are the same data.

## Consequences

- The lifecycle is tested with `dart test/state_machine_test.dart`, no widget tree.
- Illegal transitions throw `StateError` and are caught at the boundary, so a UI
  bug becomes a visible failure rather than a corrupted job.
- Adding a state means updating one table, the shared vectors and the diagram in
  the docs. That is a real cost, and it is the reason we have not added a state
  without a product requirement since.
