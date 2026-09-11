import 'package:fpdart/fpdart.dart';

import '../contracts/story_codec.dart';
import '../entities/appearance.dart';
import '../entities/beat.dart';
import '../entities/beat_kind.dart';
import '../entities/character.dart';
import '../entities/entity_kind.dart';
import '../entities/presence_state.dart';
import '../entities/story.dart';
import '../entities/story_shape.dart';
import '../entities/expression.dart';

/// Field order a braid story is written back in.
const _braidKeys = <String>[
  'slug',
  'title',
  'expression',
  'year',
  'runtime_min',
  'rubric',
  'score',
  'score_note',
  'blurb',
  'legend_object',
  'legend_note',
  'title_notes',
  'title_block',
  'mirror',
  'dashed',
  'never_separate_ok',
  'order',
  'chars',
  'beats',
];

/// Field order a two-clock story is written back in.
const _twoClockKeys = <String>[
  'slug',
  'title',
  'expression',
  'year',
  'runtime_min',
  'sub',
  'notes',
  'legend_note',
  'threads',
  'scenes',
];

/// Field order inside one character record.
const _charKeys = <String>['id', 'name', 'kind', 'width', 'colour'];

/// Field order inside one braid beat record.
const _beatKeys = <String>[
  'name',
  'kind',
  'parent',
  'loc',
  'cap',
  'tag',
  'cats',
  'clusters',
  'groups',
  'enter',
  'stubs',
  'hard',
];

/// Field order inside one two-clock scene record.
const _sceneKeys = <String>[
  'id',
  'label',
  'chapter',
  'as_screened',
  'happened',
  'thread',
  'mins',
];

/// Keys the model consumes, so everything else can be carried through as-is.
const _consumedStoryKeys = <String>{
  'slug',
  'title',
  'expression',
  'year',
  'runtime_min',
  'rubric',
  'score',
  'legend_object',
  'order',
  'chars',
  'beats',
  'threads',
  'scenes',
};

/// The one thing that knows what a stored story field means.
///
/// Decoding is deliberately total: it coerces whatever an author could
/// plausibly have typed and never throws, so one malformed row cannot kill a
/// whole-folder read. Anything it drops or cannot read is the validator's
/// business, not its own — `decode` only fails when the document is not a
/// story at all.
///
/// A braid beat's `id` is derived from its name, because that is the only
/// identity the stored format carries: renaming a beat renames it everywhere,
/// and the clusters are unaffected because they name characters, not beats.
final class StoryDocumentCodec implements StoryCodec {
  /// Creates the codec.
  const StoryDocumentCodec();

