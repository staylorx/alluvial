#!/usr/bin/env python3
"""Generalised vertical alluvial renderer (time runs down the page).

Lane x comes from mapping the horizontal layout into column space:

    fx(y) = origin + (spine_old - y) * S        (mirror=True, semantic bands)
    fx(y) = origin + (y - spine_old) * S        (mirror=False, order preserved)

Centres AND ribbon widths scale by the same S, so merged pairs keep touching.

Label type scales with ribbon width (`width_fonts`), so the legend reads as a
hierarchy: the biggest names are the biggest strands. Applies to the lane names
above the first row and to the legend.

All text lives in two safe places: staggered lane-name tiers at the top, and one
caption column beside the flow.
"""
import os

OUT = os.path.expanduser("/home/installer/hermes/projects/alluvial/out")


def width_fonts(char, base=24.0, lo=15.0, hi=26.0, power=0.5):
    """Per-character label size from ribbon width. sqrt keeps the small ones
    legible while the big ones still dominate."""
    wmax = max(w for _, w, _ in char.values())
    return {k: round(min(hi, max(lo, base * (w / wmax) ** power)), 1)
            for k, (_, w, _) in char.items()}


# Sparse SVG symbols for colour-blind mode. Index 0 is "no symbol": the
# heaviest strand gets the cleanest, highest-contrast treatment, and every other
# strand gets a distinct mark. Tiles are 9x9 user units so even a thin ribbon
# shows a whole symbol.
SYMBOLS = [
    None,                                        # solid (heaviest)
    "M0,9 L9,0",                                 # single up diagonal
    "M0,0 L9,9",                                 # single down diagonal
    "M4.5,4.5 m-1.7,0 a1.7,1.7 0 1,0 3.4,0 a1.7,1.7 0 1,0 -3.4,0",   # dot
    "M4.5,1 V8 M1,4.5 H8",                       # plus
    "M1,1 L8,8 M8,1 L1,8",                       # cross
    "M4.5,1 V8",                                 # vertical bar
    "M1,4.5 H8",                                 # horizontal bar
    "M-1,9 L3,5 M5,9 L9,5",                      # sparse double diagonal
    "M4.5,4.5 m-2.7,0 a2.7,2.7 0 1,0 5.4,0 a2.7,2.7 0 1,0 -5.4,0",   # ring
    "M4.5,1.6 L8.1,7.6 H0.9 Z",                  # triangle
    "M2.6,2.6 m-1.3,0 a1.3,1.3 0 1,0 2.6,0 a1.3,1.3 0 1,0 -2.6,0 "
    "M6.6,6.6 m-1.3,0 a1.3,1.3 0 1,0 2.6,0 a1.3,1.3 0 1,0 -2.6,0",   # dot pair
    "M1,1.5 H8 M1,7.5 H8",                       # two bars
    "M3.2,1 L7,4.5 L3.2,8",                      # chevron
]


