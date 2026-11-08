---
id: doc-2
title: Layout
type: other
created_date: '2026-11-08T18:53:00Z'
---


## Layout

| Path | What |
|---|---|
| `scripts/alluvial_vlib.py` | **The vertical engine.** Generic renderer: lanes→columns, time→down, `cb_safe` colour-blind mode, width-scaled labels. Start here. |
| `scripts/alluvial_np2.py` | Horizontal engine + Normal People (series) data. Also the source of the shared `COLS` data model. |
| `scripts/alluvial_vertical.py` | Normal People, vertical (2 panels). |
| `scripts/dresses27_vertical.py` | 27 Dresses, vertical, tagged with the romcom rubric. |
| `scripts/fellowship_vertical.py` | Fellowship of the Ring, vertical (11 strands, time from the film's runtime marks). |
| `scripts/fellowship_alluvial.py` | Fellowship, original horizontal version. |
| `scripts/normal_people_alluvial.py` | Normal People, original horizontal version. |
| `out/*.svg` | Canonical artifacts, committed. Hand-editable, restylable. |
| `out/*.png` | 2x exports for chat/print. |
| `web/` | Static-page generator (in progress — see BACKLOG below). |
| `dart/` | **The Dart store + CLI** — reads these files, validates them, writes them back. See `the backlog board (`backlog/`)`. |