  @override
  Either<StoryDecodeFailure, Story> decode(Map<String, Object?> document) {
    final slug = _str(document['slug']);
    if (slug == null || slug.isEmpty) {
      return const Left(StoryDecodeFailure('slug', 'a story needs a slug'));
    }
    final title = _str(document['title']);
    if (title == null || title.isEmpty) {
      return const Left(StoryDecodeFailure('title', 'a story needs a title'));
    }

    final rawBeats = document['beats'];
    final rawScenes = document['scenes'];
    if (rawBeats is! List && rawScenes is! List) {
      return const Left(
        StoryDecodeFailure('beats', 'a story needs a beats or a scenes list'),
      );
    }
    final shape = rawBeats is List ? StoryShape.braid : StoryShape.twoClock;

    final characters = shape == StoryShape.braid
        ? _characters(document['chars'])
        : _threads(document['threads']);

    final beats = <Beat>[];
    final appearances = <Appearance>[];
    if (shape == StoryShape.braid) {
      final rows = rawBeats as List<Object?>;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row is! Map) {
          return Left(
            StoryDecodeFailure('beats[$i]', 'a beat must be a mapping'),
          );
        }
        final map = _mapping(row);
        final name = _str(map['name']) ?? '';
        final id = _beatId(name);
        final here = _beatAppearances(id, map);
        beats.add(_beat(i + 1, name, map, here));
        appearances.addAll(here);
      }
    } else {
      final rows = rawScenes as List<Object?>;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row is! Map) {
          return Left(
            StoryDecodeFailure('scenes[$i]', 'a scene must be a mapping'),
          );
        }
        final map = _mapping(row);
        final id = _str(map['id']) ?? 'scene-${i + 1}';
        beats.add(_scene(id, i + 1, map));
        final thread = _str(map['thread']);
        if (thread != null) {
          appearances.add(
            Appearance(characterId: thread, beatId: id, order: 1, party: 0),
          );
        }
      }
    }

    final laneOrder = _strList(document['order']);
    final extra = <String, Object?>{};
    for (final entry in document.entries) {
      if (_consumedStoryKeys.contains(entry.key)) continue;
      extra[entry.key] = entry.value;
    }

    return Right(
      Story(
        slug: slug,
        title: title,
        shape: shape,
        expression: Expression.fromYaml(document['expression']),
        year: _int(document['year']),
        runtimeMinutes: _int(document['runtime_min']),
        rubricId: _str(document['rubric']),
        score: _int(document['score']),
        legendObject: _str(document['legend_object']),
        laneOrder: laneOrder.isEmpty
            ? characters.map((c) => c.id).toList()
            : laneOrder,
        characters: characters,
        beats: beats,
        appearances: appearances,
        extra: extra,
      ),
    );
  }

  @override
  Map<String, Object?> encode(Story story) {
    final characters = story.characters.map(_encodeCharacter).toList();
    final beats = story.shape == StoryShape.braid
        ? story.beats
              .map((b) => _encodeBeat(b, story.appearancesIn(b.id)))
              .toList()
        : story.beats.map((b) => _encodeScene(b)).toList();

    final body = <String, Object?>{
      'slug': story.slug,
      'title': story.title,
      // A film does not write the field back: absent means film, which is what
      // every file predating `expression` relies on.
      if (story.expression != Expression.film) 'expression': story.expression.yaml,
      'year': story.year,
      'runtime_min': story.runtimeMinutes,
      // The rubric that grades this story, if one does. Nothing is assumed for a
      // story that declares none.
      if (story.rubricId != null) 'rubric': story.rubricId,
      'score': story.score,
      if (story.legendObject != null) 'legend_object': story.legendObject,
      'order': story.shape == StoryShape.braid ? story.laneOrder : null,
      if (story.shape == StoryShape.braid) 'chars': characters,
      if (story.shape == StoryShape.braid) 'beats': beats,
      if (story.shape == StoryShape.twoClock)
        'threads': {for (final c in story.characters) c.id: c.name},
      if (story.shape == StoryShape.twoClock) 'scenes': beats,
    };
    for (final entry in story.extra.entries) {
      body[entry.key] = entry.value;
    }
    return _order(
      body,
      story.shape == StoryShape.braid ? _braidKeys : _twoClockKeys,
    );
  }

  // --- decoding helpers ----------------------------------------------------

  List<Character> _characters(Object? raw) {
    if (raw is! List) return const [];
    final out = <Character>[];
    for (final row in raw) {
      if (row is! Map) continue;
      final map = _mapping(row);
      final id = _str(map['id']);
      if (id == null || id.isEmpty) continue;
      out.add(
        Character(
          id: id,
          name: _str(map['name']) ?? id,
          kind: _entityKind(map['kind']),
          weight: _int(map['width']) ?? 0,
          colour: _str(map['colour']),
          extra: _rest(map, _charKeys),
        ),
      );
    }
    return out;
  }

  List<Character> _threads(Object? raw) {
    final out = <Character>[];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final id = '${entry.key}';
        out.add(
          Character(
            id: id,
            name: _str(entry.value) ?? id,
            kind: EntityKind.person,
          ),
        );
      }
      return out;
    }
    if (raw is List) {
      for (final row in raw) {
        if (row is Map) {
          final map = _mapping(row);
          final id = _str(map['id']);
          if (id == null || id.isEmpty) continue;
          out.add(
            Character(
              id: id,
              name: _str(map['name']) ?? id,
              kind: EntityKind.person,
            ),
          );
        }
      }
    }
    return out;
  }

  Beat _beat(
    int order,
    String name,
    Map<String, Object?> map,
    List<Appearance> here,
  ) => Beat(
    id: _beatId(name),
    name: name,
    kind: _beatKind(map['kind']),
    order: order,
    parentRef: _str(map['parent']),
    at: _str(map['loc']),
    caption: _strList(map['cap']),
    tag: _str(map['tag']),
    categories: _strList(map['cats']),
    extra: _presenceExtra(map, here),
  );

  /// Carries the parts of `enter` / `stubs` the appearances cannot express.
  ///
  /// The presence model derives both lists from the appearances, so a raw list
  /// that says something different — an id that does not stand in the beat, a
  /// different order, or an explicitly empty list meaning "nobody leaves here"
  /// — is carried verbatim and re-emitted. Nothing the author typed is lost,
  /// and the validator reports the ids that do not belong.
  Map<String, Object?> _presenceExtra(
    Map<String, Object?> map,
    List<Appearance> here,
  ) {
    final extra = _rest(map, _beatKeys);
    for (final key in const ['enter', 'stubs']) {
      final raw = map[key];
      if (raw is! List) continue;
      final ids = _strList(raw);
      final derived = [
        for (final a in here)
          if (a.state == _presenceStateOf(key)) a.characterId,
      ];
      if (ids.isEmpty || ids.join('\u0000') != derived.join('\u0000')) {
        extra[key] = ids;
      }
    }
    return extra;
  }

  PresenceState _presenceStateOf(String key) =>
      key == 'enter' ? PresenceState.entering : PresenceState.exiting;

  Beat _scene(String id, int order, Map<String, Object?> map) => Beat(
    id: id,
    name: _str(map['label']) ?? id,
    kind: BeatKind.scene,
    order: _int(map['as_screened']) ?? order,
    parentRef: _str(map['chapter']),
    happenedAt: _int(map['happened']),
    threadId: _str(map['thread']),
    minutes: _int(map['mins']),
    extra: _rest(map, _sceneKeys),
  );

  List<Appearance> _beatAppearances(String beatId, Map<String, Object?> map) {
    final out = <Appearance>[];
    final entering = _strList(map['enter']).toSet();
    final exiting = _strList(map['stubs']).toSet();

    PresenceState stateOf(String id) {
      if (entering.contains(id)) return PresenceState.entering;
      if (exiting.contains(id)) return PresenceState.exiting;
      return PresenceState.onPage;
    }

    final clusters = map['clusters'];
    if (clusters is List) {
      final party = _parties(clusters);
      var order = 0;
      for (var p = 0; p < party.length; p++) {
        for (final id in party[p]) {
          order++;
          out.add(
            Appearance(
              characterId: id,
              beatId: beatId,
              order: order,
              party: p,
              state: stateOf(id),
            ),
          );
        }
      }
    }
    final groups = map['groups'];
    if (groups is List) {
      final positioned = _positioned(groups);
      var order = 0;
      for (final entry in positioned) {
        for (final id in entry.$2) {
          order++;
          out.add(
            Appearance(
              characterId: id,
              beatId: beatId,
              order: order,
              laneY: entry.$1,
              state: stateOf(id),
            ),
          );
        }
      }
    }
    return out;
  }

  // --- encoding helpers ----------------------------------------------------

  Map<String, Object?> _encodeCharacter(Character c) =>
      _order(<String, Object?>{
        'id': c.id,
        'name': c.name,
        'kind': c.kind == EntityKind.person ? null : c.kind.name,
        'width': c.weight,
        'colour': c.colour,
        ...c.extra,
      }, _charKeys);

  Map<String, Object?> _encodeBeat(Beat b, List<Appearance> here) {
    final byParty = <int, List<String>>{};
    final byLane = <double, List<String>>{};
    final laneSequence = <double>[];
    final entering = <String>[];
    final exiting = <String>[];
    for (final a in here) {
      if (a.state == PresenceState.entering) entering.add(a.characterId);
      if (a.state == PresenceState.exiting) exiting.add(a.characterId);
      final party = a.party;
      final lane = a.laneY;
      if (party != null) {
        byParty.putIfAbsent(party, () => []).add(a.characterId);
      } else if (lane != null) {
        // Lanes are emitted in the sequence they first appear in, not sorted:
        // the sequence inside a beat is part of the record, and re-sorting it
        // silently renumbers every hand-tuned appearance on the way out.
        if (!byLane.containsKey(lane)) laneSequence.add(lane);
        byLane.putIfAbsent(lane, () => []).add(a.characterId);
      }
    }
    final partyKeys = byParty.keys.toList()..sort();

    return _order(<String, Object?>{
      'name': b.name,
      'kind': b.kind == BeatKind.beat ? null : b.kind.name,
      'parent': b.parentRef,
      'loc': b.at,
      'cap': b.caption,
      'tag': b.tag,
      'cats': b.categories,
      if (partyKeys.isEmpty && laneSequence.isEmpty) 'clusters': <Object?>[],
      if (partyKeys.isNotEmpty)
        'clusters': [for (final k in partyKeys) byParty[k]!],
      if (laneSequence.isNotEmpty)
        'groups': [
          for (final k in laneSequence) <Object?>[k, byLane[k]!],
        ],
      if (!b.extra.containsKey('enter') && entering.isNotEmpty)
        'enter': entering,
      if (!b.extra.containsKey('stubs') && exiting.isNotEmpty) 'stubs': exiting,
      ...b.extra,
    }, _beatKeys);
  }

  Map<String, Object?> _encodeScene(Beat b) => _order(<String, Object?>{
    'id': b.id,
    'label': b.name,
    'chapter': b.parentRef,
    'as_screened': b.order,
    'happened': b.happenedAt,
    'thread': b.threadId,
    'mins': b.minutes,
    ...b.extra,
  }, _sceneKeys);
}

