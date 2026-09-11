import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// Opens a repository over the store the harness set up for the current test.
///
/// Called twice in one test it must hand back two repositories over the SAME
/// store, which is what lets the suite prove a read comes back from the store
/// rather than from the object that wrote it.
typedef OpenStore = StoryRepository Function();

/// Seeds a raw document into the store, bypassing the repository's write path.
typedef SeedDocument =
    Future<void> Function(String slug, Map<String, Object?> document);

/// The behaviour every story store must have, run against each adapter.
///
/// One suite, two adapters: if a rule is only true of one of them, this is where
/// that shows up. Every test asserts on the failure channel rather than on an
/// exception, because a store that throws is a store an agent cannot drive.
void storyRepositoryContract({
  required String adapterName,
  required OpenStore open,
  SeedDocument? seed,
}) {
  /// Saves [story] under its own slug — the ordinary case.
  Future<Either<DomainFailure, Unit>> save(Story story) =>
      open().save(story, key: story.slug);

  group('StoryRepository contract: $adapterName', () {
    test(
      'Given an empty store, when listed, then there are no stories',
      () async {
        final result = await open().list();

        result.isRight().should.be(true);
        result.getRight().toNullable()!.should.beEmpty();
      },
    );

    test(
      'Given an unknown slug, when loaded, then it reports the story missing',
      () async {
        final result = await open().load('nobody-here');

        result.isLeft().should.be(true);
        final failure = result.getLeft().toNullable()!;
        failure.should.beAssignableTo<StoryNotFound>();
        failure.code.should.be('story-not-found');
      },
    );

    test(
      'Given a saved story, when read from a fresh repository, then it is the same story',
      () async {
        final before = sampleStory();
        final saved = await save(before);
        saved.isRight().should.be(true);

        final loaded = await open().load(before.slug);

        loaded.isRight().should.be(true);
        loaded.getRight().toNullable()!.should.be(before);
      },
    );

    test(
      'Given a saved story, when listed, then it carries its counts',
      () async {
        final story = sampleStory();
        await save(story);

        final listed = await open().list();

        final row = listed.getRight().toNullable()!.single;
        row.key.should.be(story.slug);
        row.title.should.be(story.title);
        row.characterCount.should.be(story.characters.length);
        row.beatCount.should.be(story.beats.length);
        row.problem.should.beNull();
      },
    );

    test(
      'Given a story the validator rejects, when saved, then it is refused and the store stays empty',
      () async {
        final broken = sampleStory().copyWithBeats(
          sampleStory().beats.take(2).toList(),
        );

        final saved = await save(broken);

        saved.isLeft().should.be(true);
        saved.getLeft().toNullable()!.should.beAssignableTo<InvalidStory>();
        (await open().load(broken.slug)).isLeft().should.be(true);
      },
    );

    test(
      'Given a saved story, when saved again, then the store still holds one row',
      () async {
        final story = sampleStory();
        await save(story);
        await save(story);

        (await open().list()).getRight().toNullable()!.length.should.be(1);
      },
    );

    test(
      'Given a rewritten title, when written and read back, then the new title is the one served',
      () async {
        final story = sampleStory();
        await save(story);
        await save(story.copyWithTitle('Second Title'));

        final loaded = await open().load(story.slug);

        loaded.getRight().toNullable()!.title.should.be('Second Title');
      },
    );

    if (seed != null) {
      test(
        'Given a document that is not a story, when listed and loaded, then the file is named rather than dropped',
        () async {
          await seed('not-a-story', {'title': 'A Title With No Slug'});

          final listed = await open().list();

          final rows = listed.getRight().toNullable()!;
          rows.length.should.be(1);
          rows.single.key.should.be('not-a-story');
          (rows.single.problem == null).should.be(false);

          final loaded = await open().load('not-a-story');
          loaded.isLeft().should.be(true);
          loaded.getLeft().toNullable()!.code.should.be('invalid-story');
        },
      );
    }
  });
}

/// A story the contract suite can save and compare — small, but valid enough to
/// survive the write guard.
Story sampleStory() => const Story(
  slug: 'a-sample',
  title: 'A Sample',
  shape: StoryShape.braid,
  year: 1999,
  characters: [
    Character(
      id: 'lea',
      name: 'Lea',
      kind: EntityKind.person,
      weight: 32,
      colour: '#1b57c4',
    ),
    Character(
      id: 'sam',
      name: 'Sam',
      kind: EntityKind.person,
      weight: 30,
      colour: '#d0316a',
    ),
  ],
  laneOrder: ['lea', 'sam'],
  beats: [
    Beat(
      id: 'one',
      name: 'ONE',
      kind: BeatKind.beat,
      order: 1,
      caption: ['first line', 'second line'],
    ),
    Beat(
      id: 'two',
      name: 'TWO',
      kind: BeatKind.beat,
      order: 2,
      caption: ['first line', 'second line'],
    ),
    Beat(
      id: 'three',
      name: 'THREE',
      kind: BeatKind.beat,
      order: 3,
      caption: ['first line', 'second line'],
    ),
    Beat(
      id: 'four',
      name: 'FOUR',
      kind: BeatKind.beat,
      order: 4,
      caption: ['first line', 'second line'],
    ),
    Beat(
      id: 'five',
      name: 'FIVE',
      kind: BeatKind.beat,
      order: 5,
      caption: ['first line', 'second line'],
    ),
    Beat(
      id: 'six',
      name: 'SIX',
      kind: BeatKind.beat,
      order: 6,
      caption: ['first line', 'second line'],
    ),
  ],
  appearances: [
    Appearance(characterId: 'lea', beatId: 'one', order: 1, party: 0),
    Appearance(characterId: 'sam', beatId: 'one', order: 2, party: 0),
    Appearance(characterId: 'lea', beatId: 'two', order: 1, party: 0),
    Appearance(characterId: 'sam', beatId: 'two', order: 2, party: 0),
    Appearance(characterId: 'lea', beatId: 'three', order: 1, party: 0),
    Appearance(characterId: 'sam', beatId: 'three', order: 2, party: 0),
    Appearance(characterId: 'lea', beatId: 'four', order: 1, party: 0),
    Appearance(characterId: 'sam', beatId: 'four', order: 2, party: 1),
    Appearance(characterId: 'lea', beatId: 'five', order: 1, party: 0),
    Appearance(characterId: 'sam', beatId: 'five', order: 2, party: 0),
    Appearance(characterId: 'lea', beatId: 'six', order: 1, party: 0),
    Appearance(characterId: 'sam', beatId: 'six', order: 2, party: 0),
  ],
);

/// Test-only conveniences for mutating the sample story.
extension SampleStoryEdits on Story {
  /// The same story under a different title.
  Story copyWithTitle(String title) => Story(
    slug: slug,
    title: title,
    shape: shape,
    work: work,
    year: year,
    runtimeMinutes: runtimeMinutes,
    score: score,
    legendObject: legendObject,
    laneOrder: laneOrder,
    characters: characters,
    beats: beats,
    appearances: appearances,
    extra: extra,
  );

  /// The same story with a different beat list.
  Story copyWithBeats(List<Beat> beats) => Story(
    slug: slug,
    title: title,
    shape: shape,
    work: work,
    year: year,
    runtimeMinutes: runtimeMinutes,
    score: score,
    legendObject: legendObject,
    laneOrder: laneOrder,
    characters: characters,
    beats: beats,
    appearances: appearances
        .where((a) => beats.any((b) => b.id == a.beatId))
        .toList(),
    extra: extra,
  );
}
