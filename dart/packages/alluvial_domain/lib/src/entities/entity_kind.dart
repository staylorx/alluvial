/// What a story follows: a person, a place, or a thing.
///
/// The chart engine only cares about weight and colour, so a location or a
/// title object (the dresses, the necklace) is a first-class strand beside
/// the people.
enum EntityKind {
  /// A human character.
  person,

  /// A location that carries the story.
  place,

  /// An object the story turns on.
  thing,
}
