# alluvial_domain

The alluvial story model: the three entities (character, beat, appearance), the
sealed failure hierarchy, the codec, the validator, and the contracts a store is
built on. Pure Dart — no I/O, no Flutter.

**Error style.** This package presents **FP-style tuples**: repository calls
answer `Future<Either<DomainFailure, T>>`, and the datasource seam answers the
unrun `TaskEither<DatasourceFailure, T>` — `.run()` it. There are no exceptions
on the seam, by design (§4.9).
Doctrine: `~/hermes/projects/dart-flutter-bible` — this package follows it and
does not restate it. This repo's deviations and local wiring: [`AGENTS.md`](../../AGENTS.md).
What is built, proven and open: [`backlog/`](../../backlog/).
