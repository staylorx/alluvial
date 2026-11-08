---
id: ALL-38
title: '`dart format` is not clean'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 38000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**`dart format` is not clean** (bible §2 wants the tree formatted before
      a commit): `dart format --output=none --set-exit-if-changed .` reports 2
      files it would change —
      `dart/packages/alluvial_domain/lib/src/codec/story_document_codec.dart`
      (a `if (...) 'expression': ...` line it wants split) and
      `dart/packages/alluvial_domain/test/story_validator_test.dart` (a block of
      `test(...)` calls it wants collapsed). Not touched here: formatting is a
      code change, and the diff is 140 lines.
<!-- SECTION:DESCRIPTION:END -->
