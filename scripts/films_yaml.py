#!/usr/bin/env python3
"""The per-film data store: films/<slug>.yaml, with a published schema.

YAML is the authored source for every chart (film braids and two-clock charts).
It is the same data the engine reads — this module is the only thing that knows
how to load it, so there is one place that decides what a film file means.

  schema/film.schema.json        the braid-chart contract
  schema/timechart.schema.json   the two-clock contract

Both are enforced (see validate_all), and both are referenced by `yaml-language-
server` comments at the top of each file so an editor offers completion while
authoring.

Loads JSON too, so nothing breaks while older files are converted.

Usage:
  python3 films_yaml.py convert [slug ...]    JSON -> YAML (skips existing YAML)
  python3 films_yaml.py validate [slug ...]   schema-check every film file
  python3 films_yaml.py roundtrip             prove YAML renders the same bytes
"""
from __future__ import annotations

import glob
import json
import os
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
FILMS = os.path.join(ROOT, "films")
SCHEMA = os.path.join(ROOT, "schema")

FILM_KEYS = ["slug", "title", "year", "runtime_min", "score", "score_note", "blurb",
             "legend_object", "legend_note", "title_notes", "title_block", "mirror",
             "dashed", "never_separate_ok", "order", "chars", "beats"]
CHAR_KEYS = ["id", "name", "width", "colour"]
BEAT_KEYS = ["name", "loc", "cap", "tag", "cats", "clusters", "groups", "enter", "stubs", "hard"]
TIME_KEYS = ["slug", "title", "year", "runtime_min", "sub", "notes", "legend_note", "threads", "scenes"]
SCENE_KEYS = ["id", "label", "chapter", "as_screened", "happened", "thread", "mins"]

HEADER = """# {what}
#
# Schema: schema/{schema}.json   (enforced — run: python3 scripts/films_yaml.py validate)
# yaml-language-server: $schema=schema/{schema}.json
#
# Editing notes:
#   cap      exactly two caption lines per beat; anything past ~47 characters
#            is word-wrapped at render time, so keep them short and factual
#   clusters who stands together, left to right. Every character present in the
#            beat must appear in exactly one cluster; anyone absent is drawn
#            off-page (hatched) automatically
#   stubs    a final exit, and it must sit on that character's LAST PRESENT beat
#   cats     which rubric category the beat's shape belongs to — this is a
#            description, NOT points owed (the film's score is the verdict)
#   order    lane stacking order; label size follows `width` instead
"""


def _order(d: dict, keys: list[str]) -> dict:
    return {k: d[k] for k in keys if k in d} | {k: v for k, v in d.items() if k not in keys}


def canonical(doc: dict) -> dict:
    """Field order that reads well by hand, beats and characters in authoring order."""
    out = _order(doc, FILM_KEYS if "beats" in doc else TIME_KEYS)
    if "beats" in out:
        out["chars"] = [_order(c, CHAR_KEYS) for c in out.get("chars", [])]
        out["beats"] = [_order(b, BEAT_KEYS) for b in out.get("beats", [])]
    if "scenes" in out:
        out["scenes"] = [_order(s, SCENE_KEYS) for s in out.get("scenes", [])]
    return out


def yaml_path(slug: str) -> str:
    return os.path.join(FILMS, f"{slug}.yaml")


def json_path(slug: str) -> str:
    return os.path.join(FILMS, f"{slug}.json")


def dump(doc: dict) -> str:
    what = ("A film's braid chart: who stands with whom, beat by beat."
            if "beats" in doc else
            "A film's two-clock chart: as screened vs as it happened.")
    schema = "film.schema" if "beats" in doc else "timechart.schema"
    try:
        flow = doc["slug"] in ()
    except Exception:
        flow = False
    body = yaml.safe_dump(canonical(doc), sort_keys=False, allow_unicode=True,
                          width=110, default_flow_style=False, indent=1)
    # caption pairs read better on one line than as a two-item block list
    lines = []
    for ln in body.splitlines():
        lines.append(ln)
    return HEADER.format(what=what, schema=schema) + "\n".join(lines) + "\n"


def load(slug: str) -> dict:
    """YAML first, JSON as the fallback while files are still being converted."""
    yp = yaml_path(slug)
    if os.path.exists(yp):
        with open(yp, encoding="utf-8") as fh:
            return yaml.safe_load(fh)
    with open(json_path(slug), encoding="utf-8") as fh:
        return json.load(fh)


def all_slugs() -> list[str]:
    seen = set()
    for pat in ("*.yaml", "*.json"):
        for p in glob.glob(os.path.join(FILMS, pat)):
            seen.add(os.path.basename(p).rsplit(".", 1)[0])
    return sorted(seen)


def is_timechart(slug: str) -> bool:
    doc = load(slug)
    return "scenes" in doc


def convert(slugs: list[str] | None = None) -> list[str]:
    written = []
    for slug in (slugs or all_slugs()):
        jp, yp = json_path(slug), yaml_path(slug)
        if os.path.exists(yp) or not os.path.exists(jp):
            continue
        with open(jp, encoding="utf-8") as fh:
            doc = json.load(fh)
        with open(yp, "w", encoding="utf-8") as fh:
            fh.write(dump(doc))
        written.append(slug)
    return written


def validate(slugs: list[str] | None = None) -> list[tuple[str, str]]:
    """-> [(slug, error)] using the published schema. Empty list means clean."""
    import jsonschema
    schemas = {}
    bad = []
    for slug in (slugs or all_slugs()):
        doc = load(slug)
        which = "timechart.schema" if "scenes" in doc else "film.schema"
        if which not in schemas:
            with open(os.path.join(SCHEMA, f"{which}.json"), encoding="utf-8") as fh:
                schemas[which] = json.load(fh)
        try:
            jsonschema.validate(doc, schemas[which])
        except jsonschema.ValidationError as exc:
            bad.append((slug, f"{'/'.join(str(p) for p in exc.absolute_path)}: {exc.message}"))
    return bad


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "validate"
    args = sys.argv[2:]
    if cmd == "convert":
        w = convert(args)
        print(f"converted {len(w)} film file(s) to YAML: {', '.join(w) or 'nothing to do'}")
    elif cmd == "validate":
        bad = validate(args)
        for slug, msg in bad:
            print(f"INVALID {slug}: {msg}")
        print(f"{len(args) or len(all_slugs()) - len(bad)} valid, {len(bad)} invalid")
        sys.exit(1 if bad else 0)
    else:
        print(__doc__)
