#!/usr/bin/env python3
"""27 Dresses (2008) - vertical alluvial, tagged with the 27-point romcom rubric.

The house the rubric is named for. Six lanes, eleven beats, time running down
the page. Each beat carries the rubric category it actually earns, so the chart
doubles as the scoring sheet for the nominal 100% anchor.

Lane geometry is order-preserving (no mirror): the wrong pair sits to the right
of the couple, so you can watch Jane's attention travel there and come back.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from alluvial_vlib import render_v, width_fonts

OUT = os.path.expanduser("/home/installer/hermes/projects/alluvial/out")

CHAR = {                                   # id: (label, width, colour)
    "jane":    ("Jane",        34, "#1b57c4"),
    "kevin":   ("Kevin",       28, "#d0316a"),
    "george":  ("George",      18, "#6e9078"),
    "tess":    ("Tess",        18, "#9c6552"),
    "casey":   ("Casey",       14, "#b09a4e"),
    "dresses": ("the dresses", 12, "#b08a94"),
}
ORDER = ["dresses", "casey", "jane", "kevin", "george", "tess"]
DASHED = {}
TAG = "#8a6a1f"

# track coordinates in lane space (mirror=False: smaller = further left)
COLS = [
 dict(beat="TWO WEDDINGS, ONE NIGHT", loc="\u2248 0\u201310 min",
      cap=["Jane has been a bridesmaid 27 times",
           "she shares a cab with a man in a tux"],
      cap_extra=("\u25b8 MEET-CUTE \u2014 an entrance, not a marriage", TAG),
      groups=[(120, ["dresses"]), (500, ["jane", "kevin"])]),

 dict(beat="THE COLUMN", loc="\u2248 10\u201325 min",
      cap=["George is back from the climbing trip",
           "Kevin writes the column Jane despises"],
      cap_extra=("\u25b8 CHEMISTRY \u2014 they argue beautifully", TAG),
      groups=[(120, ["dresses"]), (300, ["casey"]), (460, ["jane"]),
              (700, ["george"]), (580, ["kevin"])],
      enter=["casey"]),

 dict(beat="TESS COMES HOME", loc="\u2248 25\u201335 min",
      cap=["Six months in Europe, one engagement party",
           "Tess catches George before Jane can speak"],
      cap_extra=("\u25b8 the loyalty trap springs", TAG),
      groups=[(120, ["dresses"]), (300, ["casey"]), (460, ["jane"]),
              (750, ["george", "tess"]), (580, ["kevin"])],
      enter=["tess"]),

 dict(beat="THE ENGAGEMENT", loc="\u2248 35\u201350 min",
      cap=["Vegetarian, dogs, the outdoors \u2014 all borrowed",
           "their mother's dress goes to Tess"],
      cap_extra=("\u25b8 BFF \u2014 Casey, doing the actual work", TAG),
      groups=[(120, ["dresses"]), (300, ["casey"]), (460, ["jane"]),
              (750, ["george", "tess"]), (580, ["kevin"])]),

 dict(beat="THE BOATHOUSE", loc="\u2248 50\u201362 min",
      cap=["Jane plans her own dream wedding for her sister",
           "Malcolm Doyle turns out to be Kevin"],
      cap_extra=("\u25b8 chemistry, second gear", TAG),
      groups=[(120, ["dresses"]), (300, ["casey"]), (460, ["jane"]),
              (750, ["george", "tess"]), (540, ["kevin"])]),

 dict(beat="THE CLOSET", loc="\u2248 62\u201370 min",
      cap=["Twenty-seven dresses, one fashion show",
           "the bride's happiness is paramount"],
      cap_extra=("\u25b8 the scene the film is remembered for", TAG),
      groups=[(120, ["dresses"]), (300, ["casey"]), (480, ["jane", "kevin"]),
              (750, ["george", "tess"])]),

 dict(beat="THE ARTICLE", loc="\u2248 70\u201380 min",
      cap=["The piece runs without her knowing",
           "she ends it, and she is not wrong to"],
      cap_extra=("\u25b8 BREAKUP \u2014 it flows from who he is", TAG),
      groups=[(120, ["dresses"]), (300, ["casey"]), (460, ["jane"]),
              (750, ["george", "tess"]), (610, ["kevin"])]),

 dict(beat="THE SLIDESHOW", loc="\u2248 80\u201395 min",
      cap=["Tess cuts up the dress; Jane retaliates",
           "George sees the dishonesty and cancels"],
      cap_extra=("\u25b8 her sister's lane snaps off", TAG),
      groups=[(120, ["dresses"]), (300, ["casey"]), (460, ["jane"]),
              (700, ["george"]), (620, ["kevin"]), (830, ["tess"])],
      stubs=[("tess", "out", None)]),

 dict(beat="THE EMPTY VICTORY", loc="\u2248 95\u2013102 min",
      cap=["George praises her reliability",
           "she quits, and the crush has gone quiet"],
      cap_extra=("\u25b8 the dark night, kept short", TAG),
      groups=[(120, ["dresses"]), (300, ["casey"]), (460, ["jane"]),
              (760, ["george"]), (620, ["kevin"])],
      stubs=[("george", "out", None)]),

 dict(beat="ANOTHER WEDDING", loc="\u2248 102\u2013109 min",
      cap=["She finds him at somebody else's wedding",
           "and says it first, in front of strangers"],
      cap_extra=("\u25b8 GESTURE \u2014 and it is hers, not his", TAG),
      groups=[(120, ["dresses"]), (300, ["casey"]), (480, ["jane", "kevin"])]),

 dict(beat="ONE YEAR LATER", loc="the coda",
      cap=["The beach; all twenty-seven brides",
           "wearing what Jane wore at their weddings"],
      cap_extra=("\u25b8 the 28th dress", TAG),
      groups=[(430, ["dresses", "jane", "kevin"]), (300, ["casey"])]),
]

ROW_STEP = 165.0
ROW0 = 300.0
CODA_EXTRA = 70.0                     # a year passes before the last row


CB_NOTE = ("Colour-blind mode: each strand carries its own symbol; the darker the ribbon, "
           "the heavier the character. Hue is decoration only.")


def build(cb=False):
    ys, y = [], ROW0 - ROW_STEP
    for i in range(len(COLS)):
        y += ROW_STEP + (CODA_EXTRA if i == len(COLS) - 1 else 0.0)
        ys.append(y)
    char = dict(CHAR)
    lab = width_fonts(char, base=24.0, lo=14.0, hi=26.0)
    return dict(
        char=char, order=ORDER, cols=COLS, ys=ys, dashed=DASHED, cb_safe=cb,
        scale=0.55, origin=330.0, spine_old=500.0, mirror=False,
        W=1010, CAPX=570.0, LANE_HI=545.0,
        label_font=lab, legend_font=lab, tiers=4, line_cap=23, extra_gap=22,
        fonts=dict(beat=20, loc=16, cap=16.5, hard=16.5, band=14, legend_title=13,
                   title=31, sub=15.5, sub2=14.5),
        bands=[],
        legend_title=("LANES \u2014 label size follows strand width"
                      + (", symbol = identity, darkness = weight" if cb else "")),
        legend_note=("\u201cthe dresses\u201d is the title object, not a person. "
                     "Hatched lane = off-page."),
        title=[("27 Dresses \u2014 the house, vertically", "title"),
               ("Six lanes, eleven beats, 111 minutes. Time runs down the page.", "sub"),
               ("Row spacing widens before the coda \u2014 a year passes there.", "note"),
               ("Each beat is tagged with the rubric category it earns, so this doubles as the "
                "anchor's scoring sheet.", "note"),
               ("The house: 27 of 30, a nominal 100%. You don't ding the house the party's at.",
                "note"),
               ("Ebert's three: left unpicked. Whether the house is a true 27 is still under "
                "review.", "note")]
             + ([(CB_NOTE, "note")] if cb else []))


def main():
    cb = "--cb" in sys.argv
    spec = build(cb)
    svg, checks = render_v(spec)
    name = "27dresses-vertical-cb" if cb else "27dresses-vertical"
    open(f"{OUT}/{name}.svg", "w").write(svg)
    print(f"{name}: {len(svg)}B  overlaps={checks['lane_overlaps'] or 'none'}  "
          f"H={checks['H']} legend_rows={checks['legend_rows']}")
    if not cb:
        lab = spec["label_font"]
        print("label sizes:", {CHAR[k][0]: lab[k] for k in ORDER})
        print("row ys:", [round(y) for y in spec["ys"]])


if __name__ == "__main__":
    main()
