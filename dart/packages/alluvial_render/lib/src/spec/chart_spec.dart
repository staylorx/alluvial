import 'package:equatable/equatable.dart';

/// How a strand leaves, or fades from, a column.
enum StubKind {
  /// A strand joining the story: a taper widening into the lane.
  entering('in'),

  /// A strand leaving the story: a taper narrowing out of the lane.
  leaving('out'),

  /// The strand stops here — a taper plus a cross.
  breaking('break'),

  /// An open ending: the strand drifts sideways and thins away.
  fading('fade');

  const StubKind(this.stored);

  /// The name the store and the Python engine use.
  final String stored;

  /// The kind stored as [stored], or [StubKind.leaving] when unknown.
  static StubKind parse(Object? stored) => values.firstWhere(
    (kind) => kind.stored == stored,
    orElse: () => StubKind.leaving,
  );
}

/// One strand's drawing facts: what it is called, how thick it is, its colour.
final class ChartCharacter extends Equatable {
  /// Creates a strand.
  const ChartCharacter({
    required this.label,
    required this.width,
    required this.colour,
  });

  /// The name as it prints in a lane and in the legend.
  final String label;

  /// Ribbon thickness in the authored layout, before [ChartSpec.scale].
  final double width;

  /// Hex colour the strand paints with, unless colour-blind mode is on.
  final String colour;

  @override
  List<Object?> get props => [label, width, colour];
}

/// Characters standing together at one lane position in one column.
final class ChartGroup extends Equatable {
  /// Creates a group centred at [centre], standing in the order given.
  const ChartGroup(this.centre, this.ids);

  /// Lane-space centre, larger sitting further right when unmirrored.
  final double centre;

  /// The strands in this group, left to right as the reader sees them.
  final List<String> ids;

  @override
  List<Object?> get props => [centre, ids];
}

/// A strand entering, leaving, breaking or fading at a column.
final class ChartStub extends Equatable {
  /// Creates a stub.
  const ChartStub(this.id, this.kind, [this.y]);

  /// The strand the stub belongs to.
  final String id;

  /// What the stub does.
  final StubKind kind;

  /// An explicit lane position, when the source carries one.
  final double? y;

  @override
  List<Object?> get props => [id, kind, y];
}

/// An extra caption block under the two caption lines — the rubric tag.
final class ChartCaption extends Equatable {
  /// Creates an extra caption in [colour].
  const ChartCaption(this.lines, this.colour);

  /// The lines, already wrapped.
  final List<String> lines;

  /// The colour the block prints in.
  final String colour;

  @override
  List<Object?> get props => [lines, colour];
}

/// One column of the chart: a beat, what it is called, what it says.
final class ChartColumn extends Equatable {
  /// Creates a column.
  const ChartColumn({
    required this.beat,
    this.loc,
    this.caption = const [],
    this.groups = const [],
    this.enter = const [],
    this.stubs = const [],
    this.hard,
    this.captionExtra,
    this.terminalId,
  });

  /// The beat's name, printed above its row.
  final String beat;

  /// Where the beat sits in the work — `≈ 35–50 min`, a chapter card.
  final String? loc;

  /// The caption lines, already wrapped to the column.
  final List<String> caption;

  /// The groups standing in this column.
  final List<ChartGroup> groups;

  /// Strands that arrive in this column and are announced in the margin.
  final List<String> enter;

  /// Strands that leave, break or fade at this column.
  final List<ChartStub> stubs;

  /// A hard truth the beat carries, printed in red under the caption.
  final String? hard;

  /// The rubric tag block.
  final ChartCaption? captionExtra;

  /// The strand that terminates here, drawn with a dot and a dotted leader.
  final String? terminalId;

  @override
  List<Object?> get props => [
    beat,
    loc,
    caption,
    groups,
    enter,
    stubs,
    hard,
    captionExtra,
    terminalId,
  ];
}

/// The type sizes the engine prints with. Kept as [num] because the engine
/// does arithmetic on them and CPython prints `13 + 1` as `14`, not `14.0`.
final class ChartFonts extends Equatable {
  /// Creates the type scale, defaulting to the film charts' sizes.
  const ChartFonts({
    this.beat = 20,
    this.loc = 16,
    this.caption = 16.5,
    this.hard = 16.5,
    this.band = 14,
    this.legendTitle = 13,
    this.title = 31,
    this.sub = 15.5,
    this.sub2 = 14.5,
  });

  /// The beat's name.
  final num beat;

  /// Where the beat sits in the work.
  final num loc;

  /// A caption line.
  final num caption;

  /// A hard truth, and the rubric tag (one size down from [caption]).
  final num hard;

  /// A semantic band label.
  final num band;

  /// The legend's own title.
  final num legendTitle;

  /// The chart title.
  final num title;

  /// The line under the title.
  final num sub;

