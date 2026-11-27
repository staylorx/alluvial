---
id: ALL-47
title: 'The bulk `format --apply` has no unit of work'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["deviation"]
dependencies: []
ordinal: 47000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**The bulk `format --apply` rewrites N documents with no unit of work.**

§5.5 puts the transaction seam on the OPERATION — as a required constructor
dependency (a `UnitOfWork` function type) — and keeps the repository contract
plain. A store that cannot roll back is stated once at the composition root by
wiring `noOpUnitOfWork`, and a non-transactional store emulates by buffering and
committing whole (§5.6).

`alluvial format --apply` loops over every story in the store and calls
`SaveStory` one at a time
(`alluvial_cli/lib/src/commands/format_command.dart`), so a failure partway —
disk full, permissions — leaves the store HALF-formatted. The store is the
product, so that is the operation the seam is for.

A single `save()` is NOT the problem: it is a pure validator check followed by
one write, with no store read feeding the decision, so §5.5's race argument does
not apply to it.

Rewritten 2026-11-27 by reading the command. The original ticket read this as
"repository methods want an optional `IUnitOfWork? uow`" — that is wrong; the
contract is correct as it stands. Recorded in AGENTS.md item 6.
<!-- SECTION:DESCRIPTION:END -->
