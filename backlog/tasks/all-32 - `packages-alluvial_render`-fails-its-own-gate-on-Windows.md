---
id: ALL-32
title: '`packages/alluvial_render` fails its own gate on Windows'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 32000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**`packages/alluvial_render` fails its own gate on Windows.** Two causes,
      both in the harness rather than in the engine:
      1. `test/parity_test.dart` rebuilds its file keys with
         `f.path.split('/').last` — on Windows the separator is `\`, so the key
         is the whole path and **every** corpus lookup misses. The test then
         compares nothing and fails only on the hardcoded
         `identical.should.be(95)`. With the separator fixed the gate really
         runs: 96/98 identical.
      2. `test/py_num_test.dart` hard-fails (`corpus.length > 100` → false) when
         the CPython-generated fixture is absent, where the sibling parity test
         skips. On a machine with no corpus, `dart test` in this package is red
         by construction.
<!-- SECTION:DESCRIPTION:END -->
