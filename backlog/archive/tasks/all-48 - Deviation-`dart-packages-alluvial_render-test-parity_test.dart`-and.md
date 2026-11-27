---
id: ALL-48
title: 'Deviation: `dart/packages/alluvial_render/test/parity_test.dart` and'
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["deviation"]
dependencies: []
ordinal: 48000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deviation: `dart/packages/alluvial_render/test/parity_test.dart` and
`.../py_num_test.dart` — absolute POSIX paths (`/tmp/ref`, `/tmp/ref/numbers.tsv`)
as the defaults, and a `'../../../stories'` CWD-relative store. §6's pitfall
list bans hardcoded absolute paths in tests (env/`systemTemp` + `path`, and no
`/tmp/foo` literals); on Windows `/tmp/...` is not the same place MSYS thinks
it is, which is how the gate came up skipped.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed 2026-11-27: both suites and the store resolve through `alluvial_render/test/corpus_paths.dart` (`Directory.systemTemp` + `package:path`, env-overridable, no `/tmp/...` literal), and the two Python generators write to the same default — so `python3 dart/tool/render_reference.py` (no argument) + `dart test` is the whole gate on any platform. Verified running, not skipping: melos run gate clean, 147 tests. Recorded in AGENTS.md item 4.
<!-- SECTION:FINAL_SUMMARY:END -->
