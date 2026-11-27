# alluvial_testing

The shared repository contract suite every store adapter must pass — it is what
makes two adapters behaving identically a checkable fact rather than a
coincidence.

**Error style.** Not a seam of its own: it asserts the **FP-style tuples**
contract (`Future<Either<DomainFailure, T>>`) that every store adapter presents
(§4.9).
Doctrine: `~/hermes/projects/dart-flutter-bible` — this package follows it and
does not restate it. This repo's deviations and local wiring: [`AGENTS.md`](../../AGENTS.md).
What is built, proven and open: [`backlog/`](../../backlog/).
