import 'package:fpdart/fpdart.dart';

import '../entities/story.dart';

/// Translates between a stored story document and the [Story] aggregate.
///
/// The codec is the only thing that knows what a stored field means, so the
/// store cannot fork into two readings of the same file. Datasources hand it a
/// decoded mapping and never look inside.
abstract interface class StoryCodec {
  /// Decodes a stored document, or explains why it is not a story.
  Either<StoryDecodeFailure, Story> decode(Map<String, Object?> document);

  /// Encodes [story] as a document with the canonical field order.
  Map<String, Object?> encode(Story story);
}

/// Why a document could not be decoded into a [Story].
final class StoryDecodeFailure {
  /// Creates a decode failure with a [path] and a one-sentence [message].
  const StoryDecodeFailure(this.path, this.message);

  /// Dotted location inside the document.
  final String path;

  /// What is wrong, in one sentence.
  final String message;

  /// Renders as `path: message`.
  String get describe => '$path: $message';
}
