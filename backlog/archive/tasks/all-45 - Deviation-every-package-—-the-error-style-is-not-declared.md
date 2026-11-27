---
id: ALL-45
title: 'Deviation: every package — **the error style is not declared**'
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["deviation"]
dependencies: []
ordinal: 45000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deviation: every package — **the error style is not declared**. §4 requires
the style (FP-style tuples vs plain exceptions) stated in the package
barrel's doc comment, the package README, and `AGENTS.md` on deviation
("silence is the violation"). The barrels carry a descriptive line but never
say what a consumer receives; **no package has a README**; the repo has no
`AGENTS.md`.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Done: the error style is now declared in all 7 barrels, in a README for each package, and in `AGENTS.md` (FP-style tuples by default; plain values for the renderer and the CLI ring).
<!-- SECTION:FINAL_SUMMARY:END -->
