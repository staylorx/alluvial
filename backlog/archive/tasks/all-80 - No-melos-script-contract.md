---
id: ALL-80
title: 'No melos script contract (bible §2.1, §11)'
status: Done
assignee: []
created_date: '2026-11-27T00:00:00Z'
labels: ["deviation"]
dependencies: []
ordinal: 80000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**No melos script contract.** The bible makes melos *required* as the canonical
script contract in every repo, workspace or single package: every task is
declared in one root `melos:` block, and `melos run <task>` is *the* entry point
CI, agents and humans call (§2.1, §11). Melos enforces no boundaries — that is
`dart_arch_test`'s job (ALL-42).

Actual: `dart/` is a pub workspace with no `melos:` block and no melos
dependency; the gate is the hand-rolled `dart/tool/gate.dart` added on
2026-11-27. That runner works, but it is exactly the bespoke entry point the
doctrine exists to prevent.

The 2026-09-24 audit missed this deviation; it surfaced on 2026-11-27 while
re-reading the set against the bible. Recorded in `AGENTS.md` item 1.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed 2026-11-27: the root `dart/pubspec.yaml` now carries the `melos:` script contract (`analyze`, `test`, `format`, `gate`) with `melos: ^8.8.0`, and the hand-rolled `dart/tool/gate.dart` is deleted — one entry point. `melos run test` uses `--dir-exists=test`, so `alluvial_testing` (the shared contract suite, no tests of its own) is skipped rather than failed. Verified: `melos run gate` green (137 tests) and `melos run analyze` clean. Recorded as fixed in AGENTS.md item 1.
<!-- SECTION:FINAL_SUMMARY:END -->
