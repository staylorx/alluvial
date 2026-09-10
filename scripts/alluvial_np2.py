#!/usr/bin/env python3
"""Alluvial engine + Normal People datasets.

Views produced:
  np-panel-a   episodes 1-6   (series, larger type)
  np-panel-b   episodes 7-coda
  np-novel     18 dated chapters, x-spacing proportional to elapsed time
"""
import os

OUT = os.path.expanduser("/home/installer/hermes/projects/alluvial/out")

# ----------------------------------------------------------------- engine ---
DEFAULT_TERMINAL_LABEL = "Rob Hegarty takes his own life"
DEFAULT_TERMINAL_SUB = "New Year\u2019s Eve \u2014 the strand ends"


def stack(centre, ids, char, gap=5):
    total = sum(char[c][1] for c in ids) + gap * (len(ids) - 1)
    y = centre - total / 2
    out = {}
    for c in ids:
        h = char[c][1]
        out[c] = y + h / 2
        y += h + gap
    return out


def ribbon(x0, x1, y0, y1, w0, w1=None):
    w1 = w0 if w1 is None else w1
    a, b_ = w0 / 2, w1 / 2
    xm0, xm1 = x0 + (x1 - x0) * 0.42, x0 + (x1 - x0) * 0.58
    return (f"M {x0:.1f} {y0-a:.1f} "
            f"C {xm0:.1f} {y0-a:.1f} {xm1:.1f} {y1-b_:.1f} {x1:.1f} {y1-b_:.1f} "
            f"L {x1:.1f} {y1+b_:.1f} "
            f"C {xm1:.1f} {y1+b_:.1f} {xm0:.1f} {y0+a:.1f} {x0:.1f} {y0+a:.1f} Z")


def caption_rows(xs, min_sep=170.0, max_rows=3):
    """Greedy staircase: no two caption blocks on the same row overlap."""
    rows, last = [], [None] * max_rows
    for x in xs:
        for r in range(max_rows):
            if last[r] is None or last[r] + min_sep <= x:
                rows.append(r)
                last[r] = x
                break
        else:
            rows.append(max_rows - 1)
    return rows


