# alluvial_store_memory

An in-memory story store, for tests and dry runs — the second adapter behind the
same contract the folder store implements.

**Error style.** This package presents **FP-style tuples**: the repository
answers `Future<Either<DomainFailure, T>>`, through the domain's shared
orchestration. No exceptions on the seam (§4.9).
Doctrine: `~/hermes/projects/dart-flutter-bible` — this package follows it and
does not restate it. This repo's deviations and local wiring: [`AGENTS.md`](../../AGENTS.md).
What is built, proven and open: [`backlog/`](../../backlog/).
