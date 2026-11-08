---
id: ALL-72
title: Store adapters share one orchestration
status: To Do
assignee: []
created_date: '2026-11-08T18:52:00Z'
labels: []
dependencies: []
ordinal: 72000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
From dart/BACKLOG.md: **Store adapters share one orchestration.** The folder adapter and the memory
adapter differ only in where documents live, so the sequence (read, decode,
map failures, refuse to write an invalid story) lives once, in the domain, and
the contract suite proves both adapters behave the same.
<!-- SECTION:DESCRIPTION:END -->
