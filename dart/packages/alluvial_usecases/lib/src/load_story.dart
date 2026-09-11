import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Loads one whole story out of the store.
final class LoadStory {
  /// Creates the use case over [repository].
  const LoadStory(this._repository);

  final StoryRepository _repository;

  /// The story stored under [slug].
  Future<Either<DomainFailure, Story>> call({required String slug}) =>
      _repository.load(slug);
}
