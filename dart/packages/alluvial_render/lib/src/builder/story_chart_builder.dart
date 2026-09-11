import 'package:alluvial_domain/alluvial_domain.dart';

import '../engine/palette.dart';
import '../engine/vertical_renderer.dart';
import '../py_num.dart';
import '../spec/chart_spec.dart';

/// The lane band, in lane space. Larger sits further right when unmirrored.
const double laneLeft = 110.0;

/// The other end of the lane band.
const double laneRight = 830.0;

/// Column pitch.
const double rowStep = 165.0;

/// Where the first column lands.
const double rowZero = 300.0;

/// Extra air before the final row — time passes there.
const double codaExtra = 70.0;

/// The colour the rubric tag block prints in.
const String tagColour = '#8a6a1f';

/// The caption column fits about this many characters at 16.5px.
const int captionCharacters = 47;

/// The film charts' type scale.
const ChartFonts filmFonts = ChartFonts();

/// The canvas the film charts are laid out on.
const int chartWidth = 1010;

/// Word-wrap a chart caption.
///
/// Short lines pass through untouched, which is what keeps already-published
/// charts byte-identical through a change to the wrap width.
List<String> wrapCaption(Object? text, {int width = captionCharacters}) {
  final words = '${text ?? ''}'
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final lines = <String>[];
  var current = '';
  for (final word in words) {
    final candidate = '$current $word'.trim();
    if (current.isNotEmpty && pyLen(candidate) > width) {
      lines.add(current);
      current = word;
    } else {
      current = candidate;
    }
  }
  if (current.isNotEmpty) lines.add(current);
  return lines.isEmpty ? <String>[''] : lines;
}

/// Even, weight-aware placement of each cluster across the lane band.
///
/// Wider clusters — more people standing together — get proportionally more
/// room, and the first cluster lands at the left edge of the band. Evenly
/// spaced clusters strand the two-person groups that carry the meaning.
List<ChartGroup> groupsFor(List<List<String>> clusters) {
  if (clusters.isEmpty) return const [];
  if (clusters.length == 1) {
    return [
      ChartGroup(PyNum.roundTo((laneLeft + laneRight) / 2, 1), clusters.first),
    ];
  }
  final weights = [
    for (final cluster in clusters) 0.55 + 0.45 * cluster.length,
  ];
  final total = weights.fold<double>(0, (sum, w) => sum + w);
  final out = <ChartGroup>[];
  var accumulated = 0.0;
  for (var i = 0; i < clusters.length; i++) {
    final y = laneLeft + (laneRight - laneLeft) * (accumulated / total);
    out.add(ChartGroup(PyNum.roundTo(y, 1), clusters[i]));
    accumulated += weights[i];
  }
  return out;
}

/// Flatten a stored id list: a bare id, a list of ids, or a list of lists.
///
/// Hand-authored tables produce all three shapes, and one malformed row must
/// not kill a thirty-file build.
List<String> flatIds(Object? raw) {
  if (raw == null) return const [];
  if (raw is String) return raw.isEmpty ? const [] : [raw];
  if (raw is! List) return const [];
  final out = <String>[];
  for (final item in raw) {
    if (item is String) {
      if (item.isNotEmpty) out.add(item);
    } else if (item is List) {
      out.addAll(item.whereType<String>().where((id) => id.isNotEmpty));
    }
  }
  return out;
}

List<String> _stringList(Object? raw) {
  if (raw is String) return raw.isEmpty ? const [] : [raw];
  if (raw is! List) return const [];
  return raw.whereType<String>().where((s) => s.isNotEmpty).toList();
}

String? _stringOrNull(Object? raw) => raw is String ? raw : null;

List<ChartTitleLine>? _titleBlock(Object? raw) {
  if (raw is! List || raw.isEmpty) return null;
  final out = <ChartTitleLine>[];
  for (final entry in raw) {
    if (entry is! List || entry.length < 2) return null;
    final text = entry[0];
    final style = entry[1];
    if (text is! String || style is! String) return null;
    out.add(ChartTitleLine(text, style));
  }
  return out.isEmpty ? null : out;
}

Map<String, List<int>> _dashed(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, List<int>>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || value is! List) continue;
    out[key] = value.whereType<int>().toList();
  }
  return out;
}

/// The ids a `enter` / `stubs` list names.
///
/// The model derives both from the presence states of the appearances, and the
/// decoder carries only the *divergences* in `extra` — so a raw list here means
/// the stored file said something the appearances cannot express (an id that
/// does not stand in the beat, a different order, or an explicitly empty list
/// meaning "nobody leaves here"). An empty list is therefore not a signal to
/// derive; it is the answer.
List<String> _presenceIds(
  Story story,
  Beat beat,
  String key,
  PresenceState state,
) {
  final raw = beat.extra[key];
  if (raw is List) return flatIds(raw);
  return [
    for (final a in story.appearancesIn(beat.id))
      if (a.state == state) a.characterId,
  ];
}

