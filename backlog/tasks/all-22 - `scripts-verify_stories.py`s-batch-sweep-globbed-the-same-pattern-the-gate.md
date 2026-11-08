---
id: ALL-22
title: '`scripts/verify_stories.py`''s batch sweep globbed the same pattern: the gate'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`scripts/verify_stories.py`'s batch sweep globbed the same pattern: the gate
meant to catch lane and caption defects exited 0 over an EMPTY set. It now
sweeps `FY.all_slugs()` — 36 braids + 5 timecharts, 36/36 pass.
<!-- SECTION:DESCRIPTION:END -->
