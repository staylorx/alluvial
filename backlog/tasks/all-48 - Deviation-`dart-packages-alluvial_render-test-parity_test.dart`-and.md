---
id: ALL-48
title: 'Deviation: `dart/packages/alluvial_render/test/parity_test.dart` and'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
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
