---
id: ALL-37
title: '`dart test` at the workspace root exits 65'
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["defect"]
dependencies: []
ordinal: 37000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**`dart test` at the workspace root exits 65** —
      "No test files were passed and the default test/ directory doesn't exist".
      The gates only run per package; the README's "`dart test` runs that gate"
      and `dart/BACKLOG.md`'s "`dart analyze` / tests" are per-package in
      practice. Either add a root-level runner or say per-package in the docs.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed: `dart/tool/gate.dart` is the workspace gate — analyze (fatal infos/warnings), then every package's suite. The workspace root is not a package, so a root `dart test` still exits 65; the READMEs now name the gate command instead of implying a root `dart test` works.
<!-- SECTION:FINAL_SUMMARY:END -->
