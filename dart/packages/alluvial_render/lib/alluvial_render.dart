/// The renderers: a story in, an SVG out.
///
/// Two engines live here — the braid chart (time down the page, one lane per
/// strand) and the two-clock chart (as screened beside as it happened) — plus
/// the builder that turns a decoded [Story] into the layout the engine draws.
///
/// The output is deliberately byte-identical to the Python engine that produced
/// every approved chart: the layout is hand-tuned across a hundred artifacts,
/// so "equivalent output" is not good enough. Every number is printed through
/// [PyNum], which reproduces CPython's rounding.
library;

export 'src/builder/story_chart_builder.dart';
export 'src/engine/palette.dart';
export 'src/engine/ribbon.dart';
export 'src/engine/vertical_renderer.dart';
export 'src/py_num.dart';
export 'src/spec/chart_spec.dart';
export 'src/twoclock/two_clock_renderer.dart';
