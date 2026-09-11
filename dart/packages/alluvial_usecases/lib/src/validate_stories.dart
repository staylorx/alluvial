import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:fpdart/fpdart.dart';

import 'models/story_report.dart';

/// Checks stories against the store's limits, reporting per story.
///
/// The run reports on every story it was asked about rather than stopping at
/// the first bad one, and a story that cannot be decoded becomes a report whose
/// single finding carries the reason. Only a store that cannot be listed at all
/// fails the whole call.
final class ValidateStories {
  /// Creates the use case over [repository] and [validator].
  const ValidateStories(this._repository, this._validator);

  final StoryRepository _repository;
  final StoryValidator _validator;

  /// Validates [keys], or every story in the store when [keys] is empty.
  ///
  /// Arguments are store keys — the filenames a listing reports — not the
  /// stories' own slugs, which two files can share.
  Future<Either<DomainFailure, List<StoryReport>>> call({
    List<String> keys = const [],
  }) async {
    final List<String> loadable;
    if (keys.isNotEmpty) {
      loadable = keys;
    } else {
      final listed = await _repository.list();
      if (listed.isLeft()) return Left(listed.getLeft().toNullable()!);
      loadable = listed
          .getRight()
          .toNullable()!
          .map((summary) => summary.key)
          .toList();
    }

    final reports = <StoryReport>[];
    for (final key in loadable) {
      final loaded = await _repository.load(key);
      if (loaded.isLeft()) {
        final failure = loaded.getLeft().toNullable()!;
        reports.add((
          key: key,
          title: null,
          findings: [ValidationFinding(path: key, message: failure.describe)],
        ));
        continue;
      }
      final story = loaded.getRight().toNullable()!;
      reports.add((
        key: key,
        title: story.title,
        findings: _validator.validate(story),
      ));
    }
    return Right(reports);
  }
}
