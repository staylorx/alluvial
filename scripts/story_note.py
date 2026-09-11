#!/usr/bin/env python3
"""A film's chart data -> an editable Obsidian note (the chart's data store).

The chart is drawn from a table. This script renders that table as a markdown
note a human can read and hand-edit in Obsidian: the cast, the beats, and the
character-to-beat pairing made explicit, plus a free-text `notes` line on
everything. It is the human-readable face of `stories/<slug>.json`.

Two kinds of line, and the contract between them:

  - **machine fields** (`at`, `on screen`, `off page`, `entering`, `exiting`,
    `rubric`, `caption`, `tag`) mirror the JSON exactly. Regenerating the note
    from the JSON rewrites these.
  - **notes** lines are free text and are NEVER generated over: they are empty
    on first write and are shown from the JSON if the JSON already has one.

Usage:
  python3 scripts/story_note.py <slug> [...]        # -> out/notes/<slug>.md
  python3 scripts/story_note.py --all
  python3 scripts/story_note.py <slug> --stdout
"""
from __future__ import annotations

import glob
import json
import os
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


def load(slug: str) -> dict:
    with open(os.path.join(STORIES, f"{slug}.json"), encoding="utf-8") as fh:
        return json.load(fh)


def cell(value: object) -> str:
    """Markdown table cell: no pipes, no newlines."""
    s = str(value).replace("|", "/").replace("\n", " ")
    return s.strip() or "—"


def name_of(doc: dict, cid: str) -> str:
    for c in doc.get("chars", []):
        if c["id"] == cid:
            return c.get("name", cid)
    return cid


def present_in(doc: dict, cid: str) -> list[int]:
    """Beat numbers (1-based) where the character is on screen."""
    out = []
    for i, b in enumerate(doc.get("beats", []), 1):
        flat = [x for g in b.get("clusters", []) for x in g]
        if cid in flat:
            out.append(i)
    return out


def on_screen(doc: dict, beat: dict) -> str:
    groups = []
    for g in beat.get("clusters", []):
        groups.append(" + ".join(name_of(doc, x) for x in g))
    return " | ".join(groups) if groups else "—"


def off_page(doc: dict, beat: dict) -> str:
    flat = {x for g in beat.get("clusters", []) for x in g}
    rest = [c.get("name", c["id"]) for c in doc.get("chars", []) if c["id"] not in flat]
    return ", ".join(rest) if rest else "—"


