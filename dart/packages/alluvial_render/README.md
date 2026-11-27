# alluvial_render

The two SVG engines — the braid chart (time down the page, one lane per strand)
and the two-clock chart (as screened beside as it happened) — plus the builder
that turns a decoded story into the layout the engine draws.

The output is **byte-identical to the Python engine** that produced every
approved chart, and that identity is the gate: a renderer that disagrees with
the reference is worse than no renderer. Every number goes through `PyNum`,
which reproduces CPython's rounding.

**Error style.** This package presents **plain values**: `renderFilmChart`
answers a rendered chart and `renderTwoClock` an SVG string. It is a pure
function of a decoded story with no failure channel — asking for the wrong shape
is a usage error, decided by the caller (§4.9).
Doctrine: `~/hermes/projects/dart-flutter-bible` — this package follows it and
does not restate it. This repo's deviations and local wiring: [`AGENTS.md`](../../AGENTS.md).
What is built, proven and open: [`backlog/`](../../backlog/).
