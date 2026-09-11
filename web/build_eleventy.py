#!/usr/bin/env python3
"""Emit the staylorx.com assets for EVERY story chart page.

Writes into an Eleventy repo:
  src/_includes/charts/<slug>.svg        the full chart (inline, internal beat links)
  src/_includes/charts/<slug>-mini.svg   the compact map for the sticky strip
  src/_data/stories.json                   the array the paginated template pages over

One story = one file in stories/ (see STORY-SCHEMA.md). Adding a story needs no new
template: the paginated page generates itself from stories.json.

Deterministic: no timestamps, no environment reads — a rebuild of the same commit
reproduces the same bytes, which is what CI checks.

Usage:  python3 build_eleventy.py /tmp/staylorx-allfilms
"""
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, "..", "scripts")):
    if p not in sys.path:
        sys.path.insert(0, p)

import story_chart as FC          # noqa: E402
import stories_yaml as FY          # noqa: E402
import reorder_chart as RC       # noqa: E402
import rubric27                  # noqa: E402

STORIES = os.path.abspath(os.path.join(HERE, "..", "stories"))

RUBRIC = {
    "title": rubric27.TITLE,
    "kaling": rubric27.KALING,
    "frame": rubric27.FRAME,
    "cats": rubric27.CATS,
    "genre_points": sum(c["pts"] for c in rubric27.CATS if c["id"] != "ebert"),
}


def blurb(film, n_beats, n_lanes):
    if film.get("blurb"):
        return film["blurb"]
    return (f"{n_beats} beats, {n_lanes} lanes. Who is with whom, and the moment it "
            "changes. Each beat names the rubric category its shape belongs to, and the "
            "notes under it are computed from the diagram's own geometry, not written "
            "by hand.")


def build(repo):
    charts = os.path.join(repo, "src", "_includes", "charts")
    data = os.path.join(repo, "src", "_data")
    os.makedirs(charts, exist_ok=True)

    # Discovery goes through the store — one loader, or the store forks. The
    # YAML store is the authored source (JSON is only a legacy fallback), so
    # globbing for *.json here found nothing the moment the JSON files were
    # removed. <slug> is a braid chart; <slug>-timechart is the other shape and
    # is rendered separately below.
    entries, seen = [], [s for s in sorted(FY.all_slugs()) if not FY.is_timechart(s)]
    for slug in seen:
        film = FY.load(slug)
        svg, spec, H, _ = FC.render(film)
        mini, mspec, Hm, _ = FC.render(film, mini=True)
        open(os.path.join(charts, f"{slug}.svg"), "w", encoding="utf-8").write(svg)
        open(os.path.join(charts, f"{slug}-mini.svg"), "w", encoding="utf-8").write(mini)

        beats = FC.beats_data(film, spec, H, spec.get("beat_hit_half", 78))
        n_lanes = len(spec["order"])
        entries.append({
            "slug": slug,
            "title": film["title"],
            "year": film.get("year"),
            "url": f"/stories/{slug}/",
            "score": film.get("score"),
            "score_note": film.get("score_note", ""),
            "runtime": (f"{film['runtime_min']} minutes" if film.get("runtime_min") else ""),
            "n_beats": len(beats),
            "n_lanes": n_lanes,
            "blurb": blurb(film, len(beats), n_lanes),
            "chart": f"src/_includes/charts/{slug}.svg",
            "mini": f"src/_includes/charts/{slug}-mini.svg",
            "hits": FC.hits(spec, H, spec.get("beat_hit_half", 78)),
            "minihits": FC.hits(mspec, Hm, mspec.get("beat_hit_half", 7.5)),
            "beats": beats,
            # The rubric travels with the story that declares one. A story that
            # declares none gets null here, so the page layer has nothing to print
            # — the romcom rubric is never assumed onto a story it doesn't grade.
            "rubric": RUBRIC if FC.rubric_for(film) else None,
        })
        # a film with two clocks gets the second chart underneath the braid
        if any(os.path.exists(os.path.join(STORIES, f"{slug}-timechart{ext}"))
               for ext in (".yaml", ".json")):
            tc_doc = FY.load(f"{slug}-timechart")
            tc_svg, tc_info = RC.render(tc_doc)
            open(os.path.join(charts, f"{slug}-timechart.svg"), "w",
                 encoding="utf-8").write(tc_svg)
            entries[-1]["timechart"] = f"src/_includes/charts/{slug}-timechart.svg"
            entries[-1]["timechart_scenes"] = len(tc_doc["scenes"])
            entries[-1]["timechart_notes"] = tc_doc.get("notes", [])
        print(f"  {slug:34s} {len(beats):2d} beats  {n_lanes} lanes  "
              f"{len(svg)/1024:5.1f} KB  H={H:.0f}")

    # the compendium's own order: by score, unscored last
    entries.sort(key=lambda e: (-(e["score"] if e["score"] else -1), e["title"]))
    open(os.path.join(data, "stories.json"), "w", encoding="utf-8").write(
        json.dumps(entries, indent=1, ensure_ascii=False) + "\n")

    print(f"\n{len(entries)} stor{'y' if len(entries) == 1 else 'ies'} -> {data}/stories.json "
          f"({os.path.getsize(os.path.join(data, 'stories.json'))/1024:.1f} KB)")


if __name__ == "__main__":
    build(sys.argv[1] if len(sys.argv) > 1 else "/tmp/staylorx-allfilms")
