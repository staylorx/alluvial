# alluvial_usecases

The application layer: one use case per thing a caller can ask for — list, load,
save, validate, timeline, round-trip. It depends on the domain and on fpdart,
and on nothing else.

**Error style.** This package presents **FP-style tuples**: every use case
answers `Future<Either<DomainFailure, T>>`. A failure is a value, never a throw
(§4.9).
Doctrine: `~/hermes/projects/dart-flutter-bible` — this package follows it and
does not restate it. This repo's deviations and local wiring: [`AGENTS.md`](../../AGENTS.md).
What is built, proven and open: [`backlog/`](../../backlog/).
