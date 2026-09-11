/// What a character is doing in one beat.
///
/// Absence is not a state: a character missing from a beat has no appearance
/// at all, and "off page" is derived from that absence.
enum PresenceState {
  /// Present and part of the scene.
  onPage,

  /// First appearance, drawn as an entrance stub.
  entering,

  /// Final appearance, drawn as an exit stub.
  exiting,
}
