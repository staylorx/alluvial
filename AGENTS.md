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
   - Actual: **resolved 2026-11-27.** `dart/test/architecture_test.dart` asserts
     what each package may reach, that `lib/src/` is reachable only through the
     barrel, and workspace-wide cycle-freedom. It runs inside `melos run test`
     (the root is a package via `melos: useRootAsPackage`), and it fails on a
     deliberately injected cross-package `lib/src/` import.
   - Status: fixed.
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
   - Actual: **resolved 2026-11-27.** Both suites and the store resolve through
     `alluvial_render/test/corpus_paths.dart` — `Directory.systemTemp` plus
     `package:path`, environment-overridable, no literal — and
     `dart/tool/render_reference.py` / `number_corpus.py` write to the same
     default, so the gate runs rather than skipping.
   - Status: fixed.
5. **The file store is not sembast** — `dart/packages/alluvial_store_yaml`
   - Expected (§5.4): sembast is the default pure-Dart embedded file store.
   - Actual: a hand-rolled `dart:io` + `package:yaml` folder adapter.
   - Status: **argued exception** — the store is authored, human-editable,
     git-diffable YAML, and its byte-identity IS the product gate. A document
     database would destroy the property this repo exists to keep. §5.3
     explicitly declines to force a second file-based adapter.
6. **The bulk `format --apply` has no unit of work** —
   `dart/packages/alluvial_cli/lib/src/commands/format_command.dart`
   - Expected (§5.5, §5.6): the seam sits on the OPERATION — a required
     `UnitOfWork` constructor dependency, with the *repository contract left
     plain*. A store that cannot roll back says so once at the composition root,
     and emulates by buffering and committing whole.
   - Actual: `format --apply` loops over every story and calls `SaveStory` one at
     a time, so a failure partway (disk full, permissions) leaves the store
     **half-formatted** — and the store is the product. A single `save()` is not
     the problem: a pure validator check plus one write, with no store read
     feeding the decision.
   - Status: open. (The original ticket read this as "repository methods want an
     optional `uow`" — wrong; the contract is correct as it stands. Sharpened
     2026-11-27 by reading the command.)
7. **The SDK floor cannot be met by the sanctioned boundary tool** — every
   `pubspec.yaml`
   - Expected (§2.1, §RULES): `sdk: '>=3.10.0 <4.0.0'` in every pubspec.
   - Actual: `dart_arch_test` — the tool §2.9 names — requires `^3.11.0` in every
     release, so the declared 3.10 floor does not resolve; it also pins
     `analyzer: ">=9.0.0 <12.0.0"`, which holds the workspace's dev analyzer at
     11.x. (`dart analyze` itself is the SDK's analyzer and is unaffected.)
   - Status: **recorded, not changed.** The bible's own `example/` declares
     `>=3.10.0` while running the same tool, so the tension is the doctrine's;
     this repo follows the doctrine rather than inventing a fourth answer.

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
