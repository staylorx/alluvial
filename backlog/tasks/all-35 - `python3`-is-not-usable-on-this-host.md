---
id: ALL-35
title: '`python3` is not usable on this host'
status: To Do
assignee: []
created_date: '2026-11-08T18:51:00Z'
labels: []
dependencies: []
ordinal: 35000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**`python3` is not usable on this host** — `python3` is a pyenv-win shim
      with no version selected ("No global/local python version has been set"),
      so the documented commands (`python3 dart/tool/render_reference.py`,
      `python3 scripts/...`) fail as written. `python` (3.11.16, PyYAML 6.0.3)
      runs them fine. The two corpus generators needed only that rename.
<!-- SECTION:DESCRIPTION:END -->
