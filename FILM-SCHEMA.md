# Film chart data — the format

One JSON file per film: `films/<slug>.json`. Everything visual is computed from
it, so authoring a film is filling in a table, not drawing a chart. Two rules
that matter most:

- **Captions are chart captions, not prose.** Two lines, each ≤ **47** characters.
  The caption column fits about 47 at 16.5px; longer lines run off the canvas and
  the verifier will fail the film.
- **Clusters are who is standing together.** That IS the chart: a character in a
  cluster with someone else shares a lane with them; a character absent from a
  beat is off-page (drawn hatched) and the engine handles that for you.

## Shape

```json
{
  "slug": "when-harry-met-sally",
  "title": "When Harry Met Sally",
  "year": 1989,
  "runtime_min": 96,
  "score": 29,
  "score_note": "ties the top of the table with Always Be My Maybe",
  "legend_object": "the...",          // OPTIONAL: only if the film has a title object
  "order": ["harry","sally","jess","marie"],   // lane order, top-to-bottom in every stack
  "chars": [
    {"id":"harry","name":"Harry","width":32,"colour":"#1b57c4"},
    {"id":"sally","name":"Sally","width":30,"colour":"#d0316a"}
  ],
  "beats": [
    {
      "name": "THE DRIVE TO CHICAGO",
      "loc": "≈ 0–10 min",
      "cap": ["they argue about whether men and women",
              "can be friends; neither means it"],
      "tag": "MEET-CUTE — an entrance, not a marriage",
      "cats": ["meet"],
      "clusters": [["harry","sally"], ["jess"], ["marie"]],
      "enter": ["jess","marie"],       // OPTIONAL: first appearance
      "stubs": ["jess"]                // OPTIONAL: exits for good before this beat
    }
  ]
}
```

## Field rules

- **`expression`** — the form the story is told in: `film` (the default: an
  absent field means film, which is what every file written before 2026-09-11
  is), or `play`, `novel`, `series`, `short story`, `essay`, `poem`, `song`,
  `musical`. Set it for anything that is not a film. The chart's anchors follow
  it — a play's `loc` is an act and scene, not a minute mark — the store's
  header names it, and the title block says which form it is instead of
  counting minutes. **`year` is the WORK's year** (a play's first staging or
  composition), so it is no longer bounded at 1900: the store holds works older
  than cinema.
- **`runtime_min`** — a film's running time. Leave it off for a play or a
  novel; there is no honest number, so don't invent one.
- **`order`** — every id, most important first. Stacks keep this order, so the
  chart reads consistently beat to beat. Lane **label size follows width**, so
  order matters less than width.
- **`chars[].id`** — lowercase, no spaces. **`name`** — as the chart should print
  it (11 chars max: it sits in a lane label). **`width`** — the character's
  weight in the story: lead 30–34, second 22–28, third 16–20, minor 12–15.
- **`chars[].colour`** — keep the house palette so the charts look like a set:
  lead A `#1b57c4`, lead B `#d0316a`, then `#6e9078`, `#9c6552`, `#b09a4e`,
  `#8d7fa8`, `#6f8f96`, `#b08a94`.
- **`beats`** — 8–13 beats, in story order. 11 is the sweet spot.
  - **`loc`** — approximate position in the film: `"≈ 35–50 min"`, or `"the coda"`.
  - **`cap`** — exactly 2 lines, ≤ 62 chars each, factual, present tense, no
    character names invented. This is what prints beside the row.
  - **`tag`** — one clause after an em dash, naming what the beat is. E.g.
    `"BREAKUP — it flows from who he is"`.
  - **`cats`** — which rubric categories this beat earns, by id:
    `chem` (10) · `meet` (5) · `bff` (5) · `breakup` (5) · `gesture` (2) ·
    `ebert` (3). Only tag a beat when it genuinely earns it; `[]` is fine and
    common — most beats are structure, not score.
  - **`clusters`** — left-to-right on the page, each an ordered list of ids
    standing together. Every character who is *present* must appear in exactly
    one cluster; omitted characters are drawn off-page. Within a cluster the
    `order` list decides who sits on top.
  - **`enter` / `stubs`** — a first appearance and a final exit. **`stubs` must
    name the character's LAST PRESENT beat**, not the beat after (the renderer
    draws the off-page hatch from that beat's lane, so a stub on a beat where the
    character is absent raises `KeyError`).

## Hard limits

- **8 lanes maximum.** For a big ensemble (Love Actually, Crazy Stupid Love),
  pick the strands the rubric is judging and give the remainder one shared lane
  (e.g. `{"id":"others","name":"others",...}`) rather than ten lanes.
- **≤ 13 beats.** A long film gets fewer, broader beats, not more.
- A film with 4–6 lanes and 10–12 beats renders cleanly; more needs hand-tuning.

## Check your work

```bash
python3 /home/installer/hermes/projects/alluvial/scripts/film_chart.py <slug>
```

Prints the film's beat/lane counts and which beats carry a rubric category. It
must run without error.

## What NOT to do

- **A non-romcom must carry `cats: []` on every beat.** An OMITTED `cats` falls
  back to the romcom rubric category for that beat number (`rubric27.for_beat`),
  so a play or a novel silently acquires romcom commentary it never earned. Put
  the empty list in — it is a statement, not a default.
- Don't write prose, reviews, or opinion into `cap` — the captions are the
  film's skeleton.
- Don't invent beats that aren't in the film, and don't invent character names
  (say "the best friend" only if they are genuinely unnamed).
- Don't add per-beat commentary for the owner: beats are anchors to jump
  around in, nothing is expected to be written into them.
