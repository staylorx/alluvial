import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

const codec = StoryDocumentCodec();

Map<String, Object?> braidDocument() => <String, Object?>{
  'slug': 'a-braid',
  'title': 'A Braid',
  'year': 1989,
  'runtime_min': 96,
  'score': 29,
  'caption_source': 'sourced from the shooting script',
  'order': ['harry', 'boston', 'the-car'],
  'chars': <Map<String, Object?>>[
    {'id': 'harry', 'name': 'Harry', 'width': 32, 'colour': '#1b57c4'},
    {
      'id': 'boston',
      'name': 'Boston',
      'kind': 'place',
      'width': 14,
      'colour': '#6e9078',
    },
    {
      'id': 'the-car',
      'name': 'the car',
      'kind': 'thing',
      'width': 12,
      'colour': '#9c6552',
    },
  ],
  'beats': <Map<String, Object?>>[
    {
      'name': 'THE DRIVE TO CHICAGO',
      'loc': '≈ 0–8 min',
      'cap': [
        'eighteen hours to Chicago; he says men',
        'and women can never be friends',
      ],
      'tag': 'MEET-CUTE — an argument, not a courtship',
      'cats': ['meet'],
      'clusters': [
        ['harry', 'the-car'],
        ['boston'],
      ],
      'enter': ['harry'],
    },
    {
      'name': 'THE FLIGHT',
      'loc': '≈ 8–15 min',
      'cap': [
        'five years on, a flight; she has a man,',
        'he has a wife; the argument resumes',
      ],
      'cats': ['meet'],
      'clusters': [
        ['harry'],
      ],
      'stubs': ['harry'],
    },
  ],
};

Map<String, Object?> twoClockDocument() => <String, Object?>{
  'slug': 'a-chop',
  'title': 'A Chop',
  'year': 1998,
  'sub': 'Two clocks: what the film shows you, and what happens.',
  'threads': {'helen': 'Helen', 'gerry': 'Gerry'},
  'scenes': <Map<String, Object?>>[
    {
      'id': 'doors',
      'label': 'The tube doors close',
      'chapter': 'THE SPLIT',
      'as_screened': 1,
      'happened': 2,
      'thread': 'helen',
      'mins': 6,
    },
    {
      'id': 'flat',
      'label': 'She comes home early',
      'chapter': 'THE SPLIT',
      'as_screened': 2,
      'happened': 1,
      'thread': 'gerry',
      'mins': 4,
    },
  ],
};

