#!/usr/bin/env python3
"""The 27-point romcom rubric, quoted verbatim, plus which beat earns what.

Single source of truth for the rubric text so the chart, the standalone page and
the site page can't drift apart. Wording is copied from the vault draft
"Romcoms Are Science Fiction, and I Have a Rubric"
(Writing/Substack/Drafts/romcom-rubric-27.md) — quoting beats paraphrasing,
because the argument is in the exact phrasing.

Adding a film: add CATS if the rubric itself changes; add a BEAT_CATS map for
the new film's beats (1-based, matching the chart's column order).
"""
from __future__ import annotations

TITLE = "Romcoms Are Science Fiction, and I Have a Rubric"

KALING = ("\u201cI simply regard romantic comedies as a subgenre of sci-fi, in which the "
          "world operates according to different rules than my regular human world.\u201d "
          "\u2014 Mindy Kaling")

# The five genre categories, then the three the genre can't buy.
CATS = [
    dict(id="chem", name="Chemistry", pts=10,
         text="The load-bearing wall. Everything else is scaffolding. A bad meet-cute can "
              "be forgiven if the banter lands; nothing forgives dead eyes."),
    dict(id="meet", name="Meet-cute", pts=5,
         text="An entrance, not a marriage. A spilled coffee is worth two points. A spilled "
              "coffee at a wedding where they're both playing roles they don't believe in "
              "is worth the full five."),
    dict(id="bff", name="Quirky best friend", pts=5,
         text="The category most romcoms overspend on. The rubric quietly punishes that, "
              "and it should."),
    dict(id="breakup", name="Breakup that makes sense", pts=5,
         text="The third-act split should flow from who these people actually are, not from "
              "a misunderstanding that a single conversation would fix."),
    dict(id="gesture", name="Gesture that earns it", pts=2,
         text="The airport run is worth two points, maximum, and only when the breakup "
              "earned it. The original seven got split: five for the breakup, two for the "
              "gesture."),
    dict(id="ebert", name="Ebert's three scenes", pts=3,
         text="Always graded. Hawks' rule in Ebert's voice: three good scenes and no bad "
              "ones \u2014 one point per great scene, and a bad scene costs one. The genre "
              "can't buy these; only the movie can."),
]

FRAME = [
    "Twenty-seven points, across five genre categories \u2014 because the genre's patron "
    "saint is a movie called 27 Dresses, and because a perfect score should look like the "
    "film's own title.",
    "Then three more the genre can't buy. The Ebert dimension is always part of the grade, "
    "which makes thirty possible points, but the percentage runs against the twenty-seven, "
    "because the house is 27 Dresses at a nominal 100%. A movie that clears the genre "
    "ceiling lands at 104%, 107%, or 111%: the only way to beat the house is to be a better "
    "movie, not a better romcom.",
    "The house, scored: 27 of 30, nominal 100%. Ebert's three are left unpicked \u2014 whether "
    "the house is a true 27 is still under review. You don't ding the house the party's at.",
]

# 1-based beat order -> the rubric categories that beat earns. THIS IS THE HOUSE'S
# OWN MAP (27 Dresses: the cab, Casey, the gesture) — it is not a store-wide
# default and it is not consulted for a story that does not declare `rubric:
# romcom-27`. A story the rubric does not grade gets no categories at all.
BEAT_CATS = {
    1: ["meet"],      # the cab, both in wedding clothes, playing roles
    2: ["chem"],      # they argue beautifully
    4: ["bff"],       # Casey, doing the actual work
    5: ["chem"],      # chemistry, second gear
    6: ["ebert"],     # the scene the film is remembered for
    7: ["breakup"],   # the split flows from who he is
    10: ["gesture"],  # and it is hers, not his
}

BY_ID = {c["id"]: c for c in CATS}

# The rubric's id as a story declares it (`rubric: romcom-27` in the store).
ID = "romcom-27"


def for_beat(n: int) -> list[dict]:
    """The HOUSE's beat n earns ([] when the beat is structure only).

    Only meaningful for the story this map was written from; a caller must first
    know the story declares this rubric."""
    return [BY_ID[cid] for cid in BEAT_CATS.get(n, [])]


if __name__ == "__main__":
    total = sum(c["pts"] for c in CATS if c["id"] != "ebert")
    print(f"{len(CATS)} categories, {total} genre points "
          f"+ {BY_ID['ebert']['pts']} Ebert = {total + BY_ID['ebert']['pts']}")
    for i in range(1, 12):
        cats = for_beat(i)
        print(f"  beat {i:2d}: " + (", ".join(c["name"] for c in cats) if cats else "\u2014"))
