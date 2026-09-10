#!/usr/bin/env python3
"""Character alluvial diagram - Fellowship of the Ring.

A time-indexed Sankey: character 'strands' (ribbon width ~ screen presence)
converge into a single bus at Rivendell and sunder at Amon Hen.
Output: standalone SVG (rendered to PNG via headless Chromium).
"""
import math, sys

W, H = 2780, 1420
COL_X = [240, 505, 770, 1035, 1300, 1565, 1830, 2095, 2360]
GAP = 5          # gap between lanes inside a bus
STUB = 95        # length of entrance / exit tapers

# --- character registry -------------------------------------------------
CHAR = {
    #  id        label            width  colour
    "frodo":   ("Frodo",             30, "#1f5fd0"),
    "sam":     ("Sam",               22, "#c2740a"),
    "merry":   ("Merry",             16, "#1e8a44"),
    "pippin":  ("Pippin",            16, "#6f9a10"),
    "gandalf": ("Gandalf",           26, "#7040c8"),
    "aragorn": ("Aragorn",           24, "#0d7266"),
    "boromir": ("Boromir",           18, "#c62b2b"),
    "legolas": ("Legolas",           12, "#0b87ab"),
    "gimli":   ("Gimli",             12, "#a2560c"),
    "gollum":  ("Gollum",            14, "#6b7280"),
    "bilbo":   ("Bilbo",             12, "#cf3a86"),
}
ORDER = ["frodo", "sam", "merry", "pippin", "gandalf",
         "aragorn", "boromir", "legolas", "gimli", "gollum", "bilbo"]
DASHED_FROM = {"gandalf": 4, "gollum": 5}   # col index where strand goes dashed

# --- beats --------------------------------------------------------------
# groups: (centre_y, [char ids top->bottom])
BEATS = [
    dict(beat="THE SHIRE", pct="0–8%",
         cap=["Bag End and the Long-expected Party",
              "Frodo inherits; Gandalf rides off to investigate"],
         groups=[(340, ["gandalf", "frodo"]), (560, ["sam"]), (180, ["bilbo"])],
         stubs=[("bilbo", "out", 180)]),

    dict(beat="THE ROAD TO BREE", pct="8–25%",
         cap=["Bucklebury, the Old Forest, Bree",
              "Merry and Pippin join; Strider is revealed"],
         groups=[(520, ["frodo", "sam", "merry", "pippin"]),
                 (150, ["gandalf"]), (860, ["aragorn"])],
         stubs=[("merry", "in", None), ("pippin", "in", None),
                ("aragorn", "in", None)]),

    dict(beat="WEATHERTOP → THE FORD", pct="25–33%",
         cap=["Frodo is wounded; the Black Riders close in",
              "Aragorn carries the company to Rivendell"],
         groups=[(560, ["frodo", "sam", "merry", "pippin", "aragorn"]),
                 (150, ["gandalf"])]),

    dict(beat="RIVENDELL — THE COUNCIL", pct="33–45%",
         cap=["The nine walkers are chosen",
              "★ every strand merges"],
         groups=[(640, ["frodo", "sam", "merry", "pippin", "gandalf",
                        "aragorn", "boromir", "legolas", "gimli"]),
                 (1020, ["bilbo"])],
         stubs=[("boromir", "in", None), ("bilbo", "in", 1020),
                ("bilbo", "out", 1020)]),

    dict(beat="MORIA", pct="45–58%",
         cap=["Khazad-dûm and the Bridge",
              "Gandalf falls — strand detaches"],
         groups=[(640, ["frodo", "sam", "merry", "pippin",
                        "aragorn", "boromir", "legolas", "gimli"]),
                 (140, ["gandalf"])]),

    dict(beat="LOTHLÓRIEN", pct="58–70%",
         cap=["Galadriel's mirror; the company mourns",
              "Gollum begins to follow"],
         groups=[(640, ["frodo", "sam", "merry", "pippin",
                        "aragorn", "boromir", "legolas", "gimli"]),
                 (120, ["gandalf"]), (1030, ["gollum"])],
         stubs=[("gollum", "in", 1030)]),

    dict(beat="THE GREAT RIVER", pct="70–84%",
         cap=["The Anduin, and Boromir's betrayal",
              "eight still travel as one"],
         groups=[(640, ["frodo", "sam", "merry", "pippin",
                        "aragorn", "boromir", "legolas", "gimli"]),
                 (120, ["gandalf"]), (1030, ["gollum"])]),

    dict(beat="AMON HEN — THE BREAKING", pct="84–96%",
         cap=["The Fellowship sunders",
              "one bus → three stories"],
         groups=[(300, ["frodo", "sam"]), (620, ["merry", "pippin"]),
                 (900, ["aragorn", "legolas", "gimli"]),
                 (1010, ["gollum"]), (110, ["gandalf"])],
         terminal=("boromir", 745)),

    dict(beat="INTO THE TWO TOWERS", pct="96–100%",
         cap=["Three separate stories begin",
              "the strands never fully rejoin"],
         groups=[(320, ["frodo", "sam"]), (400, ["gollum"]),
                 (650, ["merry", "pippin"]),
                 (940, ["aragorn", "legolas", "gimli"]),
                 (110, ["gandalf"])]),
]