def render(doc: dict) -> str:
    slug = doc["slug"]
    title = doc.get("title", slug)
    beats = doc.get("beats", [])
    chars = doc.get("chars", [])
    chart_path = doc.get("chart_path") or f"/stories/{slug}/"
    L: list[str] = []

    # ---- frontmatter (film-level, queryable in Obsidian) -------------------
    L.append("---")
    L.append("type: film-chart")
    L.append(f"slug: {slug}")
    L.append(f'title: "{title}"')
    L.append(f"year: {doc.get('year', '')}")
    L.append(f"runtime_min: {doc.get('runtime_min', '')}")
    L.append(f"rubric_score: {doc['score'] if doc.get('score') is not None else ''}")
    L.append(f"chart_path: /stories/{slug}/")
    L.append(f"data_source: hermes/projects/alluvial/stories/{slug}.json")
    L.append(f"lanes: {len(chars)}")
    L.append(f"beats: {len(beats)}")
    L.append(f"layout: {'hand-tuned' if any('groups' in b for b in beats) else 'computed'}")
    L.append("order:")
    for cid in doc.get("order", [c["id"] for c in chars]):
        L.append(f"  - {cid}")
    if doc.get("mirror") is not None:
        L.append(f"mirror: {str(doc['mirror']).lower()}")
    if doc.get("score_note"):
        L.append(f'score_note: "{doc["score_note"]}"')
    if doc.get("legend_object"):
        L.append(f'legend_object: "{doc["legend_object"]}"')
    if doc.get("never_separate_ok"):
        L.append(f'never_separate_ok: "{doc["never_separate_ok"]}"')
    L.append("---")
    L.append("")

    # ---- how to read / edit this file --------------------------------------
    L.append(f"# {title} ({doc.get('year', '')}) — beat skeleton")
    L.append("")
    L.append(
        f"**{len(beats)} beats · {len(chars)} lanes · rubric score "
        f"{doc.get('score', '—')}**  ·  page: `{doc.get('chart_path', '')}`  ·  "
        f"from `stories/{slug}.json`"
    )
    L.append("")
    L.append("> The chart is drawn from a table, and this is that table.")
    L.append("> Lines marked **bold** are the machine fields the chart builder reads.")
    L.append("> `notes:` lines are yours — free text, never overwritten.")
    L.append("")
    if doc.get("legend_object"):
        L.append(f"*Title object:* {doc['legend_object']}  ")
        L.append("")
    if doc.get("score_note"):
        L.append(f"*Score note:* {doc['score_note']}  ")
        L.append("")

    # ---- 1. cast of characters --------------------------------------------
    L.append("## 1 · Cast of characters")
    L.append("")
    L.append(
        "Weight is ribbon thickness ≈ screen presence (lead 30–34, second 22–28, "
        "third 16–20, minor 12–15). Beat numbers are 1-based, in story order."
    )
    L.append("")
    L.append("| # | id | on chart | weight | colour | present in beats | notes |")
    L.append("|---|---|---|---|---|---|---|")
    for i, c in enumerate(chars, 1):
        beats_in = present_in(doc, c["id"])
        L.append(
            f"| {i} | `{c['id']}` | {cell(c.get('name'))} | {c.get('width', '—')} | "
            f"`{c.get('colour', '')}` | "
            f"{', '.join(map(str, beats_in)) or '—'} | {cell(c.get('notes', ''))} |"
        )
    L.append("")
    L.append(
        "Keep the house palette so the charts look like a set: lead A `#1b57c4`, lead B "
        "`#d0316a`, then `#6e9078`, `#9c6552`, `#b09a4e`, `#8d7fa8`, `#6f8f96`, `#b08a94`."
    )
    L.append("")

    # ---- 2. the beats -----------------------------------------------------
    L.append("## 2 · Plot beats")
    L.append("")
    L.append(
        "`on screen` is who is standing together, left to right as the chart draws "
        "them. `off page` is everyone else — the renderer hatches them."
    )
    L.append("")
    for i, b in enumerate(beats, 1):
        L.append(f"### {i} · {b.get('name', '')}")
        L.append("")
        L.append(f"- **at:** {cell(b.get('loc', ''))}")
        L.append(f"- **on screen:** {on_screen(doc, b)}")
        L.append(f"- **off page:** {off_page(doc, b)}")
        if b.get("enter"):
            L.append(f"- **entering:** {', '.join(name_of(doc, x) for x in b['enter'])}")
        if b.get("stubs"):
            L.append(f"- **exiting:** {', '.join(name_of(doc, x) for x in b['stubs'])}")
        cats = b.get("cats", [])
        L.append(
            "- **rubric:** "
            + ("; ".join(CAT_LABEL.get(c, c) for c in cats) if cats else "—")
        )
        for ln in b.get("cap", []):
            L.append(f"- **caption:** {ln}")
        L.append(f"- **tag:** {cell(b.get('tag', ''))}")
        L.append(f"- **notes:** {b.get('notes', '')}")
        L.append("")

    # ---- 3. threads (the storylines a lane cannot hold) --------------------
    threads = doc.get("threads_data") or doc.get("storylines")
    if threads:
        L.append("## 3 · Storylines")
        L.append("")
        L.append(
            "An ensemble gets one shared lane on the chart, so the individual "
            "threads live here instead. Beat numbers refer to section 2."
        )
        L.append("")
        L.append("| storyline | in it | beats | notes |")
        L.append("|---|---|---|---|")
        for t in threads:
            who = ", ".join(map(str, (name_of(doc, x) for x in t.get("chars", []))))
            L.append(
                f"| {cell(t.get('name'))} | {cell(who)} | "
                f"{', '.join(map(str, t.get('beats', []))) or '—'} | "
                f"{cell(t.get('notes', ''))} |"
            )
        L.append("")

    # ---- 4. provenance and limits -----------------------------------------
    L.append("## 4 · Provenance and limits")
    L.append("")
    L.append(f"- **what the chart cannot show:** {doc.get('chart_limits', '')}")
    L.append(f"- **caption source:** {doc.get('caption_source', '')}")
    L.append("")

    # ---- 5. free notes (never parsed) --------------------------------------
    L.append("## 5 · Free notes")
    L.append("")
    L.append("> Prose goes here. Nothing below this line is read by the builder, so")
    L.append("> write as loosely as you like.")
    L.append("")
    free = doc.get("notes", "")
    if free:
        L.append(free)
    else:
        L.append("_nothing yet_")
    L.append("")
    return "\n".join(L)


def main(argv: list[str]) -> int:
    args = [a for a in argv if not a.startswith("--")]
    to_stdout = "--stdout" in argv
    slugs = args[1:] if args else []
    if "--all" in argv or not slugs:
        slugs = sorted(
            os.path.splitext(os.path.basename(p))[0] for p in glob.glob(os.path.join(STORIES, "*.json"))
        )
    os.makedirs(NOTES, exist_ok=True)
    for slug in slugs:
        doc = load(slug)
        if "beats" not in doc:
            print(f"skip {slug}: two-clock chart (scenes, not beats) — no braid note yet")
            continue
        text = render(doc)
        if to_stdout:
            sys.stdout.write(text)
        else:
            path = os.path.join(NOTES, f"{slug}.md")
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(text)
            print(f"{path}  ({len(text)} chars)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
