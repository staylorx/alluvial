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

Neither file is written by `format --apply` until the data is fixed. One task
covers both: ALL-40.
