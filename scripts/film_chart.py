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

# The form the work is told in (store field `expression`); absent means a film,
# the medium this store started in. The title block follows it: a film is
# anchored to minutes, everything else to the work's own divisions.
FORMS = {"play": "A play", "novel": "A novel", "series": "A series",
         "short story": "A short story", "essay": "An essay", "poem": "A poem",
         "song": "A song", "musical": "A musical"}
ANCHORS = {"play": "acts and scenes", "novel": "its parts", "series": "its episodes",
           "short story": "the story's own turns", "essay": "its own sections",
           "poem": "its own divisions", "song": "its own divisions",
           "musical": "its acts"}


def load(slug: str) -> dict:
    """Films come from the data store: films/<slug>.yaml (JSON still works)."""
    import films_yaml
    return films_yaml.load(slug)


def _flat_ids(v) -> list[str]:
    """Accept ['a','b'] or [['a'],['b']] — hand-authored tables produce both."""
    if not v:
        return []
    out = []
    for x in (v if isinstance(v, list) else [v]):
        if isinstance(x, list):
            out.extend(y for y in x if isinstance(y, str))
        elif isinstance(x, str):
            out.append(x)
    return out


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


CAP_CHARS = 47          # the caption column fits ~47 chars at 16.5px


def wrap(text: str, width: int = CAP_CHARS) -> list[str]:
    """Word-wrap a chart caption. Short lines pass through untouched, which is
    what keeps already-published charts byte-identical."""
    words, lines, cur = str(text).split(), [], ""
    for w in words:
        cand = f"{cur} {w}".strip()
        if cur and len(cand) > width:
            lines.append(cur)
            cur = w
        else:
            cur = cand
    if cur:
        lines.append(cur)
    return lines or [""]


def spec_for(film: dict, cb: bool = False, mini: bool = False) -> dict:
    order = list(film["order"]) if film.get("order") else [c["id"] for c in film["chars"]]
    char = {c["id"]: (c["name"], c["width"], c["colour"]) for c in film["chars"]}
    known = set(char)

    cols = []
    for b in film["beats"]:
        cap: list[str] = []
        for ln in b["cap"]:
            cap.extend(wrap(ln))
        d = dict(beat=b["name"], loc=b["loc"], cap=cap)
        if b.get("groups"):
            d["groups"] = [(float(y), list(ids)) for y, ids in b["groups"]]
        else:
            cl = [[i for i in ids if i in known] for ids in b["clusters"]]
            d["groups"] = groups_for([c for c in cl if c])
        if b.get("tag"):
            tag = wrap("\u25b8 " + b["tag"])
            d["cap_extra"] = (tag if len(tag) > 1 else tag[0], TAG)
        # enter/stubs arrive from hand-authored tables: flatten any nesting, drop
        # unknown ids, and drop ids that are not actually on-page in this beat
        # (the renderer hatches from this beat's lane, so an absent id is a KeyError).
        present = {i for _y, ids in d["groups"] for i in ids}
        ent = _flat_ids(b.get("enter"))
        d["enter"] = [i for i in ent if i in known]
        st = _flat_ids(b.get("stubs"))
        d["stubs"] = [(i, "out", None) for i in st if i in known and i in present]
        if len(d["stubs"]) != len(st):
            print(f"    ! {film['slug']}: dropped {len(st) - len(d['stubs'])} stub(s) "
                  f"not on-page in this beat")
        if b.get("hard"):
            d["hard"] = b["hard"]
        cols.append(d)

    ys, y = [], ROW0 - ROW_STEP
    for i in range(len(cols)):
        y += ROW_STEP + (CODA_EXTRA if i == len(cols) - 1 else 0.0)
        ys.append(y)

    lab = width_fonts(char, base=24.0, lo=14.0, hi=26.0)
    title = film["title"] + (" (%s)" % film["year"] if film.get("year") else "")
    expr = film.get("expression") or "film"
    if film.get("title_notes"):
        notes = [(t, "note") for t in film["title_notes"]]
    elif expr != "film":
        notes = [("No beat carries a rubric category: the rubric is the romcom "
                  "rubric, and this is not a romcom.", "note")]
    else:
        notes = [("Each beat names the rubric category its shape belongs to.", "note")]
    if film.get("score") and not film.get("title_notes"):
        notes.append((f"Scored {film['score']}/30 on the rubric \u2014 {film.get('score_note', '')}".rstrip(" \u2014"),
                      "note"))
    if cb:
        notes.append(("Colour-blind mode: each strand carries its own symbol; the darker the "
                      "ribbon, the heavier the character. Hue is decoration only.", "note"))

    counted = f"{len(cols)} beats, {len(order)} lanes"
    if expr == "film":
        sub_line = (counted
                    + (f", {film['runtime_min']} minutes" if film.get("runtime_min") else "")
                    + ". Time runs down the page.")
    else:
        sub_line = (f"{counted}. {FORMS.get(expr, 'A ' + expr)} \u2014 the anchors are "
                    f"{ANCHORS.get(expr, 'its own divisions')}, not minutes.")

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
                (sub_line, "sub"),
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
    return svg, spec, checks["H"], checks


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
            "tag": (lambda t: (t if isinstance(t, str) else " ".join(t))
                .replace("\u25b8 ", ""))(c.get("cap_extra", ("", ""))[0]),
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
    svg, spec, H, _chk = render(film)
    beats = beats_data(film, spec, H, 78)
    print(f"{film['title']}: {len(svg)/1024:.1f} KB, H={H:.0f}, "
          f"{len(spec['cols'])} beats, {len(spec['order'])} lanes, "
          f"{sum(1 for b in beats if b['rubric'])} beats carry a rubric category")
