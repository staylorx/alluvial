---
id: ALL-33
title: '`hamlet` is the one real content divergence: 2 of 98 artifacts'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 33000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**`hamlet` is the one real content divergence: 2 of 98 artifacts.** With
      the corpus rebuilt and LF-normalised, `renderFilmChart` reproduces every
      artifact except `hamlet.svg` and `hamlet.cb.svg`, which differ in exactly
      one `<text>` line: Python emits `13 beats, 8 lanes. A play — the anchors
      are acts and scenes, not minutes.` (its non-film branch in
      `scripts/story_chart.py`), the Dart builder always emits the film wording
      `13 beats, 8 lanes. Time runs down the page.`
      (`dart/packages/alluvial_render/lib/src/builder/story_chart_builder.dart`,
      the `_titleBlock(...) ??` fallback). Hamlet is the only non-film braid, so
      it is the only casualty; `hamlet.mini.svg` has no footer and matches. The
      committed `out/hamlet-vertical.svg` already carries the play wording, so
      the Python side is the reference. This is the Dart half of the BACKLOG's
      "give `expression` a first-class home in the Dart store": the codec
      round-trips `expression` through `extra`, but the renderer never reads it.
      Fixing it is a code change, so it is recorded, not made.
<!-- SECTION:DESCRIPTION:END -->
