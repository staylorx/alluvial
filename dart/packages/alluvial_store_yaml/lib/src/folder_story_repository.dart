import 'package:alluvial_domain/alluvial_domain.dart';

import 'yaml_folder_datasource.dart';

/// A store whose documents are files in a folder.
///
/// The orchestration is the shared one; what makes this adapter the *folder*
/// adapter is only that its datasource reads and writes `<slug>.yaml` files.
final class FolderStoryRepository extends DocumentStoryRepository {
  /// Creates a repository over a folder of story files.
  const FolderStoryRepository({required YamlFolderDatasource super.datasource});

  /// The folder this adapter reads and writes.
  String get directory => (datasource as YamlFolderDatasource).directory;
}
