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

**Evidence found while fixing ALL-40 (2026-11-27)** — stronger than the ticket
assumed:

- Dry-run mode is not a dry run. `format` without `--apply` reports
  `would-write` for every story that merely **validates**, without ever
  comparing bytes (`format_command.dart:63-78`), so its output cannot tell you
  whether anything would actually change.
- `--apply` calls `SaveStory` on **all 36 stories unconditionally**
  (`format_command.dart:80`). Verified on a scratch copy of an unchanged store:
  it rewrote every file while changing not one byte. Every run rewrites the whole
  store even when the result is identical, so the half-write window is always
  36 files wide, not just the changed ones.
- The fix is therefore two parts: compare before writing, and make the batch
  all-or-nothing (buffer and commit whole, §5.6).

**Sequencing and value (2026-11-27)** — the two parts are NOT equal in value, so
this should not be taken as one lump:

- **Part 1, compare before writing: the real win.** Today `format` cannot answer
  any question, because it never compares. With a compare, dry-run answers "is
  the store canonical?", and that answer can become a GATE —
  `store-format: alluvial format --store stories` failing when the store is not
  canonical, joining analyze + test under `melos run gate`. The store is
  HAND-AUTHORED, since human-editable YAML is the point of the format, and nothing
  else stops a hand-edit from drifting into a second shape — which would leave the
  byte-identity parity gate comparing against a moving target.
- **Part 2, the all-or-nothing batch: insurance, and LOW severity here.** The
  store is git-tracked (36 files) and formatting is cosmetic (byte-identical on a
  canonical store), so a half-write costs one `git checkout` and the next run
  finishes the job. It earns its keep as the shop window for a bulk SEMANTIC write
  (a re-key, a migration, an import) where half-applied is genuinely bad, and by
  making "this store cannot roll back" a stated fact at the composition root
  instead of an accident of the code.
- Do both in one pass — the buffer is what makes the compare honest, because the
  intended output must be in hand before deciding to write, so splitting them
  means writing the same code twice. Part 1 alone is defensible if only the gate
  is wanted.
- Cost: about half a day with tests, no new dependencies, no user-visible change.
  It is infrastructure, not a feature.
<!-- SECTION:DESCRIPTION:END -->
