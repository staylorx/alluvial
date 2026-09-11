import 'package:equatable/equatable.dart';

import 'appearance.dart';
import 'beat.dart';
import 'character.dart';
import 'presence_state.dart';
import 'story_shape.dart';
import 'work_kind.dart';

/// One whole story — a film, a book, a play, a series.
///
/// The aggregate is the three entities and nothing else: [characters] are the
/// strands, [beats] are the columns, and [appearances] is the relation between
/// them (who stands in which beat, in what sequence, beside whom). Everything
/// the chart draws is derived from those three; `extra` carries the stored
/// fields the model does not interpret so a read/write round trip loses
/// nothing.
final class Story extends Equatable {
  /// Creates a story from its decoded parts.
  const Story({
    required this.slug,
    required this.title,
    required this.shape,
    this.work = WorkKind.film,
    this.year,
    this.runtimeMinutes,
    this.score,
    this.legendObject,
    this.laneOrder = const [],
    this.characters = const [],
    this.beats = const [],
    this.appearances = const [],
    this.extra = const {},
  });

  /// Stable key; also the store filename.
  final String slug;

  /// The work's title as it prints.
  final String title;

  /// Which authored shape the file uses.
  final StoryShape shape;

  /// Film, book, play, series, other.
  final WorkKind work;

  /// Year of release or publication.
  final int? year;

  /// Runtime in minutes, when the work has one.
  final int? runtimeMinutes;

  /// Whole-work rubric score, when it has been taken.
  final int? score;

  /// A title object rather than a person, e.g. `the dresses`.
  final String? legendObject;

  /// Lane stacking order — every character id, most important first.
  final List<String> laneOrder;

  /// The strands of the story.
  final List<Character> characters;

  /// The columns of the story, in told order.
  final List<Beat> beats;

  /// Every character's placement in every beat it appears in.
  final List<Appearance> appearances;

  /// Stored fields the model does not interpret, carried through untouched.
  final Map<String, Object?> extra;

  /// The character with [id], or null when the story has none.
  Character? character(String id) =>
      characters.where((c) => c.id == id).firstOrNull;

  /// The beat with [id], or null when the story has none.
  Beat? beat(String id) => beats.where((b) => b.id == id).firstOrNull;

  /// Every appearance in [beatId], in the sequence the reader sees.
  List<Appearance> appearancesIn(String beatId) {
    final inBeat = appearances.where((a) => a.beatId == beatId).toList();
    inBeat.sort((a, b) => a.order.compareTo(b.order));
    return inBeat;
  }

  /// The characters standing in [beatId], in sequence. Empty means nobody.
  List<Character> castIn(String beatId) => appearancesIn(
    beatId,
  ).map((a) => character(a.characterId)).nonNulls.toList();

  /// The characters the source does not place in [beatId] at all.
  List<Character> offPageIn(String beatId) {
    final present = appearancesIn(beatId).map((a) => a.characterId).toSet();
    return characters.where((c) => !present.contains(c.id)).toList();
  }

  /// The parties standing in [beatId] — each an ordered cluster of characters.
  List<List<Character>> partiesIn(String beatId) {
    final byParty = <int, List<Appearance>>{};
    for (final a in appearancesIn(beatId)) {
      final party = a.party;
      if (party == null) continue;
      byParty.putIfAbsent(party, () => []).add(a);
    }
    final keys = byParty.keys.toList()..sort();
    return keys
        .map(
          (k) => byParty[k]!
              .map((a) => character(a.characterId))
              .nonNulls
              .toList(),
        )
        .toList();
  }

  /// The characters standing beside [characterId] in [beatId], itself excluded.
  List<Character> partyWith(String characterId, String beatId) {
    final mine = appearancesIn(
      beatId,
    ).where((a) => a.characterId == characterId).firstOrNull;
    if (mine == null) return const [];
    final party = mine.party;
    if (party == null) return const [];
    return appearancesIn(beatId)
        .where((a) => a.party == party && a.characterId != characterId)
        .map((a) => character(a.characterId))
        .nonNulls
        .toList();
  }

  /// The beats [characterId] appears in, in told order.
  List<Beat> beatsFor(String characterId) {
    final ids = appearances
        .where((a) => a.characterId == characterId)
        .map((a) => a.beatId)
        .toSet();
    return beats.where((b) => ids.contains(b.id)).toList();
  }

  /// The numbers of the beats [characterId] appears in, in told order.
  List<int> beatNumbersFor(String characterId) =>
      beatsFor(characterId).map((b) => b.order).toList();

  /// The beat [characterId] last appears in, or null when it never does.
  Beat? lastBeatOf(String characterId) => beatsFor(characterId).lastOrNull;

  /// What [characterId] is doing in [beatId], or null when it is absent.
  PresenceState? presenceOf(String characterId, String beatId) => appearancesIn(
    beatId,
  ).where((a) => a.characterId == characterId).firstOrNull?.state;

  @override
  List<Object?> get props => [
    slug,
    title,
    shape,
    work,
    year,
    runtimeMinutes,
    score,
    legendObject,
    laneOrder,
    characters,
    beats,
    appearances,
    extra,
  ];
}
