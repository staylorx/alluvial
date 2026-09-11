import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:fpdart/fpdart.dart';

import 'models/roundtrip_report.dart';

/// Proves the store is a fixed point: reading a story, writing it back out and
/// reading that again must land on the same story.
///
/// This is the gate that says the model is the store's source of truth rather
/// than a second reading of it. A story that changes on the way through is data
/// the model is dropping, and it is reported per story, naming the beat or the
/// appearance that moved, so the offender is actionable rather than merely
/// guilty.
final class RoundtripStories {
  /// Creates the use case over [repository] and [codec].
  const RoundtripStories(this._repository, this._codec);

  final StoryRepository _repository;
  final StoryCodec _codec;

  /// Every story in the store with whether it survived the pass.
  ///
  /// Arguments are store keys — the filenames a listing reports.
  Future<Either<DomainFailure, List<RoundtripReport>>> call({
    List<String> keys = const [],
  }) async {
    final List<String> loadable;
    if (keys.isNotEmpty) {
      loadable = keys;
    } else {
      final listed = await _repository.list();
      if (listed.isLeft()) return Left(listed.getLeft().toNullable()!);
      loadable = listed
          .getRight()
          .toNullable()!
          .map((summary) => summary.key)
          .toList();
    }

    final reports = <RoundtripReport>[];
    for (final key in loadable) {
      final loaded = await _repository.load(key);
      if (loaded.isLeft()) {
        reports.add((
          key: key,
          stable: false,
          detail: loaded.getLeft().toNullable()!.describe,
        ));
        continue;
      }
      final story = loaded.getRight().toNullable()!;
      final again = _codec.decode(_codec.encode(story));
      final failure = again.getLeft().toNullable();
      if (failure != null) {
        reports.add((
          key: key,
          stable: false,
          detail: 'the rewritten document does not decode: ${failure.describe}',
        ));
        continue;
      }
      final second = again.getRight().toNullable()!;
      reports.add((
        key: key,
        stable: story == second,
        detail: story == second ? null : _difference(story, second),
      ));
    }
    return Right(reports);
  }

  String _difference(Story before, Story after) {
    final moved = <String>[];
    if (before.slug != after.slug) {
      moved.add('slug ${before.slug} → ${after.slug}');
    }
    if (before.title != after.title) moved.add('title');
    if (before.shape != after.shape) moved.add('shape');
    if (before.expression != after.expression) moved.add('expression');
    if (before.year != after.year) moved.add('year');
    if (before.runtimeMinutes != after.runtimeMinutes) moved.add('runtime_min');
    if (before.score != after.score) moved.add('score');
    if (before.legendObject != after.legendObject) moved.add('legend_object');
    if (before.laneOrder.join(',') != after.laneOrder.join(',')) {
      moved.add('order ${before.laneOrder} → ${after.laneOrder}');
    }
    if (before.extra.toString() != after.extra.toString()) {
      moved.add('carried fields ${before.extra.keys} → ${after.extra.keys}');
    }

    for (var i = 0; i < before.characters.length; i++) {
      final was = before.characters[i];
      final is_ = i < after.characters.length ? after.characters[i] : null;
      if (is_ == was) continue;
      moved.add('character ${was.id}: ${is_ ?? 'missing'}');
    }
    if (after.characters.length > before.characters.length) {
      moved.add(
        '${after.characters.length - before.characters.length} extra strands',
      );
    }

    for (var i = 0; i < before.beats.length; i++) {
      final was = before.beats[i];
      final is_ = i < after.beats.length ? after.beats[i] : null;
      if (is_ == was) continue;
      if (is_ == null) {
        moved.add('beat ${was.id} went missing');
        continue;
      }
      final fields = <String>[];
      if (was.id != is_.id) fields.add('id ${was.id} → ${is_.id}');
      if (was.name != is_.name) fields.add('name');
      if (was.kind != is_.kind) fields.add('kind');
      if (was.order != is_.order) fields.add('order');
      if (was.parentRef != is_.parentRef) fields.add('parent');
      if (was.at != is_.at) fields.add('loc');
      if (was.happenedAt != is_.happenedAt) fields.add('happened');
      if (was.caption.join(' | ') != is_.caption.join(' | ')) fields.add('cap');
      if (was.tag != is_.tag) fields.add('tag');
      if (was.categories.join(',') != is_.categories.join(',')) {
        fields.add('cats');
      }
      if (was.threadId != is_.threadId) fields.add('thread');
      if (was.minutes != is_.minutes) fields.add('mins');
      if (was.extra.toString() != is_.extra.toString()) {
        fields.add('extra ${was.extra} → ${is_.extra}');
      }
      moved.add(
        'beat ${was.id}: ${fields.isEmpty ? 'differs' : fields.join(', ')}',
      );
    }

    final wasHere = [...before.appearances]..sort(_byBeatThenOrder);
    final isHere = [...after.appearances]..sort(_byBeatThenOrder);
    for (var i = 0; i < wasHere.length && i < isHere.length; i++) {
      if (wasHere[i] == isHere[i]) continue;
      moved.add(
        'appearance ${wasHere[i].beatId}/${wasHere[i].characterId} '
        '(${wasHere[i].order}, party ${wasHere[i].party}, lane ${wasHere[i].laneY}) '
        '→ (${isHere[i].order}, party ${isHere[i].party}, lane ${isHere[i].laneY})',
      );
    }
    if (wasHere.length != isHere.length) {
      moved.add(
        '${before.appearances.length} appearances became '
        '${after.appearances.length}',
      );
    }

    return moved.isEmpty ? 'the stories differ' : moved.take(4).join('; ');
  }

  static int _byBeatThenOrder(Appearance a, Appearance b) {
    final beat = a.beatId.compareTo(b.beatId);
    return beat != 0 ? beat : a.order.compareTo(b.order);
  }
}
