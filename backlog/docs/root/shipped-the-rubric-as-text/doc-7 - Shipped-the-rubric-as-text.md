---
id: doc-7
title: 'Shipped: the rubric, as text'
type: other
created_date: '2026-11-08T18:53:00Z'
---


## Shipped: the rubric, as text

The page carries the rubric itself (six categories, point values, wording quoted
from the draft, the Kaling line, the house note) plus the category text under
each beat that earns one. `scripts/rubric27.py` is the single source of truth
for that text and for the beat -> category map; both page builders import it.
Live: same URL, site commit `0096f90`.
