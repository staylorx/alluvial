import 'package:equatable/equatable.dart';

import 'beat_kind.dart';

/// One column of a story: an act, a scene, or a beat inside a scene.
///
/// `order` is the beat's position in the told story (1-based). `happenedAt` is
/// the optional second clock — where the beat sits in the order things really
/// happened — and is null for a story told in order. `parentRef` names the act
/// or scene this beat is part of, which is what lets one entity cover both
/// grains.
final class Beat extends Equatable {
  /// Creates a beat from a stored beat record.
  const Beat({
    required this.id,
    required this.name,
    required this.kind,
    required this.order,
    this.parentRef,
    this.at,
    this.happenedAt,
    this.caption = const [],
    this.tag,
    this.categories = const [],
    this.threadId,
    this.minutes,
    this.extra = const {},
  });

  /// Stable key that appearances reference.
  final String id;

  /// The beat's name as it prints above its row.
  final String name;

  /// Act, scene, or beat.
  final BeatKind kind;

  /// Position in the told story, 1-based.
  final int order;

  /// The act or scene this beat belongs to, when the source says.
  final String? parentRef;

  /// Rough position in the work — `≈ 35–50 min`, `the coda`, a chapter card.
  final String? at;

  /// Position in the order things really happened, when the source carries it.
  final int? happenedAt;

  /// At most two caption lines, each short enough for the column.
  final List<String> caption;

  /// One clause naming what the beat is, after an em dash.
  final String? tag;

  /// Ids of the categories this beat's shape belongs to.
  final List<String> categories;

  /// For a two-clock story, the character whose story this scene belongs to.
  final String? threadId;

  /// Rough on-screen length, used only for ribbon thickness.
  final int? minutes;

  /// Stored fields the model does not interpret, carried through untouched.
  final Map<String, Object?> extra;

  @override
  List<Object?> get props => [
    id,
    name,
    kind,
    order,
    parentRef,
    at,
    happenedAt,
    caption,
    tag,
    categories,
    threadId,
    minutes,
    extra,
  ];
}
