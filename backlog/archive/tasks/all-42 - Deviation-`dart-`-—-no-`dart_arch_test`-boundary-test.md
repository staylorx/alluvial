---
id: ALL-42
title: 'Deviation: `dart/` — no `dart_arch_test` boundary test'
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["deviation"]
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed 2026-11-27: `dart/test/architecture_test.dart` uses `dart_arch_test` over the resolved import graph with plain `package:` URI assertions (never the glob DSL) — each package's allowed reach, `lib/src/` reachable only through the barrel, and workspace-wide cycle-freedom — plus a non-emptiness check so an empty graph cannot pass vacuously. It runs inside `melos run test` (`melos: useRootAsPackage`). Proven to fire: an injected cross-package `lib/src/` import fails the suite. Recorded as fixed in AGENTS.md item 2; the tool's cost (analyzer pinned <12, sdk ^3.11.0) is recorded as AGENTS.md item 7.
<!-- SECTION:FINAL_SUMMARY:END -->
