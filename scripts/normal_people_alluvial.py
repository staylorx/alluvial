#!/usr/bin/env python3
"""Character alluvial - Sally Rooney's Normal People (BBC/Hulu, 12 parts).

The braid: two thick ribbons that merge and separate while partner-strands
attach and detach. Vertical layout is semantic:
   above  = the social world (school / Trinity / partners)
   spine  = Connell & Marianne
   below  = family and the private / harmful
Output: standalone SVG (PNG via headless Chromium).
"""
import os

W, H = 3320, 1420
X0, STEP = 235, 218
NCOL = 13
COL_X = [X0 + i * STEP for i in range(NCOL)]
GAP, STUB, SPINE = 5, 95, 620

# id: (label, width, colour)
CHAR = {
    "connell":  ("Connell",  34, "#1b57c4"),
    "marianne": ("Marianne", 34, "#d0316a"),
    "rob":      ("Rob",      14, "#6f8f96"),
    "rachel":   ("Rachel",   12, "#8d7fa8"),
    "peggy":    ("Peggy",    12, "#b09a4e"),
    "gareth":   ("Gareth",   12, "#8a9299"),
    "jamie":    ("Jamie",    16, "#9c6552"),
    "helen":    ("Helen",    14, "#6e9078"),
    "lukas":    ("Lukas",    12, "#9aa0a6"),
    "lorraine": ("Lorraine", 14, "#7d8f52"),
    "alan":     ("Alan",     16, "#7f4a4a"),
    "denise":   ("Denise",   10, "#b0a89e"),
    "gillian":  ("Gillian",  10, "#6d78a8"),
}
ORDER = ["connell", "marianne", "rob", "rachel", "peggy", "gareth",
         "jamie", "helen", "lukas", "lorraine", "alan", "denise", "gillian"]

# interval start-column index -> strand drawn dashed there (present but off-page)
DASHED = {"rob": {3, 4, 5}}

