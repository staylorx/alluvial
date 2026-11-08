---
id: doc-11
title: Audit — Windows lane build & bible comparison (2026-09-24)
type: other
created_date: '2026-11-08T18:54:00Z'
---


## Audit — Windows lane build & bible comparison (2026-09-24)

Built and audited on the Windows lane (Dart SDK 3.13.1; Flutter not needed).
`dart/` is a Dart **pub workspace** (`dart/pubspec.yaml` lists 7 packages; the
repo root has no pubspec, as the acceptance note expected). Gates exercised:

### Build & analysis findings (open)

### Deviations from `staylorx/dart-flutter-bible` (flags, not fixes)

Read against the compact blob and §1–§11. Each is a spot where the code differs
from the bible and the bible may itself be wrong; none was changed.
