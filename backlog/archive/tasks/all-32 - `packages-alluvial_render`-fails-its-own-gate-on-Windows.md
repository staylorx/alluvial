---
id: ALL-32
title: '`packages/alluvial_render` fails its own gate on Windows'
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["defect"]
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed 2026-11-27: parity_test.dart derives keys from the URI's last path segment (no POSIX separator); py_num_test.dart skips when the corpus is absent instead of hard-failing; both generators write newline="". The gate runs everywhere and compares all 98 artifacts — 98/98 byte-identical.
<!-- SECTION:FINAL_SUMMARY:END -->
