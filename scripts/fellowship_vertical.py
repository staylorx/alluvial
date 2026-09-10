#!/usr/bin/env python3
"""Fellowship of the Ring - vertical alluvial.

Eleven strands, nine beats, time running down the page. Row spacing follows the
film's own runtime (0-8-25-33-45-58-70-84-96%), so the gaps are data.

Label type scales with strand weight: the legend and the lane names are sized
from ribbon width, so the hierarchy is readable at a glance in a cast this big.
Geometry is the old horizontal chart's strand layout mapped straight into column
space (no mirror), so the two orientations agree strand for strand.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from alluvial_vlib import render_v, width_fonts

OUT = os.path.expanduser("/home/installer/hermes/projects/alluvial/out")

CHAR = {                                   # id: (label, width, colour)
    "frodo":   ("Frodo",   30, "#1f5fd0"),
    "sam":     ("Sam",     22, "#c2740a"),
    "merry":   ("Merry",   16, "#1e8a44"),
    "pippin":  ("Pippin",  16, "#6f9a10"),
    "gandalf": ("Gandalf", 26, "#7040c8"),
    "aragorn": ("Aragorn", 24, "#0d7266"),
    "boromir": ("Boromir", 18, "#c62b2b"),
    "legolas": ("Legolas", 12, "#0b87ab"),
    "gimli":   ("Gimli",   12, "#a2560c"),
    "gollum":  ("Gollum",  14, "#6b7280"),
    "bilbo":   ("Bilbo",   12, "#cf3a86"),
}
ORDER = ["frodo", "sam", "merry", "pippin", "gandalf", "aragorn",
         "boromir", "legolas", "gimli", "gollum", "bilbo"]
DASHED = {"gandalf": {4, 5, 6, 7}, "gollum": {5, 6}}

COLS = [
 dict(beat="THE SHIRE", loc="first 8% of the film",
      cap=["Bag End and the Long-expected Party",
           "Frodo inherits; Gandalf rides off"],
      groups=[(340, ["gandalf", "frodo"]), (560, ["sam"]), (180, ["bilbo"])],
      stubs=[("bilbo", "out", 180)]),

 dict(beat="THE ROAD TO BREE", loc="8\u201325%",
      cap=["Bucklebury, the Old Forest, Bree",
           "the Ringwraiths are already riding"],
      groups=[(520, ["frodo", "sam", "merry", "pippin"]),
              (150, ["gandalf"]), (860, ["aragorn"])],
      enter=["merry", "pippin", "aragorn"],
      stubs=[("merry", "in", None), ("pippin", "in", None), ("aragorn", "in", None)]),

 dict(beat="WEATHERTOP \u2192 THE FORD", loc="25\u201333%",
      cap=["Frodo is wounded; the Riders close in",
           "Aragorn carries the company to Rivendell"],
      groups=[(560, ["frodo", "sam", "merry", "pippin", "aragorn"]),
              (150, ["gandalf"])]),

 dict(beat="RIVENDELL \u2014 THE COUNCIL", loc="33\u201345%",
      cap=["The nine walkers are chosen",
           "\u2605 every strand merges"],
      groups=[(640, ["frodo", "sam", "merry", "pippin", "gandalf",
                     "aragorn", "boromir", "legolas", "gimli"]),
              (1020, ["bilbo"])],
      enter=["boromir", "legolas", "gimli"],
      stubs=[("boromir", "in", None), ("bilbo", "in", 1020), ("bilbo", "out", 1020)]),

 dict(beat="MORIA", loc="45\u201358%",
      cap=["Khazad-d\u00fbm and the Bridge",
           "Gandalf falls \u2014 the strand detaches"],
      hard="\u25b8 one lane leaves the bus and does not come back",
      groups=[(640, ["frodo", "sam", "merry", "pippin",
                     "aragorn", "boromir", "legolas", "gimli"]),
              (140, ["gandalf"])]),

 dict(beat="LOTHL\u00d3RIEN", loc="58\u201370%",
      cap=["Galadriel's mirror; the company mourns",
           "eight lanes, still side by side"],
      groups=[(640, ["frodo", "sam", "merry", "pippin",
                     "aragorn", "boromir", "legolas", "gimli"]),
              (120, ["gandalf"]), (1030, ["gollum"])],
      enter=["gollum"],
      stubs=[("gollum", "in", 1030)]),

 dict(beat="THE GREAT RIVER", loc="70\u201384%",
      cap=["The Anduin, and Boromir's betrayal",
           "the widest the company ever is"],
      groups=[(640, ["frodo", "sam", "merry", "pippin",
                     "aragorn", "boromir", "legolas", "gimli"]),
              (120, ["gandalf"]), (1030, ["gollum"])]),

 dict(beat="AMON HEN \u2014 THE BREAKING", loc="84\u201396%",
      cap=["The Fellowship sunders",
           "one bus \u2192 three stories"],
      hard="\u25b8 Boromir's lane ends here",
      groups=[(300, ["frodo", "sam"]), (620, ["merry", "pippin"]),
              (900, ["aragorn", "legolas", "gimli"]),
              (1010, ["gollum"]), (110, ["gandalf"])],
      terminal=("boromir", 745)),

 dict(beat="INTO THE TWO TOWERS", loc="last 4%",
      cap=["Three separate stories begin",
           "the lanes never fully rejoin"],
      groups=[(320, ["frodo", "sam"]), (400, ["gollum"]),
              (650, ["merry", "pippin"]),
              (940, ["aragorn", "legolas", "gimli"]), (110, ["gandalf"])]),
]

RUNTIME = [0, 8, 25, 33, 45, 58, 70, 84, 96]     # percent marks behind the beats
ROW0 = 300.0


def ys_from_runtime(marks, base=132.0, per_point=4.2, floor_=8.0):
    ys, last = [], None
    for i, m in enumerate(marks):
        if i == 0:
            y = ROW0
        else:
            gap = marks[i] - marks[i - 1]
            y = last + base + (gap - floor_) * per_point
        ys.append(y)
        last = y
    return ys


CB_NOTE = ("Colour-blind mode: every strand carries its own symbol, and the darkest "
           "ribbons are the heaviest. Hue is decoration only.")


def build(cb=False):
    ys = ys_from_runtime(RUNTIME)
    char = {k: (l, w, c) for k, (l, w, c) in CHAR.items()}
    lab = width_fonts(char, base=24.0, lo=15.0, hi=26.0)
    return dict(
        char=char, order=ORDER, cols=COLS, ys=ys, dashed=DASHED, cb_safe=cb,
        scale=0.62, origin=480.0, spine_old=640.0, mirror=False,
        W=1220, CAPX=800.0, LANE_HI=760.0,
        label_font=lab, legend_font=lab, tiers=5,
        fonts=dict(beat=21, loc=17, cap=17, hard=17, band=15, legend_title=14,
                   title=32, sub=16, sub2=15),
        bands=[],
        legend_title=("STRANDS \u2014 label size follows strand width"
                      + (", symbol = identity, darkness = weight" if cb else "")),
        legend_note="hatched lane = off-page, still in the story",
        title=[("The Fellowship of the Ring \u2014 eleven strands, vertically", "title"),
               ("Time runs down the page; each lane is one character. Row spacing follows the "
                "film's own runtime, so the gaps are data.", "sub"),
               ("Where lanes sit side by side, they are travelling together. The nine-walker bus "
                "forms at Rivendell and shatters at Amon Hen.", "note"),
               ("Label size follows ribbon width \u2014 it is a rough measure of presence in the "
                "film, not of worth.", "note")]
             + ([(CB_NOTE, "note"),
                 ("Hatched lanes keep their symbol, so off-page stays readable.", "note")]
                if cb else []))


def main():
    cb = "--cb" in sys.argv
    spec = build(cb)
    svg, checks = render_v(spec)
    name = "lotr-vertical-cb" if cb else "lotr-vertical"
    open(f"{OUT}/{name}.svg", "w").write(svg)
    print(f"{name}: {len(svg)}B  overlaps={checks['lane_overlaps'] or 'none'}  "
          f"H={checks['H']} legend_rows={checks['legend_rows']}")
    if not cb:
        print("label sizes:", {CHAR[k][0]: spec['label_font'][k] for k in ORDER})
        print("row ys:", [round(y) for y in spec['ys']])


if __name__ == "__main__":
    main()
