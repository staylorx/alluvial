# alluvial_store_yaml

A folder of YAML files as the story store: the datasource, the canonical writer
(byte-identical to the Python writer), and the emission tool that proves it.

This store is deliberately not sembast — the files are authored, human-editable
and git-diffable, and their byte-identity is the product gate. Recorded as an
argued exception in [`AGENTS.md`](../../AGENTS.md).

**Error style.** This package presents **FP-style tuples**: the repository
answers `Future<Either<DomainFailure, T>>`, through the domain's shared
orchestration. No exceptions on the seam (§4.9).
Doctrine: `~/hermes/projects/dart-flutter-bible` — this package follows it and
does not restate it. This repo's deviations and local wiring: [`AGENTS.md`](../../AGENTS.md).
What is built, proven and open: [`backlog/`](../../backlog/).
