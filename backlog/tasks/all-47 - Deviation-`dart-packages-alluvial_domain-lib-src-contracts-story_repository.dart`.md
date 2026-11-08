---
id: ALL-47
title: >-
  Deviation:
  `dart/packages/alluvial_domain/lib/src/contracts/story_repository.dart`
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 47000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deviation: `dart/packages/alluvial_domain/lib/src/contracts/story_repository.dart`
— no `IUnitOfWork? uow` on any method. §5/§10 want write methods (and
optionally reads) to carry an optional `IUnitOfWork? uow`, with
non-transactional stores sinking it gracefully. A folder-of-files store
arguably has no transaction to expose; the contract is uniform today because
every adapter is the same shape.
<!-- SECTION:DESCRIPTION:END -->