/// Derives the beat key from its printed name.
String _beatId(String name) {
  final lowered = name.toLowerCase();
  final buffer = StringBuffer();
  var lastDash = false;
  for (final rune in lowered.runes) {
    final char = String.fromCharCode(rune);
    final isWord = RegExp('[a-z0-9]').hasMatch(char);
    if (isWord) {
      buffer.write(char);
      lastDash = false;
    } else if (!lastDash && buffer.isNotEmpty) {
      buffer.write('-');
      lastDash = true;
    }
  }
  var out = buffer.toString();
  while (out.endsWith('-')) {
    out = out.substring(0, out.length - 1);
  }
  return out.isEmpty ? 'beat' : out;
}

/// Reorders [body] so the canonical keys lead, in [keys] order.
Map<String, Object?> _order(Map<String, Object?> body, List<String> keys) {
  final out = <String, Object?>{};
  for (final key in keys) {
    if (body.containsKey(key) && body[key] != null) out[key] = body[key];
  }
  for (final entry in body.entries) {
    if (entry.value == null || out.containsKey(entry.key)) continue;
    out[entry.key] = entry.value;
  }
  return out;
}

/// Every mapping key not in [known], preserved so a write loses nothing.
Map<String, Object?> _rest(Map<String, Object?> map, List<String> known) => {
  for (final entry in map.entries)
    if (!known.contains(entry.key)) entry.key: entry.value,
};

