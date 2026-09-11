#!/usr/bin/env python3
"""Render the reference corpus the Dart renderer is gated against.

The Dart port is held to BYTE-IDENTITY with the Python engine, because the
layout is hand-tuned across a hundred artifacts and "equivalent output" would
silently redraw stories that were already approved. This script produces the
reference side of that comparison from the Python pipeline itself:

  <out>/<slug>.svg           the page's own embed, for every braid film
  <out>/<slug>.cb.svg        the colour-blind treatment
  <out>/<slug>.mini.svg      the pinned mini-map
  <out>/<slug>.spec.json     the layout the builder computed, field by field
  <out>/twoclock/<slug>.svg  every two-clock chart

The spec JSON is what makes a mismatch diagnosable: the SVG diff says something
is wrong, the spec diff says whether it was the builder (layout) or the engine
(markup).

Usage:  python3 dart/tool/render_reference.py [out-dir] [slug]
        python3 dart/tool/render_reference.py /tmp/ref

Then:   cd dart/packages/alluvial_render && dart test
        dart run tool/parity_report.dart <store-dir> /tmp/ref
"""
from __future__ import annotations

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
for path in (os.path.join(ROOT, "scripts"), os.path.join(ROOT, "web")):
    if path not in sys.path:
        sys.path.insert(0, path)

import story_chart          # noqa: E402
import stories_yaml          # noqa: E402
import reorder_chart       # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else "/tmp/ref"
ONLY = sys.argv[2] if len(sys.argv) > 2 else None

os.makedirs(OUT, exist_ok=True)
os.makedirs(os.path.join(OUT, "twoclock"), exist_ok=True)

braid = 0
two_clock = 0
for slug in stories_yaml.all_slugs():
    if ONLY and slug != ONLY:
        continue
    doc = stories_yaml.load(slug)
    if "scenes" in doc:
        svg, _info = reorder_chart.render(doc)
        with open(os.path.join(OUT, "twoclock", f"{slug}.svg"), "w", encoding="utf-8") as fh:
            fh.write(svg)
        two_clock += 1
        continue

    for suffix, kwargs in (("", {}), (".cb", {"cb": True}), (".mini", {"mini": True})):
        svg, spec, height, checks = story_chart.render(doc, **kwargs)
        with open(os.path.join(OUT, f"{slug}{suffix}.svg"), "w", encoding="utf-8") as fh:
            fh.write(svg)
        if suffix == "":
            # beat_links is a callable; the port hard-codes the same href rule
            payload = {
                "spec": {k: v for k, v in spec.items() if k != "beat_links"},
                "H": height,
                "legend_rows": checks["legend_rows"],
                "lane_overlaps": checks["lane_overlaps"],
            }
            with open(os.path.join(OUT, f"{slug}.spec.json"), "w", encoding="utf-8") as fh:
                json.dump(payload, fh, indent=1, sort_keys=True, ensure_ascii=False)
    braid += 1

print(f"braid films:        {braid}  (default + colour-blind + mini + spec json each)")
print(f"two-clock charts:   {two_clock}")
print(f"written to:         {OUT}")
