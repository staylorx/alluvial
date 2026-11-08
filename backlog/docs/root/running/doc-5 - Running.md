---
id: doc-5
title: Running
type: guide
created_date: '2026-11-08T18:53:00Z'
---


## Running

```bash
cd scripts
python3 dresses27_vertical.py        # -> out/27dresses-vertical.svg
python3 dresses27_vertical.py --cb   # -> out/27dresses-vertical-cb.svg (colour-blind)
```

Verify a render (lane order read back out of the PNG):
```bash
python3 ~/.hermes/skills/creative/narrative-alluvial/scripts/verify_render.py \
        ../out/np-vertical-a-raw.png 1120 h400:60-660
```
