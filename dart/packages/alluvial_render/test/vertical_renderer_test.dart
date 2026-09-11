import 'package:alluvial_render/alluvial_render.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

ChartCharacter _c(String label, [double width = 10]) =>
    ChartCharacter(label: label, width: width, colour: '#1b57c4');

/// A minimal two-lane chart, so the engine's structure is exercised without a
/// store: two strands standing together, in two rows.
ChartSpec _spec({
  bool mini = false,
  bool cb = false,
  double width = 10,
  String patternPrefix = '',
  bool collide = false,
}) => ChartSpec(
  characters: {'a': _c('Alpha', width), 'b': _c('Beta', width)},
  order: const ['a', 'b'],
  columns: [
    ChartColumn(
      beat: 'ONE',
      loc: '≈ 1 min',
      caption: const ['First thing'],
      groups: collide
          ? const [
              ChartGroup(470.0, ['a']),
              ChartGroup(470.4, ['b']),
            ]
          : const [
              ChartGroup(470.0, ['a', 'b']),
            ],
    ),
    const ChartColumn(
      beat: 'TWO',
      loc: '≈ 2 min',
      caption: ['Second thing'],
      groups: [
        ChartGroup(470.0, ['a', 'b']),
      ],
    ),
  ],
  ys: const [300.0, 465.0],
  title: const [ChartTitleLine('A chart', 'title')],
  width: 1010,
  capX: 570.0,
  laneHi: 545.0,
  scale: 0.55,
  origin: 330.0,
  spineOld: 500.0,
  labelFont: const {'a': 24.0, 'b': 24.0},
  legendFont: const {'a': 24.0, 'b': 24.0},
  mini: mini,
  cbSafe: cb,
  patternPrefix: patternPrefix,
  beatLinks: (i, c) => '#beat-${i + 1}',
);

void main() {
  group('the braid engine', () {
    test('Given a spec, when drawn, then the document opens and CLOSES', () {
      final svg = renderVertical(_spec()).svg;
      svg.startsWith('<svg xmlns="http://www.w3.org/2000/svg"').should.be(true);
      svg.endsWith('</svg>').should.be(true);
      svg.should.contain('<rect width="1010" height="');
    });

    test('Given mini mode, when drawn, then it still closes the svg', () {
      // The compact mode returns early; an early return that skips </svg> makes
      // every following element parse as part of the SVG, with no error.
      final result = renderVertical(_spec(mini: true));
      result.svg.endsWith('</svg>').should.be(true);
      result.svg.contains('LANES').should.be(false);
      // mini drops the legend and the title block, so it is much shorter
      (result.checks.height < renderVertical(_spec()).checks.height).should.be(
        true,
      );
    });

    test(
      'Given strands standing together, when drawn, then no lane collides',
      () {
        renderVertical(_spec()).checks.isClean.should.be(true);
      },
    );

    test(
      'Given two groups placed on top of each other, then the collision is reported',
      () {
        // Strands inside one group are packed with a gap, so a collision only
        // happens BETWEEN groups — a hand-tuned beat can place two parties on
        // each other, and that is what this check exists to catch.
        final checks = renderVertical(_spec(collide: true)).checks;
        checks.isClean.should.be(false);
        final overlap = checks.laneOverlaps.first;
        overlap.left.should.be('a');
        overlap.right.should.be('b');
        (overlap.gap < 0.5).should.be(true);
      },
    );

    test('Given a pattern prefix, when drawn, then the ids are namespaced', () {
      final svg = renderVertical(_spec(cb: true, patternPrefix: '-alt')).svg;
      svg.should.contain('<pattern id="dots-alt"');
      svg.should.contain('url(#dots-alt)');
      svg.should.contain('<pattern id="cb-alt-a"');
      svg.should.contain('url(#cb-alt-a)');
    });

    test(
      'Given a strand absent from a column, then it is not drawn across it',
      () {
        final gap = ChartSpec(
          characters: _spec().characters,
          order: const ['a', 'b'],
          columns: const [
            ChartColumn(
              beat: 'ONE',
              caption: ['First thing'],
              groups: [
                ChartGroup(470.0, ['a', 'b']),
              ],
            ),
            ChartColumn(
              beat: 'TWO',
              caption: ['Second thing'],
              groups: [
                ChartGroup(470.0, ['a']),
              ],
            ),
          ],
          ys: const [300.0, 465.0],
          title: const [ChartTitleLine('A chart', 'title')],
          width: 1010,
          capX: 570.0,
          laneHi: 545.0,
          scale: 0.55,
          origin: 330.0,
          spineOld: 500.0,
          labelFont: const {'a': 24.0, 'b': 24.0},
          legendFont: const {'a': 24.0, 'b': 24.0},
        );
        final result = renderVertical(gap);
        // one ribbon band for the strand that is there, none for the one that is not
        RegExp(
          'fill-opacity="0.82"',
        ).allMatches(result.svg).length.should.be(1);
      },
    );

    test(
      'Given a beat link rule, when drawn, then every beat gets a row and a link',
      () {
        final svg = renderVertical(_spec()).svg;
        svg.should.contain('<g class="beat-rows">');
        svg.should.contain('id="chart-01"');
        svg.should.contain('href="#beat-1"');
        svg.should.contain('href="#beat-2"');
      },
    );
  });
}
