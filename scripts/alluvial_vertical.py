#!/usr/bin/env python3
"""Vertical alluvial renderer - Normal People, series version.

Transposes the horizontal engine: time runs DOWN the page, each character owns
a vertical lane instead of a horizontal track, and the semantic bands become
left-to-right:

    FAMILY / THE PRIVATE  |  Connell & Marianne  |  THE SOCIAL WORLD

Lane x comes from mirroring the horizontal layout (x = 420 + (620 - old_y) * S)
and ribbon widths scale by the same S, so the merged pairs still touch exactly.

Everything textual lives in two safe places - the lane-name tiers at the top and
the caption column down the right - so no label can ever sit on a ribbon.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import alluvial_np2 as D          # guarded data module (renders only under __main__)

OUT = os.path.expanduser("/home/installer/hermes/projects/alluvial/out")

S = 0.60                                  # distance AND width scale (both, so merged pairs still touch)
GAP = 5 * S
SPINE_X = 420.0
SPINE_OLD = 620.0

fx = lambda old: SPINE_X + (SPINE_OLD - old) * S          # lane y -> lane x
fw = lambda w: max(4.0, round(w * S, 1))                  # ribbon width

VCHAR = {k: (lab, fw(w), col) for k, (lab, w, col) in D.SC.items()}
VORDER = [c for c in D.SORDER]

W = 1120                                  # ~1100px: readable at desktop Slack width
ROW0, ROWSTEP = 300.0, 195.0
CAPX = 690.0                              # caption column
LANE_HI = 650.0


def vstack(centre, ids):
    """Stack ids along x. Reversed order: mirrors the horizontal stacking, so a
    group that ran top-to-bottom now runs right-to-left."""
    ids = list(reversed(ids))
    total = sum(VCHAR[c][1] for c in ids) + GAP * (len(ids) - 1)
    x = centre - total / 2
    out = {}
    for c in ids:
        w = VCHAR[c][1]
        out[c] = x + w / 2
        x += w + GAP
    return out


def vribbon(x0, y0, x1, y1, w0, w1=None):
    """Downward band: travel in y, thickness in x."""
    w1 = w0 if w1 is None else w1
    a, b_ = w0 / 2, w1 / 2
    ym0, ym1 = y0 + (y1 - y0) * 0.42, y0 + (y1 - y0) * 0.58
    return (f"M {x0-a:.1f} {y0:.1f} "
            f"C {x0-a:.1f} {ym0:.1f} {x1-b_:.1f} {ym1:.1f} {x1-b_:.1f} {y1:.1f} "
            f"L {x1+b_:.1f} {y1:.1f} "
            f"C {x1+b_:.1f} {ym1:.1f} {x0+a:.1f} {ym0:.1f} {x0+a:.1f} {y0:.1f} Z")


def lane_tiers(lanes, font, tiers=4):
    """Assign each lane name a tier so no two labels on a tier overlap."""
    last = [None] * tiers
    out = {}
    for x, cid in sorted(lanes):
        label = VCHAR[cid][0]
        half = len(label) * font * 0.29
        for t in range(tiers):
            if last[t] is None or x - half > last[t] + 10:
                out[cid] = t
                last[t] = x + half
                break
        else:
            out[cid] = tiers - 1
    return out


def render_v(spec):
    cols, xs_rows = spec["cols"], spec["ys"]
    n = len(cols)
    VY = []
    for c in cols:
        row = {}
        for centre, ids in c["groups"]:
            row.update(vstack(fx(centre), ids))
        VY.append(row)

    F = spec["fonts"]
    H = spec["H"]
    svg = []
    A = svg.append
    A(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
      f'viewBox="0 0 {W} {H}" font-family="Helvetica, Arial, sans-serif">')
    A('<defs><pattern id="dots" width="26" height="26" patternUnits="userSpaceOnUse">'
      '<circle cx="1" cy="1" r="0.9" fill="#d8d2c8"/></pattern></defs>')
    A(f'<rect width="{W}" height="{H}" fill="#faf7f2"/>')
    A(f'<rect x="0" y="{ROW0-90}" width="{W}" height="{xs_rows[-1]-ROW0+180}" '
      f'fill="url(#dots)" opacity="0.55"/>')

    # rows: dotted guide + tick toward the caption column
    for y in xs_rows:
        A(f'<line x1="70" y1="{y}" x2="{LANE_HI}" y2="{y}" stroke="#c9c2b6" '
          f'stroke-width="1" stroke-dasharray="2 5"/>')
        A(f'<line x1="{LANE_HI}" y1="{y}" x2="{CAPX-14}" y2="{y}" stroke="#ded7cb" '
          f'stroke-width="1"/>')

    # caption column
    for i, c in enumerate(cols):
        y = xs_rows[i]
        A(f'<text x="{CAPX}" y="{y-12}" font-size="{F["beat"]}" font-weight="700" '
          f'fill="#2b2622" letter-spacing="1.2">{c["beat"]}</text>')
        A(f'<text x="{CAPX}" y="{y+16}" font-size="{F["loc"]}" fill="#9a9086" '
          f'letter-spacing="0.2">{c["loc"]}</text>')
        for j, t in enumerate(c["cap"]):
            A(f'<text x="{CAPX}" y="{y+46+j*25}" font-size="{F["cap"]}" '
              f'font-style="italic" fill="#7d7568">{t}</text>')
        if c.get("hard"):
            A(f'<text x="{CAPX}" y="{y+46+len(c["cap"])*25+8}" font-size="{F["hard"]}" '
              f'font-weight="700" fill="#9c3b34">{c["hard"]}</text>')
        if c.get("cap_extra"):
            txt, colr = c["cap_extra"]
            A(f'<text x="{CAPX}" y="{y+126}" font-size="{F["hard"]-1}" font-weight="700" '
              f'fill="{colr}">{txt}</text>')

    # entrance / exit tapers, breaks, fades
    for i, c in enumerate(cols):
        for (cid, kind, _y) in c.get("stubs", []):
            x, y = VY[i][cid], xs_rows[i]
            w, colour = VCHAR[cid][1], VCHAR[cid][2]
            if kind == "in":
                A(f'<path d="{vribbon(x, y-58, x, y, 2, w)}" fill="{colour}" '
                  f'fill-opacity="0.8"/>')
            elif kind == "out":
                A(f'<path d="{vribbon(x, y, x, y+58, w, 2)}" fill="{colour}" '
                  f'fill-opacity="0.8"/>')
            elif kind == "break":
                A(f'<path d="{vribbon(x, y, x, y+46, w, 2)}" fill="{colour}" '
                  f'fill-opacity="0.85"/>')
                bx, by = x + max(12, w), y + 34
                for dx, dy in ((9, -9), (9, 9)):
                    A(f'<line x1="{bx-dx}" y1="{by+dy}" x2="{bx+dx}" y2="{by-dy}" '
                      f'stroke="#9c3b34" stroke-width="2"/>')
            elif kind == "fade":
                # the coda: each lead drifts outward, away from the other
                drift = 20 if x > SPINE_X else -20
                A(f'<path d="{vribbon(x, y, x+drift, y+135, w, 2)}" fill="{colour}" '
                  f'fill-opacity="0.34"/>')

    # terminals: a life that ends
    for i, c in enumerate(cols):
        if "terminal" not in c:
            continue
        cid, _ = c["terminal"]
        x = VY[i-1][cid]
        colour = VCHAR[cid][2]
        y0 = xs_rows[i-1]
        y1 = xs_rows[i-1] + (xs_rows[i] - xs_rows[i-1]) * 0.60
        A(f'<path d="{vribbon(x, y0, x, y1, VCHAR[cid][1], 2)}" fill="{colour}" '
          f'fill-opacity="0.55"/>')
        A(f'<circle cx="{x:.1f}" cy="{y1:.1f}" r="6" fill="{colour}"/>')
        A(f'<line x1="{x+10:.1f}" y1="{y1:.1f}" x2="{CAPX-16}" y2="{y1:.1f}" '
          f'stroke="{colour}" stroke-width="1" stroke-dasharray="3 4" opacity="0.4"/>')

    # ribbons
    for cid in VORDER:
        w, colour = VCHAR[cid][1], VCHAR[cid][2]
        for i in range(n - 1):
            if cid not in VY[i] or cid not in VY[i+1]:
                continue
            d = vribbon(VY[i][cid], xs_rows[i], VY[i+1][cid], xs_rows[i+1], w)
            if i in spec.get("dashed", {}).get(cid, ()):
                A(f'<path d="{d}" fill="{colour}" fill-opacity="0.16"/>')
                A(f'<path d="{d}" fill="none" stroke="{colour}" stroke-width="1.5" '
                  f'stroke-dasharray="7 5" opacity="0.95"/>')
            else:
                A(f'<path d="{d}" fill="{colour}" fill-opacity="0.82"/>')

    # seam stubs at a panel edge
    edge = spec.get("edge")
    if edge in ("top", "both"):
        for cid in VORDER:
            if cid in VY[0]:
                x, w, col = VY[0][cid], VCHAR[cid][1], VCHAR[cid][2]
                A(f'<path d="{vribbon(x, xs_rows[0]-58, x, xs_rows[0], 2, w)}" '
                  f'fill="{col}" fill-opacity="0.72"/>')
    if edge in ("bottom", "both"):
        for cid in VORDER:
            if cid in VY[-1]:
                x, w, col = VY[-1][cid], VCHAR[cid][1], VCHAR[cid][2]
                A(f'<path d="{vribbon(x, xs_rows[-1], x, xs_rows[-1]+58, w, 2)}" '
                  f'fill="{col}" fill-opacity="0.72"/>')

    # lane names, staggered over three tiers
    present = [(VY[0][cid], cid) for cid in VORDER if cid in VY[0]]
    tiers = lane_tiers(present, F["strand"])
    for x, cid in present:
        A(f'<text x="{x:.1f}" y="{62 + tiers[cid]*38}" font-size="{F["strand"]}" '
          f'font-weight="700" text-anchor="middle" fill="{VCHAR[cid][2]}">'
          f'{VCHAR[cid][0]}</text>')
    for x, cid in present:                     # hairline down to the first row
        A(f'<line x1="{x:.1f}" y1="{62 + tiers[cid]*38 + 7}" x2="{x:.1f}" '
          f'y2="{ROW0-14}" stroke="{VCHAR[cid][2]}" stroke-width="1" opacity="0.28"/>')

    # semantic bands, under the flow
    band_y = spec["band_y"]
    for text, x0, x1 in spec["bands"]:
        A(f'<text x="{(x0+x1)/2:.0f}" y="{band_y}" font-size="{F["band"]}" '
          f'font-weight="700" letter-spacing="2" text-anchor="middle" '
          f'fill="#b3aa9d">{text}</text>')

    # legend (wraps to a second row if needed)
    ly = spec["legend_y"]
    A(f'<text x="60" y="{ly-16}" font-size="{F["legend"]-2}" font-weight="700" '
      f'letter-spacing="1.2" fill="#9a9086">{spec["legend_title"]}</text>')
    cx, cy = 60, ly
    for cid in VORDER:
        label, w, colour = VCHAR[cid]
        disp = max(14, int(w))
        item = disp + 6 + len(label) * F["legend"] * 0.56 + 22
        if cx + item > W - 60:
            cx, cy = 60, cy + 26
        A(f'<rect x="{cx:.0f}" y="{cy}" width="{disp}" height="{13}" rx="3" '
          f'fill="{colour}" fill-opacity="0.85"/>')
        A(f'<text x="{cx+disp+6:.0f}" y="{cy+12}" font-size="{F["legend"]}" '
          f'font-weight="600" fill="#2b2622">{label}</text>')
        cx += item
    A(f'<text x="{W-60}" y="{cy+12}" font-size="{F["legend"]-1}" fill="#8b8377" '
      f'text-anchor="end">{spec["legend_note"]}</text>')

    # title block
    A(f'<line x1="60" y1="{spec["rule_y"]}" x2="{W-60}" y2="{spec["rule_y"]}" '
      f'stroke="#ded7cb"/>')
    for k, (txt, sty) in enumerate(spec["title"]):
        y = spec["title_top"] + k * 26
        if sty == "title":
            A(f'<text x="60" y="{y}" font-family="Georgia, serif" '
              f'font-size="{F["title"]}" fill="#22201d">{txt}</text>')
        elif sty == "sub":
            A(f'<text x="60" y="{y}" font-size="{F["sub"]}" fill="#6f675c">{txt}</text>')
        else:
            A(f'<text x="60" y="{y}" font-size="{F["sub2"]}" font-style="italic" '
              f'fill="#9a9086">{txt}</text>')
    A('</svg>')

    # per-row lateral overlap check
    bad = []
    for i, row in enumerate(VY):
        items = sorted((x, cid) for cid, x in row.items())
        for (x1, c1), (x2, c2) in zip(items, items[1:]):
            g = (x2 - VCHAR[c2][1] / 2) - (x1 + VCHAR[c1][1] / 2)
            if g < 0.5:
                bad.append((i, c1, c2, round(g, 1)))
    return "\n".join(svg), bad


FONTS_V = dict(beat=21, loc=17, cap=17, hard=17, strand=18, end=17,
               band=15, legend=14, legend_title=14, title=32, sub=16, sub2=15)

# Rob's death and Denise's refusal carry their own line in the caption column.
TERMINAL_NOTE = ("\u25b8 Rob takes his own life \u2014 the strand ends", "#6f8f96")
BREAK_NOTE = ("\u25b8 her mother stops speaking \u2014 the strand breaks", "#9c3b34")


def legend_rows():
    """How many rows the legend needs at this width, so the footer can be sized."""
    cx, rows = 60.0, 1
    for cid in VORDER:
        label, w, _ = VCHAR[cid]
        disp = max(14, int(w))
        item = disp + 6 + len(label) * FONTS_V["legend"] * 0.56 + 22
        if cx + item > W - 60:
            rows += 1
            cx = 60.0
        cx += item
    return rows


def build(panel):
    slices = D.SCOLS[0:6] if panel == "a" else D.SCOLS[6:13]
    cols = []
    for c in slices:
        c = dict(c)
        if c.get("terminal") and panel == "b":
            c["cap_extra"] = TERMINAL_NOTE
        if any(s[1] == "break" for s in c.get("stubs", [])):
            c["cap_extra"] = BREAK_NOTE
        cols.append(c)
    rows = [ROW0 + i * ROWSTEP for i in range(len(cols))]
    last = rows[-1]
    # footer: bands must clear the DEEPEST caption block on the last row
    depth = max(46 + 25 * len(c["cap"]) + (8 if c.get("hard") else 0)
                + (26 if c.get("cap_extra") else 0) for c in cols)
    band_y = last + depth + 26
    legend_y = band_y + 58
    legend_bottom = legend_y + (legend_rows() - 1) * 26 + 13
    rule_y = legend_bottom + 42
    title_top = rule_y + 34
    H = int(title_top + 3 * 26 + 30)
    title = ([("Normal People \u2014 the braid, vertical (panel A of 2)", "title"),
              ("Time runs down the page. Episodes 1\u20136.", "sub"),
              ("Left of centre: family and the private. Centre: the two of them. "
               "Right: the social world \u2014 school, Trinity, and the partners.", "note"),
              ("Where the two centre lanes touch, they are together. Panel B carries on "
               "from the summer of episode 6.", "note")]
             if panel == "a" else
             [("Normal People \u2014 the braid, vertical (panel B of 2)", "title"),
              ("Episode 7 to the coda. The separated years.", "sub"),
              ("Every lane that pulls away from the centre is a person one of them "
               "chose instead.", "note"),
              ("At the coda the two leads fade outward, in opposite directions, and stop. "
               "The braid does not resolve.", "note")])
    return dict(cols=cols, ys=rows, dashed=D.SDASH, fonts=FONTS_V, H=H,
                band_y=band_y, legend_y=legend_y, rule_y=rule_y, title_top=title_top,
                edge=("bottom" if panel == "a" else "top"),
                bands=[("FAMILY / THE PRIVATE", 60, 300), ("THE TWO OF THEM", 330, 560),
                       ("THE SOCIAL WORLD", 570, 700)],
                legend_title="STRANDS \u2014 the two leads are the two saturated lanes",
                legend_note="hatched lane = off-page that episode",
                title=title)


def main():
    for panel in ("a", "b"):
        svg, bad = render_v(build(panel))
        p = f"{OUT}/np-vertical-{panel}.svg"
        open(p, "w").write(svg)
        print(f"np-vertical-{panel}: {len(svg)}B  lane_overlaps={bad or 'none'}  "
              f"rows={len(build(panel)['cols'])}")


if __name__ == "__main__":
    main()
