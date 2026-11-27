/// An in-memory story store, for tests and dry runs.
///
/// **This package presents FP-style tuples**: the repository answers
/// `Future<Either<DomainFailure, T>>`, through the domain's shared
/// orchestration. No exceptions on the seam.
library;

export 'src/memory_story_datasource.dart';
export 'src/memory_story_repository.dart';
