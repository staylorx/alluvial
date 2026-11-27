---
id: doc-18
title: Design rules carried from the board
type: other
created_date: '2026-11-27T00:00:00Z'
---


## Design rules carried from the board

The rules the charts and the store obey — each cost a round when broken. Several
lived only in board task titles until the 2026-11-27 triage; this is their
repo-local record. The procedural memory (engine notes, pitfalls) lives in the
Hermes skill `alluvial-store`.

- **No per-beat writing.** The beats are anchors to jump around in; there is
  nothing to say per beat and the requirement is dropped (owner, 2026-09-11). The
  rubric text sits under each beat instead, because that is text we actually have.
- **The rubric is quoted, not paraphrased.** If the rubric changes in the draft,
  change `scripts/rubric27.py` and rebuild — don't edit page copy.
- **Ribbon width ≈ narrative presence (Sankey rule).** Label size and colour-blind
  darkness both derive from it, so the encodings agree instead of fighting.
- **Time runs down in the vertical version**; the semantic bands become left/right
  (family | the leads | the social world).
- **PNG is for chat; SVG is the deliverable.** The web page inlines the SVG so the
  page's CSS and links can reach every beat.
- **The key is the address, the slug is the identity** — see *the store* (doc-14).
  Two files can share a slug; only the key is unique. Every verb takes a key, and
  writes go to the key.
- **A beat's name is its identity.** The stored format carries no beat id; ids are
  derived from the name, so renaming a beat renames it everywhere.
- **The writer folds long scalars at the first single space past column 110** and
  keeps the authored header verbatim — both derived by measuring what the Python
  writer actually emits.
- **A four-space or six-space difference is a real difference.** The one remaining
  byte difference is an explicit null; do not chase it by inventing a
  null-preserving flag.
- **Both renderers were ported, and byte-identity with the Python engine is the
  gate.** Never write a third renderer; extend `alluvial_render` and hold it to
  the Python output.
