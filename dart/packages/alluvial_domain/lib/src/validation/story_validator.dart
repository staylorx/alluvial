import '../entities/appearance.dart';
import '../entities/beat.dart';
import '../entities/character.dart';
import '../entities/presence_state.dart';
import '../entities/story.dart';
import '../entities/story_shape.dart';
import '../failures/validation_finding.dart';

/// The category ids a beat may claim.
const knownCategories = ['chem', 'meet', 'bff', 'breakup', 'gesture', 'ebert'];

/// Lane and beat budgets that keep a braid readable.
const maxBraidLanes = 8;

/// Lower bound on braid beats.
const minBraidBeats = 6;

/// Upper bound on braid beats.
const maxBraidBeats = 13;

/// Bounds on two-clock scenes.
const minTwoClockScenes = 6;

/// Upper bound on two-clock scenes.
const maxTwoClockScenes = 14;

/// Characters needed before a braid is a braid.
const minBraidCharacters = 2;

/// The longest caption line the caption column holds.
const maxCaptionChars = 62;

/// The longest lane label.
const maxCharacterNameChars = 11;

/// The longest two-clock scene label.
const maxSceneLabelChars = 34;

/// Checks a decoded story against the limits the store enforces.
///
/// Findings are errors unless marked as warnings; an error means the story
/// would render wrong or not at all, a warning means it is readable but
/// suspicious. The rules come from the published schema and the authored
/// limits in `STORY-SCHEMA.md`, restated here as the one place they live.
final class StoryValidator {
  /// Creates the validator.
  const StoryValidator();

  /// Every problem found in [story], in document order.
  List<ValidationFinding> validate(Story story) =>
      story.shape == StoryShape.braid ? _braid(story) : _twoClock(story);

  List<ValidationFinding> _braid(Story story) {
    final out = <ValidationFinding>[];
    _identity(story, out);

    final characters = story.characters;
    if (characters.length < minBraidCharacters ||
        characters.length > maxBraidLanes) {
      out.add(
        ValidationFinding(
          path: 'chars',
          message:
              '${characters.length} lanes — a braid holds '
              '$minBraidCharacters to $maxBraidLanes',
        ),
      );
    }
    final ids = <String>{};
    for (var i = 0; i < characters.length; i++) {
      final c = characters[i];
      _character(c, 'chars[$i]', out);
      if (!ids.add(c.id)) {
        out.add(
          ValidationFinding(
            path: 'chars[$i].id',
            message: 'duplicate id ${c.id}',
          ),
        );
      }
    }

    _laneOrder(story, ids, out);

    final beats = story.beats;
    if (beats.length < minBraidBeats || beats.length > maxBraidBeats) {
      out.add(
        ValidationFinding(
          path: 'beats',
          message:
              '${beats.length} beats — a braid holds '
              '$minBraidBeats to $maxBraidBeats',
        ),
      );
    }
    final beatIds = <String>{};
    for (var i = 0; i < beats.length; i++) {
      final b = beats[i];
      final path = 'beats[$i]';
      if (b.id.isEmpty) {
        out.add(
          ValidationFinding(path: 'name', message: 'a beat needs a name'),
        );
      }
      if (!beatIds.add(b.id)) {
        out.add(
          ValidationFinding(
            path: '$path.name',
            message: 'two beats share the name ${b.name}',
          ),
        );
      }
      if (b.name.length > 40) {
        out.add(
          ValidationFinding(
            path: '$path.name',
            message: '${b.name.length} characters — a beat name fits 40',
          ),
        );
      }
      if (b.caption.length != 2) {
        out.add(
          ValidationFinding(
            path: '$path.cap',
            message:
                '${b.caption.length} caption lines — a beat carries exactly 2',
          ),
        );
      }
      for (var line = 0; line < b.caption.length; line++) {
        final text = b.caption[line];
        if (text.length > maxCaptionChars) {
          out.add(
            ValidationFinding(
              path: '$path.cap[$line]',
              message:
                  '${text.length} characters — a caption line fits '
                  '$maxCaptionChars',
            ),
          );
        }
      }
      for (final cat in b.categories) {
        if (!knownCategories.contains(cat)) {
          out.add(
            ValidationFinding(
              path: '$path.cats',
              message:
                  'unknown category "$cat" — expected one of '
                  '${knownCategories.join(', ')}',
            ),
          );
        }
      }
      _beatPlacement(story, b, i, path, ids, out);
    }

    _separation(story, out);
    return out;
  }

