# AGENTS.md — instructions for agents working in this repo

The alluvial story store — a folder of authored YAML, the Python pipeline that
draws it, and the Dart port that reads, checks, writes and redraws it.

## Reading order

1. The bible compact blob: `~/hermes/projects/dart-flutter-bible/docs/00-compact.md`
   (and the section files beside it). It is the doctrine — this file never
   restates a rule, it points at one.
2. This file — this repo's deviations and local wiring only.
3. The board: [`backlog/`](backlog/) — what is built, what is proven, what is
   deliberately absent, and the open questions.

If this file contradicts the bible, the bible wins until changed by proposal.

## What this repo is

Two halves of one thing:

- **`scripts/` + `stories/` + `out/` + `web/`** — the original Python pipeline
  that produced every approved chart, the story store itself, the committed
  SVGs, and the Eleventy publisher. `stories/<key>.yaml` is the source of truth;
  read [`STORY-SCHEMA.md`](STORY-SCHEMA.md) before touching one.
- **`dart/`** — a Dart pub workspace (Topology B) that ports the store, the
  validator, an agent-facing CLI and **both renderers**. Both are byte-identical
  to the Python engine, and byte-identity is the gate. Start at
  [`dart/README.md`](dart/README.md).

## Local wiring

- `cd dart && melos run gate` — the workspace gate: analyze clean, then every
  package's suite. The workspace root is not a package, so `dart test` there
  exits 65; `melos run <task>` is the one entry point (§2.1, §11).
- `python3 dart/tool/render_reference.py <dir>` + `number_corpus.py <dir>` —
  generate the reference corpus the renderer gate compares against. The Dart
  side SKIPS when it is absent; it never invents a reference.
- `python3 scripts/stories_yaml.py validate` — the Python-side store gate.
- Never `git add -A` here: a parallel session can leave unrelated edits in the
  tree. Stage by path.

## Error style

Every package declares it in its barrel doc comment and its README (§4.9). The
default in this repo is **FP-style tuples**, and the deviations from it are:

- `alluvial_domain` — presents **FP-style tuples**: repository calls answer
  `Future<Either<DomainFailure, T>>`; the datasource seam answers the unrun
  `TaskEither<DatasourceFailure, T>`. No exceptions on the seam.
- `alluvial_usecases` — **FP-style tuples**: `Future<Either<DomainFailure, T>>`.
- `alluvial_store_yaml`, `alluvial_store_memory` — **FP-style tuples**, through
  the shared orchestration: `Future<Either<DomainFailure, T>>`.
- `alluvial_render` — **plain values**: an SVG string (or a rendered-chart
  record). It is a pure function of a decoded story and has no failure channel;
  a caller that asks for the wrong shape is a usage error.
- `alluvial_cli` — **plain values**: `Future<int>`, an exit code. It is the
  composition root and therefore the ring — the one place arguments exceptions
  are caught (§4.8).
- `alluvial_testing` — not a seam; it carries the contract suite every store
  adapter must pass.

## Deviations from `dart-flutter-bible`

Expected (doctrine) vs actual (this repo). Status: open unless marked.

1. **No melos script contract** — root `dart/pubspec.yaml`
   - Expected (§2.1, §11): every repo declares its tasks in one root `melos:`
     block, and `melos run <task>` is *the* entry point CI, agents and humans
     call.
   - Actual: **resolved 2026-11-27.** The root `melos:` block declares
     `analyze`, `test`, `format` and `gate`; the hand-rolled
     `dart/tool/gate.dart` that briefly stood in for it is gone, so there is one
     entry point again.
   - Status: fixed. (The 2026-09-24 audit had missed this deviation entirely.)
2. **No `dart_arch_test` boundary test** — `dart/`
   - Expected (§2.9, §9 step 7, §10.1): package-boundary direction + workspace
     cycle-freedom as a test-enforced gate over the resolved import graph, with
     **plain `package:` URI assertions** (the glob DSL is package-name-blind).
   - Actual: none. Nothing prevents a domain → data import today.
   - Status: open.
3. **Several classes per file** — `dart/packages/alluvial_domain/lib/src/failures/*`
     (5 + 5), `.../contracts/story_codec.dart` (2),
     `dart/packages/alluvial_render/lib/src/spec/chart_spec.dart` (10),
     `.../engine/vertical_renderer.dart` (3),
     `dart/packages/alluvial_usecases/lib/src/models/timeline.dart` (4)
   - Expected (§3.5, compact): one class per file, one file per class.
   - Actual: sealed failure families and spec value-object sets share a file.
   - Status: **argued exception** — a sealed family reads as one unit and its
     exhaustive switch is a contract; splitting it would scatter that. Recorded,
     not fixed.
4. **Test default paths are POSIX literals** —
   `dart/packages/alluvial_render/test/parity_test.dart`,
   `.../py_num_test.dart`
   - Expected (§6): never hardcode absolute paths in tests — no `/tmp/foo`;
     `Directory.systemTemp` plus `package:path`.
   - Actual: both default to `/tmp/ref`, which is not the same place on the
     Windows lane — and is how the renderer gate came up *skipped* rather than
     run.
   - Status: open.
5. **The file store is not sembast** — `dart/packages/alluvial_store_yaml`
   - Expected (§5.4): sembast is the default pure-Dart embedded file store.
   - Actual: a hand-rolled `dart:io` + `package:yaml` folder adapter.
   - Status: **argued exception** — the store is authored, human-editable,
     git-diffable YAML, and its byte-identity IS the product gate. A document
     database would destroy the property this repo exists to keep. §5.3
     explicitly declines to force a second file-based adapter.
6. **No `UnitOfWork` on the rule-carrying operation** —
   `dart/packages/alluvial_domain/lib/src/repository/document_story_repository.dart`
   - Expected (§5.5): the *repository contract stays plain*, and an operation
     that **decides a rule by reading and then writes** takes a required
     `UnitOfWork` (the no-op is wired at the composition root for a store that
     cannot roll back).
   - Actual: `save()` validates a story and then writes it, and no operation
     carries the seam.
   - Status: open. (An earlier ticket read this as "repository methods need an
     optional `uow`" — that reading is wrong; the contract is correct as-is.)

Resolved in this file: the repo had no `AGENTS.md`, and every package was silent
about its error style (§4.9) — both are declared above. The in-memory store
(`alluvial_store_memory`) is the compliant second adapter, and no deviation.

## Audit sources

The deviation set came from the Windows-lane build and standards audit
(2026-09-24), consolidated onto the board as ALL-41…ALL-50 and re-read against
the bible on 2026-11-27 — which is where items 3/5 became recorded exceptions
and item 6 was corrected.

Keep this list in sync with a re-audit: removing a deviation must be deliberate
(fix-by-change, not drift).
