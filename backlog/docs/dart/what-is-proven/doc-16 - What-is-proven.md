---
id: doc-16
title: What is proven
type: other
created_date: '2026-11-08T18:54:00Z'
---


## What is proven

Measured against the real store. The figures below were taken when it held 30
braid works + 5 two-clock charts (35 files); the store is 36 works today, so the
counts have moved by one — see ALL-34 for the stale assertions.

- **Reads** — all 35 decode, none silently dropped; a file that is not a story is
  reported in the listing rather than skipped.
- **Round trip** — 35/35 stories are a fixed point (decode → encode → decode is
  the same story).
- **Writer** — 34/35 files are reproduced **byte-for-byte**, header block
  included. The one difference is `the-tao-of-steve`'s explicit `score: null`,
  which the writer omits: an explicit null and an absent field mean the same
  thing. Do not chase it with a null-preserving flag.
- **Write cycle** — `format --apply` over a copy of the whole store writes 33
  stories, refuses 2, creates no file, loses none, and leaves 34/35 files
  byte-identical to the originals.
- **Byte-identity gate** — the reference corpus is rendered by the Python pipeline
  itself (`python dart/tool/render_reference.py <dir>`): each braid work × the
  three treatments the pages embed, plus every two-clock chart, with the spec JSON
  beside each — 98 artifacts at 36 works. Dart reproduces them; the gate is
  byte-identity with the Python engine, not "looks right".
- **Gate status** — `dart pub get` resolves (3 packages currently have newer
  versions outside constraints); `dart analyze --fatal-infos --fatal-warnings` is
  clean (zero diagnostics); `dart build cli` builds
  `build/cli/<os>/bundle/bin/alluvial` and the binary runs (`version`, `list`,
  `validate` over `stories/`).
- **Analyzer / tests** — `dart analyze` reports nothing; `dart format` changes
  nothing; 100 tests pass (domain 35, usecases 13, folder store 27, memory store
  10, CLI 15).
- **The artifact** — `dart build cli` produces a bundle; a full listing takes
  ~70 ms, against ~2 s for `dart run`. Build the bundle an agent actually uses.
- **Known divergence** — `hamlet` is the one real content divergence: 2 of the
  artifacts (`hamlet.svg`, `hamlet.cb.svg`) differ in exactly one `<text` span.
