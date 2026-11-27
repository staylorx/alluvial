---
id: ALL-47
title: >-
  Deviation:
  `dart/packages/alluvial_domain/lib/src/contracts/story_repository.dart`
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: ["deviation"]
dependencies: []
ordinal: 47000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**No `UnitOfWork` on the rule-carrying operation.** §5.5 is explicit that the
*repository contract stays plain* — the transaction seam sits on the OPERATION,
as a required constructor dependency of the use case (a `UnitOfWork` function
type), with `noOpUnitOfWork` wired at the composition root for a store that
cannot roll back.

The original reading of this ticket — "repository methods want an optional
`IUnitOfWork? uow`" — was wrong; the contract is correct as it stands.

The real residual: `DocumentStoryRepository.save()` decides a rule by reading
and then writes (it validates the story and refuses it before touching the
store), and §5.5 puts exactly that shape on the seam. No operation in the
workspace carries a `UnitOfWork` today.

Rewritten 2026-11-27 against §5.5; recorded in `AGENTS.md` item 6.
<!-- SECTION:DESCRIPTION:END -->
