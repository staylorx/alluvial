---
id: ALL-37
title: '`dart test` at the workspace root exits 65'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
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
