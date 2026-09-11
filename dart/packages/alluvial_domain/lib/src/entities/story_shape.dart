/// Which authored shape a story file uses.
///
/// A braid tells its beats in story order and joins them with clusters. A
/// two-clock story carries the same scenes twice — as screened and as they
/// happened — and needs both orders preserved rather than derived.
enum StoryShape {
  /// Beats in story order, merged and split by `clusters`.
  braid,

  /// Scenes carrying `as_screened` (story order) and `happened` (real order).
  twoClock,
}
