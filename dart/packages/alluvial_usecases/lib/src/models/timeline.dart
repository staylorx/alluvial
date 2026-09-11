import 'package:equatable/equatable.dart';

import 'package:alluvial_domain/alluvial_domain.dart';

/// One beat as a reader encounters it: who is in it, in what sequence, beside
/// whom, and who the source leaves out.
final class TimelineBeat extends Equatable {
  /// Creates one timeline row.
  const TimelineBeat({
    required this.order,
    required this.id,
    required this.name,
    required this.parties,
    required this.offPage,
    this.at,
    this.caption = const [],
    this.tag,
  });

  /// Position in the told story, 1-based.
  final int order;

  /// The beat's stable key.
  final String id;

  /// The beat's name.
  final String name;

  /// The parties standing in the beat, in reader order (left to right).
  final List<TimelineParty> parties;

  /// Character ids the source does not place in this beat.
  final List<String> offPage;

  /// The stored position string for the beat, e.g. `≈ 45–55 min`.
  final String? at;

  /// The beat's caption lines.
  final List<String> caption;

  /// The one clause naming what the beat is.
  final String? tag;

  @override
  List<Object?> get props => [
    order,
    id,
    name,
    parties,
    offPage,
    at,
    caption,
    tag,
  ];
}

/// A group of characters standing together in one beat.
final class TimelineParty extends Equatable {
  /// Creates a party placed at [index] in the beat, left to right.
  const TimelineParty({required this.index, required this.members});

  /// Position of the party in the beat, left to right.
  final int index;

  /// The characters in the party, in sequence.
  final List<TimelineActor> members;

  @override
  List<Object?> get props => [index, members];
}

/// One character's placement in one beat.
final class TimelineActor extends Equatable {
  /// Creates a placement for [characterId] at [sequence] in the beat.
  const TimelineActor({
    required this.characterId,
    required this.name,
    required this.kind,
    required this.sequence,
    required this.state,
  });

  /// The character's stable key.
  final String characterId;

  /// The character's label.
  final String name;

  /// Person, place, or thing.
  final EntityKind kind;

  /// Sequential position within the beat, 1-based.
  final int sequence;

  /// On page, entering, or exiting.
  final PresenceState state;

  @override
  List<Object?> get props => [characterId, name, kind, sequence, state];
}

/// A whole story laid out beat by beat — the relation view of the store.
final class Timeline extends Equatable {
  /// Creates a timeline for [slug].
  const Timeline({
    required this.slug,
    required this.title,
    required this.beats,
    required this.characters,
  });

  /// The story's key.
  final String slug;

  /// The story's title.
  final String title;

  /// One row per beat, in told order.
  final List<TimelineBeat> beats;

  /// The story's strands, in lane order.
  final List<Character> characters;

  @override
  List<Object?> get props => [slug, title, beats, characters];
}
