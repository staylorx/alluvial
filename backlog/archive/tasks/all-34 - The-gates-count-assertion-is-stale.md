---
id: ALL-34
title: The gate's count assertion is stale
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["defect"]
dependencies: []
ordinal: 34000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**The gate's count assertion is stale.** `identical.should.be(95)` (and
      the README / `dart/BACKLOG.md` "30 films × 3 + 5 = 95") predates the 36th
      story: the store now holds **36 stories = 31 braid + 5 two-clock = 98
      artifacts**. The assertion has to move with the store.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed: the count is no longer hardcoded. The expectation is counted against the corpus, so it cannot go stale — and asserting the total equals the corpus size stops the gate passing vacuously.
<!-- SECTION:FINAL_SUMMARY:END -->
