import 'package:equatable/equatable.dart';

/// A problem with a story's content, with the path that produced it.
///
/// The path is a dotted location inside the story (`beats[3].caption[1]`) so a
/// caller can point at the thing that has to change.
final class ValidationFinding extends Equatable {
  /// Creates a finding at [path] with a human sentence in [message].
  const ValidationFinding({
    required this.path,
    required this.message,
    this.isWarning = false,
  });

  /// Dotted location inside the story.
  final String path;

  /// What is wrong, in one sentence.
  final String message;

  /// True when the finding is advisory and must not fail a validation run.
  final bool isWarning;

  /// Renders as `path: message`, matching the store's existing gate output.
  String get describe => '$path: $message';

  @override
  List<Object?> get props => [path, message, isWarning];
}
