---
id: ALL-31
title: The byte-identity gate was **rebuilt from scratch here**, because the Python
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 31000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The byte-identity gate was **rebuilt from scratch here**, because the Python
pipeline is the only thing that can produce the reference:
`python dart/tool/render_reference.py C:/tmp/ref` (31 braid × 3 treatments +
spec JSON, 5 two-clock) and `python dart/tool/number_corpus.py
C:/tmp/ref/numbers.tsv` (534 values). Result with the corpus present:
**96 of 98 artifacts byte-identical**; 2 differ (`hamlet`, `hamlet.cb`).
<!-- SECTION:DESCRIPTION:END -->
