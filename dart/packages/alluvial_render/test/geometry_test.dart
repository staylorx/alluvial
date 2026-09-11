import 'package:alluvial_render/alluvial_render.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// The engine's own geometry, pinned against the Python formula by hand.
/// These are the numbers a byte-diff would only tell you AFTER they were wrong.
void main() {
  group('vRibbon', () {
    test('Given a straight band, when drawn, then it is the expected path', () {
      vRibbon(100, 200, 100, 400, 10).should.be(
        'M 95.0 200.0 C 95.0 284.0 95.0 316.0 95.0 400.0 '
        'L 105.0 400.0 C 105.0 316.0 105.0 284.0 105.0 200.0 Z',
      );
    });

    test('Given different widths, when drawn, then it tapers both edges', () {
      // a stub: 3px at one end, full width at the other
      final path = vRibbon(0, 0, 0, 58, 2, 10);
      path.should.contain('M -1.0 0.0');
      path.should.contain('L 5.0 58.0');
    });
  });

  group('colour-blind ranking', () {
    final characters = {
      'heavy': const ChartCharacter(
        label: 'Heavy',
        width: 20,
        colour: '#1b57c4',
      ),
      'light': const ChartCharacter(
        label: 'Light',
        width: 5,
        colour: '#d0316a',
      ),
      'mid': const ChartCharacter(label: 'Mid', width: 11, colour: '#6e9078'),
    };

    test(
      'Given strands of different weight, when ranked, then heaviest is solid',
      () {
        final styles = colourBlindStyles(characters, ['light', 'heavy', 'mid']);
        styles['heavy']!.rank.should.be(0);
        styles['heavy']!.symbol.should.beNull();
        (styles['heavy']!.opacity > styles['mid']!.opacity).should.be(true);
        (styles['mid']!.opacity > styles['light']!.opacity).should.be(true);
        styles['light']!.symbol.should.beAssignableTo<String>();
        (styles['light']!.symbolColour.startsWith('#')).should.be(true);
        (styles['light']!.symbolColour == '#d0316a').should.be(false);
      },
    );
  });

  group('widthFonts', () {
    test('Given a width, when scaled, then it follows sqrt and the clamps', () {
      final fonts = widthFonts(
        {
          'big': const ChartCharacter(
            label: 'Big',
            width: 20,
            colour: '#000000',
          ),
          'small': const ChartCharacter(
            label: 'Small',
            width: 5,
            colour: '#000000',
          ),
          'tiny': const ChartCharacter(
            label: 'Tiny',
            width: 1,
            colour: '#000000',
          ),
        },
        base: 24.0,
        lo: 14.0,
        hi: 26.0,
      );
      fonts['big'].should.be(24.0);
      // 24 * sqrt(5/20) = 12.0, which the floor lifts to 14
      fonts['small'].should.be(14.0);
      fonts['tiny'].should.be(14.0);
    });
  });
}
