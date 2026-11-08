---
id: doc-6
title: 'Shipped: film pages on staylorx.com'
type: other
created_date: '2026-11-08T18:53:00Z'
---


## Shipped: film pages on staylorx.com

Live: **https://staylorx.com/stories/27-dresses/** (section at `/stories/`).
Nav entry added; the site's build-time search index picks it up.
Repo: `taybiz/com_staylorx_www`, commit `b51aef3` (push = deploy).
Publisher: `web/build_eleventy.py` -> `src/_includes/charts/*.svg` +
`src/_data/stories.json`; page template `src/stories/27-dresses.njk`; `inline`
shortcode in `.eleventy.js`.

Scale lesson (cost one round): the site's post column is capped at 660px, so a
1010px chart rendered its captions at ~11px and read as broken. A chart page must
widen the layout for itself (`.layout` 1240px / `.main` 1040px) -> chart renders
at 976px, captions 16.4px. Phones get a fixed 820px chart inside a horizontal
scroller (13.8px) instead of a 6px fit-to-width.
