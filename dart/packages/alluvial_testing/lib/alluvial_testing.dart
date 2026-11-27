/// The shared repository contract suite every store adapter must pass.
///
/// Not a seam of its own: it asserts the **FP-style tuples** contract
/// (`Future<Either<DomainFailure, T>>`) that every store adapter presents.
library;

export 'src/story_repository_contract.dart';
