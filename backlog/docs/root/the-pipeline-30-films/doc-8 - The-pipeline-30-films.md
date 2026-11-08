---
id: doc-8
title: The pipeline (30 films)
type: other
created_date: '2026-11-08T18:53:00Z'
---


## The pipeline (30 films)

`stories/<slug>.json` (format: `STORY-SCHEMA.md`) -> `scripts/story_chart.py` (layout is
computed, not drawn) -> `web/build_eleventy.py` -> the site's paginated
`src/stories/story.njk`, which pages one over `stories.json`. Adding a story is a data
file; no new template. Verified faithful: 27 Dresses (which keeps its hand-tuned
`groups`) renders **byte-identical** through the generic path.

Layout rules that matter: in lane space larger y sits further RIGHT (mirror=False);
a film may carry explicit `groups` instead of `clusters` for hand-tuning; captions
are 2 lines of <=62 chars or the layout breaks; 8 lanes and 13 beats are the
practical ceilings.
