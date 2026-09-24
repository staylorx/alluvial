# Changelog

All notable changes to this project are recorded here.

The format is [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) where
a version applies — the Dart packages under `dart/packages/` carry `0.1.0`
today, and no git tags exist yet.

Open and pending work lives in [`BACKLOG.md`](BACKLOG.md) (the Python pipeline
and this file's own audit record) and [`dart/BACKLOG.md`](dart/BACKLOG.md) (the
Dart port). Decisions — as opposed to changes — belong here.

## [Unreleased]

### Added

- `CHANGELOG.md` (this file). The repository had `BACKLOG.md` but no change log.
- The Windows-lane build and standards audit: `BACKLOG.md` gains an
  "Audit — Windows lane build & bible comparison (2026-09-24)" section holding
  every build/analysis finding and every divergence from
  `staylorx/dart-flutter-bible`. Nothing in it was fixed here — the findings are
  recorded so the owner can decide.

### Known issues

- The Dart port's byte-identity gate does not pass as written on Windows:
  `dart test` in `dart/packages/alluvial_render` fails, because the parity test
  derives file keys with a POSIX separator and the number-corpus test hard-fails
  when its generated fixture is absent. With the corpus rebuilt and the
  separator fixed, **96 of 98 artifacts are byte-identical**.
- The two genuine divergences are `hamlet` and `hamlet.cb`: the Dart builder
  emits the film subtitle for a story whose `expression` is `play`. The committed
  `out/hamlet-vertical.svg` carries the correct play wording.
- The reference-corpus generators write CRLF on Windows, which makes a
  Windows-generated corpus fail every comparison on line endings alone.
- `dart format` reports two files it would change; `dart test` at the workspace
  root exits 65 (there is no root `test/` directory).
- `validate` reports 2 of 36 stories invalid — `50-first-dates` and `about-time`,
  both unchanged data defects recorded in `dart/BACKLOG.md`.

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
