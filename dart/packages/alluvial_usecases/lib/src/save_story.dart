import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Writes a whole story back to the store.
final class SaveStory {
  /// Creates the use case over [repository].
  const SaveStory(this._repository);

  final StoryRepository _repository;

  /// Writes [story] under [key], replacing what that key held.
  ///
  /// The key is the store address, which is not always the story's own slug —
  /// a two-clock chart filed beside its film shares the film's slug, so passing
  /// the slug here would overwrite the film's own file.
  Future<Either<DomainFailure, Unit>> call({
    required Story story,
    required String key,
  }) => _repository.save(story, key: key);
}
