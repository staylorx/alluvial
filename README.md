# Alluvial

Story structure as data you can read and a chart you can check.

One YAML file per story in a folder **is** the repository. Every story is three
entities and nothing else:

- **Character** — a person, a **place**, or a **thing**. A strand.
- **Beat** — an act, a scene, or a beat inside one. A column.
- **Appearance** — one character's place in one beat. *The relation*: where it
  sits in that beat's sequence, and who it stands with while it is there.

Everything the chart draws is derived from those three. Absence is not a state —
a character with no appearance in a beat is simply *off page*, and the store
works that out.

The picture is an **alluvial diagram**: the time-ordered Sankey, named after
alluvial fans, strands persisting and merging and splitting down a time axis.
R's `ggalluvial` draws the same form to answer the same kind of question. Read it
top to bottom and you are reading the story in the order it is told; a dashed
strand is off page.

## Two halves

- **`dart/` — the port.** A Dart pub workspace: the store, a validator, an
  agent-facing CLI, and **both renderers** (the braid chart and the two-clock
  chart). Start at [`dart/BACKLOG.md`](dart/BACKLOG.md).
- **`scripts/` + `stories/` + `out/` + `web/` — the original.** The Python pipeline
  that produced every approved chart, the story store itself, the committed SVGs,
  and the Eleventy publisher that turns a story into a page. Start at
  [`BACKLOG.md`](BACKLOG.md).

The Dart renderers reproduce the Python engine **byte for byte** — 95 of 95
reference artifacts: 30 films in each treatment the pages embed (default,
colour-blind, mini) plus all five two-clock charts, with the drawn layout
matching field for field. The layout is hand-tuned across a hundred artifacts,
so "equivalent output" was never going to be good enough. `dart test` runs that
gate.

## Quick start

```bash
# --- the Dart workspace (the store, the CLI, the renderers)
cd dart
dart pub get
cd packages/alluvial_cli

dart run bin/alluvial.dart list     --store ../../../stories      # every story
dart run bin/alluvial.dart validate --store ../../../stories      # what is wrong
dart run bin/alluvial.dart chart when-harry-met-sally \
      --store ../../../stories --out /tmp/when-harry-met-sally.svg
dart run bin/alluvial.dart chart --out-dir /tmp/charts --store ../../../stories
```

JSON is the default on stdout (`--output text` for prose) because the primary
caller is an agent. Exit codes: `0` fine, `1` the operation failed, `64` the
arguments were unusable. Nothing is written without `--out`/`--out-dir`.

```bash
# --- the Python side (the baseline the port is measured against)
python3 scripts/stories_yaml.py validate         # the authored schema gate
python3 scripts/story_chart.py notting-hill     # one film's chart, as the page embeds it
python3 dart/tool/render_reference.py          # the byte-identity reference corpus
```

## The store

`stories/<slug>.yaml`, one file per story, with the schema in `schema/` beside it
and the editing rules in each file's own header comment. The **key** is the
filename and is the handle every verb takes; the **slug** is the story's own
identity, and two files can share one — a two-clock chart is filed as
`<slug>-timechart.yaml` while still naming the film it belongs to. A folder of
these files is the whole collection.

35 stories so far: 30 braids, 5 two-clock charts. The pages built from them are
live at [staylorx.com/movies](https://staylorx.com/stories/27-dresses/).

## Where to read next

- [`dart/BACKLOG.md`](dart/BACKLOG.md) — what the port has proven, what it has
  deliberately not ported, and the two real data defects it found.
- [`BACKLOG.md`](BACKLOG.md) — the Python pipeline's own record.
- [`STORY-SCHEMA.md`](STORY-SCHEMA.md) and
  [`STORY-SCHEMA-TIMECHART.md`](STORY-SCHEMA-TIMECHART.md) — the two chart shapes,
  written out for an author.

## Licence

None yet.
