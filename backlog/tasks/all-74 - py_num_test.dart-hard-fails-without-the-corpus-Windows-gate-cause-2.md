---
id: ALL-74
title: py_num_test.dart hard-fails without the corpus (Windows gate cause 2)
status: To Do
assignee: []
created_date: '2026-11-08T18:52:00Z'
labels: []
dependencies: []
ordinal: 32600
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Sub-cause (2 of 2) of the `alluvial_render` Windows gate failure (parent item: ALL-32). From root BACKLOG.md, "Build & analysis findings (open)", numbered list item 2.

`test/py_num_test.dart` hard-fails (`corpus.length > 100` → false) when the CPython-generated fixture is absent, where the sibling parity test skips. On a machine with no corpus, `dart test` in this package is red by construction.
<!-- SECTION:DESCRIPTION:END -->
