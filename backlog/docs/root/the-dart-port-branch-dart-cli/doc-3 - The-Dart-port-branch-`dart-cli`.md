---
id: doc-3
title: The Dart port (branch `dart-cli`)
type: other
created_date: '2026-11-08T18:53:00Z'
---


## The Dart port (branch `dart-cli`)

`dart/` is a Dart pub workspace that reads this store, models it as three
entities (character / beat / appearance), validates it against the schema and
the authored limits, writes it back, and **draws it** — both renderers are
ported and byte-identical.

Read `the backlog board (`backlog/`)` for the proofs and the open questions. Two openings worth
a decision, neither closed by the port: the two-clock palette (`THREAD` in
`scripts/reorder_chart.py`) only knows Pulp Fiction's five thread ids, so four of
the five timechart charts draw every ribbon grey; and the Eleventy page layer
(`web/`) is still JavaScript.
