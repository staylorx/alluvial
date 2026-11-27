# Changelog

All notable changes to this project are recorded here.

The format is [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) where
a version applies — the Dart packages under `dart/packages/` carry `0.1.0`
today, and no git tags exist yet.

Open and pending work lives on the `backlog/` board. Decisions — as opposed to
changes — belong here.

## [Unreleased]

### Added

- `CHANGELOG.md` (this file). The repository had `BACKLOG.md` but no change log.
- The Windows-lane build and standards audit: `BACKLOG.md` gains an
  "Audit — Windows lane build & bible comparison (2026-09-24)" section holding
  every build/analysis finding and every divergence from
  `staylorx/dart-flutter-bible`. Nothing in it was fixed here — the findings are
  recorded so the owner can decide.
- The **melos script contract** in the root manifest (§2.1, §11): `analyze`,
  `test`, `format` and `gate`, so `melos run <task>` is the one entry point CI,
  agents and humans call. The workspace root is not a package, so `dart test`
  there exits 65; `melos run test` is what covers the workspace. A hand-rolled
  `tool/gate.dart` stood in for it for a few hours earlier the same day; it is
  deleted, so there is one entry point again.
- `AGENTS.md` — the bible-first pointer plus this repo's numbered deviations
  register. Re-reading the `dart-flutter-bible` sweep against the doctrine there
  closed two items (no `AGENTS.md`, undeclared error style), turned two into
  recorded exceptions (the non-sembast store, the multi-class files), corrected
  one (the `UnitOfWork` seam sits on the operation, not on the repository
  contract), and surfaced one the audit had missed (no melos script contract).
- A README per package, declaring its error style near the top (§4.9).

### Changed

- The backlog board was triaged 2026-11-27. It had been seeded by pouring both
  retired `BACKLOG.md` files into tasks, so most entries were captured state,
  rules or proofs rather than work: 38 tasks were archived (12 already true in
  the tree, 26 were notes), the proof and defect content was restored to
  `backlog/docs/dart/what-is-proven` (doc-16) and `…/real-defects-…` (doc-17), a
  new `…/design-rules` doc (doc-18) holds the rules that had no other home, and
  the duplicate tickets were folded (the Windows render gate → ALL-32, the two
  data defects → ALL-40). The open queue is now 33 items, labelled `defect` /
  `data` / `deviation` / `feature` / `refactor` / `site`.
- The Dart tree is `dart format`-clean (two files reformatted), and both READMEs
  point at `melos run gate` instead of a root `dart test` that cannot work.
- Every package barrel now declares what a caller receives: **FP-style tuples**
  by default, plain values for the renderer (an SVG string) and the CLI (an exit
  code — it is the ring).

### Fixed

- The `alluvial_render` byte-identity gate now runs and passes. Three harness
  defects had made it unreliable: the parity test rebuilt file keys with a
  POSIX-only `split('/')` (so on Windows it compared nothing and failed only on
  a hardcoded count), the number-corpus test hard-failed when its generated
  fixture was absent instead of skipping, and the count assertion was stale at
  `95`. The keys now use the URI's last path segment, both tests skip when the
  corpus is absent, and the expectation is counted against the corpus — so the
  gate can neither go stale nor pass vacuously. **98 of 98 reference artifacts
  are byte-identical**, and `dart test` is green across the workspace.
- `hamlet` reproduces the Python engine. The Dart builder hardcoded the film
  subtitle ("Time runs down the page") for every form; it now follows the
  story's `expression` exactly as the reference does, so a play is anchored to
  its acts and scenes, not minutes. The last two divergent artifacts are gone.
- The reference-corpus generators (`dart/tool/render_reference.py`,
  `dart/tool/number_corpus.py`) open their outputs with `newline=""`, so a
  corpus is LF-clean on any platform.

### Known issues

- `dart format` reports two files it would change; `dart test` at the workspace
  root exits 65 (there is no root `test/` directory). *(Board: ALL-37, ALL-38.)*
- `validate` reports 2 of 36 stories invalid — `50-first-dates` and `about-time`,
  both unchanged data defects now tracked as ALL-40 and recorded in
  `backlog/docs/dart/real-defects-this-found-in-the-existing-data` (doc-17).

## [0.1.0] — 2026-09-11

The state of the repository as its own records describe it. The date is the last
change recorded in `BACKLOG.md` / the git log; the version is what the Dart
packages declare.

### Added

- The Dart story store and CLI as a pub workspace (`dart/`): domain entities,
  use cases, two repository adapters (folder-of-YAML and in-memory) behind one
  contract suite, a validator, an agent-facing `alluvial` CLI, and both
  renderers — the braid chart and the two-clock chart.
- The `expression` field on a story (`film` by default, else `play`, `novel`,
  `series`, `short story`, `essay`, `poem`, `song`, `musical`), with `rubric` as
  a first-class field beside it. A story that declares no rubric is never
  assumed to be graded.
- `stories/hamlet.yaml` — the first non-film in the store: 13 beats, 8 lanes,
  every beat anchored to an act and scene.

### Fixed

- `web/build_eleventy.py` discovered stories by globbing `stories/*.json` after
  the superseded JSON store was removed, so it published **0 films** and
  reported success; discovery now goes through the store's own API.
- `scripts/verify_stories.py`'s batch sweep globbed the same pattern and exited
  0 over an empty set; it now sweeps the store's own slug list (36 braids +
  5 timecharts).
- Grading was store-wide rather than per-story: 27 Dresses' beat map was the
  fallback for every beat that omitted its categories, so an ungraded story
  silently acquired romcom commentary. The rubric is now declared per story.
