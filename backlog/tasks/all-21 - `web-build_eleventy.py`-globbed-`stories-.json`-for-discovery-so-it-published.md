---
id: ALL-21
title: >-
  `web/build_eleventy.py` globbed `stories/*.json` for discovery, so it
  published
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`web/build_eleventy.py` globbed `stories/*.json` for discovery, so it published
**0 films** and reported success. Discovery now goes through the store's own
API (`FY.all_slugs()` + `is_timechart`). Verified by republishing: all 30 site
charts come back **byte-identical** to the live artifacts except the two whose
store data was corrected after the last publish (`the-wedding-singer`,
`10-things-i-hate-about-you`) — those corrections were never republished.
<!-- SECTION:DESCRIPTION:END -->
