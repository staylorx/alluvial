---
id: doc-14
title: The store
type: other
created_date: '2026-11-08T18:54:00Z'
---


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
