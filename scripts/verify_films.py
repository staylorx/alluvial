#!/usr/bin/env python3
"""Batch-verify every film in films/ before anything is published.

Checks each file for the schema's hard limits, then renders the chart and looks
for the failure modes that only show up in the drawing: lanes overlapping,
caption lines running into each other or into the next beat, and text that would
print outside the canvas.

Usage:
  python3 verify_films.py            # every film, summary + failures
  python3 verify_films.py <slug> ... # just these
Exit code is non-zero if any film FAILS a check, so it can gate a publish.
"""
from __future__ import annotations

import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import film_chart as FC          # noqa: E402
import rubric27                  # noqa: E402

MAX_BEATS, MAX_LANES, CAP_LINES, CAP_CHARS = 13, 8, 2, 62
CAT_IDS = set(rubric27.BY_ID)

TEXT_RE = re.compile(
    r'<text[^>]*x="([-\d.]+)"[^>]*y="([-\d.]+)"[^>]*font-size="([\d.]+)"[^>]*>(.*?)</text>',
    re.S)


def schema_errors(film: dict) -> list[str]:
    errs = []
    ids = [c["id"] for c in film.get("chars", [])]
    chars = {c["id"]: c for c in film.get("chars", [])}
    if not ids:
        return ["no chars"]
    if len(ids) > MAX_LANES:
        errs.append(f"{len(ids)} lanes (max {MAX_LANES})")
    if film.get("order") and set(film["order"]) != set(ids):
        errs.append("order does not list exactly the character ids")
    beats = film.get("beats", [])
    if not beats:
        return errs + ["no beats"]
    if len(beats) > MAX_BEATS:
        errs.append(f"{len(beats)} beats (max {MAX_BEATS})")
    for i, b in enumerate(beats, 1):
        cap = b.get("cap", [])
        if len(cap) != CAP_LINES:
            errs.append(f"beat {i}: {len(cap)} caption lines (want {CAP_LINES})")
        for ln in cap:
            if len(ln) > CAP_CHARS:
                errs.append(f"beat {i}: caption line is {len(ln)} chars (max {CAP_CHARS})")
        if not b.get("groups"):
            flat = [i2 for cl in b.get("clusters", []) for i2 in cl]
            dupes = {x for x in flat if flat.count(x) > 1}
            if dupes:
                errs.append(f"beat {i}: {sorted(dupes)} appear in more than one cluster")
            unknown = [x for x in flat + list(b.get("enter", [])) + list(b.get("stubs", []))
                       if x not in chars]
            if unknown:
                errs.append(f"beat {i}: unknown ids {sorted(set(unknown))}")
        for cid in b.get("cats") or []:
            if cid not in CAT_IDS:
                errs.append(f"beat {i}: unknown rubric id '{cid}'")
    return errs


def text_boxes(svg: str) -> list[tuple[float, float, float, float, str]]:
    """Approximate bbox per <text>: width from char count x 0.55em."""
    out = []
    for m in TEXT_RE.finditer(svg):
        x, y, fs, body = float(m.group(1)), float(m.group(2)), float(m.group(3)), m.group(4)
        txt = re.sub(r"<[^>]+>", "", body).strip()
        if not txt:
            continue
        w = len(txt) * fs * 0.55
        out.append((x, y - fs * 0.8, x + w, y + fs * 0.25, txt))
    return out


def collisions(boxes, min_dx=6.0, min_dy=3.0):
    """Overlap in BOTH axes by more than a hair.

    The bbox is an approximation (char count x 0.55em, no real font metrics), so
    the thresholds are set to catch a genuine print-on-print collision without
    firing on labels that merely sit near each other. Calibrated against the
    hand-tuned 27 Dresses chart, which must come back clean.
    """
    hits = []
    for i in range(len(boxes)):
        for j in range(i + 1, len(boxes)):
            a, b = boxes[i], boxes[j]
            dx = min(a[2], b[2]) - max(a[0], b[0])
            dy = min(a[3], b[3]) - max(a[1], b[1])
            if dx > min_dx and dy > min_dy:
                hits.append((a[4][:34], b[4][:34], round(dx, 1), round(dy, 1)))
    return hits


def check(slug: str) -> tuple[bool, list[str], list[str]]:
    film = FC.load(slug)
    errs = schema_errors(film)
    notes = []
    if errs:
        return False, errs, notes
    for label, mini in (("chart", False), ("mini", True)):
        svg, spec, H, chk = FC.render(film, mini=mini)
        W = spec["W"]
        boxes = text_boxes(svg)
        out_of_canvas = [t for (x0, y0, x1, y1, t) in boxes if x1 > W - 2 or x0 < 2 or y1 > H + 40]
        cross = collisions(boxes)
        if out_of_canvas:
            errs.append(f"{label}: {len(out_of_canvas)} text box(es) outside the canvas, "
                        f"e.g. {out_of_canvas[0][:40]!r}")
        if chk.get("lane_overlaps"):
            errs.append(f"{label}: lanes overlap at {len(chk['lane_overlaps'])} place(s)")
        # text overlap is approximate here (no real font metrics): triage, not a gate.
        # The authoritative pass is the browser getBBox scan before publishing.
        notes.append(f"{label}: H={H:.0f} texts={len(boxes)} overlaps~{len(cross)}"
                     + (f" (worst {cross[0][0]!r}x{cross[0][1]!r} {cross[0][2]}x{cross[0][3]}px)"
                        if cross else ""))
    return not errs, errs, notes


def main(argv):
    slugs = argv or [os.path.basename(p)[:-5] for p in sorted(glob.glob(
        os.path.join(FC.FILMS, "*.json")))]
    bad = []
    for slug in slugs:
        try:
            ok, errs, notes = check(slug)
        except Exception as exc:                      # malformed JSON should not stop the sweep
            ok, errs, notes = False, [f"{type(exc).__name__}: {exc}"], []
        print(f"{'OK  ' if ok else 'FAIL'} {slug:36s} " + "; ".join(notes))
        for e in errs:
            print(f"       - {e}")
        if not ok:
            bad.append(slug)
    print(f"\n{len(slugs) - len(bad)}/{len(slugs)} pass"
          + (f" | failing: {', '.join(bad)}" if bad else ""))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
