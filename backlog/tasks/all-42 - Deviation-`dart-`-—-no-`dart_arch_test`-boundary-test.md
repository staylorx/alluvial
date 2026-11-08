---
id: ALL-42
title: 'Deviation: `dart/` — no `dart_arch_test` boundary test'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 42000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deviation: `dart/` — no `dart_arch_test` boundary test. The bible makes
package-boundary direction + workspace-wide cycle-freedom a **test-enforced CI
hard gate** (§2 "Test-enforced", §9 step 7, §10 checklist). The workspace has
none: no `dart_arch_test` dependency, no architecture test, no workspace-root
`test/`. Boundaries are currently enforced by nothing.
<!-- SECTION:DESCRIPTION:END -->
