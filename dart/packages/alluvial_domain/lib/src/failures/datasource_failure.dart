import 'package:equatable/equatable.dart';

/// Failure of a datasource operation.
///
/// Datasources do mechanical I/O only, so their failures name the artefact and
/// what the third-party call said; the repository maps these upward into
/// `DomainFailure`s.
sealed class DatasourceFailure extends Equatable {
  /// Const constructor for subclasses.
  const DatasourceFailure();

  /// Where the failure happened — a path or a store key.
  String get location;

  /// A human sentence for logs and reports.
  String get detail;
}

/// A stored document does not exist.
final class DocumentMissing extends DatasourceFailure {
  /// Creates a missing-document failure for [location].
  const DocumentMissing(this.location);

  @override
  final String location;

  @override
  String get detail => 'no document at $location';

  @override
  List<Object?> get props => [location];
}

/// A stored document exists but could not be read.
final class DocumentUnreadable extends DatasourceFailure {
  /// Creates an unreadable-document failure with the underlying [reason].
  const DocumentUnreadable(this.location, this.reason);

  @override
  final String location;

  /// What the filesystem or decoder reported.
  final String reason;

  @override
  String get detail => '$location could not be read: $reason';

  @override
  List<Object?> get props => [location, reason];
}

/// A stored document exists but is not valid YAML, or is not a mapping.
final class DocumentMalformed extends DatasourceFailure {
  /// Creates a malformed-document failure [line] lines in, with [reason].
  const DocumentMalformed(this.location, this.reason, {this.line});

  @override
  final String location;

  /// What the decoder reported.
  final String reason;

  /// One-based line the decoder stopped on, when it says.
  final int? line;

  @override
  String get detail =>
      '$location is not a story document: $reason${line == null ? '' : ' (line $line)'}';

  @override
  List<Object?> get props => [location, reason, line];
}

/// A document could not be written.
final class DocumentUnwritable extends DatasourceFailure {
  /// Creates an unwritable-document failure with the underlying [reason].
  const DocumentUnwritable(this.location, this.reason);

  @override
  final String location;

  /// What the filesystem reported.
  final String reason;

  @override
  String get detail => '$location could not be written: $reason';

  @override
  List<Object?> get props => [location, reason];
}