def render(spec):
    char, order, cols = spec["char"], spec["order"], spec["cols"]
    xs, n = spec["xs"], len(spec["cols"])
    W, H, sh = spec["W"], spec["H"], spec.get("lane_shift", 0)
    F, gap, stub = spec["fonts"], 5, spec.get("stub", 95)
    lane = lambda y: y + sh

    Y = []
    for c in cols:
        col = {}
        for centre, ids in c["groups"]:
            col.update(stack(centre, ids, char, gap))
        Y.append(col)

    rows = spec.get("cap_rows") or [0] * n
    hdr = spec["header_rows"]
    line = spec["line_dy"]              # list of dy for beat, loc, cap1, cap2, hard

    svg = []
    A = svg.append
    A(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
      f'viewBox="0 0 {W} {H}" font-family="Helvetica, Arial, sans-serif">')
    A('<defs><pattern id="dots" width="26" height="26" patternUnits="userSpaceOnUse">'
      '<circle cx="1" cy="1" r="0.9" fill="#d8d2c8"/></pattern></defs>')
    A(f'<rect width="{W}" height="{H}" fill="#faf7f2"/>')
    bt, bb = spec["bg"]
    A(f'<rect x="0" y="{bt}" width="{W}" height="{bb-bt}" fill="url(#dots)" opacity="0.55"/>')

    for y, text in spec["bands"]:
        A(f'<text x="46" y="{y}" font-size="{F["band"]}" font-weight="700" '
          f'letter-spacing="2.4" fill="#b3aa9d">{text}</text>')

    # columns: grid line + caption block (staircase rows)
    for i, c in enumerate(cols):
        x = xs[i]
        A(f'<line x1="{x}" y1="{spec["grid_top"]}" x2="{x}" y2="{spec["grid_bot"]}" '
          f'stroke="#c9c2b6" stroke-width="1" stroke-dasharray="2 5"/>')
        y0 = hdr[rows[i]]
        A(f'<text x="{x}" y="{y0+line[0]}" font-size="{F["beat"]}" font-weight="700" '
          f'fill="#2b2622" letter-spacing="1.4">{c["beat"]}</text>')
        A(f'<text x="{x}" y="{y0+line[1]}" font-size="{F["loc"]}" fill="#9a9086" '
          f'letter-spacing="0.3">{c["loc"]}</text>')
        for j, t in enumerate(c["cap"]):
            A(f'<text x="{x}" y="{y0+line[2+j]}" font-size="{F["cap"]}" '
              f'font-style="italic" fill="#7d7568">{t}</text>')
        if c.get("hard"):
            A(f'<text x="{x}" y="{y0+line[4]}" font-size="{F["hard"]}" font-weight="700" '
              f'fill="#9c3b34">{c["hard"]}</text>')

    # entrance / exit tapers, broken strands, fading endings
    for i, c in enumerate(cols):
        for (cid, kind, y_over) in c.get("stubs", []):
            y = lane(y_over if y_over is not None else Y[i][cid])
            w, colour = char[cid][1], char[cid][2]
            if kind == "in":
                A(f'<path d="{ribbon(xs[i]-stub, xs[i], y, y, 3, w)}" fill="{colour}" '
                  f'fill-opacity="0.8"/>')
            elif kind == "out":
                A(f'<path d="{ribbon(xs[i], xs[i]+stub, y, y, w, 3)}" fill="{colour}" '
                  f'fill-opacity="0.8"/>')
            elif kind == "break":
                A(f'<path d="{ribbon(xs[i], xs[i]+50, y, y, w, 3)}" fill="{colour}" '
                  f'fill-opacity="0.85"/>')
                bx = xs[i] + 70
                for a_, b_ in ((1, 1), (1, -1)):
                    A(f'<line x1="{bx}" y1="{y-9*b_}" x2="{bx+16}" y2="{y+9*b_}" '
                      f'stroke="#9c3b34" stroke-width="1.8"/>')
                A(f'<text x="{bx}" y="{y+34}" font-size="{F["cap"]}" font-weight="700" '
                  f'fill="#9c3b34">her mother stops speaking</text>')
            elif kind == "fade":
                A(f'<path d="{ribbon(xs[i], xs[i]+130, y, y+14, w, 2)}" fill="{colour}" '
                  f'fill-opacity="0.34"/>')

    # terminals
    for i, c in enumerate(cols):
        if "terminal" not in c:
            continue
        cid, end_y = c["terminal"]
        prev, colour = lane(Y[i-1][cid]), char[cid][2]
        x0 = xs[i-1]
        x1 = xs[i-1] + (xs[i] - xs[i-1]) * 0.60
        ey = lane(end_y)
        sub_txt = c.get("terminal_sub", DEFAULT_TERMINAL_SUB)
        lab_txt = c.get("terminal_label", DEFAULT_TERMINAL_LABEL)
        A(f'<path d="{ribbon(x0, x1, prev, ey, char[cid][1], 2)}" fill="{colour}" '
          f'fill-opacity="0.55"/>')
        A(f'<circle cx="{x1+8:.1f}" cy="{ey:.1f}" r="5" fill="{colour}"/>')
        A(f'<text x="{x1+20:.1f}" y="{ey-10:.1f}" font-size="{F["strand"]-1.5}" '
          f'font-weight="700" fill="{colour}">{lab_txt}</text>')
        A(f'<text x="{x1+20:.1f}" y="{ey+7:.1f}" font-size="{F["cap"]}" font-style="italic" '
          f'fill="#8b8377">{sub_txt}</text>')

    # ribbons
    for cid in order:
        w, colour = char[cid][1], char[cid][2]
        for i in range(n - 1):
            if cid not in Y[i] or cid not in Y[i+1]:
                continue
            d = ribbon(xs[i], xs[i+1], lane(Y[i][cid]), lane(Y[i+1][cid]), w)
            if i in spec.get("dashed", {}).get(cid, ()):
                A(f'<path d="{d}" fill="{colour}" fill-opacity="0.16"/>')
                A(f'<path d="{d}" fill="none" stroke="{colour}" stroke-width="1.6" '
                  f'stroke-dasharray="7 5" opacity="0.95"/>')
            else:
                A(f'<path d="{d}" fill="{colour}" fill-opacity="0.82"/>')

    # seam stubs (panel splits)
    edge = spec.get("edge")
    if edge in ("right", "both"):
        for cid in order:
            if cid in Y[-1]:
                y, colour = lane(Y[-1][cid]), char[cid][2]
                A(f'<path d="{ribbon(xs[-1], xs[-1]+58, y, y, char[cid][1], 3)}" '
                  f'fill="{colour}" fill-opacity="0.72"/>')
    if edge in ("left", "both"):
        for cid in order:
            if cid in Y[0]:
                y, colour = lane(Y[0][cid]), char[cid][2]
                A(f'<path d="{ribbon(xs[0]-58, xs[0], y, y, 3, char[cid][1])}" '
                  f'fill="{colour}" fill-opacity="0.72"/>')

    if spec.get("start_labels", True):
        for cid in order:
            if cid in Y[0]:
                A(f'<text x="{xs[0]-20}" y="{lane(Y[0][cid])+4:.1f}" '
                  f'font-size="{F["strand"]}" font-weight="700" text-anchor="end" '
                  f'fill="{char[cid][2]}">{char[cid][0]}</text>')
    for entry in spec.get("end_labels", []):
        y, text, colour = entry[0], entry[1], entry[2]
        A(f'<text x="{xs[-1]+spec.get("end_dx",146)}" y="{lane(y)+4:.1f}" '
          f'font-size="{F["end"]}" font-weight="700" fill="{colour}">{text}</text>')

    for i, c in enumerate(cols):                       # in-glyph notes
        for (nx, ny, txt, colr, sz) in c.get("notes", []):
            A(f'<text x="{xs[i]+nx}" y="{lane(ny)}" font-size="{sz or F["cap"]}" '
              f'font-style="italic" fill="{colr}">{txt}</text>')

    # legend
    ly = spec["legend_y"]
    A(f'<text x="60" y="{ly-18}" font-size="{F["legend_title"]}" font-weight="700" '
      f'letter-spacing="1.4" fill="#9a9086">{spec["legend_title"]}</text>')
    cx = 60
    for cid in order:
        label, w, colour = char[cid]
        disp = max(16, w // 2)
        A(f'<rect x="{cx}" y="{ly}" width="{disp}" height="14" rx="3" fill="{colour}" '
          f'fill-opacity="0.85"/>')
        A(f'<text x="{cx+disp+7}" y="{ly+12}" font-size="{F["legend"]}" '
          f'font-weight="600" fill="#2b2622">{label}</text>')
        cx += disp + 7 + len(label) * (F["legend"] * 0.58) + 26
    if spec.get("legend_note"):
        A(f'<text x="{W-60}" y="{ly+12}" font-size="{F["legend_title"]+1}" fill="#8b8377" '
          f'text-anchor="end">{spec["legend_note"]}</text>')

    # title block
    A(f'<line x1="60" y1="{H-158}" x2="{W-60}" y2="{H-158}" stroke="#ded7cb"/>')
    for k, (txt, sty) in enumerate(spec["title"]):
        y = H - 108 + k * spec.get("title_dy", 26)[k]
        if sty == "title":
            A(f'<text x="60" y="{y}" font-family="Georgia, serif" '
              f'font-size="{F["title"]}" fill="#22201d">{txt}</text>')
        elif sty == "sub":
            A(f'<text x="60" y="{y}" font-size="{F["sub"]}" fill="#6f675c">{txt}</text>')
        else:
            A(f'<text x="60" y="{y}" font-size="{F["sub2"]}" font-style="italic" '
              f'fill="#9a9086">{txt}</text>')
    A('</svg>')

    bad = []
    for i, col in enumerate(Y):
        items = sorted((lane(y), cid) for cid, y in col.items())
        for (y1, c1), (y2, c2) in zip(items, items[1:]):
            g = (y2 - char[c2][1] / 2) - (y1 + char[c1][1] / 2)
            if g < 1:
                bad.append((i, c1, c2, round(g, 1)))
    return "\n".join(svg), {"lane_overlaps": bad, "cols": n,
                            "ribbons": sum(1 for _ in ())}


# ------------------------------------------------------------- series data ---
SC = {
    "connell":  ("Connell",  34, "#1b57c4"), "marianne": ("Marianne", 34, "#d0316a"),
    "rob":      ("Rob",      14, "#6f8f96"), "rachel":   ("Rachel",   12, "#8d7fa8"),
    "peggy":    ("Peggy",    12, "#b09a4e"), "gareth":   ("Gareth",   12, "#8a9299"),
    "jamie":    ("Jamie",    16, "#9c6552"), "helen":    ("Helen",    14, "#6e9078"),
    "lukas":    ("Lukas",    12, "#9aa0a6"), "lorraine": ("Lorraine", 14, "#7d8f52"),
    "alan":     ("Alan",     16, "#7f4a4a"), "denise":   ("Denise",   10, "#b0a89e"),
    "gillian":  ("Gillian",  10, "#6d78a8"),
}
SORDER = ["connell", "marianne", "rob", "rachel", "peggy", "gareth",
          "jamie", "helen", "lukas", "lorraine", "alan", "denise", "gillian"]
SPINE = 620
SDASH = {"rob": {3, 4, 5}}

SCOLS = [
 dict(beat="EPISODE 1", loc="Carricklea, Co. Sligo",
      cap=["Final year of school,", "and the secret starts"],
      groups=[(250, ["rob"]), (310, ["rachel"]), (SPINE, ["connell", "marianne"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])]),
 dict(beat="EPISODE 2", loc="Carricklea",
      cap=["The affair deepens;", "he won't say it aloud"],
      groups=[(250, ["rob"]), (310, ["rachel"]), (SPINE, ["connell", "marianne"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])]),
 dict(beat="EPISODE 3", loc="The Debs",
      cap=["He takes Rachel", "to the Debs, not her"],
      hard="\u25b8 assaulted at the fundraiser",
      groups=[(250, ["rob"]), (SPINE, ["connell", "rachel"]), (725, ["marianne"]),
              (850, ["lorraine"]), (940, ["alan"]), (1050, ["denise"])],
      stubs=[("rachel", "out", None)]),
 dict(beat="EPISODE 4", loc="Dublin",
      cap=["Trinity, months later:", "she has friends, he has rent"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (410, ["marianne", "gareth"]),
              (SPINE, ["connell"]), (810, ["lorraine"]), (920, ["alan"]),
              (1030, ["denise"])],
      stubs=[("peggy", "in", None), ("gareth", "in", None)]),
 dict(beat="EPISODE 5", loc="Dublin",
      cap=["Friends again \u2014 Gareth out,", "Jamie circling"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (410, ["gareth"]), (460, ["jamie"]),
              (660, ["marianne"]), (SPINE, ["connell"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
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
              (SPINE, ["connell", "helen"]), (810, ["lorraine"]), (920, ["alan"]),
              (1030, ["denise"])],
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
              (SPINE, ["connell", "helen"]), (810, ["lorraine"]), (920, ["alan"]),
              (1030, ["denise"])],
      stubs=[("lukas", "in", None), ("lukas", "out", None)]),
 dict(beat="EPISODE 10", loc="Sligo & Dublin",
      cap=["Rob dies; Connell", "starts therapy"],
      hard="\u25b8 31 December, alone",
      groups=[(350, ["peggy"]), (500, ["marianne"]), (545, ["helen"]),
              (SPINE, ["connell"]), (690, ["gillian"]), (760, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
      stubs=[("gillian", "in", None), ("helen", "out", 545)], terminal=("rob", 250)),
 dict(beat="EPISODE 11", loc="Sligo",
      cap=["Home again \u2014 she asks", "him to hurt her"],
      hard="\u25b8 then Alan breaks her nose",
      groups=[(350, ["peggy"]), (SPINE, ["connell", "marianne"]), (690, ["gillian"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])],
      stubs=[("alan", "out", None)]),
 dict(beat="EPISODE 12", loc="Sligo & Dublin",
      cap=["Christmas with the Waldrons;", "New York is offered"],
      groups=[(350, ["peggy"]), (SPINE, ["connell", "marianne"]), (690, ["gillian"]),
              (810, ["lorraine"]), (1030, ["denise"])],
      stubs=[("gillian", "out", None), ("denise", "break", None)]),
 dict(beat="CODA", loc="Dublin \u2192 New York",
      cap=["He goes. She stays.", "The braid never resolves"],
      groups=[(350, ["peggy"]), (480, ["connell"]), (730, ["marianne"]),
              (860, ["lorraine"])],
      stubs=[("connell", "fade", None), ("marianne", "fade", None)]),
]

# -------------------------------------------------------------- novel data ---
NC = dict(SC)
NORDER = ["connell", "marianne", "rob", "rachel", "peggy", "gareth", "jamie",
          "helen", "lukas", "lorraine", "alan", "denise", "gillian"]
NDASH = {"rob": {5, 6, 7, 8, 9, 10, 11}}   # off-page between the Dublin years
MONTHS = [0, 1, 2, 3, 3.066, 7, 10, 13, 15, 18, 20, 24, 30, 35, 38, 42, 42.001, 49]

NCOLS = [
 dict(beat="JANUARY 2011", loc="Carricklea, Co. Sligo",
      cap=["She answers the door;", "the secret begins"],
      groups=[(250, ["rob"]), (310, ["rachel"]), (SPINE, ["connell", "marianne"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])]),
 dict(beat="THREE WEEKS LATER", loc="February 2011",
      cap=["The affair thickens;", "nobody is told"],
      groups=[(250, ["rob"]), (310, ["rachel"]), (SPINE, ["connell", "marianne"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])]),
 dict(beat="ONE MONTH LATER", loc="March 2011",
      cap=["Exams, and the Debs", "coming round"],
      groups=[(250, ["rob"]), (310, ["rachel"]), (SPINE, ["connell", "marianne"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])]),
 dict(beat="SIX WEEKS LATER", loc="April 2011 \u2014 the Debs",
      cap=["He asks Rachel;", "she stops answering"],
      hard="\u25b8 the Debs",
      groups=[(250, ["rob"]), (SPINE, ["connell", "rachel"]), (700, ["marianne"]),
              (860, ["lorraine"]), (950, ["alan"]), (1060, ["denise"])],
      stubs=[("rachel", "out", None)]),
 dict(beat="TWO DAYS LATER", loc="April 2011",
      cap=["Eric tells him everyone", "already knew"],
      hard="\u25b8 two days on",
      groups=[(250, ["rob"]), (SPINE, ["connell"]), (740, ["marianne"]),
              (880, ["lorraine"]), (960, ["alan"]), (1070, ["denise"])]),
 dict(beat="FOUR MONTHS LATER", loc="August 2011 \u2014 Trinity",
      cap=["Dublin: she has friends,", "he has no money"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (410, ["marianne", "gareth"]),
              (SPINE, ["connell"]), (810, ["lorraine"]), (920, ["alan"]),
              (1030, ["denise"])],
      stubs=[("peggy", "in", None), ("gareth", "in", None)]),
 dict(beat="THREE MONTHS LATER", loc="November 2011",
      cap=["Friends again;", "Gareth is gone"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (410, ["gareth"]), (460, ["jamie"]),
              (660, ["marianne"]), (SPINE, ["connell"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
      stubs=[("jamie", "in", None), ("gareth", "out", None)]),
 dict(beat="THREE MONTHS LATER", loc="February 2012",
      cap=["Back together \u2014 and", "still not a couple"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (460, ["jamie"]),
              (SPINE, ["connell", "marianne"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])]),
 dict(beat="TWO MONTHS LATER", loc="April 2012",
      cap=["Peggy asks outright;", "they half answer"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (460, ["jamie"]),
              (SPINE, ["connell", "marianne"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])]),
 dict(beat="THREE MONTHS LATER", loc="July 2012",
      cap=["Summer: two lives", "in two places"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (460, ["marianne", "jamie"]),
              (SPINE, ["connell"]), (810, ["lorraine"]), (920, ["alan"]),
              (1030, ["denise"])]),
 dict(beat="SIX WEEKS LATER", loc="September 2012",
      cap=["Helen now, for him;", "Jamie still for her"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (460, ["marianne", "jamie"]),
              (SPINE, ["connell", "helen"]), (810, ["lorraine"]), (920, ["alan"]),
              (1030, ["denise"])],
      stubs=[("helen", "in", None)]),
 dict(beat="FOUR MONTHS LATER", loc="January 2013 \u2014 Trieste",
      cap=["Italy: one house, and", "Jamie's grip on her"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (460, ["marianne", "jamie"]),
              (512, ["helen"]), (580, ["connell"]), (810, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
      stubs=[("jamie", "out", None)]),
 dict(beat="SIX MONTHS LATER", loc="July 2013 \u2014 Sweden",
      cap=["A year abroad;", "Lukas, and the camera"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (500, ["marianne", "lukas"]),
              (SPINE, ["connell", "helen"]), (810, ["lorraine"]), (920, ["alan"]),
              (1030, ["denise"])],
      stubs=[("lukas", "in", None)]),
 dict(beat="FIVE MONTHS LATER", loc="December 2013",
      cap=["The away year ends;", "Lukas does too"],
      groups=[(250, ["rob"]), (350, ["peggy"]), (500, ["marianne", "lukas"]),
              (SPINE, ["connell", "helen"]), (810, ["lorraine"]), (920, ["alan"]),
              (1030, ["denise"])],
      stubs=[("lukas", "out", None)]),
 dict(beat="THREE MONTHS LATER", loc="March 2014",
      cap=["Rob is dead;", "the counsellor"],
      hard="\u25b8 he died at New Year",
      terminal_label="Rob, at New Year",
      terminal_sub="the strand ends between chapters",
      groups=[(350, ["peggy"]), (500, ["marianne"]), (545, ["helen"]),
              (SPINE, ["connell"]), (690, ["gillian"]), (760, ["lorraine"]),
              (920, ["alan"]), (1030, ["denise"])],
      stubs=[("gillian", "in", None), ("helen", "out", 545)], terminal=("rob", 250)),
 dict(beat="FOUR MONTHS LATER", loc="July 2014 \u2014 home",
      cap=["She asks him to", "hurt her"],
      hard="\u25b8 then Alan, at the house",
      groups=[(350, ["peggy"]), (SPINE, ["connell", "marianne"]), (690, ["gillian"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])]),
 dict(beat="FIVE MINUTES LATER", loc="July 2014",
      cap=["Connell goes to the", "house and ends it"],
      hard="\u25b8 five minutes on",
      groups=[(350, ["peggy"]), (SPINE, ["connell", "marianne"]), (690, ["gillian"]),
              (810, ["lorraine"]), (920, ["alan"]), (1030, ["denise"])],
      stubs=[("alan", "out", None), ("gillian", "out", None)]),
 dict(beat="SEVEN MONTHS LATER", loc="February 2015",
      cap=["New York is offered;", "she tells him to go"],
      groups=[(350, ["peggy"]), (SPINE, ["connell", "marianne"]), (810, ["lorraine"])],
      stubs=[("connell", "fade", None), ("marianne", "fade", None)]),
]


def x_positions(months, x0=300.0, base=168.0, per_month=20.0, tight=52.0,
                instant=0.5):
    """Elapsed time -> x. A one-month gap is `base` wide; longer gaps grow with
    the extra months; gaps under `instant` months (two days, five minutes) clamp
    to `tight` so the two chapters still read as separate columns."""
    xs, last = [], None
    for i, m in enumerate(months):
        if i == 0:
            x = x0
        else:
            g = m - months[i-1]
            x = last + (tight if g < instant else base + (g - 1) * per_month)
        xs.append(x)
        last = x
    return xs


def series_view(panel):
    if panel == "a":
        return dict(char=SC, order=SORDER, cols=SCOLS[0:6], dashed=SDASH,
                    xs=[330, 700, 1070, 1440, 1810, 2180], W=2560, H=1420,
                    header_rows=[58], grid_top=152, grid_bot=1150, bg=(140, 1150),
                    bands=[(207, "THE SOCIAL WORLD"), (1120, "FAMILY / THE PRIVATE")],
                    edge="right", end_dx=140,
                    end_labels=[(250, "Rob", SC["rob"][2]), (350, "Peggy", SC["peggy"][2]),
                                (460, "Jamie", SC["jamie"][2]),
                                (600.5, "Connell", SC["connell"][2]),
                                (639.5, "Marianne", SC["marianne"][2]),
                                (810, "Lorraine", SC["lorraine"][2]),
                                (920, "Alan", SC["alan"][2]),
                                (1030, "Denise", SC["denise"][2])],
                    legend_y=1195,
                    legend_title="STRANDS \u2014 the two leads are the two saturated ribbons",
                    legend_note="hatched ribbon = off-page that episode")
    return dict(char=SC, order=SORDER, cols=SCOLS[6:13], dashed=SDASH,
                xs=[340, 680, 1020, 1360, 1700, 2040, 2380], W=2840, H=1420,
                header_rows=[58], grid_top=152, grid_bot=1150, bg=(140, 1150),
                bands=[(207, "THE SOCIAL WORLD"), (1120, "FAMILY / THE PRIVATE")],
                edge="left", end_dx=150,
                end_labels=[(350, "Peggy, Joanna & the Trinity circle", SC["peggy"][2]),
                            (480, "Connell \u2192 a year in New York", SC["connell"][2]),
                            (730, "Marianne stays \u2014 \u201cI\u2019ll always be here\u201d",
                             SC["marianne"][2]),
                            (860, "Lorraine", SC["lorraine"][2])],
                legend_y=1195,
                legend_title="STRANDS \u2014 the two leads are the two saturated ribbons",
                legend_note="hatched ribbon = off-page that episode")


def novel_view():
    xs = x_positions(MONTHS)
    W = int(xs[-1] + 430)
    return dict(char=NC, order=NORDER, cols=NCOLS, dashed=NDASH, xs=xs,
                W=W, H=1420, header_rows=[58, 146],
                cap_rows=caption_rows(xs), grid_top=236, grid_bot=1150,
                bg=(150, 1150),
                bands=[(207, "THE SOCIAL WORLD"), (1120, "FAMILY / THE PRIVATE")],
                end_dx=150,
                end_labels=[(350, "Peggy & the Trinity circle", NC["peggy"][2]),
                            (600.5, "Connell \u2192 New York", NC["connell"][2]),
                            (639.5, "Marianne \u2014 \u201cI\u2019ll always be here\u201d",
                             NC["marianne"][2]),
                            (810, "Lorraine", NC["lorraine"][2])],
                legend_y=1195,
                legend_title="STRANDS \u2014 the two leads are the two saturated ribbons",
                legend_note="hatched ribbon = off-page that chapter")


FONTS_PANEL = dict(beat=16.5, loc=12.5, cap=12.5, hard=12.5, strand=15, end=14,
                   band=12.5, legend=13, legend_title=12, title=42, sub=16, sub2=14.5)
FONTS_NOVEL = dict(beat=12.5, loc=10.8, cap=11.2, hard=11.2, strand=13, end=12.5,
                   band=11, legend=11.5, legend_title=10.5, title=32, sub=13.5, sub2=12.5)

VIEWS = {
 "np-panel-a": (series_view("a"), FONTS_PANEL, [0, 20, 42, 59, 86], 29,
   [("Normal People \u2014 the braid, panel A of 2: episodes 1\u20136", "title"),
    ("Above the spine: the social world. On it: Connell and Marianne. Below it: family, and the private.", "sub"),
    ("Panel B carries on from the summer of episode 6. Where the two thick ribbons touch, they are together.", "note")]),
 "np-panel-b": (series_view("b"), FONTS_PANEL, [0, 20, 42, 59, 86], 29,
   [("Normal People \u2014 the braid, panel B of 2: episode 7 to the coda", "title"),
    ("The separated years. Every strand that leaves the spine is a person one of them chose instead.", "sub"),
    ("Continues panel A. Alan and Denise run the full width \u2014 off-stage in some episodes, never out of her story.", "note")]),
 "np-novel": (novel_view(), FONTS_NOVEL, [0, 17, 38, 54, 74], 24,
   [("Normal People \u2014 the same braid on the novel\u2019s own clock", "title"),
    ("Eighteen chapters, January 2011 to February 2015. Column spacing tracks elapsed time: a month is a fixed width, longer gaps widen, and the two chapters that happen days and minutes apart sit almost on top of their predecessors.", "sub"),
    ("Two chapters refuse the pattern: \u201cTwo Days Later\u201d and \u201cFive Minutes Later\u201d sit almost on top of the chapter before them. Rooney elides three, four, six months; she will not elide these.", "note")]),
}

def main():
    for name, (spec, fonts, line_dy, tdy, title) in VIEWS.items():
        spec.update(fonts=fonts, line_dy=line_dy, stub=95)
        spec["title"], spec["title_dy"] = title, [tdy, 30, 26]
        svg, checks = render(spec)
        open(f"{OUT}/{name}.svg", "w").write(svg)
        print(f"{name}: {len(svg)}B  cols={checks['cols']}  "
              f"lane_overlaps={checks['lane_overlaps'] or 'none'}  "
              f"W={spec['W']} x-positions={len(spec['xs'])}")
    v = VIEWS["np-novel"][0]
    print("novel x gaps:", [round(b - a) for a, b in zip(v["xs"], v["xs"][1:])])
    print("novel caption rows:", v["cap_rows"])


if __name__ == "__main__":
    main()
