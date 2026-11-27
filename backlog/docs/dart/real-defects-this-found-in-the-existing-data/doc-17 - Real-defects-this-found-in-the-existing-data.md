---
id: doc-17
title: Real defects this found in the existing data
type: other
created_date: '2026-11-08T18:54:00Z'
---


## Real defects this found in the existing data

`validate` is stricter than the Python gate, whose JSON schema only covers
shapes. Both findings are the documented rule from `STORY-SCHEMA.md` — a stub
must sit on the character's last present beat — so both are content errors, not
validator noise:

- `50-first-dates` — `beats[6].stubs` names henry, and henry stands in "THE BOAT"
  later; the same beat pair also marks him `enter` after he appeared.
- `about-time` — `beats[9].stubs` names dad, who does not stand in that beat. The
  Python renderer silently drops a stub like this, so the chart may already be
  under-drawing that fade.

**Both fixed 2026-11-27 — `validate` is clean, 0 of 36 invalid.**

They turned out to be two *different* errors sharing one cause: using `enter` /
`stubs` — which mean *first* and *last* appearance — to express a mid-story
departure.

- `50-first-dates` — both marks were simply false; henry stands in every beat, so
  he neither exits nor re-enters. `stubs: [henry]` (beat 6) and `enter: [henry]`
  (beat 7) removed. The chart loses a phantom `new lanes ▸ Henry` banner and a
  spurious exit stub, and is 24 px shorter.
- `about-time` — the mark was in the right spirit and the wrong beat. `stubs:
  [dad]` moved from "THE THIRD CHILD" (beat 9, a beat he does not stand in — he
  is dead) to "THE LAST TRIP" (beat 8), his last present beat. The prediction
  above was right: the Python renderer HAD been silently dropping the fade, and
  now draws dad's exit stub at the scene that is his goodbye.

Both edits change the rendered SVG, and the two engines still agree byte for
byte (98 of 98). `format --apply` also stops refusing those two files, so all 36
write.

**What is NOT fixed, because the schema cannot say it:** a character who leaves
and returns mid-story. `enter` / `stubs` are first/last only, and
`PresenceState` has no third state. The prose (`cap` / `tag`) carries that beat
— "he leaves Hawaii", "the gesture is the return". If that device is wanted as a
*drawn* thing, it is a schema feature, not a data fix, and it should be proposed
as one rather than smuggled into the data.

One task covered both: ALL-40. Closed 2026-11-27.
