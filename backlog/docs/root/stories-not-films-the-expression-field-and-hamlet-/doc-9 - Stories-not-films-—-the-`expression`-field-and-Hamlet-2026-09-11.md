---
id: doc-9
title: Stories, not films — the `expression` field, and Hamlet (2026-09-11)
type: other
created_date: '2026-11-08T18:53:00Z'
---


## Stories, not films — the `expression` field, and Hamlet (2026-09-11)

The store's naming is behind its content: these are **stories**, and `film` is
only one of the forms they arrive in. Two changes landed together:

Two things were left BROKEN by `180d780` (Remove the superseded JSON store), and
both failed SILENTLY — found while wiring Hamlet up, fixed here:

**And the rubric is not a property of the store — it is a property of the story
being graded** (owner correction, 2026-09-11: "the rubric is still for romcom
movies. for our story alluvials, they may or may not line up to a romcom movie").
The model had it backwards: `rubric27.BEAT_CATS` — 27 Dresses' OWN beat map — was
the store-wide fallback for any beat that omitted `cats`, so a story the rubric
does not grade silently acquired the house's romcom commentary by beat number, and
`build_eleventy` put the rubric on every published entry. Now `rubric` is a
DECLARED field (`romcom-27` today): the schema requires it for `score`/`score_note`,
the validator refuses a score, a score note or a beat category on an ungraded story,
and the house's map is reachable only through that declaration. The 30 romcoms each
declare it; hamlet declares none and gets no rubric text anywhere. Byte-neutral:
republishing still reproduces the live site artifacts (29/30 charts + every
stories.json rubric block).

Still open, in order: (1) rename the store and its paths from films to stories —
`stories/` -> `stories/`, `stories_yaml.py` / `STORY-SCHEMA.md`, and on the site
`/stories/` -> `/stories/` with redirects for the 30 live URLs; (2) give
`expression` a first-class home in the Dart store (the codec carries it in
`extra` today: it round-trips, but that is not modelling) — same for `rubric`;
(3) republish the two corrected films; (4) the site's story page must honor a null
`rubric` (guard the rubricsheet and the score) and render a non-film's anchors,
which lands with (1) or (3); (5) `out/notes/*.md` don't yet carry the `rubric` row
(regenerating them trips the note_hash refusal by design — not worth churning 30
files for a cosmetic line).
