/// The grain of a [Beat]: a whole act, one scene, or a beat inside a scene.
///
/// A beat carries `parentRef` naming the act or scene it belongs to, so the
/// same entity models "this is Act II" and "this is the deli scene".
enum BeatKind {
  /// A whole act of the work.
  act,

  /// A scene: the usual grain of a braid column.
  scene,

  /// A beat inside a scene — the finest grain.
  beat,
}
