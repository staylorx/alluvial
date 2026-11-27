/// A folder of YAML files as the story store.
///
/// **This package presents FP-style tuples**: the repository answers
/// `Future<Either<DomainFailure, T>>`, through the domain's shared
/// orchestration. No exceptions on the seam.
library;

export 'src/folder_story_repository.dart';
export 'src/yaml_folder_datasource.dart';
export 'src/yaml_writer.dart';
