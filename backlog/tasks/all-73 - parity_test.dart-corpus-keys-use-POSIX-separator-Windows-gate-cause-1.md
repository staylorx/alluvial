---
id: ALL-73
title: parity_test.dart corpus keys use POSIX separator (Windows gate cause 1)
status: To Do
assignee: []
created_date: '2026-11-08T18:52:00Z'
labels: []
dependencies: []
ordinal: 32500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Sub-cause (1 of 2) of the `alluvial_render` Windows gate failure (parent item: ALL-32). From root BACKLOG.md, "Build & analysis findings (open)", numbered list item 1.

`test/parity_test.dart` rebuilds its file keys with `f.path.split('/').last` — on Windows the separator is `\`, so the key is the whole path and **every** corpus lookup misses. The test then compares nothing and fails only on the hardcoded `identical.should.be(95)`. With the separator fixed the gate really runs: 96/98 identical.
<!-- SECTION:DESCRIPTION:END -->
