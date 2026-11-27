---
id: ALL-43
title: 'Deviation: `dart/` — no workspace-wide `dart test`'
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["deviation"]
dependencies: []
ordinal: 43000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deviation: `dart/` — no workspace-wide `dart test`. The bible's gate is
"`dart test` green across the workspace" (§10); the workspace root has no test
directory, so the gate only exists per package.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed by the same change as ALL-37: `dart run tool/gate.dart` IS the workspace-wide test gate the bible asks for (clean analyze + all six package suites, 137 tests).
<!-- SECTION:FINAL_SUMMARY:END -->
