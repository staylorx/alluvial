/// The application layer: one use case per thing a caller can ask for.
///
/// **This package presents FP-style tuples**: every use case answers
/// `Future<Either<DomainFailure, T>>`. A failure is a value, never a throw.
library;

export 'src/list_stories.dart';
export 'src/load_story.dart';
export 'src/models/roundtrip_report.dart';
export 'src/models/story_report.dart';
export 'src/models/timeline.dart';
export 'src/roundtrip_stories.dart';
export 'src/save_story.dart';
export 'src/story_timeline.dart';
export 'src/validate_stories.dart';
