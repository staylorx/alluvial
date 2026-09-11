import 'package:equatable/equatable.dart';

import 'story_shape.dart';
import 'expression.dart';

/// The cheap face of a story: what a listing needs without decoding the cast.
///
/// [key] is the address — the filename in a folder store, and the handle every
/// other verb takes. [slug] is the story's own identity, which is NOT always
/// the same thing: a two-clock chart is filed as `<slug>-timechart.yaml` while
/// still naming the work it belongs to, so two files legitimately share one
/// slug. Loading a story always goes through [key].
///
/// A row exists for every file in the store. When a file cannot be decoded the
/// row still appears, with [problem] carrying the reason — a listing that
/// silently drops a broken file is worse than one that names it.
final class StorySummary extends Equatable {
  /// Creates a summary row.
  const StorySummary({
    required this.key,
    this.slug,
    this.title,
    this.shape,
    this.expression,
    this.characterCount,
    this.beatCount,
    this.year,
    this.runtimeMinutes,
    this.score,
    this.problem,
  });

  /// The store key this story is filed under.
  final String key;

  /// The story's own slug, or null when the file could not be decoded.
  final String? slug;

  /// The work's title, or null when the file could not be decoded.
  final String? title;

  /// Which authored shape the file uses, or null when undecoded.
  final StoryShape? shape;

  /// Film, book, play, series, other, or null when undecoded.
  final Expression? expression;

  /// How many strands the story carries, or null when undecoded.
  final int? characterCount;

  /// How many columns the story carries, or null when undecoded.
  final int? beatCount;

  /// Year of release or publication.
  final int? year;

  /// Runtime in minutes, when the work has one.
  final int? runtimeMinutes;

  /// The rubric that grades this story, if any (its store id).
  final int? score;

  /// Why this file could not be decoded, or null when it decoded cleanly.
  final String? problem;

  @override
  List<Object?> get props => [
    key,
    slug,
    title,
    shape,
    expression,
    characterCount,
    beatCount,
    year,
    runtimeMinutes,
    score,
    problem,
  ];
}
