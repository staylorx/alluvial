---
id: ALL-36
title: The corpus generator writes CRLF on Windows
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 36000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**The corpus generator writes CRLF on Windows.** `render_reference.py`
      and `number_corpus.py` open their outputs in text mode without
      `newline=''`, so on Windows every one of the 129 reference files gets
      `\r\n`. The Dart renderers emit `\n`, so a Windows-generated corpus fails
      **all 93** braid comparisons on line endings alone — a false alarm that
      hides the two genuine `hamlet` diffs. Generate with `newline=''`, or
      normalise, or compare after normalising.
<!-- SECTION:DESCRIPTION:END -->
