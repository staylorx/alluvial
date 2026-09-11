import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Lists every story in the store, summarised.
final class ListStories {
  /// Creates the use case over [repository].
  const ListStories(this._repository);

  final StoryRepository _repository;

  /// Every story in the store, ordered by slug, without decoding the cast.
  Future<Either<DomainFailure, List<StorySummary>>> call() =>
      _repository.list();
}
