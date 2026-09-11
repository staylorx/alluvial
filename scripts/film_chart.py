#!/usr/bin/env python3
"""Generic film chart builder: a compact per-film table -> the chart spec.

`films/<slug>.json` carries only what a researcher can actually know about a
film: its people, its beats, who is standing with whom in each beat, and which
rubric category each beat earns. Layout (lane x, row spacing, type sizes) is
computed here, so adding a film is authoring a table, not drawing a chart.

A beat may instead give explicit `groups: [[y, [ids]], ...]` in the engine's lane
space (larger y = further LEFT) for a hand-tuned chart — 27 Dresses keeps its
tuned layout that way, so it renders byte-identical to the approved version.

Cluster order in the JSON is left-to-right as the reader sees the chart; this
module maps that onto the engine's mirrored lane space.
"""
from __future__ import annotations

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, "..", "web")):
    if p not in sys.path:
        sys.path.insert(0, p)

from alluvial_vlib import render_v, width_fonts     # noqa: E402
import rubric27                                     # noqa: E402
from build_page import lane_rows, events_for        # noqa: E402  (shared derived-events logic)

FILMS = os.path.abspath(os.path.join(HERE, "..", "films"))

# --- layout constants (shared with the tuned 27 Dresses chart) ---------------
Y_LEFT, Y_RIGHT = 110.0, 830.0    # lane space: larger y sits further RIGHT (mirror=False)
ROW_STEP = 165.0
ROW0 = 300.0
CODA_EXTRA = 70.0                 # extra air before a final row (time passes)
TAG = "#8a6a1f"

FONTS = dict(beat=20, loc=16, cap=16.5, hard=16.5, band=14, legend_title=13,
             title=31, sub=15.5, sub2=14.5)


def load(slug: str) -> dict:
    with open(os.path.join(FILMS, f"{slug}.json"), encoding="utf-8") as fh:
        return json.load(fh)


def groups_for(clusters: list[list[str]]) -> list[tuple[float, list[str]]]:
    """Even, weight-aware placement of each cluster across the lane band.

    Wider clusters (more people standing together) get proportionally more room;
    the first cluster lands at the left edge of the band.
    """
    if len(clusters) == 1:
        return [(round((Y_LEFT + Y_RIGHT) / 2, 1), list(clusters[0]))]
    weights = [0.55 + 0.45 * len(c) for c in clusters]
    total = sum(weights)
    out, acc = [], 0.0
    for i, cl in enumerate(clusters):
        y = Y_LEFT + (Y_RIGHT - Y_LEFT) * (acc / total)
        out.append((round(y, 1), list(cl)))
        acc += weights[i]
    return out


def spec_for(film: dict, cb: bool = False, mini: bool = False) -> dict:
    order = list(film["order"]) if film.get("order") else [c["id"] for c in film["chars"]]
    char = {c["id"]: (c["name"], c["width"], c["colour"]) for c in film["chars"]}
    known = set(char)

    cols = []
    for b in film["beats"]:
        d = dict(beat=b["name"], loc=b["loc"], cap=list(b["cap"]))
        if b.get("groups"):
            d["groups"] = [(float(y), list(ids)) for y, ids in b["groups"]]
        else:
            cl = [[i for i in ids if i in known] for ids in b["clusters"]]
            d["groups"] = groups_for([c for c in cl if c])
        if b.get("tag"):
            d["cap_extra"] = ("\u25b8 " + b["tag"], TAG)
        if b.get("enter"):
            d["enter"] = [i for i in b["enter"] if i in known]
        if b.get("stubs"):
            d["stubs"] = [(i, "out", None) for i in b["stubs"] if i in known]
        if b.get("hard"):
            d["hard"] = b["hard"]
        cols.append(d)

    ys, y = [], ROW0 - ROW_STEP
    for i in range(len(cols)):
        y += ROW_STEP + (CODA_EXTRA if i == len(cols) - 1 else 0.0)
        ys.append(y)

    lab = width_fonts(char, base=24.0, lo=14.0, hi=26.0)
    title = film["title"] + (" (%s)" % film["year"] if film.get("year") else "")
    if film.get("title_notes"):
        notes = [(t, "note") for t in film["title_notes"]]
    else:
        notes = [("Each beat is tagged with the rubric category it earns, so this doubles "
                  "as the film's scoring sheet.", "note")]
    if film.get("score") and not film.get("title_notes"):
        notes.append((f"Scored {film['score']}/30 on the rubric \u2014 {film.get('score_note', '')}".rstrip(" \u2014"),
                      "note"))
    if cb:
        notes.append(("Colour-blind mode: each strand carries its own symbol; the darker the "
                      "ribbon, the heavier the character. Hue is decoration only.", "note"))

    return dict(
        char=char, order=order, cols=cols, ys=ys, dashed=film.get("dashed", {}),
        cb_safe=cb, scale=0.55, origin=330.0, spine_old=500.0,
        mirror=film.get("mirror", False), W=1010, CAPX=570.0, LANE_HI=545.0,
        label_font=lab, legend_font=lab, tiers=4, line_cap=23, extra_gap=22,
        fonts=dict(FONTS), bands=[],
        legend_title=("LANES \u2014 label size follows strand width"
                      + (", symbol = identity, darkness = weight" if cb else "")),
        legend_note=film.get("legend_note") or
                    ("Hatched lane = off-page."
                     + (f" \u201c{film['legend_object']}\u201d is a thing, not a person."
                        if film.get("legend_object") else "")),
        title=film.get("title_block") or
              ([(f"{title} \u2014 the braid", "title"),
                (f"{len(cols)} beats, {len(order)} lanes"
                 + (f", {film['runtime_min']} minutes" if film.get("runtime_min") else "")
                 + ". Time runs down the page.", "sub"),
                ("Row spacing widens before the coda \u2014 time passes there.", "note")]
               + notes),
    )


