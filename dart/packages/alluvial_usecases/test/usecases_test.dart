import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_store_memory/alluvial_store_memory.dart';
import 'package:alluvial_testing/alluvial_testing.dart';
import 'package:alluvial_usecases/alluvial_usecases.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Map<String, Object?>> documents;
  late StoryRepository repository;

  setUp(() {
    documents = <String, Map<String, Object?>>{};
    repository = MemoryStoryRepository(
      datasource: MemoryStoryDatasource(documents),
    );
  });

  group('ListStories', () {
    test(
      'Given an empty store, when listed, then it is Right and empty',
      () async {
        final result = await ListStories(repository).call();

        result.isRight().should.be(true);
        result.getRight().toNullable()!.should.beEmpty();
      },
    );

    test(
      'Given a saved story, when listed, then the row carries its key and its slug',
      () async {
        await repository.save(sampleStory(), key: 'a-sample');

        final result = await ListStories(repository).call();

        final row = result.getRight().toNullable()!.single;
        row.key.should.be('a-sample');
        row.slug.should.be('a-sample');
        row.title.should.be('A Sample');
      },
    );
  });

  group('LoadStory', () {
    test('Given a stored story, when loaded, then it is Right', () async {
      await repository.save(sampleStory(), key: 'a-sample');

      final result = await LoadStory(repository).call(slug: 'a-sample');

      result.isRight().should.be(true);
      result.getRight().toNullable()!.title.should.be('A Sample');
    });

    test(
      'Given an unknown slug, when loaded, then it is Left with the story-not-found code',
      () async {
        final result = await LoadStory(repository).call(slug: 'nobody');

        result.isLeft().should.be(true);
        result.getLeft().toNullable()!.code.should.be('story-not-found');
      },
    );
  });

  group('SaveStory', () {
    test('Given a valid story, when saved, then it is Right', () async {
      final result = await SaveStory(
        repository,
      ).call(story: sampleStory(), key: 'a-sample');

      result.isRight().should.be(true);
    });

    test(
      'Given a story with too few beats, when saved, then it is Left and nothing is stored',
      () async {
        final broken = sampleStory().copyWithBeats(
          sampleStory().beats.take(2).toList(),
        );

        final result = await SaveStory(
          repository,
        ).call(story: broken, key: 'a-sample');

        result.isLeft().should.be(true);
        result.getLeft().toNullable()!.should.beAssignableTo<InvalidStory>();
        documents.should.beEmpty();
      },
    );
  });

  group('ValidateStories', () {
    test(
      'Given a clean store, when validated, then every report is clean',
      () async {
        await repository.save(sampleStory(), key: 'a-sample');

        final result = await ValidateStories(
          repository,
          const StoryValidator(),
        ).call();

        final report = result.getRight().toNullable()!.single;
        report.key.should.be('a-sample');
        report.findings.should.beEmpty();
      },
    );

    test(
      'Given a file that is not a story, when validated, then the report names it instead of the run failing',
      () async {
        documents['broken'] = {'title': 'No Slug Here'};

        final result = await ValidateStories(
          repository,
          const StoryValidator(),
        ).call();

        result.isRight().should.be(true);
        final report = result.getRight().toNullable()!.single;
        report.key.should.be('broken');
        report.title.should.beNull();
        report.findings.single.message.should.contain('a story needs a slug');
      },
    );

    test(
      'Given a named key, when validated, then only that story is reported',
      () async {
        await repository.save(sampleStory(), key: 'a-sample');
        documents['broken'] = {'title': 'No Slug Here'};

        final result = await ValidateStories(
          repository,
          const StoryValidator(),
        ).call(keys: ['broken']);

        result.getRight().toNullable()!.length.should.be(1);
        result.getRight().toNullable()!.single.key.should.be('broken');
      },
    );
  });

  group('RoundtripStories', () {
    test(
      'Given a clean store, when round-tripped, then nothing changes',
      () async {
        await repository.save(sampleStory(), key: 'a-sample');

        final result = await RoundtripStories(
          repository,
          const StoryDocumentCodec(),
        ).call();

        final report = result.getRight().toNullable()!.single;
        report.stable.should.be(true);
        report.detail.should.beNull();
      },
    );

    test(
      'Given an unknown key, when round-tripped, then it is reported as changed with the reason',
      () async {
        final result = await RoundtripStories(
          repository,
          const StoryDocumentCodec(),
        ).call(keys: ['nobody']);

        final report = result.getRight().toNullable()!.single;
        report.stable.should.be(false);
        report.detail.should.contain('no story stored');
      },
    );
  });

  group('StoryTimeline', () {
    test(
      'Given a stored story, when laid out, then the parties come back in sequence with the off-page list',
      () async {
        await repository.save(sampleStory(), key: 'a-sample');

        final result = await StoryTimeline(repository).call(slug: 'a-sample');

        final timeline = result.getRight().toNullable()!;
        timeline.beats.length.should.be(6);
        timeline.characters.map((c) => c.id).should.be(['lea', 'sam']);
        final first = timeline.beats.first;
        first.parties.single.members.map((m) => m.sequence).should.be([1, 2]);
        first.parties.single.members.map((m) => m.characterId).should.be([
          'lea',
          'sam',
        ]);
        first.offPage.should.beEmpty();
      },
    );

    test('Given an unknown slug, when laid out, then it is Left', () async {
      final result = await StoryTimeline(repository).call(slug: 'nobody');

      result.isLeft().should.be(true);
    });
  });
}
