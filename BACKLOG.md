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

- **The store + CLI**: `alluvial <verb> --store stories --output json` — `list`,
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
from it. Adding a story = writing one table + the prose.

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

`stories/<slug>.json` (format: `STORY-SCHEMA.md`) -> `scripts/story_chart.py` (layout is
computed, not drawn) -> `web/build_eleventy.py` -> the site's paginated
`src/stories/story.njk`, which pages one over `stories.json`. Adding a story is a data
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

- **`expression`** (both schemas + `STORY_KEYS`/`TIME_KEYS`) — `film` by default,
  else `play`, `novel`, `series`, `short story`, `essay`, `poem`, `song`,
  `musical`. Absent means film, so every existing file, chart and published
  artifact stays byte-identical. `year` is now the WORK's year (minimum 1, not
  1900), and a non-film titles itself by form instead of counting minutes
  ("A play — the anchors are acts and scenes, not minutes.").
- **`stories/hamlet.yaml`** — the first non-film: 13 beats, 8 lanes, every beat
  anchored to an act and scene. Hamlet declares no `rubric`, so no beat carries a
  category and nothing is claimed for it (`cats: []` on its beats is an explicit
  "nothing earned here"). The ghost
  holds a lane; Fortinbras, Rosencrantz and Guildenstern, the players, Osric and
  the gravediggers are named in captions/tags plus `chart_limits`.

Two things were left BROKEN by `180d780` (Remove the superseded JSON store), and
both failed SILENTLY — found while wiring Hamlet up, fixed here:

- `web/build_eleventy.py` globbed `stories/*.json` for discovery, so it published
  **0 films** and reported success. Discovery now goes through the store's own
  API (`FY.all_slugs()` + `is_timechart`). Verified by republishing: all 30 site
  charts come back **byte-identical** to the live artifacts except the two whose
  store data was corrected after the last publish (`the-wedding-singer`,
  `10-things-i-hate-about-you`) — those corrections were never republished.
- `scripts/verify_stories.py`'s batch sweep globbed the same pattern: the gate
  meant to catch lane and caption defects exited 0 over an EMPTY set. It now
  sweeps `FY.all_slugs()` — 36 braids + 5 timecharts, 36/36 pass.

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

## Decisions worth not re-litigating

- Ribbon width ≈ narrative presence (Sankey rule). Label size + colour-blind
  darkness both derive from it, so the encodings agree instead of fighting.
- Time runs down in the vertical version; the semantic bands become left/right
  (family | the leads | the social world).
- Time-proportional row spacing where the data has real gaps (novel chapters,
  film runtime marks). The clamp on near-instant gaps is itself a finding.
- PNG is for chat; SVG is the deliverable. The web page inlines the SVG so the
  page's CSS and links can reach every beat.

## Audit — Windows lane build & bible comparison (2026-09-24)

Built and audited on the Windows lane (Dart SDK 3.13.1; Flutter not needed).
`dart/` is a Dart **pub workspace** (`dart/pubspec.yaml` lists 7 packages; the
repo root has no pubspec, as the acceptance note expected). Gates exercised:

- `dart pub get` — resolves (3 packages have newer versions outside constraints).
- `dart analyze --fatal-infos --fatal-warnings` — **clean, zero diagnostics**.
- `dart build cli --target bin/alluvial.dart` — builds
  `build/cli/windows_x64/bundle/bin/alluvial.exe`; the binary runs
  (`version`, `list`, `validate` over `stories/`: 36 stories, 2 invalid).
- `dart test` — green in 6 of 7 packages; **`packages/alluvial_render` fails**
  (see below). Per-package: cli 20, domain 39, store_memory 10, store_yaml 27,
  usecases 13.
- The byte-identity gate was **rebuilt from scratch here**, because the Python
  pipeline is the only thing that can produce the reference:
  `python dart/tool/render_reference.py C:/tmp/ref` (31 braid × 3 treatments +
  spec JSON, 5 two-clock) and `python dart/tool/number_corpus.py
  C:/tmp/ref/numbers.tsv` (534 values). Result with the corpus present:
  **96 of 98 artifacts byte-identical**; 2 differ (`hamlet`, `hamlet.cb`).

### Build & analysis findings (open)

