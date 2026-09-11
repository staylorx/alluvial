import 'package:fpdart/fpdart.dart';

import '../entities/story.dart';
import '../entities/story_summary.dart';
import '../failures/domain_failure.dart';

/// The seam the rest of the system reads stories through.
///
/// A repository orchestrates: it asks a datasource for documents, decodes them
/// through the codec, validates what came back, and maps datasource failures
/// into domain ones. Callers depend on this contract, never on an adapter.
///
/// Every method returns `Future<Either<DomainFailure, T>>` — the public seam
/// the doctrine pins, with the `TaskEither` chain run inside the adapter.
abstract interface class StoryRepository {
  /// Every story in the store, summarised, ordered by key.
  Future<Either<DomainFailure, List<StorySummary>>> list();

  /// The story stored under [key].
  ///
  /// The key is the store address — the filename in a folder store. It is NOT
  /// always the story's own slug: a two-clock chart is filed as
  /// `<slug>-timechart.yaml` while still naming the work it belongs to.
  Future<Either<DomainFailure, Story>> load(String key);

  /// Writes [story] under [key], replacing whatever that key held.
  ///
  /// The key is required rather than defaulted to the story's slug, because a
  /// story that shares a slug with another file — a chart beside its film —
  /// would otherwise overwrite the other file.
  Future<Either<DomainFailure, Unit>> save(Story story, {required String key});
}
