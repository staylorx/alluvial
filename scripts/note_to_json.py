#!/usr/bin/env python3
"""An edited Obsidian note -> the film's chart data. The inverse of story_note.py.

Reads the note's machine fields (frontmatter scalars + `order` list, the cast
table, and the `- **field:**` bullets under each `### n · BEAT` block) and
rebuilds the film dict the chart builder consumes. Free prose in section 5 is
never parsed, so note-taking can never break a chart.

  python3 scripts/note_to_json.py --check            # round-trip every film
  python3 scripts/note_to_json.py --check <slug> ...
  python3 scripts/note_to_json.py <slug>             # note -> stories/<slug>.json
  python3 scripts/note_to_json.py <slug> --stdout    # ... print instead

A film whose layout is hand-tuned (`groups`, i.e. 27 Dresses) is refused: its
approved chart is byte-identical only to its own JSON, so the JSON stays the
source of truth for that one.
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
STORIES = os.path.join(ROOT, "stories")
NOTES = os.path.join(ROOT, "out", "notes")

CAT_LABEL = {
    "chem": "chemistry (10)",
    "meet": "meet-cute (5)",
    "bff": "best friend (5)",
    "breakup": "breakup (5)",
    "gesture": "grand gesture (2)",
    "ebert": "Ebert's three (3)",
}
LABEL_CAT = {v: k for k, v in CAT_LABEL.items()}
DASH = "—"


class NoteError(Exception):
    pass


def split_front(text: str) -> tuple[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        raise NoteError("no frontmatter")
    return m.group(1), m.group(2)


def parse_front(front: str) -> dict:
    data: dict = {}
    key = None
    for line in front.splitlines():
        if re.match(r"^\s+-\s+", line):
            if key is None:
                raise NoteError("list item before any key")
            data.setdefault(key, []).append(line.strip()[2:].strip())
            continue
        m = re.match(r"^([A-Za-z_]+):\s*(.*)$", line)
        if not m:
            raise NoteError(f"unparsable frontmatter line: {line!r}")
        key, val = m.group(1), m.group(2).strip()
        if val == "":
            data[key] = []          # a list starts here
        elif val.startswith('"') and val.endswith('"'):
            data[key] = val[1:-1]
        else:
            data[key] = val
    return data


def sections(body: str) -> dict[str, str]:
    """Map a section keyword ('Cast of characters', 'Plot beats', ...) to its text."""
    out: dict[str, str] = {}
    parts = re.split(r"^##\s+.*?·\s*(.+?)\s*$", body, flags=re.M)
    # parts = [preamble, heading1, text1, heading2, text2, ...]
    for i in range(1, len(parts) - 1, 2):
        out[parts[i].strip()] = parts[i + 1]
    return out


def scalar(val: str) -> str:
    val = val.strip()
    return "" if val in (DASH, "") else val


def parse_chars(sec: str) -> tuple[list[dict], dict[str, str]]:
    chars, name_to_id = [], {}
    for line in sec.splitlines():
        if not line.startswith("|") or set(line) <= set("|- "):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 7 or cells[0] == "#":
            continue
        _, cid, name, width, colour, _present, notes = cells[:7]
        cid = cid.strip("`")
        name = scalar(name)
        chars.append({"id": cid, "name": name or cid, "width": int(width),
                      "colour": colour.strip("`"), "notes": scalar(notes) or None})
        name_to_id[name or cid] = cid
    if not chars:
        raise NoteError("no cast table rows found")
    return chars, name_to_id


def parse_beats(sec: str, name_to_id: dict[str, str], film: str) -> list[dict]:
    blocks = re.split(r"^###\s+(\d+)\s+·\s+(.*)$", sec, flags=re.M)
    # blocks = [preamble, n, name, text, n, name, text, ...]
    beats = []
    for i in range(1, len(blocks) - 2, 3):
        name, text = blocks[i + 1].strip(), blocks[i + 2]
        beat: dict = {"name": name}
        caps: list[str] = []
        for line in text.splitlines():
            m = re.match(r"^-\s+\*\*(.+?):\*\*\s?(.*)$", line)
            if not m:
                continue
            key, val = m.group(1), m.group(2).strip()
            if key == "at":
                beat["loc"] = scalar(val)
            elif key == "on screen":
                clusters = []
                if val != DASH:
                    for group in val.split(" | "):
                        ids = []
                        for nm in group.split(" + "):
                            nm = nm.strip()
                            if nm not in name_to_id:
                                raise NoteError(
                                    f"{film} beat {name!r}: unknown character {nm!r}")
                            ids.append(name_to_id[nm])
                        clusters.append(ids)
                beat["clusters"] = clusters
            elif key == "entering":
                beat["enter"] = [name_to_id[x.strip()] for x in val.split(",")
                                 if x.strip() in name_to_id]
            elif key == "exiting":
                beat["stubs"] = [name_to_id[x.strip()] for x in val.split(",")
                                 if x.strip() in name_to_id]
            elif key == "rubric":
                beat["cats"] = [] if val == DASH else [
                    LABEL_CAT[x.strip()] for x in val.split(";") if x.strip() in LABEL_CAT]
            elif key == "caption":
                caps.append(val)
            elif key == "tag":
                beat["tag"] = scalar(val)
            elif key == "notes":
                if scalar(val):
                    beat["notes"] = val
        # canonical field order, matching stories/*.json
        order = ["name", "loc", "cap", "tag", "cats", "clusters", "enter", "stubs", "notes"]
        beat["cap"] = caps
        beats.append({k: beat[k] for k in order if k in beat})
    if not beats:
        raise NoteError(f"{film}: no beat blocks found")
    return beats


def parse_storylines(sec: str | None, name_to_id: dict[str, str]) -> list[dict] | None:
    if sec is None:
        return None
    rows = []
    for line in sec.splitlines():
        if not line.startswith("|") or set(line) <= set("|- "):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 4 or cells[0] == "storyline":
            continue
        name, who, beats, notes = cells[:4]
        ids = [name_to_id[x.strip()] for x in who.split(",") if x.strip() in name_to_id]
        nums = [int(x) for x in re.findall(r"\d+", beats)]
        out: dict = {"name": name, "chars": ids, "beats": nums}
        if scalar(notes):
            out["notes"] = scalar(notes)
        rows.append(out)
    return rows or None


def bullets(sec: str | None) -> dict[str, str]:
    out = {}
    for line in (sec or "").splitlines():
        m = re.match(r"^-\s+\*\*(.+?):\*\*\s?(.*)$", line)
        if m:
            out[m.group(1)] = scalar(m.group(2))
    return out


def parse_note(text: str, film: str = "?") -> dict:
    front, body = split_front(text)
    fm = parse_front(front)
    if fm.get("layout") == "hand-tuned":
        raise NoteError(f"{film}: layout is hand-tuned — edit stories/{film}.json directly")
    sec = sections(body)
    chars, name_to_id = parse_chars(sec.get("Cast of characters", ""))
    beats = parse_beats(sec.get("Plot beats", ""), name_to_id, film)
    doc: dict = {"slug": fm["slug"], "title": fm.get("title", fm["slug"])}
    for key, conv in (("year", int), ("runtime_min", int), ("rubric_score", int)):
        val = str(fm.get(key, "") or "").strip()
        if val and val.lower() != "none":
            doc["score" if key == "rubric_score" else key] = conv(val)
    for key in ("score_note", "legend_object", "never_separate_ok"):
        if fm.get(key):
            doc[key] = fm[key]
    order = fm.get("order") or [c["id"] for c in chars]
    doc["order"] = list(order)
    doc["chars"] = [{k: v for k, v in c.items() if v is not None} for c in chars]
    doc["beats"] = beats
    lines = parse_storylines(sec.get("Storylines"), name_to_id)
    if lines:
        doc["storylines"] = lines
    prov = bullets(sec.get("Provenance and limits"))
    for key, label in (("caption_source", "caption source"),
                       ("chart_limits", "what the chart cannot show")):
        if prov.get(label):
            doc[key] = prov[label]
    return doc


def normalise(doc: dict) -> dict:
    """Compare like with like: `stubs: []` == no `stubs` key, and `score: None` == no score."""
    out = {k: v for k, v in doc.items() if v is not None}
    out["beats"] = [
        {k: v for k, v in b.items() if not (isinstance(v, list) and not v)}
        for b in doc.get("beats", [])
    ]
    return out


def main(argv: list[str]) -> int:
    args = [a for a in argv if not a.startswith("--")]
    slugs = args[1:]
    if "--check" in argv:
        import story_chart as FC
        slugs = slugs or sorted(
            os.path.splitext(os.path.basename(p))[0] for p in glob.glob(os.path.join(STORIES, "*.json"))
        )
        bad = []
        for slug in slugs:
            note = os.path.join(NOTES, f"{slug}.md")
            src = os.path.join(STORIES, f"{slug}.json")
            if not os.path.exists(src):
                continue
            with open(src, encoding="utf-8") as fh:
                original = json.load(fh)
            if "beats" not in original:
                print(f"SKIP  {slug:38} (two-clock chart, no braid to round-trip)")
                continue
            if not os.path.exists(note):
                print(f"SKIP  {slug:38} (no note yet)")
                continue
            try:
                with open(note, encoding="utf-8") as fh:
                    back = parse_note(fh.read(), slug)
            except NoteError as exc:
                print(f"SKIP  {slug:38} ({exc})")
                continue
            same_data = normalise(back) == normalise(original)
            # the check that actually matters: the same chart comes out of both
            same_chart = FC.render(original)[0] == FC.render(back)[0]
            if same_data and same_chart:
                print(f"OK    {slug:38} note -> data and chart identical")
            else:
                bad.append(slug)
                diff = [k for k in set(back) | set(original)
                        if back.get(k) != original.get(k)]
                print(f"DIFF  {slug:38} data: {sorted(diff)} chart-identical: {same_chart}")
        print(f"\n{len(slugs)} film files, {len(bad)} differing")
        return 1 if bad else 0

    if not slugs:
        print(__doc__)
        return 2
    for slug in slugs:
        with open(os.path.join(NOTES, f"{slug}.md"), encoding="utf-8") as fh:
            doc = parse_note(fh.read(), slug)
        text = json.dumps(doc, indent=2, ensure_ascii=False) + "\n"
        if "--stdout" in argv:
            sys.stdout.write(text)
        else:
            path = os.path.join(STORIES, f"{slug}.json")
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(text)
            print(f"{path}  written from note")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
