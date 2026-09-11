import 'dart:typed_data';

/// Python's `len(s)`: code points, not UTF-16 code units.
///
/// Every width the engine estimates is `len(text) * size * factor`, and those
/// estimates decide where the legend wraps and which lane-name tier a label
/// lands in — so the count has to match Python's exactly.
int pyLen(String s) => s.runes.length;

/// Python-faithful numeric formatting.
///
/// The renderer is compared byte-for-byte against the Python engine, so every
/// number in the SVG must print exactly as CPython prints it. Two differences
/// from Dart's built-ins matter, and both are reachable by the real layout:
///
/// * CPython rounds **half to even** on the exact decimal value of the binary
///   double. Dart's `round()` is half-away-from-zero, so `round(16.5)` is `17`
///   where Python says `16` — and a ribon width of 30 at scale 0.55 hits that
///   exact tie.
/// * CPython's `round(x, n)` and `f"{x:.nf}"` round the *exact* value, not the
///   shortest decimal repr. `2.675` is really `2.67499999…`, so Python gives
///   `2.67` and a naive `toStringAsFixed(2)` gives `2.68`.
///
/// [fixed] therefore decomposes the double into its exact decimal expansion
/// with `BigInt` arithmetic and rounds that, which is what CPython does.
final class PyNum {
  const PyNum._();

  /// Exact decimal of `|v|`: the value is `digits * 10^-places`.
  static ({String digits, int places}) exactAbsolute(double v) {
    final data = ByteData(8)..setFloat64(0, v.abs(), Endian.big);
    final bits = data.getUint64(0);
    final exponentBits = (bits >> 52) & 0x7FF;
    final fractionBits = bits & 0xFFFFFFFFFFFFF;
    final BigInt mantissa;
    final int exponent;
    if (exponentBits == 0) {
      mantissa = BigInt.from(fractionBits);
      exponent = -1074;
    } else {
      mantissa = BigInt.from(fractionBits | (1 << 52));
      exponent = exponentBits - 1075;
    }
    if (mantissa == BigInt.zero) return (digits: '0', places: 0);
    if (exponent >= 0) {
      return (digits: (mantissa << exponent).toString(), places: 0);
    }
    final places = -exponent;
    final scaled = mantissa * BigInt.from(5).pow(places);
    return (digits: scaled.toString(), places: places);
  }

  static String _withPoint(String digits, int places) {
    if (places == 0) return digits;
    final padded = digits.padLeft(places + 1, '0');
    final cut = padded.length - places;
    return '${padded.substring(0, cut)}.${padded.substring(cut)}';
  }

  static bool _isOdd(String digits) {
    final last = digits.codeUnitAt(digits.length - 1) - 0x30;
    return last.isOdd;
  }

  static String _roundExact(String digits, int places, int to) {
    if (places <= to) return _withPoint(digits + '0' * (to - places), to);
    final drop = places - to;
    final String kept;
    final String dropped;
    if (digits.length > drop) {
      kept = digits.substring(0, digits.length - drop);
      dropped = digits.substring(digits.length - drop);
    } else {
      kept = '0';
      dropped = digits.padLeft(drop, '0');
    }
    final first = dropped.codeUnitAt(0) - 0x30;
    final bool up;
    if (first > 5) {
      up = true;
    } else if (first < 5) {
      up = false;
    } else if (dropped.substring(1).contains(RegExp('[1-9]'))) {
      up = true;
    } else {
      up = _isOdd(kept); // an exact tie rounds to the even neighbour
    }
    final rounded = up ? (BigInt.parse(kept) + BigInt.one).toString() : kept;
    return _withPoint(rounded, to);
  }

  /// Python's `f"{v:.<digits>f}"`.
  static String fixed(double v, int digits) {
    final sign = (v.isNegative && !v.isNaN) ? '-' : '';
    if (v.isNaN) return 'nan';
    if (v.isInfinite) return '${sign}inf';
    final exact = exactAbsolute(v);
    return '$sign${_roundExact(exact.digits, exact.places, digits)}';
  }

  /// Python's `round(v, digits)` — a double, rounded half to even.
  static double roundTo(double v, int digits) => double.parse(fixed(v, digits));

  /// Python's `round(v)` — an int, rounded half to even.
  static int roundToInt(double v) => int.parse(fixed(v, 0));

  /// Python's `str(v)` for a float.
  ///
  /// Both languages print the shortest round-tripping decimal, so Dart's own
  /// representation matches CPython for the range this renderer produces
  /// (`~1e-3` to `~1e6`). Outside it CPython switches to exponent notation at
  /// different thresholds (`1e-05` where Dart writes `0.00001`), which no chart
  /// coordinate reaches.
  static String repr(double v) {
    if (v.isNaN) return 'nan';
    if (v.isInfinite) return v.isNegative ? '-inf' : 'inf';
    return v.toString();
  }

  /// Python's `str(v)`: an int prints bare, a float keeps its point.
  static String number(num v) => v is int ? '$v' : repr(v.toDouble());

  /// Python's `f"{v:.<digits>f}"` for either runtime type.
  static String fixedNum(num v, int digits) => fixed(v.toDouble(), digits);
}
