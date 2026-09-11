# Alluvial charts — BACKLOG

**Read this first.** Hand-authored alluvial (time-indexed Sankey) charts for
stories: films, novels, series. Pure Python → SVG → PNG. No libraries, no
runtime deps beyond PIL for export.

Canonical home: `~/hermes/projects/alluvial/`
Procedural memory: skill `narrative-alluvial` (engine docs, design rules, pitfalls).

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

## The data model

Every chart is one `COLS` table: a list of beats, each with
`beat` / `loc` / `cap` / `hard` / `tag` / `groups` / `stubs` / `terminal` /
`enter`, plus a `CHAR` map (label, ribbon width, colour). **This table is the
content model** — the SVG, the PNG, and (next) the web page are all rendered
from it. Adding a film = writing one table + the prose.

## Running

```bash
cd scripts
python3 dresses27_vertical.py        # -> out/27dresses-vertical.svg
python3 dresses27_vertical.py --cb   # -> out/27dresses-vertical-cb.svg (colour-blind)
```

Verify a render (lane order read back out of the PNG):
```bash
python3 ~/.hermes/skills/creative/narrative-alluvial/scripts/verify_render.py \
        ../out/np-vertical-a-raw.png 1120 h400:60-660
```

## Done

- [x] Horizontal engine + Normal People (full, 13 columns; 2-panel split; novel with time-proportional spacing)
- [x] Fellowship horizontal (11 strands, 9 beats)
- [x] Vertical engine (transposed; semantic bands become left/right)
- [x] Width-scaled label type (legend + lane names) — hierarchy at a glance
- [x] Colour-blind mode (`cb_safe`): luminance ramp by strand weight + one symbol per strand, opt-in and byte-identical when off
- [x] 27 Dresses vertical, tagged with the romcom rubric beats
- [x] Checkpoint: repo, verified regenerable (all 11 SVGs byte-identical after the move)

## Shipped: film pages on staylorx.com

Live: **https://staylorx.com/movies/27-dresses/** (section at `/movies/`).
Nav entry added; the site's build-time search index picks it up.
Repo: `taybiz/com_staylorx_www`, commit `b51aef3` (push = deploy).
Publisher: `web/build_eleventy.py` -> `src/_includes/charts/*.svg` +
`src/_data/films.json`; page template `src/movies/27-dresses.njk`; `inline`
shortcode in `.eleventy.js`.

Scale lesson (cost one round): the site's post column is capped at 660px, so a
1010px chart rendered its captions at ~11px and read as broken. A chart page must
widen the layout for itself (`.layout` 1240px / `.main` 1040px) -> chart renders
at 976px, captions 16.4px. Phones get a fixed 820px chart inside a horizontal
scroller (13.8px) instead of a 6px fit-to-width.

## Shipped: the rubric, as text

The page carries the rubric itself (six categories, point values, wording quoted
from the draft, the Kaling line, the house note) plus the category text under
each beat that earns one. `scripts/rubric27.py` is the single source of truth
for that text and for the beat -> category map; both page builders import it.
Live: same URL, site commit `0096f90`.

## Decisions

- **No per-beat writing.** The beats are anchors to jump around in — there is
  nothing to say per beat and the requirement is dropped (owner, 2026-09-11).
  Do not add writing slots back. The rubric text sits under each beat instead,
  because that is text we actually have.
- **The rubric is quoted, not paraphrased.** If the rubric changes in the draft,
  change `scripts/rubric27.py` and rebuild — don't edit page copy.

## The pipeline (30 films)

`films/<slug>.json` (format: `FILM-SCHEMA.md`) -> `scripts/film_chart.py` (layout is
computed, not drawn) -> `web/build_eleventy.py` -> the site's paginated
`src/movies/film.njk`, which pages one over `films.json`. Adding a film is a data
file; no new template. Verified faithful: 27 Dresses (which keeps its hand-tuned
`groups`) renders **byte-identical** through the generic path.

Layout rules that matter: in lane space larger y sits further RIGHT (mirror=False);
a film may carry explicit `groups` instead of `clusters` for hand-tuning; captions
are 2 lines of <=62 chars or the layout breaks; 8 lanes and 13 beats are the
practical ceilings.

## Next

- [ ] Batch-verify every film's chart (lane overlaps + caption collisions) before
      publishing, and spot-check captions against each film's cited source.
- [ ] Focus mode for big casts (Anna Karenina): click a character, dim the rest.
- [ ] Chunked mode for very long works (Anna Karenina: ~8 parts, ~90 beats).
      Long scroll is the goal; per-part SVG panels keep each file small.
- [ ] Lane budget: 6–11 lanes is the legible maximum. Needs a strategy for
      15+ character casts (focus mode, "others" lane, or per-part lane sets).
- [ ] Density mode: one caption line per beat for long works, prose carries detail.
- [ ] Optional: Okabe–Ito palette swap as a second colour-blind mode.

## Decisions worth not re-litigating

- Ribbon width ≈ narrative presence (Sankey rule). Label size + colour-blind
  darkness both derive from it, so the encodings agree instead of fighting.
- Time runs down in the vertical version; the semantic bands become left/right
  (family | the leads | the social world).
- Time-proportional row spacing where the data has real gaps (novel chapters,
  film runtime marks). The clamp on near-instant gaps is itself a finding.
- PNG is for chat; SVG is the deliverable. The web page inlines the SVG so the
  page's CSS and links can reach every beat.