void main() {
  group('StoryDocumentCodec — braid', () {
    test(
      'Given a braid document, when decoded, then the three entities are separate collections',
      () {
        final story = codec.decode(braidDocument()).getRight().toNullable()!;

        story.shape.should.be(StoryShape.braid);
        story.characters.length.should.be(3);
        story.beats.length.should.be(2);
        story.appearances.length.should.be(4);
        story.title.should.be('A Braid');
        story.score.should.be(29);
      },
    );

    test(
      'Given a character with a kind, when decoded, then a place and a thing are not people',
      () {
        final story = codec.decode(braidDocument()).getRight().toNullable()!;

        story.character('harry')!.kind.should.be(EntityKind.person);
        story.character('boston')!.kind.should.be(EntityKind.place);
        story.character('the-car')!.kind.should.be(EntityKind.thing);
      },
    );

    test(
      'Given a beat name, when decoded, then the beat key is derived from it',
      () {
        final story = codec.decode(braidDocument()).getRight().toNullable()!;

        story.beats.map((beat) => beat.id).should.be([
          'the-drive-to-chicago',
          'the-flight',
        ]);
      },
    );

    test(
      'Given clusters, when decoded, then sequence and party describe the relation',
      () {
        final story = codec.decode(braidDocument()).getRight().toNullable()!;

        final first = story.appearancesIn('the-drive-to-chicago');
        first.map((a) => a.characterId).should.be([
          'harry',
          'the-car',
          'boston',
        ]);
        first.map((a) => a.order).should.be([1, 2, 3]);
        first.map((a) => a.party).should.be([0, 0, 1]);
        story
            .partyWith('harry', 'the-drive-to-chicago')
            .map((c) => c.id)
            .should
            .be(['the-car']);
      },
    );

    test(
      'Given enter and stubs, when decoded, then they become presence states',
      () {
        final story = codec.decode(braidDocument()).getRight().toNullable()!;

        story
            .presenceOf('harry', 'the-drive-to-chicago')
            .should
            .be(PresenceState.entering);
        story
            .presenceOf('harry', 'the-flight')
            .should
            .be(PresenceState.exiting);
        story
            .presenceOf('boston', 'the-drive-to-chicago')
            .should
            .be(PresenceState.onPage);
      },
    );

    test(
      'Given a character absent from a beat, when asked, then it is off page and states are null',
      () {
        final story = codec.decode(braidDocument()).getRight().toNullable()!;

        story.offPageIn('the-flight').map((c) => c.id).should.be([
          'boston',
          'the-car',
        ]);
        story.presenceOf('boston', 'the-flight').should.beNull();
      },
    );

    test(
      'Given stored fields the model does not interpret, when decoded, then they are carried',
      () {
        final story = codec.decode(braidDocument()).getRight().toNullable()!;

        story.extra['caption_source'].should.be(
          'sourced from the shooting script',
        );
      },
    );

    test(
      'Given a caption written as one bare string, when decoded, then it is read as one line',
      () {
        final document = braidDocument();
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
          'cap': 'a single line caption',
        };

        final story = codec.decode(document).getRight().toNullable()!;

        story.beats.first.caption.should.be(['a single line caption']);
      },
    );

    test(
      'Given clusters nested one level deeper, when decoded, then they are flattened',
      () {
        final document = braidDocument();
        (document['beats']! as List)[0] = {
          ...(document['beats']! as List)[0] as Map<String, Object?>,
          'clusters': [
            [
              ['harry'],
            ],
            [
              ['the-car'],
            ],
          ],
        };

        final story = codec.decode(document).getRight().toNullable()!;

        story
            .appearancesIn('the-drive-to-chicago')
            .map((a) => a.party)
            .should
            .be([0, 1]);
      },
    );

    test(
      'Given hand-tuned groups, when decoded, then the lane positions are kept',
      () {
        final document = braidDocument();
        (document['beats']! as List)[0] =
            {...(document['beats']! as List)[0] as Map<String, Object?>}
              ..remove('clusters')
              ..['groups'] = [
                [
                  200.0,
                  ['harry'],
                ],
                [
                  600.0,
                  ['boston'],
                ],
              ];

        final story = codec.decode(document).getRight().toNullable()!;

        final first = story.appearancesIn('the-drive-to-chicago');
        first.map((a) => a.laneY).should.be([200.0, 600.0]);
        first.map((a) => a.party).should.be([null, null]);
      },
    );
    test(
      'Given hand-tuned groups in descending lane order, when encoded and decoded again, then the sequence does not move',
      () {
        final document = braidDocument();
        (document['beats']! as List)[0] =
            {...(document['beats']! as List)[0] as Map<String, Object?>}
              ..remove('clusters')
              ..['groups'] = [
                [
                  430.0,
                  ['harry'],
                ],
                [
                  200.0,
                  ['boston'],
                ],
              ];

        final first = codec.decode(document).getRight().toNullable()!;
        final second = codec
            .decode(codec.encode(first))
            .getRight()
            .toNullable()!;

        second.should.be(first);
      },
    );

    test(
      'Given two groups on the same lane, when encoded, then they are normalised to one group per lane',
      () {
        // A repeated lane is a position two clusters share, which the renderer
        // would draw on top of each other. The model keeps one group per lane, so
        // the first pass normalises the input and every pass after it is stable.
        final document = braidDocument();
        (document['beats']! as List)[0] =
            {...(document['beats']! as List)[0] as Map<String, Object?>}
              ..remove('clusters')
              ..['groups'] = [
                [
                  430.0,
                  ['harry'],
                ],
                [
                  200.0,
                  ['boston'],
                ],
                [
                  430.0,
                  ['the-car'],
                ],
              ];

        final first = codec.decode(document).getRight().toNullable()!;
        final second = codec
            .decode(codec.encode(first))
            .getRight()
            .toNullable()!;
        final third = codec
            .decode(codec.encode(second))
            .getRight()
            .toNullable()!;

        final lanes = second
            .appearancesIn('the-drive-to-chicago')
            .map((a) => a.laneY);
        lanes.should.be([430.0, 430.0, 200.0]);
        third.should.be(second);
      },
    );
  });

  group('StoryDocumentCodec — two clocks', () {
    test(
      'Given a scenes document, when decoded, then it is a two-clock story with threads as characters',
      () {
        final story = codec.decode(twoClockDocument()).getRight().toNullable()!;

        story.shape.should.be(StoryShape.twoClock);
        story.characters.map((c) => c.id).should.be(['helen', 'gerry']);
        story.beats.length.should.be(2);
        story.beats.first.id.should.be('doors');
        story.beats.first.happenedAt.should.be(2);
        story.beats.first.threadId.should.be('helen');
        story.beats.first.parentRef.should.be('THE SPLIT');
        story.beats.first.minutes.should.be(6);
      },
    );

    test(
      'Given a thread on a scene, when decoded, then the thread stands in that beat',
      () {
        final story = codec.decode(twoClockDocument()).getRight().toNullable()!;

        story.castIn('doors').map((c) => c.id).should.be(['helen']);
        story.presenceOf('helen', 'doors').should.be(PresenceState.onPage);
      },
    );
  });

  group('StoryDocumentCodec — refusal and fixed point', () {
    test(
      'Given a document with no slug, when decoded, then it is refused with the path named',
      () {
        final result = codec.decode({'title': 'Nameless'});

        result.isLeft().should.be(true);
        result.getLeft().toNullable()!.path.should.be('slug');
      },
    );

    test(
      'Given a document with neither beats nor scenes, when decoded, then it is refused',
      () {
        final result = codec.decode({'slug': 'empty', 'title': 'Empty'});

        result.isLeft().should.be(true);
        result.getLeft().toNullable()!.path.should.be('beats');
      },
    );

    test(
      'Given a decoded story, when encoded and decoded again, then nothing changes',
      () {
        final first = codec.decode(braidDocument()).getRight().toNullable()!;
        final second = codec
            .decode(codec.encode(first))
            .getRight()
            .toNullable()!;

        second.should.be(first);
      },
    );

    test(
      'Given a decoded two-clock story, when encoded and decoded again, then nothing changes',
      () {
        final first = codec.decode(twoClockDocument()).getRight().toNullable()!;
        final second = codec
            .decode(codec.encode(first))
            .getRight()
            .toNullable()!;

        second.should.be(first);
      },
    );

    test(
      'Given a story, when encoded, then the canonical keys lead the document',
      () {
        final story = codec.decode(braidDocument()).getRight().toNullable()!;

        final keys = codec.encode(story).keys.toList();

        keys.take(6).should.be([
          'slug',
          'title',
          'year',
          'runtime_min',
          'score',
          'order',
        ]);
        keys.indexOf('chars').should.beLessThan(keys.indexOf('beats'));
      },
    );
  });
}
