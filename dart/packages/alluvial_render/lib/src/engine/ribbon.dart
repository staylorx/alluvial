import '../py_num.dart';

/// A constant-thickness bezier band running in y: the mirror of the horizontal
/// ribbon. Travel is measured in y and thickness in x, so a strand's lane is a
/// column of the page.
///
/// The two control points sit at 0.42 / 0.58 of the span, which is what makes
/// the flow read as a smooth S-curve rather than a straight taper.
String vRibbon(
  double x0,
  double y0,
  double x1,
  double y1,
  double w0, [
  double? w1,
]) {
  final half0 = w0 / 2;
  final half1 = (w1 ?? w0) / 2;
  final mid0 = y0 + (y1 - y0) * 0.42;
  final mid1 = y0 + (y1 - y0) * 0.58;
  final a = PyNum.fixed(x0 - half0, 1);
  final b = PyNum.fixed(x1 - half1, 1);
  final c = PyNum.fixed(x1 + half1, 1);
  final d = PyNum.fixed(x0 + half0, 1);
  final y0s = PyNum.fixed(y0, 1);
  final y1s = PyNum.fixed(y1, 1);
  final m0 = PyNum.fixed(mid0, 1);
  final m1 = PyNum.fixed(mid1, 1);
  return 'M $a $y0s '
      'C $a $m0 $b $m1 $b $y1s '
      'L $c $y1s '
      'C $c $m1 $d $m0 $d $y0s Z';
}