def mix(hex_a, hex_b, t):
    a = [int(hex_a[i:i+2], 16) for i in (1, 3, 5)]
    b = [int(hex_b[i:i+2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(a, b))


def cb_style(char, order, bg="#faf7f2"):
    """Colour-blind treatment: rank strands by ribbon width, ramp the contrast
    down the ranking, and give each a unique symbol.

    Returns {cid: (rank, fill_opacity, symbol_path, symbol_colour)}.
    Hue still differs, but it is no longer load-bearing: the symbol identifies
    and the darkness ranks.
    """
    ranked = sorted(order, key=lambda k: (-char[k][1], order.index(k)))
    span = max(1, len(ranked) - 1)
    out = {}
    for i, cid in enumerate(ranked):
        t = i / span
        out[cid] = (i, round(0.95 - 0.50 * t, 3),
                    SYMBOLS[i % len(SYMBOLS)],
                    mix(char[cid][2], "#141414", 0.35))
    return out


def vribbon(x0, y0, x1, y1, w0, w1=None):
    w1 = w0 if w1 is None else w1
    a, b_ = w0 / 2, w1 / 2
    ym0, ym1 = y0 + (y1 - y0) * 0.42, y0 + (y1 - y0) * 0.58
    return (f"M {x0-a:.1f} {y0:.1f} "
            f"C {x0-a:.1f} {ym0:.1f} {x1-b_:.1f} {ym1:.1f} {x1-b_:.1f} {y1:.1f} "
            f"L {x1+b_:.1f} {y1:.1f} "
            f"C {x1+b_:.1f} {ym1:.1f} {x0+a:.1f} {ym0:.1f} {x0+a:.1f} {y0:.1f} Z")


def render_v(spec):
    char, order, cols, ys = spec["char"], spec["order"], spec["cols"], spec["ys"]
    S = spec["scale"]
    origin, spine_old = spec["origin"], spec["spine_old"]
    mirror = spec.get("mirror", True)
    W, CAPX = spec["W"], spec["CAPX"]
    LANE_HI = spec["LANE_HI"]
    F = spec["fonts"]
    lab_font = spec["label_font"]          # per-character label size
    GAP = 5 * S
    n = len(cols)

    if mirror:
        fx = lambda y: origin + (spine_old - y) * S
    else:
        fx = lambda y: origin + (y - spine_old) * S

    def vstack(centre, ids):
        if mirror:                          # mirroring reverses the stacking order
            ids = list(reversed(ids))
        total = sum(char[c][1] * S for c in ids) + GAP * (len(ids) - 1)
        x = centre - total / 2
        out = {}
        for c in ids:
            w = char[c][1] * S
            out[c] = x + w / 2
            x += w + GAP
        return out

    CB = cb_style(char, order) if spec.get("cb_safe") else {}

    def fill_of(cid):
        return f"url(#cb-{cid})" if CB else char[cid][2]

    VY = []
    for c in cols:
        row = {}
        for centre, ids in c["groups"]:
            row.update(vstack(fx(centre), ids))
        VY.append(row)

    def lane_tiers(lanes, tiers=5):
        """Greedy staircase so no two lane names share a tier and overlap."""
        last = [None] * tiers
        out = {}
        for x, cid in sorted(lanes):
            half = len(char[cid][0]) * lab_font[cid] * 0.29
            for t in range(tiers):
                if last[t] is None or x - half > last[t] + 10:
                    out[cid] = t
                    last[t] = x + half
                    break
            else:
                out[cid] = tiers - 1
        return out

    LCAP = spec.get("line_cap", 25)
    XGAP = spec.get("extra_gap", 26)

    def cap_depth(c):
        d = 46 + LCAP * len(c["cap"]) + (8 if c.get("hard") else 0)
        if c.get("cap_extra"):
            d += XGAP
        if c.get("enter"):
            d += XGAP
        return d

    def legend_rows():
        cx, rows, rowmax = 60.0, 1, 0.0
        for cid in order:
            label, w, _ = char[cid]
            f = spec["legend_font"][cid]
            disp = max(6, round(w * S))
            item = disp + 6 + len(label) * f * 0.56 + 22
            if cx + item > W - 60:
                rows += 1
                cx = 60.0
            cx += item
            rowmax = max(rowmax, f)
        return rows, rowmax

    lrows, lfont = legend_rows()
    last_row = ys[-1]
    band_y = last_row + max(cap_depth(c) for c in cols) + 26
    legend_y = band_y + (58 if spec.get("bands") else 26)
    legend_bottom = legend_y + (lrows - 1) * (lfont * 1.5) + lfont * 1.1
    note_y = legend_bottom + 24 if spec.get("legend_note") else None
    rule_y = (note_y if note_y else legend_bottom) + 30
    title_top = rule_y + 34
    H = int(title_top + 26 * (len(spec["title"]) - 1) + 30)

    svg = []
    A = svg.append
    A(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
      f'viewBox="0 0 {W} {H}" font-family="Helvetica, Arial, sans-serif">')
    A('<defs><pattern id="dots" width="26" height="26" patternUnits="userSpaceOnUse">'
      '<circle cx="1" cy="1" r="0.9" fill="#d8d2c8"/></pattern>'
      + ("" if CB else "</defs>"))
    if CB:
        for cid in order:
            _rank, _op, _sym, _dark = CB[cid]
            A(f'<pattern id="cb-{cid}" width="9" height="9" patternUnits="userSpaceOnUse">')
            A(f'<rect width="9" height="9" fill="{char[cid][2]}" fill-opacity="{_op}"/>')
            if _sym:
                A(f'<path d="{_sym}" fill="none" stroke="{_dark}" stroke-width="1.3" '
                  f'stroke-linecap="round" opacity="0.92"/>')
            A('</pattern>')
        A('</defs>')
    A(f'<rect width="{W}" height="{H}" fill="#faf7f2"/>')
    A(f'<rect x="0" y="{ys[0]-90}" width="{W}" height="{last_row-ys[0]+180}" '
      f'fill="url(#dots)" opacity="0.55"/>')

    for y in ys:
        A(f'<line x1="70" y1="{y}" x2="{LANE_HI}" y2="{y}" stroke="#c9c2b6" '
          f'stroke-width="1" stroke-dasharray="2 5"/>')
        A(f'<line x1="{LANE_HI}" y1="{y}" x2="{CAPX-14}" y2="{y}" stroke="#ded7cb" '
          f'stroke-width="1"/>')

    # caption column
    for i, c in enumerate(cols):
        y = ys[i]
        A(f'<text x="{CAPX}" y="{y-12}" font-size="{F["beat"]}" font-weight="700" '
          f'fill="#2b2622" letter-spacing="1.1">{c["beat"]}</text>')
        if c.get("loc"):
            A(f'<text x="{CAPX}" y="{y+16}" font-size="{F["loc"]}" fill="#9a9086">'
              f'{c["loc"]}</text>')
        for j, t in enumerate(c["cap"]):
            A(f'<text x="{CAPX}" y="{y+46+j*LCAP}" font-size="{F["cap"]}" '
              f'font-style="italic" fill="#7d7568">{t}</text>')
        ly = y + 46 + len(c["cap"]) * LCAP + 8
        if c.get("hard"):
            A(f'<text x="{CAPX}" y="{ly}" font-size="{F["hard"]}" font-weight="700" '
              f'fill="#9c3b34">{c["hard"]}</text>')
            ly += XGAP
        if c.get("cap_extra"):
            txt, colr = c["cap_extra"]
            A(f'<text x="{CAPX}" y="{ly}" font-size="{F["hard"]-1}" font-weight="700" '
              f'fill="{colr}">{txt}</text>')
            ly += XGAP
        if c.get("enter"):
            A(f'<text x="{CAPX}" y="{ly}" font-size="{F["cap"]-2}" fill="#9a9086">'
              f'new lanes \u25b8</text>')
            cx = CAPX + 78
            for cid in c["enter"]:
                A(f'<text x="{cx:.0f}" y="{ly}" font-size="{lab_font[cid]:.1f}" '
                  f'font-weight="700" fill="{char[cid][2]}">{char[cid][0]}</text>')
                cx += len(char[cid][0]) * lab_font[cid] * 0.58 + 12

    # stubs, breaks, fades
    for i, c in enumerate(cols):
        for (cid, kind, _y) in c.get("stubs", []):
            x, y = VY[i][cid], ys[i]
            w, colour = char[cid][1] * S, char[cid][2]
            ff = fill_of(cid)
            if kind == "in":
                A(f'<path d="{vribbon(x, y-58, x, y, 2, w)}" fill="{ff}" '
                  f'fill-opacity="{1 if CB else 0.8}"/>')
            elif kind == "out":
                A(f'<path d="{vribbon(x, y, x, y+58, w, 2)}" fill="{ff}" '
                  f'fill-opacity="{1 if CB else 0.8}"/>')
            elif kind == "break":
                A(f'<path d="{vribbon(x, y, x, y+46, w, 2)}" fill="{ff}" '
                  f'fill-opacity="{1 if CB else 0.85}"/>')
                bx, by = x + max(12, w), y + 34
                for dx, dy in ((9, -9), (9, 9)):
                    A(f'<line x1="{bx-dx}" y1="{by+dy}" x2="{bx+dx}" y2="{by-dy}" '
                      f'stroke="#9c3b34" stroke-width="2"/>')
            elif kind == "fade":
                drift = 20 if x > origin else -20
                A(f'<path d="{vribbon(x, y, x+drift, y+135, w, 2)}" fill="{ff}" '
                  f'fill-opacity="{0.45 if CB else 0.34}"/>')

    # terminals
    for i, c in enumerate(cols):
        if "terminal" not in c:
            continue
        cid, _ = c["terminal"]
        x, colour = VY[i-1][cid], char[cid][2]
        y0 = ys[i-1]
        y1 = ys[i-1] + (ys[i] - ys[i-1]) * 0.60
        A(f'<path d="{vribbon(x, y0, x, y1, char[cid][1] * S, 2)}" fill="{fill_of(cid)}" '
          f'fill-opacity="{0.8 if CB else 0.55}"/>')
        A(f'<circle cx="{x:.1f}" cy="{y1:.1f}" r="6" fill="{colour}"/>')
        A(f'<line x1="{x+10:.1f}" y1="{y1:.1f}" x2="{CAPX-16}" y2="{y1:.1f}" '
          f'stroke="{colour}" stroke-width="1" stroke-dasharray="3 4" opacity="0.4"/>')

    # ribbons
    for cid in order:
        w, colour = char[cid][1] * S, char[cid][2]
        for i in range(n - 1):
            if cid not in VY[i] or cid not in VY[i+1]:
                continue
            d = vribbon(VY[i][cid], ys[i], VY[i+1][cid], ys[i+1], w)
            if i in spec.get("dashed", {}).get(cid, ()):
                A(f'<path d="{d}" fill="{fill_of(cid)}" '
                  f'fill-opacity="{0.3 if CB else 0.16}"/>')
                A(f'<path d="{d}" fill="none" stroke="{colour}" stroke-width="1.5" '
                  f'stroke-dasharray="7 5" opacity="0.95"/>')
            else:
                A(f'<path d="{d}" fill="{fill_of(cid)}" '
                  f'fill-opacity="{1 if CB else 0.82}"/>')

    edge = spec.get("edge")
    if edge in ("top", "both"):
        for cid in order:
            if cid in VY[0]:
                x, w, col = VY[0][cid] - 0, char[cid][1] * S, char[cid][2]
                A(f'<path d="{vribbon(x, ys[0]-58, x, ys[0], 2, w)}" fill="{fill_of(cid)}" '
                  f'fill-opacity="{1 if CB else 0.72}"/>')
    if edge in ("bottom", "both"):
        for cid in order:
            if cid in VY[-1]:
                x, w, col = VY[-1][cid], char[cid][1] * S, char[cid][2]
                A(f'<path d="{vribbon(x, ys[-1], x, ys[-1]+58, w, 2)}" fill="{fill_of(cid)}" '
                  f'fill-opacity="{1 if CB else 0.72}"/>')

    # lane names, staggered, sized by strand weight
    present = [(VY[0][cid], cid) for cid in order if cid in VY[0]]
    tiers = lane_tiers(present, spec.get("tiers", 5))
    for x, cid in present:
        f = lab_font[cid]
        A(f'<text x="{x:.1f}" y="{44 + tiers[cid]*40 + f*0.8:.0f}" font-size="{f}" '
          f'font-weight="700" text-anchor="middle" fill="{char[cid][2]}">'
          f'{char[cid][0]}</text>')
    for x, cid in present:
        f = lab_font[cid]
        A(f'<line x1="{x:.1f}" y1="{44 + tiers[cid]*40 + f*0.8 + 7:.0f}" x2="{x:.1f}" '
          f'y2="{ys[0]-14}" stroke="{char[cid][2]}" stroke-width="1" opacity="0.28"/>')

    # semantic bands
    for text, x0, x1 in spec.get("bands", []):
        A(f'<text x="{(x0+x1)/2:.0f}" y="{band_y}" font-size="{F["band"]}" '
          f'font-weight="700" letter-spacing="2" text-anchor="middle" '
          f'fill="#b3aa9d">{text}</text>')

    # legend: type size follows strand weight
    ly = legend_y
    A(f'<text x="60" y="{ly-16}" font-size="{F["legend_title"]}" font-weight="700" '
      f'letter-spacing="1.1" fill="#9a9086">{spec["legend_title"]}</text>')
    cx, cy = 60.0, ly
    for cid in order:
        label, w, colour = char[cid]
        f = spec["legend_font"][cid]
        disp = max(6, round(w * S))
        item = disp + 6 + len(label) * f * 0.56 + 22
        if cx + item > W - 60:
            cx, cy = 60.0, cy + lfont * 1.5
        sh = max(11 if CB else 9, round(f * 0.62 * (1.3 if CB else 1)))
        A(f'<rect x="{cx:.0f}" y="{cy + f*0.78 - sh/2:.0f}" width="{max(disp, 11) if CB else disp}" '
          f'height="{sh}" rx="2" fill="{fill_of(cid)}" '
          f'fill-opacity="{1 if CB else 0.85}"/>')
        A(f'<text x="{cx+disp+6:.0f}" y="{cy + f*0.78:.0f}" font-size="{f}" '
          f'font-weight="600" fill="#2b2622">{label}</text>')
        cx += item
    if spec.get("legend_note"):
        A(f'<text x="60" y="{note_y:.0f}" font-size="{F["legend_title"]+1}" '
          f'font-style="italic" fill="#8b8377">{spec["legend_note"]}</text>')

    # title block
    A(f'<line x1="60" y1="{rule_y}" x2="{W-60}" y2="{rule_y}" stroke="#ded7cb"/>')
    for k, (txt, sty) in enumerate(spec["title"]):
        y = title_top + k * 26
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
    for i, row in enumerate(VY):
        items = sorted((x, cid) for cid, x in row.items())
        for (x1, c1), (x2, c2) in zip(items, items[1:]):
            g = (x2 - char[c2][1] * S / 2) - (x1 + char[c1][1] * S / 2)
            if g < 0.5:
                bad.append((i, c1, c2, round(g, 1)))
    return "\n".join(svg), {"lane_overlaps": bad, "H": H, "legend_rows": lrows}
