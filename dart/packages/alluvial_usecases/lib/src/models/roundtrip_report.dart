/// Whether one story survived a document → model → document → model pass.
///
/// [key] is the store key the story was loaded by. `detail` names what changed
/// when it did, so a caller can act without re-deriving the comparison.
typedef RoundtripReport = ({String key, bool stable, String? detail});
