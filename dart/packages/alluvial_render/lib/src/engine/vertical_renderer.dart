import 'dart:math' as math;

import '../py_num.dart';
import '../spec/chart_spec.dart';
import 'palette.dart';
import 'ribbon.dart';

/// Two strands drawn closer together than the engine allows.
final class LaneOverlap {
  /// Creates a report of a collision in column [column].
  const LaneOverlap({
    required this.column,
    required this.left,
    required this.right,
    required this.gap,
  });

  /// Index of the column the collision is in.
  final int column;

  /// The strand sitting to the left.
  final String left;

  /// The strand sitting to the right.
  final String right;

  /// The gap between them, in pixels.
  final double gap;
}

/// What the engine measured about the chart it drew.
final class RenderChecks {
  /// Creates the checks.
  const RenderChecks({
    required this.height,
    required this.legendRows,
    required this.laneOverlaps,
  });

  /// Canvas height.
  final int height;

  /// How many rows the legend wrapped into.
  final int legendRows;

  /// Lane collisions, empty when the layout is clean.
  final List<LaneOverlap> laneOverlaps;

  /// True when no two strands were drawn overlapping.
  bool get isClean => laneOverlaps.isEmpty;
}

/// A drawn chart.
final class RenderResult {
  /// Creates a result.
  const RenderResult({
    required this.svg,
    required this.checks,
    required this.laneX,
  });

  /// The SVG document.
  final String svg;

  /// What the engine measured.
  final RenderChecks checks;

  /// The x of every strand in every column — the layout, for tests and pages.
  final List<Map<String, double>> laneX;
}

