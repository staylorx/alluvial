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
| `dart/` | **The Dart store + CLI** — reads these files, validates them, writes them back. See `dart/BACKLOG.md`. |

## The Dart port (branch `dart-cli`)

`dart/` is a Dart pub workspace that reads this store, models it as three
entities (character / beat / appearance), validates it against the schema and
the authored limits, writes it back, and **draws it** — both renderers are
ported and byte-identical.

- **The store + CLI**: `alluvial <verb> --store films --output json` — `list`,
  `show`, `validate`, `timeline`, `roundtrip`, `format` (dry-run first), `chart`
  (`--variant braid|colour-blind|mini|two-clock`, `--out`, `--out-dir`).
- **The renderers match the Python engine to the byte.** The reference corpus is
  rendered by the Python pipeline itself: 30 braid films × the three treatments
  the pages embed, plus all 5 two-clock charts = 95 artifacts. Dart reproduces
  all 95, with the drawn layout matching field for field. `dart test` in
  `packages/alluvial_render` runs that gate.
- Measured on this store: all 35 files decode; 35/35 are a fixed point through
  decode → encode → decode; a full `format --apply` cycle over a copy reproduces
  34 of 35 files byte-for-byte and loses none.

Read `dart/BACKLOG.md` for the proofs and the open questions. Two openings worth
a decision, neither closed by the port: the two-clock palette (`THREAD` in
`scripts/reorder_chart.py`) only knows Pulp Fiction's five thread ids, so four of
the five timechart charts draw every ribbon grey; and the Eleventy page layer
(`web/`) is still JavaScript.

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

## Stories, not films — the `expression` field, and Hamlet (2026-09-11)

The store's naming is behind its content: these are **stories**, and `film` is
only one of the forms they arrive in. Two changes landed together:

- **`expression`** (both schemas + `FILM_KEYS`/`TIME_KEYS`) — `film` by default,
  else `play`, `novel`, `series`, `short story`, `essay`, `poem`, `song`,
  `musical`. Absent means film, so every existing file, chart and published
  artifact stays byte-identical. `year` is now the WORK's year (minimum 1, not
  1900), and a non-film titles itself by form instead of counting minutes
  ("A play — the anchors are acts and scenes, not minutes.").
- **`films/hamlet.yaml`** — the first non-film: 13 beats, 8 lanes, every beat
  anchored to an act and scene. Every beat carries `cats: []` explicitly — an
  OMITTED `cats` silently inherits the romcom category for that beat number
  (`rubric27.for_beat`), which is the trap a non-romcom falls into. The ghost
  holds a lane; Fortinbras, Rosencrantz and Guildenstern, the players, Osric and
  the gravediggers are named in captions/tags plus `chart_limits`.

Two things were left BROKEN by `180d780` (Remove the superseded JSON store), and
both failed SILENTLY — found while wiring Hamlet up, fixed here:

- `web/build_eleventy.py` globbed `films/*.json` for discovery, so it published
  **0 films** and reported success. Discovery now goes through the store's own
  API (`FY.all_slugs()` + `is_timechart`). Verified by republishing: all 30 site
  charts come back **byte-identical** to the live artifacts except the two whose
  store data was corrected after the last publish (`the-wedding-singer`,
  `10-things-i-hate-about-you`) — those corrections were never republished.
- `scripts/verify_films.py`'s batch sweep globbed the same pattern: the gate
  meant to catch lane and caption defects exited 0 over an EMPTY set. It now
  sweeps `FY.all_slugs()` — 36 braids + 5 timecharts, 36/36 pass.

Still open, in order: (1) rename the store and its paths from films to stories —
`films/` -> `stories/`, `films_yaml.py` / `FILM-SCHEMA.md`, and on the site
`/movies/` -> `/stories/` with redirects for the 30 live URLs; (2) give
`expression` a first-class home in the Dart store (the codec carries it in
`extra` today: it round-trips, but that is not modelling); (3) republish the two
corrected films.

## Decisions worth not re-litigating

- Ribbon width ≈ narrative presence (Sankey rule). Label size + colour-blind
  darkness both derive from it, so the encodings agree instead of fighting.
- Time runs down in the vertical version; the semantic bands become left/right
  (family | the leads | the social world).
- Time-proportional row spacing where the data has real gaps (novel chapters,
  film runtime marks). The clamp on near-instant gaps is itself a finding.
- PNG is for chat; SVG is the deliverable. The web page inlines the SVG so the
  page's CSS and links can reach every beat.
