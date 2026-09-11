import 'package:fpdart/fpdart.dart';

import '../codec/story_document_codec.dart';
import '../contracts/story_codec.dart';
import '../contracts/story_datasource.dart';
import '../contracts/story_repository.dart';
import '../entities/story.dart';
import '../entities/story_summary.dart';
import '../failures/datasource_failure.dart';
import '../failures/domain_failure.dart';
import '../failures/validation_finding.dart';
import '../validation/story_validator.dart';

/// The orchestration every document-backed store shares.
///
/// A store differs from another store only in where its documents live, so the
/// sequence — ask the datasource, decode through the codec, map mechanical
/// failures into domain ones, refuse to write a story the validator rejects —
/// lives here once. Adapters extend this and supply their datasource, which is
/// why two of them behaving identically is a design fact rather than a
/// coincidence.
class DocumentStoryRepository implements StoryRepository {
  /// Creates the repository over [datasource].
  const DocumentStoryRepository({
    required this.datasource,
    this.codec = const StoryDocumentCodec(),
    this.validator = const StoryValidator(),
  });

  /// The mechanical I/O behind this repository.
  final StoryDatasource datasource;

  /// The one thing that knows what a stored field means.
  final StoryCodec codec;

  /// The limits a story must satisfy before it can be written back.
  final StoryValidator validator;

  @override
  Future<Either<DomainFailure, List<StorySummary>>> list() async {
    final keys = await datasource
        .slugs()
        .mapLeft(
          (failure) => StoreUnavailable(failure.location, failure.detail),
        )
        .run();
    if (keys.isLeft()) return Left(keys.getLeft().toNullable()!);

    final summaries = <StorySummary>[];
    for (final slug in keys.getRight().toNullable()!) {
      final loaded = await load(slug);
      final failure = loaded.getLeft().toNullable();
      if (failure != null) {
        summaries.add(
          StorySummary(key: slug, title: slug, problem: failure.describe),
        );
        continue;
      }
      final story = loaded.getRight().toNullable()!;
      summaries.add(
        StorySummary(
          key: slug,
          slug: story.slug,
          title: story.title,
          shape: story.shape,
          expression: story.expression,
          characterCount: story.characters.length,
          beatCount: story.beats.length,
          year: story.year,
          runtimeMinutes: story.runtimeMinutes,
          score: story.score,
        ),
      );
    }
    return Right(summaries);
  }

  @override
  Future<Either<DomainFailure, Story>> load(String slug) => datasource
      .read(slug)
      .mapLeft(_readFailure(slug))
      .flatMap(_decode(slug))
      .run();

  @override
  Future<Either<DomainFailure, Unit>> save(
    Story story, {
    required String key,
  }) async {
    final findings = validator.validate(story);
    if (findings.any((finding) => !finding.isWarning)) {
      return Left(InvalidStory(key, findings));
    }
    return datasource
        .write(key, codec.encode(story))
        .mapLeft((failure) => StoryNotWritable(key, failure.detail))
        .run();
  }

  DomainFailure Function(DatasourceFailure) _readFailure(String slug) =>
      (failure) => switch (failure) {
        DocumentMissing() => StoryNotFound(slug),
        DocumentUnreadable() || DocumentMalformed() => StoreUnavailable(
          failure.location,
          failure.detail,
        ),
        DocumentUnwritable() => StoryNotWritable(slug, failure.detail),
      };

  TaskEither<DomainFailure, Story> Function(Map<String, Object?>) _decode(
    String slug,
  ) =>
      (document) => TaskEither<DomainFailure, Story>(() async {
        final decoded = codec.decode(document);
        final failure = decoded.getLeft().toNullable();
        if (failure != null) {
          return Either.left(
            InvalidStory(slug, [
              ValidationFinding(path: failure.path, message: failure.message),
            ]),
          );
        }
        return Either.right(decoded.getRight().toNullable()!);
      });
}
