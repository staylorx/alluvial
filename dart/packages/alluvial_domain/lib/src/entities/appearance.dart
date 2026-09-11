import 'package:equatable/equatable.dart';

import 'presence_state.dart';

/// A character's place in one beat: where it sits in the sequence, and who it
/// stands with while it is there.
///
/// This is the relation entity. `order` is the character's sequential position
/// within the beat; `party` is the cluster it shares that beat with (everyone
/// carrying the same `party` in the same beat is standing together). A
/// hand-tuned beat carries `laneY` instead of `party`.
final class Appearance extends Equatable {
  /// Creates an appearance of one character in one beat.
  const Appearance({
    required this.characterId,
    required this.beatId,
    required this.order,
    this.party,
    this.laneY,
    this.state = PresenceState.onPage,
  });

  /// The character standing in the beat.
  final String characterId;

  /// The beat the character stands in.
  final String beatId;

  /// Sequential position within the beat, 1-based, left to right.
  final int order;

  /// Cluster index within the beat, or null when the beat is hand-tuned.
  final int? party;

  /// Hand-tuned lane position, larger sitting further right. Null when the
  /// beat is placed by clusters.
  final double? laneY;

  /// On page, entering, or exiting.
  final PresenceState state;

  @override
  List<Object?> get props => [characterId, beatId, order, party, laneY, state];
}
