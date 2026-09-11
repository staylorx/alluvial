# Two-clock chart data — the format

One optional file per chopped-up film: `films/<slug>-timechart.json`. It carries
the same film's scenes twice — once in the order the film screens them, once in
the order they happen to the people in it. The chart draws both spines and joins
each scene across, so the crossings are the film's cuts.

```json
{
  "slug": "sliding-doors",
  "title": "Sliding Doors",
  "year": 1998,
  "runtime_min": 99,
  "sub": "Two clocks: what the film shows you, and what actually happens.",
  "notes": ["One line of context.", "A second line, optional."],
  "threads": {"helen": "Helen", "gerry": "Gerry", "james": "James"},
  "legend_note": "Numbering: left spine = screening order, right spine = real order.",
  "scenes": [
    {"id": "doors", "label": "The tube doors close", "chapter": "THE SPLIT",
     "as_screened": 1, "happened": 1, "thread": "helen", "mins": 6}
  ]
}
```

## Rules

- **`as_screened` and `happened` must each be a permutation of 1..N** for the
  same N scenes — every scene gets one position on each spine, no gaps, no
  duplicates. This is what makes the crossings meaningful.
- **6–14 scenes.** Fewer than 6 is not a chop; more than 14 stops being readable.
- **`label`** ≤ 34 characters, a plain description of the scene. **`chapter`** is
  the film's own chapter card where it has one (e.g. `PROLOGUE`), otherwise the
  act it sits in.
- **`thread`** must be a key in `threads` — it colours the node and its ribbon, so
  use it for whose story the scene belongs to.
- **`mins`** is a rough on-screen length, used only for ribbon thickness.
- **Only chart the chop where it is real.** If a film tells itself in order, it
  does not need this chart. If it has two parallel timelines (Sliding Doors),
  chart the film's own interleaving rather than inventing a merged chronology.
- Do not invent scenes. If the chronology is a judgement call, say so in `notes`
  and keep the labels to what the film actually shows.

## Check your work

```bash
python3 /home/installer/hermes/projects/alluvial/scripts/verify_films.py <slug>-timechart
```

The verifier checks the permutation rule, the scene count, thread keys and label
lengths.