END_LABELS = [
    (320, "Frodo & Sam → Mordor", "#1f5fd0", "solid"),
    (400, "Gollum follows, unseen", "#6b7280", "dashed"),
    (650, "Merry & Pippin → Isengard, then Rohan", "#1e8a44", "solid"),
    (940, "Aragorn, Legolas & Gimli → the hunt", "#0d7266", "solid"),
    (110, "Gandalf → reborn on Zirakzigil (off-page)", "#7040c8", "dashed", 195),
]


def stack(centre, ids):
    total = sum(CHAR[c][1] for c in ids) + GAP * (len(ids) - 1)
    y = centre - total / 2
    out = {}
    for c in ids:
        h = CHAR[c][1]
        out[c] = y + h / 2
        y += h + GAP
    return out


# y[col][char]
Y = []
for b in BEATS:
    col = {}
    for centre, ids in b["groups"]:
        col.update(stack(centre, ids))
    Y.append(col)


def ribbon(x0, x1, y0, y1, w0, w1=None):
    """Bezier flow band from (x0,y0) to (x1,y1); w0/w1 are ribbon thicknesses."""
    w1 = w0 if w1 is None else w1
    a, b_ = w0 / 2, w1 / 2
    xm0, xm1 = x0 + (x1 - x0) * 0.42, x0 + (x1 - x0) * 0.58
    return (f"M {x0:.1f} {y0-a:.1f} "
            f"C {xm0:.1f} {y0-a:.1f} {xm1:.1f} {y1-b_:.1f} {x1:.1f} {y1-b_:.1f} "
            f"L {x1:.1f} {y1+b_:.1f} "
            f"C {xm1:.1f} {y1+b_:.1f} {xm0:.1f} {y0+a:.1f} {x0:.1f} {y0+a:.1f} Z")


svg = []
A = svg.append
A(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
  f'viewBox="0 0 {W} {H}" font-family="Helvetica, Arial, sans-serif">')
A('<defs>')
A('<pattern id="dots" width="26" height="26" patternUnits="userSpaceOnUse">'
  '<circle cx="1" cy="1" r="0.9" fill="#d8d2c8"/></pattern>')
A('</defs>')
A(f'<rect width="{W}" height="{H}" fill="#faf7f2"/>')
A(f'<rect x="0" y="130" width="{W}" height="1000" fill="url(#dots)" opacity="0.55"/>')

