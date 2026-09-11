# alluvial (Dart) — BACKLOG

**Read this first.** The Dart story store and CLI: a folder of YAML files is the
repository, the CLI reads it, checks it, and writes it back.

Canonical home while it is being baselined: `~/hermes/projects/alluvial/dart/`
(git branch `dart-cli`). The Python pile it replaces lives one level up.

## The three entities

Everything in the store is these three, and nothing else:

| Entity | Is | Carries |
|---|---|---|
| **Character** | a person, a **place**, or a **thing** | a stable id, a label, `kind`, a weight (narrative presence ≈ ribbon width), a colour |
| **Beat** | an act, a scene, or a beat inside one | id, name, `kind`, `parentRef` (the act or scene it is part of), position in the told story, optional second-clock position, two caption lines, a tag, category ids |
| **Appearance** | one character's place in one beat — **the relation** | which character, which beat, its `order` (sequence within the beat), its `party` (who it stands with), or an explicit `laneY` for hand-tuned beats, and a state (on page / entering / exiting) |

The relation is derived from `clusters` on the way in and rebuilt on the way
out, so a beat's shape is authored once and the model holds it explicitly
instead of every caller re-parsing it. Absence is not a state: a character with
no appearance in a beat is *off page*, and the store derives that (`offPageIn`).

## The store

`<slug>.yaml`, one file per story, with a `<slug>.json` read as a fallback. The
**key** is the filename and is the handle every verb takes. The **slug** is the
story's own identity and is not always the same thing: a two-clock chart is
filed as `<slug>-timechart.yaml` while still naming the film it belongs to, so
two files legitimately share one slug. Writes go to the key — writing by slug
would overwrite the film's own file (this bug was written once and caught by a
real end-to-end write, which is why `format --apply` exists).

Nothing the codec does not model is dropped: uninterpreted fields are carried in
`extra` and re-emitted, including an `enter`/`stubs` list the presence model
cannot express.

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

## What is proven

Measured against the real 35-file store (30 braid + 5 two-clock):

- **Reads**: all 35 decode, none silently dropped; a file that is not a story is
  reported in the listing rather than skipped.
- **Round trip**: 35/35 stories are a fixed point (decode → encode → decode is
  the same story).
- **Writer**: 34/35 files are reproduced **byte-for-byte**, header block
  included. The one difference is `the-tao-of-steve`'s explicit `score: null`,
  which the writer omits — an explicit null and an absent field mean the same
  thing, and it is the only normalisation left.
- **Write cycle**: `format --apply` over a copy of the whole store writes 33
  stories, refuses 2, creates no file, loses none, and leaves 34/35 files
  byte-identical to the originals.
- **Analyzer / tests**: `dart analyze --fatal-infos --fatal-warnings` reports
  nothing; `dart format` changes nothing; 100 tests pass (35 domain, 13
  usecases, 27 folder store, 10 memory store, 15 CLI).
- **The artifact**: `dart build cli` produces a bundle; a full 35-story listing
  takes ~70 ms, against ~2 s for `dart run`.

## Real defects this found in the existing data

`validate` is stricter than the Python gate, whose JSON schema only covers
shapes. Both findings are the documented rule from `FILM-SCHEMA.md` — a stub
must sit on the character's last present beat — so both are content errors, not
validator noise:

- `50-first-dates` — `beats[6].stubs` names henry, and henry stands in
  "THE BOAT" later; the same beat pair also marks him `enter` after he appeared.
- `about-time` — `beats[9].stubs` names dad, who does not stand in that beat.
  The Python renderer silently drops a stub like this (the skill's own note says
  it does), so the chart may already be under-drawing that exit.

Neither file is written by `format --apply` until the data is fixed.

## Not ported (deliberately)

- **The renderers.** The Python engine draws the SVG (horizontal, vertical,
  two-clock, colour-blind mode, the eleventy publisher). A second renderer that
  disagrees with the first is worse than one renderer, so the port is a phase of
  its own and its gate is byte-identity with the approved artifacts — the same
  gate the Python pipeline used on itself.
- **The note ↔ data loop.** `film_note.py` / `note_to_json.py` (the readable
  editing surface with the note-body hash guard) have no Dart counterpart yet.
- **The web page builder.**

## Next

- [ ] Port the renderer with byte-identity as the gate: the approved `.svg`
      files in `../out/` are the fixture, and `dart run tool/emission_report.dart`
      is the shape of the harness.
- [ ] Beat ids are derived from the beat's name (the stored format carries no
      beat id), so renaming a beat renames it everywhere. If a stable identity
      is wanted, the schema and the Python writer have to agree on an `id:` field
      first — do not invent one on the Dart side alone.
- [ ] Decide the store's `kind` vocabulary for works that are not films (the
      field exists, defaults to `film`, and no file uses it yet).
- [ ] The two-clock shape reads but does not yet expose its second clock in
      `timeline` (the crossings are the point of that chart).
- [ ] A `new` verb to scaffold a story file from a template.
- [ ] Fix the two data defects above, or write down why they are intentional.

## Decisions worth not re-litigating

- **The key is the address, the slug is the identity.** Two files can share a
  slug; only the key is unique. Every verb takes a key.
- **The beat's name is its identity.** Derived ids are stable and checkable;
  a rename is a rename.
- **The writer folds long scalars at the first single space past column 110 and
  keeps the authored header verbatim.** Both were derived by measuring what the
  Python writer actually emits, and they are what takes byte-identity from 0 to
  34 of 35 files.
- **A four-space or six-space difference is a real difference.** The one
  remaining byte difference is an explicit null; do not chase it by inventing a
  null-preserving flag.
- **Store adapters share one orchestration.** The folder adapter and the memory
  adapter differ only in where documents live, so the sequence (read, decode,
  map failures, refuse to write an invalid story) lives once, in the domain, and
  the contract suite proves both adapters behave the same.
