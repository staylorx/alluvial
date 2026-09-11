import 'package:alluvial_domain/alluvial_domain.dart';

import 'memory_story_datasource.dart';

/// A store held in memory.
///
/// The orchestration is the shared one; what makes this adapter the *memory*
/// adapter is only that nothing survives the process.
final class MemoryStoryRepository extends DocumentStoryRepository {
  /// Creates a repository over an in-memory store.
  const MemoryStoryRepository({
    required MemoryStoryDatasource super.datasource,
  });
}