# --- beat grid + top labels --------------------------------------------
for i, b in enumerate(BEATS):
    x = COL_X[i]
    A(f'<line x1="{x}" y1="140" x2="{x}" y2="1130" stroke="#c9c2b6" '
      f'stroke-width="1" stroke-dasharray="2 5"/>')
    A(f'<text x="{x}" y="58" font-size="14" font-weight="700" fill="#2b2622" '
      f'letter-spacing="1.6">{b["beat"]}</text>')
    A(f'<text x="{x}" y="76" font-size="11.5" fill="#9a9086" '
      f'letter-spacing="0.6">{b["pct"]}</text>')
    for j, line in enumerate(b["cap"]):
        w_ = "700" if line.startswith("★") else "400"
        fill = "#8a6a1f" if line.startswith("★") else "#7d7568"
        sty = "normal" if line.startswith("★") else "italic"
        A(f'<text x="{x}" y="{100 + j*17}" font-size="11.5" font-weight="{w_}" '
          f'font-style="{sty}" fill="{fill}">{line}</text>')

# --- entrance / exit tapers -------------------------------------------
for i, b in enumerate(BEATS):
    for (cid, kind, y_override) in b.get("stubs", []):
        col = Y[i]
        y = y_override if y_override is not None else col[cid]
        w = CHAR[cid][1]
        col_id = CHAR[cid][2]
        dash = (cid in DASHED_FROM and i >= DASHED_FROM[cid])
        if kind == "in":
            A(f'<path d="{ribbon(COL_X[i]-STUB, COL_X[i], y, y, 3, w)}" '
              f'fill="{col_id}" fill-opacity="0.8"/>')
        else:
            A(f'<path d="{ribbon(COL_X[i], COL_X[i]+STUB, y, y, w, 3)}" '
              f'fill="{col_id}" fill-opacity="0.8"/>')

# --- terminals (Boromir) ----------------------------------------------
for i, b in enumerate(BEATS):
    if "terminal" not in b:
        continue
    cid, end_y = b["terminal"]
    prev = Y[i - 1][cid]
    x0, x1 = COL_X[i - 1], COL_X[i - 1] + (COL_X[i] - COL_X[i - 1]) * 0.62
    col_id = CHAR[cid][2]
    A(f'<path d="{ribbon(x0, x1, prev, end_y, CHAR[cid][1], 2)}" '
      f'fill="{col_id}" fill-opacity="0.55"/>')
    A(f'<circle cx="{x1+7:.1f}" cy="{end_y:.1f}" r="5" fill="{col_id}"/>')
    A(f'<text x="{x1+20:.1f}" y="{end_y-9:.1f}" font-size="12.5" '
      f'font-weight="700" fill="{col_id}">Boromir falls at Amon Hen</text>')
    A(f'<text x="{x1+20:.1f}" y="{end_y+7:.1f}" font-size="11" '
      f'font-style="italic" fill="#8b8377">the strand ends here</text>')

# --- main ribbons ------------------------------------------------------
for cid in ORDER:
    w = CHAR[cid][1]
    colour = CHAR[cid][2]
    for i in range(len(BEATS) - 1):
        if cid not in Y[i] or cid not in Y[i + 1]:
            continue
        y0, y1 = Y[i][cid], Y[i + 1][cid]
        dash = cid in DASHED_FROM and i + 1 >= DASHED_FROM[cid]
        d = ribbon(COL_X[i], COL_X[i + 1], y0, y1, w)
        if dash:
            A(f'<path d="{d}" fill="{colour}" fill-opacity="0.17"/>')
            A(f'<path d="{d}" fill="none" stroke="{colour}" stroke-width="1.6" '
              f'stroke-dasharray="7 5" opacity="0.95"/>')
        else:
            A(f'<path d="{d}" fill="{colour}" fill-opacity="0.82"/>')

# --- start labels ------------------------------------------------------
for cid in ORDER:
    if cid not in Y[0]:
        continue
    y = Y[0][cid]
    A(f'<text x="{COL_X[0]-22}" y="{y+4:.1f}" font-size="14" font-weight="700" '
      f'text-anchor="end" fill="{CHAR[cid][2]}">{CHAR[cid][0]}</text>')

