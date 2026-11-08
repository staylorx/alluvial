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

Neither file is written by `format --apply` until the data is fixed.