  List<ValidationFinding> _twoClock(Story story) {
    final out = <ValidationFinding>[];
    _identity(story, out);

    final beats = story.beats;
    if (beats.length < minTwoClockScenes || beats.length > maxTwoClockScenes) {
      out.add(
        ValidationFinding(
          path: 'scenes',
          message:
              '${beats.length} scenes — a two-clock chart holds '
              '$minTwoClockScenes to $maxTwoClockScenes',
        ),
      );
    }

    final characterIds = story.characters.map((c) => c.id).toSet();
    final sceneIds = <String>{};
    final screened = <int>{};
    final happened = <int>{};
    for (var i = 0; i < beats.length; i++) {
      final b = beats[i];
      final path = 'scenes[$i]';
      if (!sceneIds.add(b.id)) {
        out.add(
          ValidationFinding(
            path: '$path.id',
            message: 'duplicate scene id ${b.id}',
          ),
        );
      }
      if (b.name.length > maxSceneLabelChars) {
        out.add(
          ValidationFinding(
            path: '$path.label',
            message:
                '${b.name.length} characters — a scene label fits '
                '$maxSceneLabelChars',
          ),
        );
      }
      final thread = b.threadId;
      if (thread == null) {
        out.add(
          ValidationFinding(
            path: '$path.thread',
            message: 'a scene needs a thread',
          ),
        );
      } else if (!characterIds.contains(thread)) {
        out.add(
          ValidationFinding(
            path: '$path.thread',
            message: 'thread "$thread" is not one of the story\'s threads',
          ),
        );
      }
      final real = b.happenedAt;
      if (real == null) {
        out.add(
          ValidationFinding(
            path: '$path.happened',
            message: 'a scene needs a happened position',
          ),
        );
      } else if (!happened.add(real)) {
        out.add(
          ValidationFinding(
            path: '$path.happened',
            message: 'position $real is used twice on the real spine',
          ),
        );
      }
      if (!screened.add(b.order)) {
        out.add(
          ValidationFinding(
            path: '$path.as_screened',
            message: 'position ${b.order} is used twice on the screening spine',
          ),
        );
      }
    }

    if (beats.isNotEmpty) {
      final expected = {for (var n = 1; n <= beats.length; n++) n};
      if (screened.length != beats.length || !expected.containsAll(screened)) {
        out.add(
          const ValidationFinding(
            path: 'scenes.as_screened',
            message: 'the screening order must be a permutation of 1..N',
          ),
        );
      }
      if (happened.length != beats.length || !expected.containsAll(happened)) {
        out.add(
          const ValidationFinding(
            path: 'scenes.happened',
            message: 'the real order must be a permutation of 1..N',
          ),
        );
      }
    }
    return out;
  }

