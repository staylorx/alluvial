#!/usr/bin/env python3
"""Emit the staylorx.com assets for a film chart page.

Writes into an Eleventy repo:
  src/_includes/charts/<slug>.svg        the full chart (inline, internal beat links)
  src/_includes/charts/<slug>-mini.svg   the compact map for the sticky strip
  src/_data/films.json                   film + beat data the page template loops

Deterministic: no timestamps, no environment reads — a rebuild of the same
commit reproduces the same bytes, which is what CI checks.

Usage:  python3 build_eleventy.py /tmp/staylorx-charts
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "scripts"))

import build_page as BP
from alluvial_vlib import render_v


def hits(spec, H, half):
    """Overlay geometry as percentages, so the template can lay real HTML
    anchors over an SVG that scales to any column width."""
    out = []
    for i, c in enumerate(spec["cols"]):
        out.append({
            "n": i + 1,
            "href": f"#beat-{i+1:02d}",
            "name": c["beat"],
            "top": round((spec["ys"][i] - half) / H * 100, 3),
            "height": round((2 * half) / H * 100, 3),
        })
    return out


def build(repo):
    svg_full, spec, H = BP.chart_svg(False)
    svg_mini, mspec, Hm = BP.chart_svg(False, mini=True)
    rows = BP.lane_rows(spec)
    char, S = spec["char"], spec["scale"]

    beats = []
    for i, c in enumerate(spec["cols"]):
        if i == 0:
            changes = [f"{char[k][0]} enters" for k in spec["order"] if k in rows[0]]
        else:
            changes = BP.events_for(i, char, S, rows)
        tag = c.get("cap_extra", ("", ""))[0].replace("\u25b8 ", "")
        beats.append({
            "n": i + 1,
            "id": f"beat-{i+1:02d}",
            "name": c["beat"],
            "loc": c["loc"],
            "line": c["cap"][0],
            "changes": changes,
            "tag": tag,
            "prose": "",          # empty until there is real writing to put here
        })

    films = {
        "27-dresses": {
            "slug": "27-dresses",
            "title": "27 Dresses",
            "year": 2008,
            "url": "/movies/27-dresses/",
            "runtime": "111 minutes",
            "blurb": ("Eleven beats, six lanes. Who is with whom, and the moment it "
                      "changes. The notes under each beat are computed from the "
                      "diagram's own geometry, not written by hand."),
            "chart": f"src/_includes/charts/27-dresses.svg",
            "mini": f"src/_includes/charts/27-dresses-mini.svg",
            "hits": hits(spec, H, spec.get("beat_hit_half", 78)),
            "minihits": hits(mspec, Hm, mspec.get("beat_hit_half", 7.5)),
            "beats": beats,
        }
    }

    charts = os.path.join(repo, "src", "_includes", "charts")
    os.makedirs(charts, exist_ok=True)
    open(os.path.join(charts, "27-dresses.svg"), "w").write(svg_full)
    open(os.path.join(charts, "27-dresses-mini.svg"), "w").write(svg_mini)
    data = os.path.join(repo, "src", "_data")
    open(os.path.join(data, "films.json"), "w").write(json.dumps(films, indent=2) + "\n")

    print(f"chart  {len(svg_full)/1024:.1f} KB  ({H:.0f}px tall, {len(spec['cols'])} beats)")
    print(f"mini   {len(svg_mini)/1024:.1f} KB  ({Hm:.0f}px tall)")
    print(f"films.json {len(json.dumps(films))/1024:.1f} KB")
    print(f"wrote -> {charts}/27-dresses.svg, 27-dresses-mini.svg, {data}/films.json")


if __name__ == "__main__":
    build(sys.argv[1] if len(sys.argv) > 1 else "/tmp/staylorx-charts")