/// The layout of [story] as a chart spec.
///
/// Everything a researcher cannot know — lane x, row step, type sizes, the
/// title block — is computed here, so authoring a subject stays filling in a
/// table. A beat carrying hand-tuned groups keeps them exactly as authored.
ChartSpec buildChartSpec(Story story, {bool cb = false}) {
  final characters = <String, ChartCharacter>{
    for (final c in story.characters)
      c.id: ChartCharacter(
        label: c.name,
        width: c.weight.toDouble(),
        colour: c.colour ?? '#888888',
      ),
  };
  final order = story.laneOrder.isNotEmpty
      ? List<String>.from(story.laneOrder)
      : [for (final c in story.characters) c.id];
  final known = characters.keys.toSet();

  final columns = <ChartColumn>[];
  for (final beat in story.beats) {
    final caption = <String>[];
    for (final line in beat.caption) {
      caption.addAll(wrapCaption(line));
    }

    final handTuned = story.handTunedGroupsIn(beat.id);
    final List<ChartGroup> groups;
    if (handTuned.isNotEmpty) {
      groups = [for (final (centre, ids) in handTuned) ChartGroup(centre, ids)];
    } else {
      final clusters = [
        for (final party in story.partiesIn(beat.id))
          [
            for (final member in party)
              if (known.contains(member.id)) member.id,
          ],
      ];
      groups = groupsFor([
        for (final cluster in clusters)
          if (cluster.isNotEmpty) cluster,
      ]);
    }

    final tag = beat.tag;
    ChartCaption? captionExtra;
    if (tag != null && tag.isNotEmpty) {
      final lines = wrapCaption('\u25b8 $tag');
      captionExtra = ChartCaption(
        lines.length > 1 ? lines : [lines.first],
        tagColour,
      );
    }

    // The engine hatches from this beat's own lanes, so a stub for a strand
    // that is not standing here would raise; the Python builder drops it (and
    // says so on stdout), and the validator reports it as a data defect.
    final present = {for (final group in groups) ...group.ids};
    final entering = [
      for (final id in _presenceIds(
        story,
        beat,
        'enter',
        PresenceState.entering,
      ))
        if (known.contains(id)) id,
    ];
    final storedStubs = _presenceIds(
      story,
      beat,
      'stubs',
      PresenceState.exiting,
    );
    final stubs = [
      for (final id in storedStubs)
        if (known.contains(id) && present.contains(id))
          ChartStub(id, StubKind.leaving),
    ];

    final hard = beat.extra['hard'];
    columns.add(
      ChartColumn(
        beat: beat.name,
        loc: beat.at,
        caption: caption,
        groups: groups,
        enter: entering,
        stubs: stubs,
        hard: hard == null ? null : '$hard',
        captionExtra: captionExtra,
      ),
    );
  }

  final ys = <double>[];
  var y = rowZero - rowStep;
  for (var i = 0; i < columns.length; i++) {
    y += rowStep + (i == columns.length - 1 ? codaExtra : 0.0);
    ys.add(y);
  }

  final labelFont = widthFonts(characters, base: 24.0, lo: 14.0, hi: 26.0);
  final titleText =
      story.title + (story.year != null ? ' (${story.year})' : '');

  final titleNotes = _stringList(story.extra['title_notes']);
  final notes = <ChartTitleLine>[];
  if (titleNotes.isNotEmpty) {
    notes.addAll([for (final note in titleNotes) ChartTitleLine(note, 'note')]);
  } else {
    notes.add(
      const ChartTitleLine(
        'Each beat names the rubric category its shape belongs to.',
        'note',
      ),
    );
  }
  final score = story.score;
  if (score != null && score != 0 && titleNotes.isEmpty) {
    final scoreNote = _stringOrNull(story.extra['score_note']) ?? '';
    final line = 'Scored $score/30 on the rubric \u2014 $scoreNote'.replaceAll(
      RegExp(r'[ \u2014]+$'),
      '',
    );
    notes.add(ChartTitleLine(line, 'note'));
  }
  if (cb) {
    notes.add(
      const ChartTitleLine(
        'Colour-blind mode: each strand carries its own symbol; the darker the '
            'ribbon, the heavier the character. Hue is decoration only.',
        'note',
      ),
    );
  }

  final legendObject = story.legendObject;
  final storedLegendNote = _stringOrNull(story.extra['legend_note']);
  final runtime = story.runtimeMinutes;

  return ChartSpec(
    characters: characters,
    order: order,
    columns: columns,
    ys: ys,
    title:
        _titleBlock(story.extra['title_block']) ??
        <ChartTitleLine>[
          ChartTitleLine('$titleText \u2014 the braid', 'title'),
          ChartTitleLine(
            '${columns.length} beats, ${order.length} lanes'
                '${runtime != null ? ', $runtime minutes' : ''}. '
                'Time runs down the page.',
            'sub',
          ),
          const ChartTitleLine(
            'Row spacing widens before the coda \u2014 time passes there.',
            'note',
          ),
          ...notes,
        ],
    width: chartWidth,
    capX: 570.0,
    laneHi: 545.0,
    scale: 0.55,
    origin: 330.0,
    spineOld: 500.0,
    labelFont: labelFont,
    legendFont: labelFont,
    fonts: filmFonts,
    mirror: story.extra['mirror'] == true,
    cbSafe: cb,
    dashed: _dashed(story.extra['dashed']),
    legendTitle:
        'LANES \u2014 label size follows strand width'
        '${cb ? ', symbol = identity, darkness = weight' : ''}',
    legendNote: (storedLegendNote != null && storedLegendNote.isNotEmpty)
        ? storedLegendNote
        : 'Hatched lane = off-page.'
              '${legendObject != null ? ' \u201c$legendObject\u201d is a thing, not a person.' : ''}',
    tiers: 4,
    lineCap: 23,
    extraGap: 22,
  );
}

