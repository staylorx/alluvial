---
id: ALL-44
title: >-
  Deviation:
  `dart/packages/alluvial_domain/lib/src/failures/domain_failure.dart`,
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 44000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deviation: `dart/packages/alluvial_domain/lib/src/failures/domain_failure.dart`,
`.../datasource_failure.dart`, `.../contracts/story_codec.dart`,
`dart/packages/alluvial_render/lib/src/spec/chart_spec.dart`,
`.../engine/vertical_renderer.dart`,
`dart/packages/alluvial_usecases/lib/src/models/timeline.dart` — more than one
class per file (5, 5, 2, 10, 3 and 4 respectively). The bible's rule is "One
class per file, one file per class" (§2, §3). Argue for an exception (a sealed
failure family and a spec value-object set read better together) or split
them; the bible does not carve one out.
<!-- SECTION:DESCRIPTION:END -->
