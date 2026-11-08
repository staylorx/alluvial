---
id: ALL-49
title: 'Deviation: `dart/packages/alluvial_render/test/parity_test.dart` — file names'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 49000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deviation: `dart/packages/alluvial_render/test/parity_test.dart` — file names
are derived with `split('/')`, a POSIX-only assumption. §6's spirit (and
"tests pass on my machine, fail in CI") covers it; there is no bible rule
about separators, only about portability.
<!-- SECTION:DESCRIPTION:END -->
