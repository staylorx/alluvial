---
id: doc-4
title: The data model
type: other
created_date: '2026-11-08T18:53:00Z'
---


## The data model

Every chart is one `COLS` table: a list of beats, each with
`beat` / `loc` / `cap` / `hard` / `tag` / `groups` / `stubs` / `terminal` /
`enter`, plus a `CHAR` map (label, ribbon width, colour). **This table is the
content model** — the SVG, the PNG, and (next) the web page are all rendered
from it. Adding a story = writing one table + the prose.
