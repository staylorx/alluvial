import 'package:equatable/equatable.dart';

import 'validation_finding.dart';

/// Failure of a domain operation.
///
/// Sealed so a `switch` over it is exhaustive: every caller has to say what it
/// does about each way a story can fail to arrive. Each failure carries a
/// stable [code] for callers that parse and a [describe] sentence for humans.
sealed class DomainFailure extends Equatable {
  /// Const constructor for subclasses.
  const DomainFailure();

  /// Stable machine-readable name, safe to branch on.
  String get code;

  /// One sentence naming what went wrong.
  String get describe;
}

/// The store has no story under that key.
final class StoryNotFound extends DomainFailure {
  /// Creates a not-found failure for [slug].
  const StoryNotFound(this.slug);

  /// The key that was asked for.
  final String slug;

  @override
  String get code => 'story-not-found';

  @override
  String get describe => 'no story stored under "$slug"';

  @override
  List<Object?> get props => [slug];
}

/// The store itself could not be read or written.
final class StoreUnavailable extends DomainFailure {
  /// Creates a store failure naming the [location] and the [detail].
  const StoreUnavailable(this.location, this.detail);

  /// The directory or file that failed.
  final String location;

  /// What the adapter reported.
  final String detail;

  @override
  String get code => 'store-unavailable';

  @override
  String get describe => 'the store at $location is unavailable: $detail';

  @override
  List<Object?> get props => [location, detail];
}

/// The stored content does not describe a story this model accepts.
final class InvalidStory extends DomainFailure {
  /// Creates an invalid-story failure carrying every finding.
  const InvalidStory(this.slug, this.findings);

  /// The key whose content failed.
  final String slug;

  /// Everything wrong with it, in the order found.
  final List<ValidationFinding> findings;

  /// Only the findings that are not warnings.
  List<ValidationFinding> get errors =>
      findings.where((f) => !f.isWarning).toList();

  @override
  String get code => 'invalid-story';

  @override
  String get describe =>
      '"$slug" has ${errors.length} problem'
      '${errors.length == 1 ? '' : 's'}: '
      '${errors.map((f) => f.describe).join('; ')}';

  @override
  List<Object?> get props => [slug, findings];
}

/// A story could not be written back to the store.
final class StoryNotWritable extends DomainFailure {
  /// Creates a write failure for [slug] with the adapter's [detail].
  const StoryNotWritable(this.slug, this.detail);

  /// The key that could not be written.
  final String slug;

  /// What the adapter reported.
  final String detail;

  @override
  String get code => 'story-not-writable';

  @override
  String get describe => 'could not write "$slug": $detail';

  @override
  List<Object?> get props => [slug, detail];
}
