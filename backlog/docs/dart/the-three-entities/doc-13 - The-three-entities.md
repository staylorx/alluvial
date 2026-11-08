---
id: doc-13
title: The three entities
type: other
created_date: '2026-11-08T18:54:00Z'
---


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
