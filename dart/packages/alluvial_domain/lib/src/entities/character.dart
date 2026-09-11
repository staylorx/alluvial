import 'package:equatable/equatable.dart';

import 'entity_kind.dart';

/// One strand of a story: a person, a place, or a thing.
///
/// `weight` is the strand's narrative presence (ribbon width) and `colour` is
/// the palette entry the chart paints it with. Both are optional because the
/// two-clock shape names its threads without either.
final class Character extends Equatable {
  /// Creates a strand from a stored character record.
  const Character({
    required this.id,
    required this.name,
    required this.kind,
    this.weight = 0,
    this.colour,
    this.extra = const {},
  });

  /// Stable key that beats and appearances reference.
  final String id;

  /// Label as it prints in a lane.
  final String name;

  /// Person, place or thing.
  final EntityKind kind;

  /// Narrative presence — the ribbon width. Zero when the source omits it.
  final int weight;

  /// Hex colour (`#rrggbb`), or null when the source omits it.
  final String? colour;

  /// Stored fields the model does not interpret, carried through untouched.
  final Map<String, Object?> extra;

  @override
  List<Object?> get props => [id, name, kind, weight, colour, extra];
}
