#!/usr/bin/env python3
"""Write the number corpus the Dart port's formatting is pinned against.

The renderer is compared byte for byte with CPython, and the two languages
disagree about rounding: CPython rounds half to EVEN on the exact binary value
of a double, Dart's round() is half-away-from-zero, and toStringAsFixed rounds
half-up. round(16.5) is 16 in Python and 17 in Dart — and a 30-wide ribbon at
scale 0.55 hits that exact tie, so the layout notices.

This script emits every value the renderer actually formats (label sizes, lane
x positions, ribbon widths, colour-blind opacities) plus a set of deliberate
ties, as TSV:

  value  <fixed1>  <fixed0>  <round1>  <round3>  <round0>  <repr>

`dart/packages/alluvial_render/test/py_num_test.dart` reads it and fails on any
disagreement, so the port is checked against CPython's own output rather than
against hand-written expectations.

Usage:  python3 dart/tool/number_corpus.py [out-file]
        python3 dart/tool/number_corpus.py /tmp/ref/numbers.tsv
"""
from __future__ import annotations

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
for path in (os.path.join(ROOT, "scripts"), os.path.join(ROOT, "web")):
    if path not in sys.path:
        sys.path.insert(0, path)

import story_chart          # noqa: E402
import stories_yaml          # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else "/tmp/ref/numbers.tsv"

values: list[float] = []

for slug in stories_yaml.all_slugs():
    doc = stories_yaml.load(slug)
    if "scenes" in doc:
        continue
    char = {c["id"]: (c["name"], c["width"], c["colour"]) for c in doc["chars"]}
    spec = story_chart.spec_for(doc)

    # label sizes (the sqrt width scale) and the ribbon widths behind them
    values.extend(story_chart.width_fonts(char, base=24.0, lo=14.0, hi=26.0).values())
    values.extend(c["width"] * 0.55 for c in doc["chars"])
    values.extend(spec["ys"])

    # lane centres -> lane x, for every authored cluster and hand-tuned group
    scale, origin, spine = spec["scale"], spec["origin"], spec["spine_old"]
    for column in spec["cols"]:
        for centre, _ids in column["groups"]:
            values.append(centre)
            values.append(origin + (centre - spine) * scale)

    # legend geometry
    for cid in spec["order"]:
        label, width, _colour = spec["char"][cid]
        font = spec["legend_font"][cid]
        values.append(label.__len__() * font * 0.56)
        values.append(label.__len__() * font * 0.62)
        values.append(font * 0.78)
        values.append(max(9, round(font * 0.62)))

# the colour-blind ramp: rank fraction -> opacity
for count in range(1, 13):
    span = max(1, count - 1)
    values.extend(0.95 - 0.50 * (i / span) for i in range(count))

# deliberate ties and awkward decimals
values.extend([
    0.5, 1.5, 2.5, 3.5, 16.5, 17.5, 18.5, 20.5, 21.5, 26.5, 30.5, 105.5,
    0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.125, 0.375, 0.625, 0.875,
    2.675, 1.005, 8.835, 1.0 / 3.0, 2.0 / 3.0, 0.1, 0.2, 0.3, 0.7,
    469.99999999999994, 470.00000000000006, 109.95, 110.05, 838.775,
    0.0, 1.0, 24.0, 26.0, 14.0, 13.0, 15.5, 16.25, 2479.0, 0.5125, 0.5124999999,
])

seen: set[float] = set()
rows: list[float] = []
for value in values:
    value = float(value)
    if value in seen:
        continue
    seen.add(value)
    rows.append(value)

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as fh:
    for value in rows:
        fh.write("\t".join([
            repr(value),
            f"{value:.1f}",
            f"{value:.0f}",
            repr(round(value, 1)),
            repr(round(value, 3)),
            repr(round(value)),
            str(value),
        ]) + "\n")

print(f"{len(rows)} distinct values -> {OUT}")
print('sanity: round(16.5) =', round(16.5), '| f"{2.675:.2f}" =', f'{2.675:.2f}',
      '| round(469.99999999999994, 1) =', round(469.99999999999994, 1))
