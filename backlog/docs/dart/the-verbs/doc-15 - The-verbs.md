---
id: doc-15
title: The verbs
type: other
created_date: '2026-11-08T18:54:00Z'
---


## The verbs

`alluvial <verb> --store <dir> [--output json|text]`, JSON on stdout by default
because the primary caller is an agent.

| Verb | Does |
|---|---|
| `list` | every story, summarised, with its key, shape, counts, and any decode problem |
| `show <key>` | one story: `chars`, `beats`, `appearances` as separate collections |
| `validate [key...]` | the schema and authored limits; exit 1 if any story has an error |
| `timeline <key>` | beat by beat: parties in sequence, and who is off page |
| `roundtrip [key...]` | read → encode → decode and report what moved, per story |
| `format [key...] [--apply]` | write the canonical form; dry run unless `--apply`; refuses a story with errors |
| `chart <key> [--out f] [--svg]` | draw the story as an SVG, or `--out-dir <d>` for every story in the store |
| `version` | what is running, as JSON |

`chart` takes `--variant braid\|colour-blind\|mini\|two-clock`. The renderer picks
itself from the story's shape: a two-clock story has no braid to draw and a braid
story has no second clock, so asking for the wrong one is a usage error (exit 64)
rather than a silently empty chart. Nothing is written without `--out`/`--out-dir`.

Exit codes: `0` fine, `1` the operation failed but the arguments were fine, `64`
the arguments were not usable (including an unknown verb or a missing `--store`).
