import 'package:fpdart/fpdart.dart';

import '../failures/datasource_failure.dart';

/// Mechanical document I/O: list keys, read a document, write a document.
///
/// A datasource is deliberately dumb — it moves mappings in and out of a
/// backing store and knows nothing about what they mean. Two adapters over one
/// contract (a folder of files, and memory) prove the contract is not shaped
/// around either one.
abstract interface class StoryDatasource {
  /// Every story key the store holds, sorted.
  TaskEither<DatasourceFailure, List<String>> slugs();

  /// The raw document stored under [slug].
  TaskEither<DatasourceFailure, Map<String, Object?>> read(String slug);

  /// Writes [document] under [slug], replacing anything already there.
  TaskEither<DatasourceFailure, Unit> write(
    String slug,
    Map<String, Object?> document,
  );
}