  void _identity(Story story, List<ValidationFinding> out) {
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(story.slug)) {
      out.add(
        const ValidationFinding(
          path: 'slug',
          message: 'a slug is lowercase letters, digits and dashes',
        ),
      );
    }
    final year = story.year;
    if (year != null && (year < 1900 || year > 2100)) {
      out.add(
        ValidationFinding(path: 'year', message: '$year is out of range'),
      );
    }
    final runtime = story.runtimeMinutes;
    if (runtime != null && (runtime < 1 || runtime > 400)) {
      out.add(
        ValidationFinding(
          path: 'runtime_min',
          message: '$runtime is out of range',
        ),
      );
    }
    final score = story.score;
    if (score != null && (score < 0 || score > 30)) {
      out.add(
        ValidationFinding(path: 'score', message: '$score is out of range'),
      );
    }
  }

  void _character(Character c, String path, List<ValidationFinding> out) {
    if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(c.id)) {
      out.add(
        ValidationFinding(
          path: '$path.id',
          message:
              'a character id is lowercase letters, digits, dash or underscore',
        ),
      );
    }
    if (c.name.isEmpty) {
      out.add(
        ValidationFinding(path: '$path.name', message: 'a lane needs a label'),
      );
    }
    if (c.name.length > maxCharacterNameChars) {
      out.add(
        ValidationFinding(
          path: '$path.name',
          message:
              '${c.name.length} characters — a lane label fits '
              '$maxCharacterNameChars',
        ),
      );
    }
    if (c.weight != 0 && (c.weight < 10 || c.weight > 40)) {
      out.add(
        ValidationFinding(
          path: '$path.width',
          message: 'weight ${c.weight} is outside the 10-40 band',
        ),
      );
    }
    final colour = c.colour;
    if (colour != null && !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(colour)) {
      out.add(
        ValidationFinding(
          path: '$path.colour',
          message: '$colour is not #rrggbb',
        ),
      );
    }
  }

  void _laneOrder(Story story, Set<String> ids, List<ValidationFinding> out) {
    final seen = <String>{};
    for (final id in story.laneOrder) {
      if (!ids.contains(id)) {
        out.add(
          ValidationFinding(path: 'order', message: 'unknown character "$id"'),
        );
      }
      if (!seen.add(id)) {
        out.add(
          ValidationFinding(path: 'order', message: 'duplicate entry "$id"'),
        );
      }
    }
    for (final id in ids) {
      if (!seen.contains(id)) {
        out.add(
          ValidationFinding(
            path: 'order',
            message: 'character "$id" is missing from the lane order',
          ),
        );
      }
    }
  }

  void _beatPlacement(
    Story story,
    Beat beat,
    int index,
    String path,
    Set<String> characterIds,
    List<ValidationFinding> out,
  ) {
    final here = story.appearancesIn(beat.id);
    if (here.isEmpty) {
      out.add(
        ValidationFinding(
          path: path,
          message: 'no clusters — every beat needs who stands in it',
        ),
      );
    }
    final seen = <String>{};
    for (final a in here) {
      if (!characterIds.contains(a.characterId)) {
        out.add(
          ValidationFinding(
            path: '$path.clusters',
            message: 'unknown character "${a.characterId}"',
          ),
        );
      }
      if (!seen.add(a.characterId)) {
        out.add(
          ValidationFinding(
            path: '$path.clusters',
            message: '"${a.characterId}" appears in two clusters',
          ),
        );
      }
      if (a.state == PresenceState.exiting) {
        final after = story
            .beatsFor(a.characterId)
            .where((later) => later.order > index + 1)
            .firstOrNull;
        if (after != null) {
          out.add(
            ValidationFinding(
              path: '$path.stubs',
              message:
                  '"${a.characterId}" exits here but is present in '
                  '"${after.name}" later',
            ),
          );
        }
      }
      if (a.state == PresenceState.entering && index > 0) {
        final earlier = story
            .beatsFor(a.characterId)
            .where((b) => b.order < beat.order)
            .isNotEmpty;
        if (earlier) {
          out.add(
            ValidationFinding(
              path: '$path.enter',
              message:
                  '"${a.characterId}" is marked entering but appeared earlier',
              isWarning: true,
            ),
          );
        }
      }
    }

    for (final key in const ['enter', 'stubs']) {
      final raw = beat.extra[key];
      if (raw is! List) continue;
      final present = here.map((a) => a.characterId).toSet();
      for (final id in raw) {
        if (id is! String || present.contains(id)) continue;
        out.add(
          ValidationFinding(
            path: '$path.$key',
            message: '"$id" is named in $key but does not stand in this beat',
          ),
        );
        break;
      }
    }
  }

  void _separation(Story story, List<ValidationFinding> out) {
    if (story.extra.containsKey('never_separate_ok')) return;
    final ranked = [...story.characters]
      ..sort((a, b) => b.weight.compareTo(a.weight));
    if (ranked.length < 2) return;
    final leads = [ranked[0].id, ranked[1].id];
    var togetherOnly = story.beats.isNotEmpty;
    for (final beat in story.beats) {
      final here = story.appearancesIn(beat.id);
      final a = here.where((x) => x.characterId == leads[0]).firstOrNull;
      final b = here.where((x) => x.characterId == leads[1]).firstOrNull;
      if (a == null || b == null || a.party != b.party || a.party == null) {
        togetherOnly = false;
        break;
      }
    }
    if (togetherOnly) {
      out.add(
        ValidationFinding(
          path: 'beats',
          message:
              '${ranked[0].name} and ${ranked[1].name} share a cluster in '
              'every beat — the split has gone missing',
          isWarning: true,
        ),
      );
    }
  }
}

/// Every appearance in a beat, as a helper for callers walking the model.
extension AppearanceOrdering on List<Appearance> {
  /// The same list sorted by the sequence the reader sees.
  List<Appearance> get inSequence =>
      [...this]..sort((a, b) => a.order.compareTo(b.order));
}
