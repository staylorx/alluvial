---
id: ALL-46
title: 'Deviation: `dart/packages/alluvial_store_yaml` — the file store is a'
status: Done
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["deviation"]
dependencies: []
ordinal: 46000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deviation: `dart/packages/alluvial_store_yaml` — the file store is a
hand-rolled `dart:io` + `package:yaml` folder adapter, where §5 names
**sembast** as "the default pure-Dart embedded file store" (tests:
`databaseFactoryMemory`). The bible's rule assumes a database; this store is a
folder of authored YAML that has to stay byte-identical and human-editable, so
the bible may be the thing that is wrong here.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Recorded, not fixed: an argued exception in `AGENTS.md` item 5 — the store is authored, git-diffable, byte-identical YAML, and that byte-identity IS the product gate; §5.3 declines to force a second file adapter.
<!-- SECTION:FINAL_SUMMARY:END -->