- [ ] **`packages/alluvial_render` fails its own gate on Windows.** Two causes,
      both in the harness rather than in the engine:
      1. `test/parity_test.dart` rebuilds its file keys with
         `f.path.split('/').last` — on Windows the separator is `\`, so the key
         is the whole path and **every** corpus lookup misses. The test then
         compares nothing and fails only on the hardcoded
         `identical.should.be(95)`. With the separator fixed the gate really
         runs: 96/98 identical.
      2. `test/py_num_test.dart` hard-fails (`corpus.length > 100` → false) when
         the CPython-generated fixture is absent, where the sibling parity test
         skips. On a machine with no corpus, `dart test` in this package is red
         by construction.
- [ ] **`hamlet` is the one real content divergence: 2 of 98 artifacts.** With
      the corpus rebuilt and LF-normalised, `renderFilmChart` reproduces every
      artifact except `hamlet.svg` and `hamlet.cb.svg`, which differ in exactly
      one `<text>` line: Python emits `13 beats, 8 lanes. A play — the anchors
      are acts and scenes, not minutes.` (its non-film branch in
      `scripts/story_chart.py`), the Dart builder always emits the film wording
      `13 beats, 8 lanes. Time runs down the page.`
      (`dart/packages/alluvial_render/lib/src/builder/story_chart_builder.dart`,
      the `_titleBlock(...) ??` fallback). Hamlet is the only non-film braid, so
      it is the only casualty; `hamlet.mini.svg` has no footer and matches. The
      committed `out/hamlet-vertical.svg` already carries the play wording, so
      the Python side is the reference. This is the Dart half of the BACKLOG's
      "give `expression` a first-class home in the Dart store": the codec
      round-trips `expression` through `extra`, but the renderer never reads it.
      Fixing it is a code change, so it is recorded, not made.
- [ ] **The gate's count assertion is stale.** `identical.should.be(95)` (and
      the README / `dart/BACKLOG.md` "30 films × 3 + 5 = 95") predates the 36th
      story: the store now holds **36 stories = 31 braid + 5 two-clock = 98
      artifacts**. The assertion has to move with the store.
- [ ] **`python3` is not usable on this host** — `python3` is a pyenv-win shim
      with no version selected ("No global/local python version has been set"),
      so the documented commands (`python3 dart/tool/render_reference.py`,
      `python3 scripts/...`) fail as written. `python` (3.11.16, PyYAML 6.0.3)
      runs them fine. The two corpus generators needed only that rename.
- [ ] **The corpus generator writes CRLF on Windows.** `render_reference.py`
      and `number_corpus.py` open their outputs in text mode without
      `newline=''`, so on Windows every one of the 129 reference files gets
      `\r\n`. The Dart renderers emit `\n`, so a Windows-generated corpus fails
      **all 93** braid comparisons on line endings alone — a false alarm that
      hides the two genuine `hamlet` diffs. Generate with `newline=''`, or
      normalise, or compare after normalising.
- [ ] **`dart test` at the workspace root exits 65** —
      "No test files were passed and the default test/ directory doesn't exist".
      The gates only run per package; the README's "`dart test` runs that gate"
      and `dart/BACKLOG.md`'s "`dart analyze` / tests" are per-package in
      practice. Either add a root-level runner or say per-package in the docs.
- [ ] **`dart format` is not clean** (bible §2 wants the tree formatted before
      a commit): `dart format --output=none --set-exit-if-changed .` reports 2
      files it would change —
      `dart/packages/alluvial_domain/lib/src/codec/story_document_codec.dart`
      (a `if (...) 'expression': ...` line it wants split) and
      `dart/packages/alluvial_domain/test/story_validator_test.dart` (a block of
      `test(...)` calls it wants collapsed). Not touched here: formatting is a
      code change, and the diff is 140 lines.
- [ ] **Stale numbers in the docs.** `README.md` and `dart/BACKLOG.md` say 35
      stories / 30 braid films / 95 artifacts / "34 of 35 byte-identical"; the
      store is at 36 stories now (31 braid + 5 two-clock). `dart/BACKLOG.md`
      still lists the renderers under "Not ported (deliberately)" although both
      are ported and gated.
- [ ] **The two data defects are still open** (`validate`: 2 of 36 invalid) —
      `50-first-dates` (`beats[6].stubs` names henry, who stands in "THE BOAT"
      later; the same pair also marks him `enter` after he appeared) and
      `about-time` (`beats[9].stubs` names dad, who does not stand in that
      beat). Unchanged from `dart/BACKLOG.md`; the renderer still silently drops
      that stub.
- [ ] **No `AGENTS.md` in this repo**, though the task and the bible both assume
      one (the bible repo has its own). Not created here — writing an AGENTS.md
      is a conventions decision for the owner.

### Deviations from `staylorx/dart-flutter-bible` (flags, not fixes)

Read against the compact blob and §1–§11. Each is a spot where the code differs
from the bible and the bible may itself be wrong; none was changed.

- Deviation: `dart/` — no `dart_arch_test` boundary test. The bible makes
  package-boundary direction + workspace-wide cycle-freedom a **test-enforced CI
  hard gate** (§2 "Test-enforced", §9 step 7, §10 checklist). The workspace has
  none: no `dart_arch_test` dependency, no architecture test, no workspace-root
  `test/`. Boundaries are currently enforced by nothing.
- Deviation: `dart/` — no workspace-wide `dart test`. The bible's gate is
  "`dart test` green across the workspace" (§10); the workspace root has no test
  directory, so the gate only exists per package.
- Deviation: `dart/packages/alluvial_domain/lib/src/failures/domain_failure.dart`,
  `.../datasource_failure.dart`, `.../contracts/story_codec.dart`,
  `dart/packages/alluvial_render/lib/src/spec/chart_spec.dart`,
  `.../engine/vertical_renderer.dart`,
  `dart/packages/alluvial_usecases/lib/src/models/timeline.dart` — more than one
  class per file (5, 5, 2, 10, 3 and 4 respectively). The bible's rule is "One
  class per file, one file per class" (§2, §3). Argue for an exception (a sealed
  failure family and a spec value-object set read better together) or split
  them; the bible does not carve one out.
- Deviation: every package — **the error style is not declared**. §4 requires
  the style (FP-style tuples vs plain exceptions) stated in the package
  barrel's doc comment, the package README, and `AGENTS.md` on deviation
  ("silence is the violation"). The barrels carry a descriptive line but never
  say what a consumer receives; **no package has a README**; the repo has no
  `AGENTS.md`.
- Deviation: `dart/packages/alluvial_store_yaml` — the file store is a
  hand-rolled `dart:io` + `package:yaml` folder adapter, where §5 names
  **sembast** as "the default pure-Dart embedded file store" (tests:
  `databaseFactoryMemory`). The bible's rule assumes a database; this store is a
  folder of authored YAML that has to stay byte-identical and human-editable, so
  the bible may be the thing that is wrong here.
- Deviation: `dart/packages/alluvial_domain/lib/src/contracts/story_repository.dart`
  — no `IUnitOfWork? uow` on any method. §5/§10 want write methods (and
  optionally reads) to carry an optional `IUnitOfWork? uow`, with
  non-transactional stores sinking it gracefully. A folder-of-files store
  arguably has no transaction to expose; the contract is uniform today because
  every adapter is the same shape.
- Deviation: `dart/packages/alluvial_render/test/parity_test.dart` and
  `.../py_num_test.dart` — absolute POSIX paths (`/tmp/ref`, `/tmp/ref/numbers.tsv`)
  as the defaults, and a `'../../../stories'` CWD-relative store. §6's pitfall
  list bans hardcoded absolute paths in tests (env/`systemTemp` + `path`, and no
  `/tmp/foo` literals); on Windows `/tmp/...` is not the same place MSYS thinks
  it is, which is how the gate came up skipped.
- Deviation: `dart/packages/alluvial_render/test/parity_test.dart` — file names
  are derived with `split('/')`, a POSIX-only assumption. §6's spirit (and
  "tests pass on my machine, fail in CI") covers it; there is no bible rule
  about separators, only about portability.
- Deviation: `dart/packages/alluvial_store_memory` — the in-memory store is a
  legitimate second adapter and the contract suite does run against both
  (bible-compliant), but no bible §5 "UnitOfWork pitfalls" apply here because
  there is no UnitOfWork; recorded so the next reader does not go looking for
  the pitfall section.