/// Reads [raw] as a list of cluster id-lists, flattening any nesting.
List<List<String>> _parties(Object? raw) {
  if (raw is! List) return const [];
  final out = <List<String>>[];
  for (final row in raw) {
    if (row is List) {
      final ids = <String>[];
      for (final x in row) {
        if (x is List) {
          ids.addAll(_strList(x));
        } else {
          final s = _str(x);
          if (s != null) ids.add(s);
        }
      }
      out.add(ids);
    } else {
      final s = _str(row);
      if (s != null) out.add([s]);
    }
  }
  return out;
}

/// Reads hand-tuned `[lane_y, [ids]]` pairs, keeping their positions.
List<(double, List<String>)> _positioned(Object? raw) {
  if (raw is! List) return const [];
  final out = <(double, List<String>)>[];
  for (final row in raw) {
    if (row is! List || row.length < 2) continue;
    final y = _double(row[0]);
    if (y == null) continue;
    out.add((y, _strList(row[1])));
  }
  return out;
}

/// Narrows an arbitrary map to a string-keyed one.
Map<String, Object?> _mapping(Map<Object?, Object?> raw) => {
  for (final entry in raw.entries) '${entry.key}': entry.value,
};

/// Reads a string, or null when the value is not one.
String? _str(Object? value) => value is String ? value : null;

/// Reads an integer, tolerating a numeric string.
int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Reads a double, tolerating an integer.
double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Reads a list of strings, tolerating a bare string or nested lists.
List<String> _strList(Object? value) {
  if (value == null) return const [];
  if (value is String) return value.isEmpty ? const [] : [value];
  if (value is! List) return const [];
  final out = <String>[];
  for (final row in value) {
    if (row is String) {
      out.add(row);
    } else if (row is List) {
      out.addAll(_strList(row));
    }
  }
  return out;
}

/// Reads an entity kind, defaulting to a person.
EntityKind _entityKind(Object? value) => switch (_str(value)) {
  'place' => EntityKind.place,
  'thing' => EntityKind.thing,
  _ => EntityKind.person,
};

/// Reads a beat kind, defaulting to a beat inside a scene.
BeatKind _beatKind(Object? value) => switch (_str(value)) {
  'act' => BeatKind.act,
  'scene' => BeatKind.scene,
  _ => BeatKind.beat,
};
