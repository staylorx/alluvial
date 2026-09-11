/// What kind of work a story file holds.
///
/// Existing files are all films and leave the field out; a book, a play or a
/// series is the same three entities with a different label on the top.
enum WorkKind {
  /// A film.
  film,

  /// A novel or a short story.
  book,

  /// A stage play or a musical.
  play,

  /// A television or streaming series.
  series,

  /// Anything else — an oral history, a case study, a game.
  other,
}
