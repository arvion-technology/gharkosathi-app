# ADR 0003: no third-party state or router package in the sample

**Status:** accepted for the sample; the production app uses Riverpod.

## Context

The production GharKo Sathi app uses Riverpod for dependency injection and a
declarative router. Publishing that source would be accurate to the product but
would make the repository harder to read in isolation: the reviewer would need
`flutter pub get`, a matching Riverpod major version and provider graph context
before the first screen rendered.

The repository's job is to show the architecture and the two pieces of logic that
were genuinely difficult: the job state machine and the offline queue.

## Decision

The sample uses `ChangeNotifier`-free, plain `StatefulWidget` screens, a small
`InMemoryRepository` behind an abstract interface, and a route table with
`onGenerateRoute`. Nothing outside the Flutter SDK is imported in `lib/`.

## Consequences

- `flutter analyze lib` and the Dart tests run without network access.
- The repository boundary is explicit in `core/repository.dart`. Swapping in the
  production HTTP implementation is a file replacement, not a screen rewrite.
- The sample does not demonstrate Riverpod's provider graph. That is a real
  omission from the production architecture, and this ADR exists so the gap is
  stated rather than implied.