/// Where a beat links to in the page.
typedef ChartLinks = String? Function(int index, ChartColumn column);

/// A rendered film chart.
final class RenderedChart {
  /// Creates a rendered chart.
  const RenderedChart({
    required this.svg,
    required this.spec,
    required this.checks,
  });

  /// The SVG, with the class and scaling attributes the pages embed.
  final String svg;

  /// The spec it was drawn from.
  final ChartSpec spec;

  /// What the engine measured.
  final RenderChecks checks;

  /// Canvas height.
  int get height => checks.height;
}

/// Draw [story] the way the film pages embed it.
///
/// [mini] is the page's pinned map (rows collapse, no legend), [cb] is the
/// colour-blind treatment, and both are namespaced so several charts can share
/// one document.
RenderedChart renderFilmChart(
  Story story, {
  bool cb = false,
  bool mini = false,
  ChartLinks? href,
}) {
  final base = buildChartSpec(story, cb: cb);
  final links =
      href ??
      (int index, ChartColumn column) =>
          '#beat-${(index + 1).toString().padLeft(2, '0')}';

  var spec = base;
  if (mini) {
    final step = base.miniStep;
    spec = ChartSpec(
      characters: base.characters,
      order: base.order,
      columns: base.columns,
      ys: [
        for (var i = 0; i < base.ys.length; i++)
          (base.miniPad + i * step).toDouble(),
      ],
      title: base.title,
      width: 560,
      capX: base.capX,
      laneHi: base.laneHi,
      scale: base.scale,
      origin: base.origin,
      spineOld: base.spineOld,
      labelFont: base.labelFont,
      legendFont: base.legendFont,
      fonts: base.fonts,
      mirror: base.mirror,
      cbSafe: base.cbSafe,
      dashed: base.dashed,
      bands: base.bands,
      legendTitle: base.legendTitle,
      legendNote: base.legendNote,
      edge: base.edge,
      tiers: base.tiers,
      lineCap: base.lineCap,
      extraGap: base.extraGap,
      mini: true,
      miniPad: base.miniPad,
      miniStep: base.miniStep,
      beatHitHalf: step / 2,
      beatLinks: links,
    );
  }

  final rowMarkPrefix = mini ? 'mini' : (cb ? 'cbchart' : 'chart');
  final patternPrefix = (cb ? '-alt' : '') + (mini ? '-mini' : '');
  final full = ChartSpec(
    characters: spec.characters,
    order: spec.order,
    columns: spec.columns,
    ys: spec.ys,
    title: spec.title,
    width: spec.width,
    capX: spec.capX,
    laneHi: spec.laneHi,
    scale: spec.scale,
    origin: spec.origin,
    spineOld: spec.spineOld,
    labelFont: spec.labelFont,
    legendFont: spec.legendFont,
    fonts: spec.fonts,
    mirror: spec.mirror,
    cbSafe: spec.cbSafe,
    dashed: spec.dashed,
    bands: spec.bands,
    legendTitle: spec.legendTitle,
    legendNote: spec.legendNote,
    edge: spec.edge,
    tiers: spec.tiers,
    lineCap: spec.lineCap,
    extraGap: spec.extraGap,
    mini: spec.mini,
    miniPad: spec.miniPad,
    miniStep: spec.miniStep,
    beatHitHalf: spec.beatHitHalf,
    patternPrefix: patternPrefix,
    rowMarkPrefix: rowMarkPrefix,
    beatLinks: links,
  );

  final result = renderVertical(full);
  final svg = result.svg.replaceFirst(
    '<svg ',
    '<svg class="chart" preserveAspectRatio="xMidYMin meet" ',
  );
  return RenderedChart(svg: svg, spec: full, checks: result.checks);
}
