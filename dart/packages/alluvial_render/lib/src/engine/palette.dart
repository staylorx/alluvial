import 'dart:math' as math;

import '../py_num.dart';
import '../spec/chart_spec.dart';

/// Sparse SVG symbols for colour-blind mode. Index 0 is "no symbol": the
/// heaviest strand gets the cleanest, highest-contrast treatment, and every
/// other strand gets a distinct mark.
///
/// Tiles are 9x9 user units, so even a thin ribbon shows a whole symbol.
const List<String?> sparseSymbols = [
  null, // solid (heaviest)
  'M0,9 L9,0', // single up diagonal
  'M0,0 L9,9', // single down diagonal
  'M4.5,4.5 m-1.7,0 a1.7,1.7 0 1,0 3.4,0 a1.7,1.7 0 1,0 -3.4,0', // dot
  'M4.5,1 V8 M1,4.5 H8', // plus
  'M1,1 L8,8 M8,1 L1,8', // cross
  'M4.5,1 V8', // vertical bar
  'M1,4.5 H8', // horizontal bar
  'M-1,9 L3,5 M5,9 L9,5', // sparse double diagonal
  'M4.5,4.5 m-2.7,0 a2.7,2.7 0 1,0 5.4,0 a2.7,2.7 0 1,0 -5.4,0', // ring
  'M4.5,1.6 L8.1,7.6 H0.9 Z', // triangle
  'M2.6,2.6 m-1.3,0 a1.3,1.3 0 1,0 2.6,0 a1.3,1.3 0 1,0 -2.6,0 '
      'M6.6,6.6 m-1.3,0 a1.3,1.3 0 1,0 2.6,0 a1.3,1.3 0 1,0 -2.6,0', // dot pair
  'M1,1.5 H8 M1,7.5 H8', // two bars
  'M3.2,1 L7,4.5 L3.2,8', // chevron
];

/// Two hex colours mixed by [t], as `#rrggbb`.
String mixColour(String hexA, String hexB, double t) {
  final a = [
    for (final i in const [1, 3, 5])
      int.parse(hexA.substring(i, i + 2), radix: 16),
  ];
  final b = [
    for (final i in const [1, 3, 5])
      int.parse(hexB.substring(i, i + 2), radix: 16),
  ];
  final out = <String>[];
  for (var i = 0; i < 3; i++) {
    // CPython rounds half to even; the port must print the same two digits.
    final mixed = PyNum.roundToInt(a[i] + (b[i] - a[i]) * t);
    out.add(mixed.toRadixString(16).padLeft(2, '0'));
  }
  return '#${out.join()}';
}

/// How one strand is drawn in colour-blind mode.
final class ColourBlindStyle {
  /// Creates the treatment for one strand.
  const ColourBlindStyle({
    required this.rank,
    required this.opacity,
    required this.symbol,
    required this.symbolColour,
  });

  /// Position in the width ranking, 0 heaviest.
  final int rank;

  /// Fill opacity from the luminance ramp.
  final double opacity;

  /// The strand's symbol path, or null for the heaviest strand (solid).
  final String? symbol;

  /// The darkened strand colour the symbol strokes in.
  final String symbolColour;
}

/// Rank the strands by ribbon width, ramp the contrast down the ranking, and
/// give each a unique symbol.
///
/// Hue still differs, but it is no longer load-bearing: the symbol identifies
/// and the darkness ranks.
Map<String, ColourBlindStyle> colourBlindStyles(
  Map<String, ChartCharacter> characters,
  List<String> order, {
  String background = '#faf7f2',
}) {
  final ranked = List<String>.from(order)
    ..sort((a, b) {
      final byWidth = characters[b]!.width.compareTo(characters[a]!.width);
      return byWidth != 0
          ? byWidth
          : order.indexOf(a).compareTo(order.indexOf(b));
    });
  final span = math.max(1, ranked.length - 1);
  final out = <String, ColourBlindStyle>{};
  for (var i = 0; i < ranked.length; i++) {
    final id = ranked[i];
    final t = i / span;
    out[id] = ColourBlindStyle(
      rank: i,
      opacity: PyNum.roundTo(0.95 - 0.50 * t, 3),
      symbol: sparseSymbols[i % sparseSymbols.length],
      symbolColour: mixColour(characters[id]!.colour, '#141414', 0.35),
    );
  }
  return out;
}

/// Per-strand label size from ribbon width. `sqrt` keeps the small ones legible
/// while the big ones still dominate.
Map<String, double> widthFonts(
  Map<String, ChartCharacter> characters, {
  double base = 24.0,
  double lo = 15.0,
  double hi = 26.0,
  double power = 0.5,
}) {
  var maxWidth = 0.0;
  for (final c in characters.values) {
    if (c.width > maxWidth) maxWidth = c.width;
  }
  final out = <String, double>{};
  for (final entry in characters.entries) {
    final scaled = base * math.pow(entry.value.width / maxWidth, power);
    out[entry.key] = PyNum.roundTo(math.min(hi, math.max(lo, scaled)), 1);
  }
  return out;
}
