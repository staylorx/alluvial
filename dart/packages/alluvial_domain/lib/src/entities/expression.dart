/// The form a story is told in — the store's `expression` field.
///
/// The vocabulary is the Python reference store's, deliberately: the two
/// implementations read one store, so a second name or a second set of spellings
/// for the same field is a fork. `kind` is already taken INSIDE the same document
/// (a character has a kind, a beat has a kind), which is why the top-level field
/// is not called that.
///
/// Absent means [Expression.film]: every file written before the field existed is
/// a film, so a film does not write it back and nothing else may be assumed from
/// its absence.
enum Expression {
  /// A film.
  film,

  /// A stage play.
  play,

  /// A novel.
  novel,

  /// A television or streaming series.
  series,

  /// A short story.
  shortStory,

  /// An essay.
  essay,

  /// A poem.
  poem,

  /// A song.
  song,

  /// A musical.
  musical;

  /// The string the store writes (one value has a space in it).
  String get yaml => switch (this) {
    Expression.shortStory => 'short story',
    _ => name,
  };

  /// Reads the store's spelling; anything unknown reads as [Expression.film],
  /// which is what an absent field means and what the validator flags.
  static Expression fromYaml(Object? value) => switch (value) {
    'play' => Expression.play,
    'novel' => Expression.novel,
    'series' => Expression.series,
    'short story' => Expression.shortStory,
    'essay' => Expression.essay,
    'poem' => Expression.poem,
    'song' => Expression.song,
    'musical' => Expression.musical,
    _ => Expression.film,
  };
}
