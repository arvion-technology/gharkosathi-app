# Architecture

GharKo Sathi is a Flutter app for booking verified home-service workers in Nepal.
This repository is the architecture sample extracted from the production app; it
is not the published binary. The live service runs at
[gharkosewa.com](https://gharkosewa.com).

Three constraints shaped the code:

1. A worker cannot be matched before KYC is verified.
2. Money sits in escrow until completion is confirmed, and a dispute freezes it.
3. The worker app is used in basements and stairwells, so a job update made
   offline must survive the process being killed and must apply exactly once.

## Layers

```
lib/
├── main.dart, app.dart      MaterialApp shell, theme, route table
├── router.dart              named routes; screens receive typed arguments
├── theme/arvion_theme.dart  colour and component tokens for Material 3
├── core/
│   ├── models.dart          Service, Worker, Job, JobEvent, WalletEntry, Dispute, Quote
│   ├── state_machine.dart   JobStateMachine: edges, guards, transitions
│   ├── offline_queue.dart   ordered idempotent queue with backoff and JSON persistence
│   ├── repository.dart      HomeServicesRepository + InMemoryRepository
│   └── mock_data.dart       seeded services, workers, sample job
└── screens/                 eight screens, one file each
```

The dependency direction is `screens → repository → (models, state machine)`.
`core/` imports no Flutter widgets at all. That is what makes the state machine
and the queue testable with plain `dart`, without a widget tree or a device.

## The job lifecycle

```
draft → requested → matching → matched → enRoute → inProgress → completed → paid → closed
                        │          │         │                    │
                        └ cancelled┘         └──────────── disputed ──────┐
                                                                          ↓
                                                                    refunded → closed
```

Twelve states, twenty-three legal edges and eight guards. The table is a
`Map<JobStatus, Set<JobStatus>>` in `JobStateMachine`, not a switch inside a
screen. The guards are product rules:

- `matching → matched` needs a worker id.
- `completed → paid` needs escrow held **and** proof uploaded.
- `matched/enRoute → cancelled` needs the late-cancellation fee accepted.
- `inProgress/completed → disputed` needs a reason of at least 10 characters.
- `paid → disputed` needs to be inside the dispute window.
- `disputed → refunded` needs a completed review.

Escrow is not a second balance. `Job.escrow` derives `held`, `releasable`,
`released` or `frozen` from the status, so the wallet and the tracking screen
cannot disagree.

## Offline queue

`OfflineQueue` stores `OfflineOperation` entries with an idempotency key, the
mutation type and a payload. Rules:

- Enqueue is deduplicated by key.
- Flush is ordered and stops at the first failure; a later update never overtakes
  an earlier one.
- Failure increments the attempt count and schedules exponential backoff
  (1s, 2s, 4s, 8s, capped at 30s).
- The queue serialises to JSON and restores at launch, before the first screen
  paints.
- Five failed attempts mark the head as exhausted so the UI can ask the user,
  rather than retrying forever.

The server side of the contract is an `Idempotency-Key` header carrying the same
key. The sample stops at the queue and an in-memory repository; the HTTP client is
not included.

## KYC

KYC is a separate state machine: `notStarted → documentsUploaded → inReview →
verified | rejected`. A rejected application can resubmit without losing captured
documents. The worker profile badge reads `Worker.isVerified`, which is derived
from `KycState.verified`; the matching repository filters on it, so a screen
cannot accidentally display an unverified worker as bookable.

## What the sample leaves out

- The HTTP repository, secure token storage and push notifications.
- Real document upload, camera capture and the reviewer console.
- Payment-provider integration. The wallet shows escrow semantics, not a
  gateway.
- State management packages. See `docs/adr/0003-no-third-party-state.md` for the
  trade-off.

## Tests

Two layers, both runnable from a fresh clone:

```bash
npm test                            # JavaScript mirror of the state machine + queue (17 cases)
dart test/state_machine_test.dart   # pure Dart lifecycle tests against shared vectors
dart test/offline_queue_test.dart   # pure Dart queue tests
flutter analyze lib                 # static analysis of the Flutter source
```

`test/vectors/job_flow.json` is the shared contract. The Dart tests and the
JavaScript mirror both read it, so a lifecycle rule that changes on one side
fails on the other.