/// The braid chart: time runs down the page, one lane per strand.
///
/// A port of the Python engine that produced every approved chart, kept
/// byte-identical on purpose — the layout is hand-tuned across a hundred
/// artifacts, so "equivalent output" is not good enough. Every number is
/// printed through [PyNum].
RenderResult renderVertical(ChartSpec spec) {
  final characters = spec.characters;
  final order = spec.order;
  final columns = spec.columns;
  final ys = spec.ys;
  final scale = spec.scale;
  final origin = spec.origin;
  final spineOld = spec.spineOld;
  final mirror = spec.mirror;
  final width = spec.width;
  final capX = spec.capX;
  final laneHi = spec.laneHi;
  final fonts = spec.fonts;
  final labelFont = spec.labelFont;
  final legendFont = spec.legendFont;
  final gap = 5 * scale;
  final columnCount = columns.length;
  final mini = spec.mini;
  final lineCap = spec.lineCap;
  final extraGap = spec.extraGap;

  double fx(double y) => mirror
      ? origin + (spineOld - y) * scale
      : origin + (y - spineOld) * scale;

  /// Stack the strands of one group around [centre].
  Map<String, double> vstack(double centre, List<String> ids) {
    // Mirroring reverses the stacking order, so a pair that ran top-to-bottom
    // now runs right-to-left.
    final stacked = mirror ? ids.reversed.toList() : ids;
    var total = 0.0;
    for (final id in stacked) {
      total += characters[id]!.width * scale;
    }
    total += gap * (stacked.length - 1);
    var x = centre - total / 2;
    final out = <String, double>{};
    for (final id in stacked) {
      final ribbonWidth = characters[id]!.width * scale;
      out[id] = x + ribbonWidth / 2;
      x += ribbonWidth + gap;
    }
    return out;
  }

  final cb = spec.cbSafe
      ? colourBlindStyles(characters, order)
      : const <String, ColourBlindStyle>{};
  final pp = spec.patternPrefix;

  String fillOf(String id) =>
      cb.isEmpty ? characters[id]!.colour : 'url(#cb$pp-$id)';

  final laneX = <Map<String, double>>[];
  for (final column in columns) {
    final row = <String, double>{};
    for (final group in column.groups) {
      row.addAll(vstack(fx(group.centre), group.ids));
    }
    laneX.add(row);
  }

  /// Greedy staircase so no two lane names share a tier and overlap.
  Map<String, int> laneTiers(List<(double, String)> lanes, int tiers) {
    final last = List<double?>.filled(tiers, null);
    final out = <String, int>{};
    final sorted = List<(double, String)>.of(lanes)
      ..sort((a, b) {
        final byX = a.$1.compareTo(b.$1);
        return byX != 0 ? byX : a.$2.compareTo(b.$2);
      });
    for (final (x, id) in sorted) {
      final half = pyLen(characters[id]!.label) * labelFont[id]! * 0.29;
      var placed = false;
      for (var tier = 0; tier < tiers; tier++) {
        final free = last[tier] == null || x - half > last[tier]! + 10;
        if (free) {
          out[id] = tier;
          last[tier] = x + half;
          placed = true;
          break;
        }
      }
      if (!placed) out[id] = tiers - 1;
    }
    return out;
  }

  /// How deep a beat's caption block runs, so the footer can clear the deepest.
  double captionDepth(ChartColumn column) {
    var depth =
        46 + lineCap * column.caption.length + (column.hard != null ? 8 : 0);
    final extra = column.captionExtra;
    if (extra != null) depth += extraGap * extra.lines.length;
    if (column.enter.isNotEmpty) depth += extraGap;
    return depth.toDouble();
  }

  (int, double) measureLegend() {
    var cx = 60.0;
    var rows = 1;
    var rowMax = 0.0;
    for (final id in order) {
      final character = characters[id]!;
      final font = legendFont[id]!;
      final swatch = math.max(6, PyNum.roundToInt(character.width * scale));
      final item = swatch + 6 + pyLen(character.label) * font * 0.56 + 22;
      if (cx + item > width - 60) {
        rows += 1;
        cx = 60.0;
      }
      cx += item;
      rowMax = math.max(rowMax, font);
    }
    return (rows, rowMax);
  }

  final lastRow = ys.last;
  final (legendRows, legendFontMax) = measureLegend();
  final double bandY;
  final double legendY;
  final double? noteY;
  final double ruleY;
  final double titleTop;
  final int height;
  if (mini) {
    height = (lastRow + spec.miniPad).toInt();
    bandY = 0;
    legendY = 0;
    noteY = null;
    ruleY = 0;
    titleTop = 0;
  } else {
    var deepest = 0.0;
    for (final column in columns) {
      deepest = math.max(deepest, captionDepth(column));
    }
    bandY = lastRow + deepest + 26;
    legendY = bandY + (spec.bands.isNotEmpty ? 58 : 26);
    final legendBottom =
        legendY +
        (legendRows - 1) * (legendFontMax * 1.5) +
        legendFontMax * 1.1;
    noteY = spec.legendNote != null ? legendBottom + 24 : null;
    ruleY = (noteY ?? legendBottom) + 30;
    titleTop = ruleY + 34;
    height = (titleTop + 26 * (spec.title.length - 1) + 30).toInt();
  }

  final svg = <String>[];
  svg.add(
    '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" '
    'viewBox="0 0 $width $height" font-family="Helvetica, Arial, sans-serif">',
  );
  var defs =
      '<defs><pattern id="dots$pp" width="26" height="26" '
      'patternUnits="userSpaceOnUse"><circle cx="1" cy="1" r="0.9" '
      'fill="#d8d2c8"/></pattern>';
  if (!spec.cbSafe) defs += '</defs>';
  svg.add(defs);
  if (spec.cbSafe) {
    for (final id in order) {
      final style = cb[id]!;
      svg.add(
        '<pattern id="cb$pp-$id" width="9" height="9" '
        'patternUnits="userSpaceOnUse">',
      );
      svg.add(
        '<rect width="9" height="9" fill="${characters[id]!.colour}" '
        'fill-opacity="${PyNum.repr(style.opacity)}"/>',
      );
      if (style.symbol != null) {
        svg.add(
          '<path d="${style.symbol}" fill="none" '
          'stroke="${style.symbolColour}" stroke-width="1.3" '
          'stroke-linecap="round" opacity="0.92"/>',
        );
      }
      svg.add('</pattern>');
    }
    svg.add('</defs>');
  }
  svg.add('<rect width="$width" height="$height" fill="#faf7f2"/>');
  svg.add(
    '<rect x="0" y="${PyNum.repr(ys.first - 90)}" width="$width" '
    'height="${PyNum.repr(lastRow - ys.first + 180)}" fill="url(#dots$pp)" '
    'opacity="0.55"/>',
  );

  for (final y in ys) {
    svg.add(
      '<line x1="70" y1="${PyNum.repr(y)}" x2="${PyNum.repr(laneHi)}" '
      'y2="${PyNum.repr(y)}" stroke="#c9c2b6" stroke-width="1" '
      'stroke-dasharray="2 5"/>',
    );
    svg.add(
      '<line x1="${PyNum.repr(laneHi)}" y1="${PyNum.repr(y)}" '
      'x2="${PyNum.repr(capX - 14)}" y2="${PyNum.repr(y)}" stroke="#ded7cb" '
      'stroke-width="1"/>',
    );
  }

  for (var i = 0; i < columnCount && !mini; i++) {
    final column = columns[i];
    final y = ys[i];
    svg.add(
      '<text x="${PyNum.repr(capX)}" y="${PyNum.repr(y - 12)}" '
      'font-size="${PyNum.number(fonts.beat)}" font-weight="700" '
      'fill="#2b2622" letter-spacing="1.1">${column.beat}</text>',
    );
    if (column.loc != null) {
      svg.add(
        '<text x="${PyNum.repr(capX)}" y="${PyNum.repr(y + 16)}" '
        'font-size="${PyNum.number(fonts.loc)}" fill="#9a9086">'
        '${column.loc}</text>',
      );
    }
    for (var j = 0; j < column.caption.length; j++) {
      svg.add(
        '<text x="${PyNum.repr(capX)}" y="${PyNum.repr(y + 46 + j * lineCap)}" '
        'font-size="${PyNum.number(fonts.caption)}" font-style="italic" '
        'fill="#7d7568">${column.caption[j]}</text>',
      );
    }
    var ly = y + 46 + column.caption.length * lineCap + 8;
    if (column.hard != null) {
      svg.add(
        '<text x="${PyNum.repr(capX)}" y="${PyNum.repr(ly)}" '
        'font-size="${PyNum.number(fonts.hard)}" font-weight="700" '
        'fill="#9c3b34">${column.hard}</text>',
      );
      ly += extraGap;
    }
    final extra = column.captionExtra;
    if (extra != null) {
      for (final line in extra.lines) {
        svg.add(
          '<text x="${PyNum.repr(capX)}" y="${PyNum.repr(ly)}" '
          'font-size="${PyNum.number(fonts.hard - 1)}" font-weight="700" '
          'fill="${extra.colour}">$line</text>',
        );
        ly += extraGap;
      }
    }
    if (column.enter.isNotEmpty) {
      svg.add(
        '<text x="${PyNum.repr(capX)}" y="${PyNum.repr(ly)}" '
        'font-size="${PyNum.number(fonts.caption - 2)}" fill="#9a9086">'
        'new lanes \u25b8</text>',
      );
      var cx = capX + 78;
      var enterY = ly;
      for (final id in column.enter) {
        final label = characters[id]!.label;
        final needed = pyLen(label) * labelFont[id]! * 0.62;
        if (cx + needed > width - 8) {
          cx = capX + 78;
          enterY = enterY + (fonts.caption - 2) * 1.5;
        }
        svg.add(
          '<text x="${PyNum.fixed(cx, 0)}" y="${PyNum.repr(enterY)}" '
          'font-size="${PyNum.fixed(labelFont[id]!, 1)}" font-weight="700" '
          'fill="${characters[id]!.colour}">$label</text>',
        );
        cx += needed + 12;
      }
    }
  }

  for (var i = 0; i < columnCount; i++) {
    for (final stub in columns[i].stubs) {
      final x = laneX[i][stub.id];
      if (x == null) continue;
      final y = ys[i];
      final ribbonWidth = characters[stub.id]!.width * scale;
      final fill = fillOf(stub.id);
      switch (stub.kind) {
        case StubKind.entering:
          svg.add(
            '<path d="${vRibbon(x, y - 58, x, y, 2, ribbonWidth)}" fill="$fill" '
            'fill-opacity="${spec.cbSafe ? '1' : '0.8'}"/>',
          );
        case StubKind.leaving:
          svg.add(
            '<path d="${vRibbon(x, y, x, y + 58, ribbonWidth, 2)}" fill="$fill" '
            'fill-opacity="${spec.cbSafe ? '1' : '0.8'}"/>',
          );
        case StubKind.breaking:
          svg.add(
            '<path d="${vRibbon(x, y, x, y + 46, ribbonWidth, 2)}" fill="$fill" '
            'fill-opacity="${spec.cbSafe ? '1' : '0.85'}"/>',
          );
          final bx = x + math.max(12, ribbonWidth);
          final by = y + 34;
          for (final (dx, dy) in const [(9, -9), (9, 9)]) {
            svg.add(
              '<line x1="${PyNum.repr(bx - dx)}" y1="${PyNum.repr(by + dy)}" '
              'x2="${PyNum.repr(bx + dx)}" y2="${PyNum.repr(by - dy)}" '
              'stroke="#9c3b34" stroke-width="2"/>',
            );
          }
        case StubKind.fading:
          final drift = x > origin ? 20.0 : -20.0;
          svg.add(
            '<path d="${vRibbon(x, y, x + drift, y + 135, ribbonWidth, 2)}" '
            'fill="$fill" fill-opacity="${spec.cbSafe ? '0.45' : '0.34'}"/>',
          );
      }
    }
  }

  for (var i = 0; i < columnCount; i++) {
    final id = columns[i].terminalId;
    if (id == null) continue;
    // A terminal on the first column reads the previous row as the last, which
    // is what the Python engine does with a negative index.
    final from = i == 0 ? laneX.length - 1 : i - 1;
    final x = laneX[from][id]!;
    final colour = characters[id]!.colour;
    final y0 = ys[from];
    final y1 = y0 + (ys[i] - y0) * 0.60;
    svg.add(
      '<path d="${vRibbon(x, y0, x, y1, characters[id]!.width * scale, 2)}" '
      'fill="${fillOf(id)}" fill-opacity="${spec.cbSafe ? '0.8' : '0.55'}"/>',
    );
    svg.add(
      '<circle cx="${PyNum.fixed(x, 1)}" cy="${PyNum.fixed(y1, 1)}" r="6" '
      'fill="$colour"/>',
    );
    svg.add(
      '<line x1="${PyNum.fixed(x + 10, 1)}" y1="${PyNum.fixed(y1, 1)}" '
      'x2="${PyNum.fixed(capX - 16, 1)}" y2="${PyNum.fixed(y1, 1)}" '
      'stroke="$colour" stroke-width="1" stroke-dasharray="3 4" '
      'opacity="0.4"/>',
    );
  }

  for (final id in order) {
    final ribbonWidth = characters[id]!.width * scale;
    final colour = characters[id]!.colour;
    final dashed = spec.dashed[id] ?? const <int>[];
    for (var i = 0; i < columnCount - 1; i++) {
      if (!laneX[i].containsKey(id) || !laneX[i + 1].containsKey(id)) continue;
      final path = vRibbon(
        laneX[i][id]!,
        ys[i],
        laneX[i + 1][id]!,
        ys[i + 1],
        ribbonWidth,
      );
      if (dashed.contains(i)) {
        svg.add(
          '<path d="$path" fill="${fillOf(id)}" '
          'fill-opacity="${spec.cbSafe ? '0.3' : '0.16'}"/>',
        );
        svg.add(
          '<path d="$path" fill="none" stroke="$colour" stroke-width="1.5" '
          'stroke-dasharray="7 5" opacity="0.95"/>',
        );
      } else {
        svg.add(
          '<path d="$path" fill="${fillOf(id)}" '
          'fill-opacity="${spec.cbSafe ? '1' : '0.82'}"/>',
        );
      }
    }
  }

  final edge = spec.edge;
  if (edge == 'top' || edge == 'both') {
    for (final id in order) {
      final x = laneX.first[id];
      if (x == null) continue;
      svg.add(
        '<path d="${vRibbon(x, ys.first - 58, x, ys.first, 2, characters[id]!.width * scale)}" '
        'fill="${fillOf(id)}" fill-opacity="${spec.cbSafe ? '1' : '0.72'}"/>',
      );
    }
  }
  if (edge == 'bottom' || edge == 'both') {
    for (final id in order) {
      final x = laneX.last[id];
      if (x == null) continue;
      svg.add(
        '<path d="${vRibbon(x, ys.last, x, ys.last + 58, characters[id]!.width * scale, 2)}" '
        'fill="${fillOf(id)}" fill-opacity="${spec.cbSafe ? '1' : '0.72'}"/>',
      );
    }
  }

  final present = <(double, String)>[
    if (!mini)
      for (final id in order)
        if (laneX.first.containsKey(id)) (laneX.first[id]!, id),
  ];
  final tiers = laneTiers(present, spec.tiers);
  for (final (x, id) in present) {
    final font = labelFont[id]!;
    svg.add(
      '<text x="${PyNum.fixed(x, 1)}" '
      'y="${PyNum.fixed(44 + tiers[id]! * 40 + font * 0.8, 0)}" '
      'font-size="${PyNum.number(font)}" font-weight="700" '
      'text-anchor="middle" fill="${characters[id]!.colour}">'
      '${characters[id]!.label}</text>',
    );
  }
  for (final (x, id) in present) {
    final font = labelFont[id]!;
    svg.add(
      '<line x1="${PyNum.fixed(x, 1)}" '
      'y1="${PyNum.fixed(44 + tiers[id]! * 40 + font * 0.8 + 7, 0)}" '
      'x2="${PyNum.fixed(x, 1)}" y2="${PyNum.repr(ys.first - 14)}" '
      'stroke="${characters[id]!.colour}" stroke-width="1" opacity="0.28"/>',
    );
  }

  if (!mini) {
    for (final band in spec.bands) {
      svg.add(
        '<text x="${PyNum.fixed((band.x0 + band.x1) / 2, 0)}" '
        'y="${PyNum.repr(bandY)}" font-size="${PyNum.number(fonts.band)}" '
        'font-weight="700" letter-spacing="2" text-anchor="middle" '
        'fill="#b3aa9d">${band.text}</text>',
      );
    }
  }

  void emitBeatLinks() {
    final links = spec.beatLinks;
    if (links == null) return;
    final half = spec.beatHitHalf;
    final pre = spec.rowMarkPrefix;
    svg.add('<g class="beat-rows">');
    for (var i = 0; i < columnCount; i++) {
      final href = links(i, columns[i]);
      if (href == null || href.isEmpty) continue;
      final y = ys[i];
      final n = (i + 1).toString().padLeft(2, '0');
      svg.add(
        '<rect class="rowmark" id="$pre-$n" data-beat="$n" x="0" '
        'y="${PyNum.fixedNum(y - half, 0)}" width="$width" '
        'height="${PyNum.number(half * 2)}" fill="transparent" '
        'pointer-events="none"/>',
      );
    }
    for (var i = 0; i < columnCount; i++) {
      final href = links(i, columns[i]);
      if (href == null || href.isEmpty) continue;
      final y = ys[i];
      svg.add(
        '<a class="beat-link" href="$href"><rect class="hit" x="0" '
        'y="${PyNum.fixedNum(y - half, 0)}" width="$width" '
        'height="${PyNum.number(half * 2)}" fill="transparent"/>'
        '<title>${columns[i].beat}</title></a>',
      );
    }
    svg.add('</g>');
  }

  // Mini mode is the page's pinned map: rows collapse onto each other, the
  // legend and title are dropped, and the svg still has to CLOSE.
  if (mini) {
    emitBeatLinks();
    svg.add('</svg>');
    return RenderResult(
      svg: svg.join('\n'),
      checks: RenderChecks(
        height: height,
        legendRows: legendRows,
        laneOverlaps: findLaneOverlaps(laneX, characters, scale),
      ),
      laneX: laneX,
    );
  }

  var cy = legendY;
  svg.add(
    '<text x="60" y="${PyNum.repr(cy - 16)}" '
    'font-size="${PyNum.number(fonts.legendTitle)}" font-weight="700" '
    'letter-spacing="1.1" fill="#9a9086">${spec.legendTitle}</text>',
  );
  var cx = 60.0;
  for (final id in order) {
    final character = characters[id]!;
    final font = legendFont[id]!;
    final swatch = math.max(6, PyNum.roundToInt(character.width * scale));
    final item = swatch + 6 + pyLen(character.label) * font * 0.56 + 22;
    final needed = swatch + 6 + pyLen(character.label) * font * 0.62;
    if (cx + math.max(item, needed) > width - 2) {
      cx = 60.0;
      cy = cy + legendFontMax * 1.5;
    }
    final swatchHeight = math.max(
      spec.cbSafe ? 11 : 9,
      PyNum.roundToInt(font * 0.62 * (spec.cbSafe ? 1.3 : 1)),
    );
    svg.add(
      '<rect x="${PyNum.fixed(cx, 0)}" '
      'y="${PyNum.fixed(cy + font * 0.78 - swatchHeight / 2, 0)}" '
      'width="${spec.cbSafe ? math.max(swatch, 11) : swatch}" '
      'height="$swatchHeight" rx="2" fill="${fillOf(id)}" '
      'fill-opacity="${spec.cbSafe ? '1' : '0.85'}"/>',
    );
    svg.add(
      '<text x="${PyNum.fixed(cx + swatch + 6, 0)}" '
      'y="${PyNum.fixed(cy + font * 0.78, 0)}" '
      'font-size="${PyNum.number(font)}" font-weight="600" '
      'fill="#2b2622">${character.label}</text>',
    );
    cx += item;
  }
  if (spec.legendNote != null) {
    svg.add(
      '<text x="60" y="${PyNum.fixed(noteY!, 0)}" '
      'font-size="${PyNum.number(fonts.legendTitle + 1)}" font-style="italic" '
      'fill="#8b8377">${spec.legendNote}</text>',
    );
  }

  emitBeatLinks();

  svg.add(
    '<line x1="60" y1="${PyNum.repr(ruleY)}" x2="${PyNum.number(width - 60)}" '
    'y2="${PyNum.repr(ruleY)}" stroke="#ded7cb"/>',
  );
  for (var k = 0; k < spec.title.length; k++) {
    final line = spec.title[k];
    final y = titleTop + k * 26;
    if (line.style == 'title') {
      svg.add(
        '<text x="60" y="${PyNum.repr(y)}" font-family="Georgia, serif" '
        'font-size="${PyNum.number(fonts.title)}" fill="#22201d">'
        '${line.text}</text>',
      );
    } else if (line.style == 'sub') {
      svg.add(
        '<text x="60" y="${PyNum.repr(y)}" '
        'font-size="${PyNum.number(fonts.sub)}" fill="#6f675c">'
        '${line.text}</text>',
      );
    } else {
      svg.add(
        '<text x="60" y="${PyNum.repr(y)}" '
        'font-size="${PyNum.number(fonts.sub2)}" font-style="italic" '
        'fill="#9a9086">${line.text}</text>',
      );
    }
  }
  svg.add('</svg>');

  return RenderResult(
    svg: svg.join('\n'),
    checks: RenderChecks(
      height: height,
      legendRows: legendRows,
      laneOverlaps: findLaneOverlaps(laneX, characters, scale),
    ),
    laneX: laneX,
  );
}

/// Two strands closer than half a pixel are drawn on top of each other.
List<LaneOverlap> findLaneOverlaps(
  List<Map<String, double>> laneX,
  Map<String, ChartCharacter> characters,
  double scale,
) {
  final bad = <LaneOverlap>[];
  for (var i = 0; i < laneX.length; i++) {
    final items = laneX[i].entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (var j = 0; j + 1 < items.length; j++) {
      final left = items[j];
      final right = items[j + 1];
      final gap =
          (right.value - characters[right.key]!.width * scale / 2) -
          (left.value + characters[left.key]!.width * scale / 2);
      if (gap < 0.5) {
        bad.add(
          LaneOverlap(
            column: i,
            left: left.key,
            right: right.key,
            gap: PyNum.roundTo(gap, 1),
          ),
        );
      }
    }
  }
  return bad;
}
