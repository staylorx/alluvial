---
id: ALL-64
title: 'Work-form field: converged on the Python reference''s `expression`'
status: Done
assignee: []
created_date: '2026-11-08T18:52:00Z'
labels: []
dependencies: []
ordinal: 64000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
From dart/BACKLOG.md: **Work-form field: converged on the Python reference's `expression`.**
      2026-09-11: the port had invented `kind` (WorkKind: film/book/play/series/
      other) for a field no file used. The Python store is the reference and calls
      it `expression` (`film|play|novel|series|short story|essay|poem|song|musical`,
      absent = film), so the port adopted the name AND the vocabulary — `kind`
      already means something else inside the same document (a character's kind, a
      beat's kind). `rubric` (the id of the rubric grading a story, e.g.
      `romcom-27`) is first-class beside it: both are in the canonical key order
      exactly where the Python writer puts them, which is what keeps emission
      byte-identical. Categories are checked against the rubric the story DECLARES
      (`rubricCategories`), and a score without a rubric is a finding: the rubrics
      are romcom instruments and nothing is assumed about a story that declares
      none. `year` is no longer bounded at 1900 (a play from 1600 is legal).
      Measured on the renamed 36-file store: byte-identical 35/36, content stable
      36/36 (the one difference remains the-tao-of-steve's explicit `score: null`).
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Shipped
<!-- SECTION:FINAL_SUMMARY:END -->
