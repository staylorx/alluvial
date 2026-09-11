import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Story documents held in a map, for tests and dry runs.
///
/// The map is handed in rather than created internally, so a second datasource
/// built over the same map sees what the first one wrote — which is how the
/// contract suite proves a read comes back from the store and not from the
/// object that wrote it.
final class MemoryStoryDatasource implements StoryDatasource {
  /// Creates a datasource over [documents], or over a fresh store.
  MemoryStoryDatasource([Map<String, Map<String, Object?>>? documents])
    : documents = documents ?? <String, Map<String, Object?>>{};

  /// The backing store, shared between every datasource over it.
  final Map<String, Map<String, Object?>> documents;

  @override
  TaskEither<DatasourceFailure, List<String>> slugs() =>
      TaskEither<DatasourceFailure, List<String>>(
        () async => Either.right(documents.keys.toList()..sort()),
      );

  @override
  TaskEither<DatasourceFailure, Map<String, Object?>> read(String slug) {
    final document = documents[slug];
    if (document == null) {
      return TaskEither<DatasourceFailure, Map<String, Object?>>(
        () async => Either.left(DocumentMissing(slug)),
      );
    }
    return TaskEither<DatasourceFailure, Map<String, Object?>>(
      () async => Either.right(_copy(document)),
    );
  }

  @override
  TaskEither<DatasourceFailure, Unit> write(
    String slug,
    Map<String, Object?> document,
  ) => TaskEither<DatasourceFailure, Unit>(() async {
    documents[slug] = _copy(document);
    return Either.right(unit);
  });
}

/// Copies a document deeply enough that a caller cannot reach into the store.
Map<String, Object?> _copy(Map<String, Object?> document) => {
  for (final entry in document.entries) entry.key: _clone(entry.value),
};

Object? _clone(Object? value) => switch (value) {
  Map<Object?, Object?>() => {
    for (final entry in value.entries) '${entry.key}': _clone(entry.value),
  },
  List<Object?>() => [for (final item in value) _clone(item)],
  _ => value,
};
