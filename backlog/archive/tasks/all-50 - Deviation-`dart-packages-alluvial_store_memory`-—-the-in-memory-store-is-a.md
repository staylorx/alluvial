---
id: ALL-50
title: 'Deviation: `dart/packages/alluvial_store_memory` — the in-memory store is a'
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["deviation"]
dependencies: []
ordinal: 50000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deviation: `dart/packages/alluvial_store_memory` — the in-memory store is a
legitimate second adapter and the contract suite does run against both
(bible-compliant), but no bible §5 "UnitOfWork pitfalls" apply here because
there is no UnitOfWork; recorded so the next reader does not go looking for
the pitfall section.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Not a deviation: the in-memory store is the compliant second adapter behind the contract suite. Recorded as such in `AGENTS.md`.
<!-- SECTION:FINAL_SUMMARY:END -->