COLS = [
 dict(beat="EPISODE 1", loc="Carricklea, Co. Sligo",
      cap=["Final year of school,", "and the secret starts"],
      groups=[(250, ["rob"]), (310, ["rachel"]),
              (SPINE, ["connell", "marianne"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])]),

 dict(beat="EPISODE 2", loc="Carricklea",
      cap=["The affair deepens;", "he won't say it aloud"],
      groups=[(250, ["rob"]), (310, ["rachel"]),
              (SPINE, ["connell", "marianne"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])]),

 dict(beat="EPISODE 3", loc="The Debs",
      cap=["He takes Rachel", "to the Debs, not her"],
      hard="\u25b8 assaulted at the fundraiser",
      groups=[(250, ["rob"]), (SPINE, ["connell", "rachel"]),
              (725, ["marianne"]), (850, ["lorraine"]),
              (940, ["alan"]), (1050, ["denise"])],
      stubs=[("rachel", "out", None)]),

 dict(beat="EPISODE 4", loc="Dublin",
      cap=["Trinity, months later:", "she has friends, he has rent"],
      groups=[(250, ["rob"]), (350, ["peggy"]),
              (410, ["marianne", "gareth"]), (SPINE, ["connell"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])],
      stubs=[("peggy", "in", None), ("gareth", "in", None)]),

 dict(beat="EPISODE 5", loc="Dublin",
      cap=["Friends again \u2014 Gareth out,", "Jamie circling"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (410, ["gareth"]),
              (460, ["jamie"]), (660, ["marianne"]), (SPINE, ["connell"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])],
      stubs=[("jamie", "in", None), ("gareth", "out", None)]),

 dict(beat="EPISODE 6", loc="Dublin \u2192 Sligo",
      cap=["The best of it \u2014 then", "Sligo, then money"],
      hard="\u25b8 her brother, at home",
      groups=[(250, ["rob"]), (350, ["peggy"]), (460, ["jamie"]),
              (SPINE, ["connell", "marianne"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])]),

 dict(beat="EPISODE 7", loc="Sligo / Dublin",
      cap=["Summer apart: Jamie for", "her, Helen for him"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (460, ["marianne", "jamie"]),
              (SPINE, ["connell", "helen"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
      stubs=[("helen", "in", None)]),

 dict(beat="EPISODE 8", loc="Italy",
      cap=["Jamie's grip tightens;", "she chooses Connell anyway"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (460, ["marianne", "jamie"]),
              (512, ["helen"]), (580, ["connell"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
      stubs=[("jamie", "out", None)]),

 dict(beat="EPISODE 9", loc="Lule\u00e5, Sweden / Dublin",
      cap=["Sweden \u2014 Lukas;", "Connell calls too often"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (500, ["marianne", "lukas"]),
              (SPINE, ["connell", "helen"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
      stubs=[("lukas", "in", None), ("lukas", "out", None)]),

 dict(beat="EPISODE 10", loc="Sligo & Dublin",
      cap=["Rob dies; Connell", "starts therapy"],
      hard="\u25b8 31 December, alone",
      groups=[(350, ["peggy"]), (500, ["marianne"]), (545, ["helen"]),
              (SPINE, ["connell"]), (690, ["gillian"]), (760, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
      stubs=[("gillian", "in", None), ("helen", "out", 545)],
      terminal=("rob", 250)),

 dict(beat="EPISODE 11", loc="Sligo",
      cap=["Home again \u2014 she asks", "him to hurt her"],
      hard="\u25b8 then Alan breaks her nose",
      groups=[(350, ["peggy"]), (SPINE, ["connell", "marianne"]),
              (690, ["gillian"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
      stubs=[("alan", "out", None)]),

 dict(beat="EPISODE 12", loc="Sligo & Dublin",
      cap=["Christmas with the Waldrons;", "New York is offered"],
      groups=[(350, ["peggy"]), (SPINE, ["connell", "marianne"]),
              (690, ["gillian"]), (810, ["lorraine"]), (1030, ["denise"])],
      stubs=[("gillian", "out", None), ("denise", "break", None)]),

 dict(beat="CODA", loc="Dublin \u2192 New York",
      cap=["He goes. She stays.", "The braid never resolves"],
      groups=[(350, ["peggy"]), (480, ["connell"]),
              (730, ["marianne"]), (860, ["lorraine"])],
      stubs=[("connell", "fade", None), ("marianne", "fade", None)]),
]

END_LABELS = [
    (350, "Peggy, Joanna & the Trinity circle", "#b09a4e"),
    (480, "Connell \u2192 a year in New York", "#1b57c4"),
    (730, "Marianne stays \u2014 \u201cI\u2019ll always be here\u201d", "#d0316a"),
    (860, "Lorraine", "#7d8f52"),
]
BANDS = [(207, "THE SOCIAL WORLD"), (1120, "FAMILY / THE PRIVATE")]


def stack(centre, ids):
    total = sum(CHAR[c][1] for c in ids) + GAP * (len(ids) - 1)
    y = centre - total / 2
    out = {}
    for c in ids:
        h = CHAR[c][1]
        out[c] = y + h / 2
        y += h + GAP
    return out


Y = []
for c in COLS:
    col = {}
    for centre, ids in c["groups"]:
        col.update(stack(centre, ids))
    Y.append(col)


def ribbon(x0, x1, y0, y1, w0, w1=None):
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
A('<defs><pattern id="dots" width="26" height="26" patternUnits="userSpaceOnUse">'
  '<circle cx="1" cy="1" r="0.9" fill="#d8d2c8"/></pattern></defs>')
A(f'<rect width="{W}" height="{H}" fill="#faf7f2"/>')
A(f'<rect x="0" y="130" width="{W}" height="1020" fill="url(#dots)" opacity="0.55"/>')

for y, text in BANDS:
    A(f'<text x="46" y="{y}" font-size="11" font-weight="700" letter-spacing="2.4" '
      f'fill="#b3aa9d">{text}</text>')

for i, c in enumerate(COLS):
    x = COL_X[i]
    A(f'<line x1="{x}" y1="140" x2="{x}" y2="1150" stroke="#c9c2b6" '
      f'stroke-width="1" stroke-dasharray="2 5"/>')
    A(f'<text x="{x}" y="58" font-size="13.5" font-weight="700" fill="#2b2622" '
      f'letter-spacing="1.5">{c["beat"]}</text>')
    A(f'<text x="{x}" y="76" font-size="11" fill="#9a9086" letter-spacing="0.3">{c["loc"]}</text>')
    for j, line in enumerate(c["cap"]):
        A(f'<text x="{x}" y="{100 + j*16}" font-size="10.8" font-style="italic" '
          f'fill="#7d7568">{line}</text>')
    if c.get("hard"):
        A(f'<text x="{x}" y="{136}" font-size="10.8" font-weight="700" '
          f'fill="#9c3b34">{c["hard"]}</text>')

for i, c in enumerate(COLS):
    for (cid, kind, y_over) in c.get("stubs", []):
        y = y_over if y_over is not None else Y[i][cid]
        w, colour = CHAR[cid][1], CHAR[cid][2]
        if kind == "in":
            A(f'<path d="{ribbon(COL_X[i]-STUB, COL_X[i], y, y, 3, w)}" '
              f'fill="{colour}" fill-opacity="0.8"/>')
        elif kind == "out":
            A(f'<path d="{ribbon(COL_X[i], COL_X[i]+STUB, y, y, w, 3)}" '
              f'fill="{colour}" fill-opacity="0.8"/>')
        elif kind == "break":
            A(f'<path d="{ribbon(COL_X[i], COL_X[i]+50, y, y, w, 3)}" '
              f'fill="{colour}" fill-opacity="0.85"/>')
            bx = COL_X[i] + 70
            A(f'<line x1="{bx}" y1="{y-9}" x2="{bx+16}" y2="{y+9}" stroke="#9c3b34" '
              f'stroke-width="1.8"/>')
            A(f'<line x1="{bx}" y1="{y+9}" x2="{bx+16}" y2="{y-9}" stroke="#9c3b34" '
              f'stroke-width="1.8"/>')
            A(f'<text x="{bx}" y="{y+34}" font-size="11.5" font-weight="700" '
              f'fill="#9c3b34">her mother stops speaking</text>')
        elif kind == "fade":
            A(f'<path d="{ribbon(COL_X[i], COL_X[i]+130, y, y+14, w, 2)}" '
              f'fill="{colour}" fill-opacity="0.34"/>')

for i, c in enumerate(COLS):
    if "terminal" not in c:
        continue
    cid, end_y = c["terminal"]
    prev, colour = Y[i-1][cid], CHAR[cid][2]
    x0 = COL_X[i-1]
    x1 = COL_X[i-1] + (COL_X[i] - COL_X[i-1]) * 0.60
    A(f'<path d="{ribbon(x0, x1, prev, end_y, CHAR[cid][1], 2)}" '
      f'fill="{colour}" fill-opacity="0.55"/>')
    A(f'<circle cx="{x1+8:.1f}" cy="{end_y:.1f}" r="5" fill="{colour}"/>')
    A(f'<text x="{x1+20:.1f}" y="{end_y-10:.1f}" font-size="12.5" font-weight="700" '
      f'fill="{colour}">Rob Hegarty takes his own life</text>')
    A(f'<text x="{x1+20:.1f}" y="{end_y+6:.1f}" font-size="11" font-style="italic" '
      f'fill="#8b8377">New Year\u2019s Eve \u2014 the strand ends</text>')

for cid in ORDER:
    w, colour = CHAR[cid][1], CHAR[cid][2]
    for i in range(NCOL - 1):
        if cid not in Y[i] or cid not in Y[i+1]:
            continue
        d = ribbon(COL_X[i], COL_X[i+1], Y[i][cid], Y[i+1][cid], w)
        if i in DASHED.get(cid, ()):
            A(f'<path d="{d}" fill="{colour}" fill-opacity="0.16"/>')
            A(f'<path d="{d}" fill="none" stroke="{colour}" stroke-width="1.6" '
              f'stroke-dasharray="7 5" opacity="0.95"/>')
        else:
            A(f'<path d="{d}" fill="{colour}" fill-opacity="0.82"/>')

for cid in ORDER:
    if cid not in Y[0]:
        continue
    A(f'<text x="{COL_X[0]-20}" y="{Y[0][cid]+4:.1f}" font-size="13.5" '
      f'font-weight="700" text-anchor="end" fill="{CHAR[cid][2]}">{CHAR[cid][0]}</text>')

for y, text, colour in END_LABELS:
    A(f'<text x="{COL_X[-1]+146}" y="{y+4:.1f}" font-size="12.5" font-weight="700" '
      f'fill="{colour}">{text}</text>')

A(f'<text x="{COL_X[0]+14}" y="{SPINE-54}" font-size="12" font-style="italic" '
  f'fill="#1b57c4">the two of them \u2014 the braid</text>')

lx, ly = 60, 1195
A(f'<text x="{lx}" y="{ly-18}" font-size="11" font-weight="700" letter-spacing="1.4" '
  f'fill="#9a9086">STRANDS \u2014 the two leads are the two saturated ribbons</text>')
cx = lx
for cid in ORDER:
    label, w, colour = CHAR[cid]
    disp = max(16, w // 2)
    A(f'<rect x="{cx}" y="{ly}" width="{disp}" height="14" rx="3" fill="{colour}" '
      f'fill-opacity="0.85"/>')
    A(f'<text x="{cx+disp+7}" y="{ly+12}" font-size="12.5" font-weight="600" '
      f'fill="#2b2622">{label}</text>')
    cx += disp + 7 + len(label) * 7.2 + 26
A(f'<text x="{W-60}" y="{ly+12}" font-size="12" fill="#8b8377" text-anchor="end">'
  f'hatched ribbon = off-page that episode</text>')

A(f'<line x1="60" y1="1262" x2="{W-60}" y2="1262" stroke="#ded7cb"/>')
A(f'<text x="60" y="1312" font-family="Georgia, serif" font-size="33" fill="#22201d">'
  f'Normal People \u2014 a character alluvial</text>')
A(f'<text x="60" y="1343" font-size="13.5" fill="#6f675c">'
  f'Thirteen columns: the twelve episodes of the BBC/Hulu series, then a coda. '
  f'Rooney\u2019s novel covered the same ground \u2014 January 2011 to February 2015 \u2014 in dated chapters. '
  f'There is no film.</text>')
A(f'<text x="60" y="1368" font-size="12.5" font-style="italic" fill="#9a9086">'
  f'Above the spine: the social world. On it: Connell and Marianne. Below it: family, and the private. '
  f'Where the two thick ribbons touch, they are together; where they part, someone else is holding on. '
  f'Alan and Denise run the full width \u2014 off-stage in some episodes, never out of her story.</text>')
A('</svg>')

out = os.path.expanduser("~/diagrams/normal-people-alluvial.svg")
with open(out, "w") as f:
    f.write("\n".join(svg))
t = "\n".join(svg)
print(out, {"bytes": len(t), "ribbons": t.count('fill-opacity="0.82"'),
            "dashed": t.count('stroke-dasharray="7 5"'),
            "cols": len(COLS), "nan": "nan" in t.lower().replace("font-family", "")})

# --- geometry self-check: no lane overlaps at any column -------------------
bad = []
for i, col in enumerate(Y):
    items = sorted((y, cid) for cid, y in col.items())
    for (y1, c1), (y2, c2) in zip(items, items[1:]):
        gap = (y2 - CHAR[c2][1] / 2) - (y1 + CHAR[c1][1] / 2)
        if gap < 1:
            bad.append((COLS[i]["beat"], c1, c2, round(gap, 1)))
print("lane overlaps:", bad if bad else "none")
