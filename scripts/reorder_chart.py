#!/usr/bin/env python3
"""Two-time chart: the order you are told the story vs the order it happened.

The braid charts follow the director's clock. This one puts BOTH clocks on one
page: the left spine is the order the film screens its scenes, the right spine is
the order they actually happen to the people in it. A scene is one node on each
side, joined by a ribbon — so a ribbon that runs straight means the story is
telling itself in order, and a ribbon that crosses means the film cut time.

That crossing IS the chart. Pulp Fiction is the demo case.

Data per scene:
  id, label, chapter (where it sits in the film's chapter cards),
  as_screened (1..N order of appearance), happened (1..N real order),
  thread (which strand the scene belongs to — colour), chars (rough minutes)

Usage:  python3 reorder_chart.py <slug>
"""
from __future__ import annotations

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "out"))
DATA = os.path.abspath(os.path.join(HERE, "..", "films"))

BG = "#faf7f2"
INK = "#22201d"
MUT = "#7d7568"
RULE = "#ded7cb"

# thread colours, matched to the braid charts' palette
THREAD = {
    "jules": "#1b57c4",      # Jules & Vincent
    "butch": "#d0316a",      # Butch
    "mia": "#6e9078",        # Mia
    "diners": "#b09a4e",     # Pumpkin & Honey Bunny
    "wolf": "#8d7fa8",       # the Wolf / the cleanup
}


def load(slug: str) -> dict:
    with open(os.path.join(DATA, f"{slug}-timechart.json"), encoding="utf-8") as fh:
        return json.load(fh)


def render(doc: dict) -> tuple[str, dict]:
    scenes = doc["scenes"]
    n = len(scenes)
    left = sorted(scenes, key=lambda s: s["as_screened"])
    right = sorted(scenes, key=lambda s: s["happened"])

    W = 1010
    TOP = 250.0                 # room for the title block
    PITCH = 176.0
    NODE_H = 62.0
    LX, RX = 56.0, 584.0        # column x
    NW = 370.0                  # node width
    H = TOP + PITCH * n + 190.0

    y_screen = {s["id"]: TOP + i * PITCH for i, s in enumerate(left)}
    y_real = {s["id"]: TOP + i * PITCH for i, s in enumerate(right)}

    out = [
        f'<svg class="chart" preserveAspectRatio="xMidYMin meet" xmlns="http://www.w3.org/2000/svg" '
        f'width="{W:.0f}" height="{H:.0f}" viewBox="0 0 {W:.0f} {H:.0f}" '
        f'font-family="Helvetica, Arial, sans-serif">',
        f'<rect width="{W:.0f}" height="{H:.0f}" fill="{BG}"/>',
    ]
    A = out.append

    # ---- title block
    title_txt = f"{doc['title']} — two clocks"
    A(f'<text x="56" y="92" font-size="31" font-weight="700" fill="{INK}">{title_txt}</text>')
    A(f'<text x="56" y="126" font-size="15.5" fill="#4a453f">{doc["sub"]}</text>')
    for i, line in enumerate(doc.get("notes", [])):
        A(f'<text x="56" y="{158 + i*24}" font-size="14.5" fill="{MUT}">{line}</text>')

    # ---- column headings
    A(f'<text x="{LX}" y="{TOP - 42:.0f}" font-size="13" font-weight="700" '
      f'letter-spacing="1.2" fill="#9a9086">AS SCREENED</text>')
    A(f'<text x="{RX + NW}" y="{TOP - 42:.0f}" font-size="13" font-weight="700" '
      f'letter-spacing="1.2" fill="#9a9086" text-anchor="end">AS IT HAPPENED</text>')

    # ---- ribbons first, so nodes sit on top of them
    for s in scenes:
        y0 = y_screen[s["id"]] + NODE_H / 2
        y1 = y_real[s["id"]] + NODE_H / 2
        col = THREAD.get(s["thread"], "#888")
        x0, x1 = LX + NW, RX
        dx = (x1 - x0) * 0.45
        A(f'<path d="M {x0:.0f} {y0:.1f} C {x0+dx:.0f} {y0:.1f} {x1-dx:.0f} {y1:.1f} {x1:.0f} {y1:.1f}" '
          f'fill="none" stroke="{col}" stroke-width="{max(6, min(14, s.get("mins", 10) * 0.5)):.1f}" '
          f'stroke-opacity="0.55" stroke-linecap="round"/>')

    # ---- nodes on both spines
    for side, ymap, order in (("l", y_screen, left), ("r", y_real, right)):
        for s in order:
            y = ymap[s["id"]]
            col = THREAD.get(s["thread"], "#888")
            x = LX if side == "l" else RX
            A(f'<rect x="{x:.0f}" y="{y:.1f}" width="{NW:.0f}" height="{NODE_H:.0f}" rx="8" '
              f'fill="#ffffff" stroke="{col}" stroke-width="2"/>')
            A(f'<rect x="{x:.0f}" y="{y:.1f}" width="7" height="{NODE_H:.0f}" rx="3" fill="{col}"/>')
            A(f'<text x="{x+18:.0f}" y="{y+26:.1f}" font-size="17" font-weight="700" '
              f'fill="{INK}">{s["label"]}</text>')
            A(f'<text x="{x+18:.0f}" y="{y+48:.1f}" font-size="13.5" fill="{MUT}">{s["chapter"]}</text>')
            # the position numbers, so the crossing is countable
            num = s["as_screened"] if side == "l" else s["happened"]
            nx = x + NW - 16
            A(f'<text x="{nx:.0f}" y="{y+NODE_H/2+6:.1f}" font-size="16" font-weight="700" '
              f'fill="{col}" text-anchor="end">{num}</text>')

    # ---- legend
    ly = TOP + PITCH * n + 40
    A(f'<text x="56" y="{ly:.0f}" font-size="13" font-weight="700" letter-spacing="1.1" '
      f'fill="#9a9086">THREADS</text>')
    cx = 56.0
    for k, col in THREAD.items():
        if not any(s["thread"] == k for s in scenes):
            continue
        label = doc["threads"][k]
        A(f'<rect x="{cx:.0f}" y="{ly+14:.0f}" width="22" height="9" rx="2" fill="{col}" fill-opacity="0.85"/>')
        A(f'<text x="{cx+30:.0f}" y="{ly+23:.0f}" font-size="14" font-weight="600" fill="#2b2622">{label}</text>')
        cx += 30 + len(label) * 8.4 + 26
    A(f'<text x="56" y="{ly+58:.0f}" font-size="14" font-style="italic" fill="#8b8377">{doc["legend_note"]}</text>')

    A("</svg>")
    return "\n".join(out), {"H": H, "W": W, "scenes": n}


def main():
    slug = sys.argv[1] if len(sys.argv) > 1 else "pulp-fiction"
    doc = load(slug)
    svg, info = render(doc)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"{slug}-timechart.svg")
    open(path, "w", encoding="utf-8").write(svg)
    print(f"{slug}: {len(svg)/1024:.1f} KB  {info['scenes']} scenes  H={info['H']:.0f}  -> {path}")


if __name__ == "__main__":
    main()
