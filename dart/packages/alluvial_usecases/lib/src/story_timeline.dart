import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:fpdart/fpdart.dart';

import 'models/timeline.dart';

/// Lays one story out beat by beat — who is in each beat, in what sequence,
/// beside whom, and who the source leaves out.
final class StoryTimeline {
  /// Creates the use case over [repository].
  const StoryTimeline(this._repository);

  final StoryRepository _repository;

  /// The relation view of the story stored under [slug].
  Future<Either<DomainFailure, Timeline>> call({required String slug}) async {
    final loaded = await _repository.load(slug);
    return loaded.map(_build);
  }

  Timeline _build(Story story) => Timeline(
    slug: story.slug,
    title: story.title,
    characters: [
      for (final id in story.laneOrder) ?story.character(id),
      ...story.characters.where((c) => !story.laneOrder.contains(c.id)),
    ],
    beats: [
      for (final beat in story.beats)
        TimelineBeat(
          order: beat.order,
          id: beat.id,
          name: beat.name,
          at: beat.at,
          caption: beat.caption,
          tag: beat.tag,
          parties: [
            for (final party in story.partiesIn(beat.id).indexed)
              TimelineParty(
                index: party.$1,
                members: [
                  for (final character in party.$2)
                    TimelineActor(
                      characterId: character.id,
                      name: character.name,
                      kind: character.kind,
                      sequence: _sequenceOf(story, character.id, beat.id),
                      state:
                          story.presenceOf(character.id, beat.id) ??
                          PresenceState.onPage,
                    ),
                ],
              ),
          ],
          offPage: [
            for (final character in story.offPageIn(beat.id)) character.id,
          ],
        ),
    ],
  );

  int _sequenceOf(Story story, String characterId, String beatId) =>
      story
          .appearancesIn(beatId)
          .where((a) => a.characterId == characterId)
          .firstOrNull
          ?.order ??
      0;
}