# --- end labels + strand names at the split ----------------------------
for entry in END_LABELS:
    y, text, colour, style = entry[0], entry[1], entry[2], entry[3]
    ty = entry[4] if len(entry) > 4 else y
    if ty != y:   # leader line when the end label sits clear of the strand tip
        A(f'<path d="M {COL_X[-1]+12} {y} C {COL_X[-1]+30} {y+40} '
          f'{COL_X[-1]+28} {ty-45} {COL_X[-1]+34} {ty-24}" fill="none" '
          f'stroke="{colour}" stroke-width="1.2" stroke-dasharray="4 3" opacity="0.75"/>')
    A(f'<text x="{COL_X[-1]+26}" y="{ty+4:.1f}" font-size="12.5" font-weight="700" '
      f'fill="{colour}">{text}</text>')

# --- annotation for the nine-walker bus --------------------------------
bus_top = 640 - (sum(CHAR[c][1] for c in
                     ["frodo","sam","merry","pippin","gandalf","aragorn",
                      "boromir","legolas","gimli"]) + GAP*8) / 2
A(f'<text x="{COL_X[3]+14}" y="{bus_top-14:.1f}" font-size="15" font-weight="700" '
  f'fill="#2b2622">THE FELLOWSHIP OF THE RING — nine walkers, one bus</text>')
A(f'<text x="{COL_X[4]+14}" y="300" font-size="15" font-weight="700" '
  f'fill="#7040c8">Gandalf falls — the strand leaves the company</text>')
A(f'<text x="{COL_X[5]-90}" y="1078" font-size="13" font-style="italic" '
  f'fill="#6b7280">Gollum, off to the side, begins to follow</text>')

# --- legend ------------------------------------------------------------
lx, ly = 60, 1195
A(f'<text x="{lx}" y="{ly-18}" font-size="11" font-weight="700" '
  f'letter-spacing="1.4" fill="#9a9086">STRANDS (ribbon thickness ≈ screen presence)</text>')
cx = lx
for cid in ORDER:
    label, w, colour = CHAR[cid]
    dash = cid in DASHED_FROM
    A(f'<rect x="{cx}" y="{ly}" width="{max(14, w//2)}" height="14" rx="3" '
      f'fill="{colour}" fill-opacity="{"0.25" if dash else "0.85"}" '
      f'{"stroke=" + chr(34) + colour + chr(34) + " stroke-dasharray=" + chr(34) + "4 3" + chr(34) if dash else ""}/>')
    A(f'<text x="{cx + max(14, w//2) + 7}" y="{ly+12}" font-size="13" '
      f'font-weight="600" fill="#2b2622">{label}</text>')
    cx += max(14, w // 2) + 7 + len(label) * 7.4 + 30
A(f'<text x="{W-60}" y="{ly+12}" font-size="12" fill="#8b8377" '
  f'text-anchor="end">dashed = off-page / following unseen</text>')

# --- title block -------------------------------------------------------
A(f'<line x1="60" y1="1265" x2="{W-60}" y2="1265" stroke="#ded7cb"/>')
A(f'<text x="60" y="1315" font-family="Georgia, serif" font-size="34" '
  f'fill="#22201d">The Fellowship of the Ring — a character alluvial</text>')
A(f'<text x="60" y="1348" font-size="14" fill="#6f675c">'
  f'Eleven strands across nine beats. Convergence is a scene; divergence is a story. '
  f'Ribbon width approximates screen presence — not a measure of importance.</text>')
A(f'<text x="60" y="1373" font-size="12.5" font-style="italic" fill="#9a9086">'
  f'An alluvial diagram: a Sankey whose horizontal axis is time. '
  f'Built by hermes-agent — pure hand-authored SVG.</text>')
A('</svg>')

out = "/home/installer/hermes/projects/alluvial/out/fellowship-alluvial.svg"
with open(out, "w") as f:
    f.write("\n".join(svg))

txt = "\n".join(svg)
checks = {
    "bytes": len(txt),
    "ribbon_paths": txt.count('fill-opacity="0.82"'),
    "dashed_ribbons": txt.count('stroke-dasharray="7 5"'),
    "nan": ("nan" in txt.lower().replace("font-family", "")),
}
print(out, checks)