def render(film: dict, cb: bool = False, mini: bool = False, href=lambda i, c: f"#beat-{i+1:02d}"):
    """-> (svg, spec, H). Mirrors the page builder's embed settings."""
    spec = spec_for(film, cb)
    spec["beat_links"] = href
    spec["rowmark_prefix"] = "mini" if mini else ("cbchart" if cb else "chart")
    spec["pattern_prefix"] = ("-alt" if cb else "") + ("-mini" if mini else "")
    if mini:
        step = spec.get("mini_step", 15.0)
        spec["ys"] = [spec.get("mini_pad", 26) + i * step for i in range(len(spec["ys"]))]
        spec["mini"] = True
        spec["W"] = 560
        spec["beat_hit_half"] = step / 2
    svg, checks = render_v(spec)
    svg = svg.replace("<svg ", '<svg class="chart" preserveAspectRatio="xMidYMin meet" ', 1)
    return svg, spec, checks["H"]


def beats_data(film: dict, spec: dict, H: float, half: float) -> list[dict]:
    """The page's beat sections: derived changes + the rubric text it earns."""
    rows = lane_rows(spec)
    char, S = spec["char"], spec["scale"]
    out = []
    for i, c in enumerate(spec["cols"]):
        if i == 0:
            changes = [f"{char[k][0]} enters" for k in spec["order"] if k in rows[0]]
        else:
            changes = events_for(i, char, S, rows)
        cats = film["beats"][i].get("cats")
        rub = ([rubric27.BY_ID[c] for c in cats if c in rubric27.BY_ID]
               if cats is not None else rubric27.for_beat(i + 1))
        out.append({
            "n": i + 1,
            "id": f"beat-{i+1:02d}",
            "name": c["beat"],
            "loc": c["loc"],
            "line": c["cap"][0],
            "changes": changes,
            "tag": c.get("cap_extra", ("", ""))[0].replace("\u25b8 ", ""),
            "rubric": [dict(rc) for rc in rub],
        })
    return out


def hits(spec: dict, H: float, half: float) -> list[dict]:
    return [{"n": i + 1, "href": f"#beat-{i+1:02d}", "name": c["beat"],
             "top": round((spec["ys"][i] - half) / H * 100, 3),
             "height": round((2 * half) / H * 100, 3)}
            for i, c in enumerate(spec["cols"])]


if __name__ == "__main__":
    slug = sys.argv[1]
    film = load(slug)
    svg, spec, H = render(film)
    beats = beats_data(film, spec, H, 78)
    print(f"{film['title']}: {len(svg)/1024:.1f} KB, H={H:.0f}, "
          f"{len(spec['cols'])} beats, {len(spec['order'])} lanes, "
          f"{sum(1 for b in beats if b['rubric'])} beats carry a rubric category")