  /// A note line in the title block.
  final num sub2;

  @override
  List<Object?> get props => [
    beat,
    loc,
    caption,
    hard,
    band,
    legendTitle,
    title,
    sub,
    sub2,
  ];
}

/// A semantic band label above the first row.
final class ChartBand extends Equatable {
  /// Creates a band label spanning [x0]..[x1].
  const ChartBand(this.text, this.x0, this.x1);

  /// The label.
  final String text;

  /// Left edge of the band it labels.
  final double x0;

  /// Right edge of the band it labels.
  final double x1;

  @override
  List<Object?> get props => [text, x0, x1];
}

/// One line of the title block, with the style it prints in.
final class ChartTitleLine extends Equatable {
  /// Creates a title line.
  const ChartTitleLine(this.text, this.style);

  /// The line.
  final String text;

  /// `title`, `sub` or `note`.
  final String style;

  @override
  List<Object?> get props => [text, style];
}

/// Everything the engine needs to draw one chart. A value object: two specs
/// that compare equal must produce the same bytes.
final class ChartSpec extends Equatable {
  /// Creates a chart spec.
  const ChartSpec({
    required this.characters,
    required this.order,
    required this.columns,
    required this.ys,
    required this.title,
    required this.width,
    required this.capX,
    required this.laneHi,
    required this.scale,
    required this.origin,
    required this.spineOld,
    required this.labelFont,
    required this.legendFont,
    this.fonts = const ChartFonts(),
    this.mirror = false,
    this.cbSafe = false,
    this.dashed = const {},
    this.bands = const [],
    this.legendTitle,
    this.legendNote,
    this.edge,
    this.tiers = 5,
    this.lineCap = 25,
    this.extraGap = 26,
    this.mini = false,
    this.miniPad = 26,
    this.miniStep = 15,
    this.beatHitHalf = 78,
    this.patternPrefix = '',
    this.rowMarkPrefix = 'chart',
    this.beatLinks,
  });

  /// The strands, by id.
  final Map<String, ChartCharacter> characters;

  /// Lane stacking order: every strand id, heaviest first.
  final List<String> order;

  /// The columns, top to bottom.
  final List<ChartColumn> columns;

  /// The y of every column.
  final List<double> ys;

  /// The title block, rendered at the bottom.
  final List<ChartTitleLine> title;

  /// Canvas width.
  final int width;

  /// x where the caption column starts.
  final double capX;

  /// x where the lane grid lines end.
  final double laneHi;

  /// The scale mapping lane space to x.
  final double scale;

  /// x of lane-space zero.
  final double origin;

  /// The lane-space position that maps to [origin].
  final double spineOld;

  /// Per-strand label size.
  final Map<String, double> labelFont;

  /// Per-strand legend size.
  final Map<String, double> legendFont;

  /// The type scale.
  final ChartFonts fonts;

  /// True to map lane space with the semantic bands mirrored.
  final bool mirror;

  /// True for the colour-blind treatment: symbols plus a darkness ramp.
  final bool cbSafe;

  /// Column indices where a strand runs off-page and is drawn dashed.
  final Map<String, List<int>> dashed;

  /// Semantic band labels above the first row.
  final List<ChartBand> bands;

  /// The legend's title line.
  final String? legendTitle;

  /// The italic line under the legend.
  final String? legendNote;

  /// `top`, `bottom` or `both`: close the flow with entry/exit tapers.
  final String? edge;

  /// How many tiers the lane names may stagger into.
  final int tiers;

  /// Line spacing of the caption block.
  final int lineCap;

  /// Extra gap per block inside the caption column.
  final int extraGap;

  /// True for the page's pinned mini-map: rows collapse, no legend.
  final bool mini;

  /// Padding above the first row in mini mode.
  final num miniPad;

  /// Row step in mini mode.
  final num miniStep;

  /// Half-height of a beat's hit area.
  final num beatHitHalf;

  /// Namespace for the pattern ids, so several charts can share a page.
  final String patternPrefix;

  /// Namespace for the row-marker ids.
  final String rowMarkPrefix;

  /// Where a beat links to, or null for a beat that links nowhere.
  final String? Function(int index, ChartColumn column)? beatLinks;

  /// The strand with [id], or null when the spec has none.
  ChartCharacter? character(String id) => characters[id];

  @override
  List<Object?> get props => [
    characters,
    order,
    columns,
    ys,
    title,
    width,
    capX,
    laneHi,
    scale,
    origin,
    spineOld,
    labelFont,
    legendFont,
    fonts,
    mirror,
    cbSafe,
    dashed,
    bands,
    legendTitle,
    legendNote,
    edge,
    tiers,
    lineCap,
    extraGap,
    mini,
    miniPad,
    miniStep,
    beatHitHalf,
    patternPrefix,
    rowMarkPrefix,
  ];
}
