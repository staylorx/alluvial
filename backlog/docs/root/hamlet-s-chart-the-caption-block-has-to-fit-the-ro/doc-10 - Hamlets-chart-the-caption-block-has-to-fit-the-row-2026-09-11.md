---
id: doc-10
title: 'Hamlet''s chart: the caption block has to fit the row (2026-09-11)'
type: other
created_date: '2026-11-08T18:54:00Z'
---


## Hamlet's chart: the caption block has to fit the row (2026-09-11)

Found with a real-font-metric scan (Chromium `getBBox`), not by eye: five text
collisions in `stories/hamlet.yaml`'s chart. Cause is arithmetic, not art.

A beat's block in the caption column is `46 + 2 caption lines (23px each) + 8
+ tag line(s) + entrant line(s)` and the row pitch is **165px**. Two beats were
over it: THE COURT (a five-name entrant list wraps to two lines, + a tag) at
165.5px, and THE HOUSE (its tag wrapped to two lines at the 46-character wrap
width, "▸ " included) at 166px — so the entrant list printed into the next beat's
title.

The court cannot shrink: five lanes genuinely arrive in ACT I, SC. 2, and the
column cannot fit five names on one line at any lane width (even at the minimum
label font they need ~369px of the 354px available). So the court's tag is gone
(its caption already says what it is) and the wrapping tags are shortened to one
line. Every block is now ≤144px.

What is left, deliberately: the two remaining `getBBox` overlaps are between
ADJACENT LINES of the court's wrapped entrant list, where the names are drawn at
the lane font (up to 26px) on a 21.75px line pitch. No ink collides — none of those
five names has a descender. The engine rule that would remove them (size a wrapped
entrant line to its tallest name) touches **6 beats across 6 stories, 5 of them
published films**, and needs the Dart renderer to follow, so it is the owner's call
rather than a silent re-render of approved charts.
