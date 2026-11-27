---
id: ALL-40
title: The two data defects are still open
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["data"]
dependencies: []
ordinal: 40000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**The two data defects are still open** (`validate`: 2 of 36 invalid) —
      `50-first-dates` (`beats[6].stubs` names henry, who stands in "THE BOAT"
      later; the same pair also marks him `enter` after he appeared) and
      `about-time` (`beats[9].stubs` names dad, who does not stand in that
      beat). Unchanged from `dart/BACKLOG.md`; the renderer still silently drops
      that stub.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed 2026-11-27 — `validate` is clean, 0 of 36 invalid. Two different errors, one cause: `enter`/`stubs` mean FIRST/LAST appearance, and both files used them for a mid-story departure. `50-first-dates`: henry stands in every beat, so `stubs:[henry]` (beat 6) and `enter:[henry]` (beat 7) were simply false — removed; the chart loses a phantom 'new lanes ▸ Henry' banner and a spurious exit stub and is 24 px shorter. `about-time`: `stubs:[dad]` was right in spirit and wrong in beat — moved from THE THIRD CHILD (beat 9, where he does not stand; he is dead) to THE LAST TRIP (beat 8), his last present beat, so his exit stub is now actually drawn at his goodbye scene. Proven to change the render: both SVGs differ old->new, and Python and Dart still agree 98/98. `format --apply` no longer refuses either file. Recorded in doc-17 and the CHANGELOG. The one thing NOT fixed: a character who leaves and returns mid-story has no schema support (enter/stubs are first/last only, PresenceState has no third state) — the prose carries it; that is a schema feature, not a data fix.
<!-- SECTION:FINAL_SUMMARY:END -->
