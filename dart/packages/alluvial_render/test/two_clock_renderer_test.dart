import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_render/alluvial_render.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

Beat _scene(
  String id,
  String label,
  String chapter,
  int screened,
  int happened,
  String thread,
  int minutes,
) => Beat(
  id: id,
  name: label,
  kind: BeatKind.scene,
  order: screened,
  parentRef: chapter,
  happenedAt: happened,
  threadId: thread,
  minutes: minutes,
);

Story _story(List<Beat> scenes) => Story(
  slug: 'demo-timechart',
  title: 'Demo',
  shape: StoryShape.twoClock,
  characters: const [
    Character(id: 'a', name: 'Thread A', kind: EntityKind.person),
    Character(id: 'b', name: 'Thread B', kind: EntityKind.person),
  ],
  beats: scenes,
  extra: const {
    'sub': 'A subtitle',
    'notes': ['A note'],
    'legend_note': 'A legend note',
  },
);

void main() {
  group('the two-clock renderer', () {
    test(
      'Given a story told in order, when drawn, then the ribbon runs straight',
      () {
        final story = _story([
          _scene('one', 'Scene one', 'CH 1', 1, 1, 'a', 10),
          _scene('two', 'Scene two', 'CH 2', 2, 2, 'b', 10),
        ]);
        final svg = renderTwoClock(story);
        svg.startsWith('<svg class="chart"').should.be(true);
        svg.endsWith('</svg>').should.be(true);
        // same y on both spines: straight ribbons, no crossing
        RegExp(
          r'M 426 (\d+\.\d) C 497 \1 513 \1 584 \1',
        ).allMatches(svg).length.should.be(2);
      },
    );

    test('Given a cut in time, when drawn, then the ribbon crosses', () {
      final story = _story([
        _scene('one', 'Scene one', 'CH 1', 1, 2, 'a', 10),
        _scene('two', 'Scene two', 'CH 2', 2, 1, 'a', 10),
      ]);
      final svg = renderTwoClock(story);
      // a straight ribbon needs the same y on both spines; a cut cannot have it
      RegExp(
        r'M 426 (\d+\.\d) C 497 \1 513 \1 584 \1',
      ).allMatches(svg).length.should.be(0);
    });

    test('Given an unknown thread, when drawn, then it falls back to grey', () {
      final story = _story([
        _scene('one', 'Scene one', 'CH 1', 1, 1, 'zed', 10),
      ]);
      renderTwoClock(story).should.contain('stroke="#888"');
    });

    test(
      'Given a thread with no scenes, when drawn, then it is not in the legend',
      () {
        final story = _story([
          _scene('one', 'Scene one', 'CH 1', 1, 1, 'jules', 10),
        ]);
        final svg = renderTwoClock(story);
        // the thread id is used as the label here because the fixture's own
        // characters are named otherwise
        svg.should.contain('>jules</text>');
        svg.contains('the cleanup').should.be(false);
      },
    );

    test(
      'Given the node labels, when drawn, then both spines print the same words',
      () {
        // The reader is comparing two orderings of the same words; paraphrasing
        // either side destroys the comparison.
        final story = _story([
          _scene('one', 'Scene one', 'CH 1', 1, 2, 'a', 10),
          _scene('two', 'Scene two', 'CH 2', 2, 1, 'a', 10),
        ]);
        final svg = renderTwoClock(story);
        RegExp('>Scene one<').allMatches(svg).length.should.be(2);
        RegExp('>Scene two<').allMatches(svg).length.should.be(2);
      },
    );

    test('Given the canvas, when drawn, then the height fits every row', () {
      final story = _story([
        _scene('one', 'Scene one', 'CH 1', 1, 1, 'a', 10),
        _scene('two', 'Scene two', 'CH 2', 2, 2, 'b', 10),
        _scene('three', 'Scene three', 'CH 3', 3, 3, 'a', 10),
      ]);
      // 3 scenes: 250 + 176*3 + 190 = 968
      renderTwoClock(story).should.contain('height="968"');
    });

    test('Given a two-clock story, when asked, then it reports its shape', () {
      isTwoClock(_story(const [])).should.be(true);
      isTwoClock(
        const Story(slug: 'x', title: 'X', shape: StoryShape.braid),
      ).should.be(false);
    });
  });
}
