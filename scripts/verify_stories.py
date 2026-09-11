#!/usr/bin/env python3
"""Batch-verify every film in stories/ before anything is published.

Checks each file for the schema's hard limits, then renders the chart and looks
for the failure modes that only show up in the drawing: lanes overlapping,
caption lines running into each other or into the next beat, and text that would
print outside the canvas.

Usage:
  python3 verify_stories.py            # every film, summary + failures
  python3 verify_stories.py <slug> ... # just these
Exit code is non-zero if any film FAILS a check, so it can gate a publish.
"""
from __future__ import annotations

import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import story_chart as FC          # noqa: E402
import stories_yaml as FY          # noqa: E402
import rubric27                  # noqa: E402

MAX_BEATS, MAX_LANES, CAP_LINES, CAP_CHARS = 13, 8, 2, 62
# The form the work is told in. Absent means a film (the store's first medium);
# anything else is anchored to its own divisions rather than to minutes.
EXPRESSIONS = {"film", "play", "novel", "series", "short story", "essay", "poem",
               "song", "musical"}

TEXT_RE = re.compile(
    r'<text[^>]*x="([-\d.]+)"[^>]*y="([-\d.]+)"[^>]*font-size="([\d.]+)"[^>]*>(.*?)</text>',
    re.S)


def timechart_errors(doc: dict) -> list[str]:
    errs = []
    sc = doc.get("scenes", [])
    if not 6 <= len(sc) <= 14:
        errs.append(f"{len(sc)} scenes (want 6-14)")
    for key in ("as_screened", "happened"):
        pos = sorted(s.get(key) for s in sc)
        if pos != list(range(1, len(sc) + 1)):
            errs.append(f"{key} is not a permutation of 1..{len(sc)}")
    threads = set(doc.get("threads", {}))
    for s in sc:
        if s.get("thread") not in threads:
            errs.append(f"scene {s.get('id')!r}: thread {s.get('thread')!r} not in threads")
        if len(s.get("label", "")) > 34:
            errs.append(f"scene {s.get('id')!r}: label is {len(s['label'])} chars (max 34)")
    return errs


def schema_errors(film: dict) -> list[str]:
    errs = []
    expr = film.get("expression")
    if expr is not None and expr not in EXPRESSIONS:
        errs.append(f"expression {expr!r} is not one of {sorted(EXPRESSIONS)}")
    # Grading is DECLARED per story. A score, a score note or a beat category with
    # no declared rubric is a claim about an instrument nobody named — and a story
    # the rubric does not grade must carry none of them.
    graded = FC.rubric_for(film)
    rid = film.get("rubric")
    if rid is not None and not graded:
        errs.append(f"rubric {rid!r} is not one of {sorted(FC.RUBRICS)}")
    if not graded:
        for key in ("score", "score_note"):
            if film.get(key) is not None:
                errs.append(f"{key} present without a rubric — nothing grades this story")
    cat_ids = set(graded.BY_ID) if graded else set()
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
        if not isinstance(cap, list):
            errs.append(f"beat {i}: cap is {type(cap).__name__}, not a list")
        for ln in cap if isinstance(cap, list) else []:
            if not isinstance(ln, str):
                errs.append(f"beat {i}: caption line is {type(ln).__name__}, not a string")
            elif len(ln) > CAP_CHARS:
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
        cl = b.get("clusters") or []
        if cl == [] and not b.get("groups"):
            errs.append(f"beat {i}: no clusters at all")
        cats = b.get("cats")
        if cats is not None and not isinstance(cats, list):
            errs.append(f"beat {i}: cats is {type(cats).__name__}, not a list")
        for cid in (cats if isinstance(cats, list) else []):
            if cid not in cat_ids:
                errs.append(f"beat {i}: unknown rubric id {cid!r}")
        if not isinstance(b.get("name", ""), str) or not isinstance(b.get("tag", ""), str):
            errs.append(f"beat {i}: name/tag must be strings")
    # NOTE for future sweeps: do NOT add a rule that "a beat tagged breakup must
    # have the leads apart". A breakup beat is the scene where the split HAPPENS,
    # so the couple is normally co-located in it, and the reconciliation usually
    # follows the last one. Sweeping all 30 films with that rule flags 12 of them
    # and every flag is a false positive. The real error signature is the one
    # below: no separation ANYWHERE in the film (that is how Notting Hill's
    # missing year apart presented).
    #
    # A romance whose two leads share a lane in EVERY beat is missing its split.
    # Catches the failure mode where a chart shows the couple together from the
    # meet-cute to the coda, which is never true of a third-act-breakup film.
    if (len(order := (film.get("order") or ids)) >= 2 and not film.get("never_separate_ok")
            and all(not b.get("groups") for b in beats)):
        lead_a, lead_b = order[0], order[1]
        together = []
        for b in beats:
            flat = [set(c) for c in (b.get("clusters") or [])]
            together.append(any(lead_a in c and lead_b in c for c in flat))
        if together and all(together):
            errs.append(f"leads '{lead_a}' and '{lead_b}' share a lane in every beat "
                        f"— a romance with no separation is almost certainly wrong")
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
    if slug.endswith("-timechart"):
        doc = FC.load(slug)
        errs = timechart_errors(doc)
        return not errs, errs, [f"{len(doc['scenes'])} scenes"]
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
    # Discovery goes through the store. This used to glob stories/*.json, so the
    # day the JSON files were removed the batch sweep verified NOTHING and still
    # exited 0 — a green gate over an empty set.
    slugs = argv or FY.all_slugs()
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
