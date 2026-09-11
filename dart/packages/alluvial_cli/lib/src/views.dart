import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_usecases/alluvial_usecases.dart';

/// The JSON face of a story listing row.
///
/// `key` is the handle every other verb takes; `slug` is the story's own
/// identity, which two files can share.
Map<String, Object?> summaryJson(StorySummary summary) => {
  'key': summary.key,
  'slug': summary.slug,
  'title': summary.title,
  'shape': summary.shape?.name,
  'work': summary.work?.name,
  'year': summary.year,
  'runtime_min': summary.runtimeMinutes,
  'score': summary.score,
  'characters': summary.characterCount,
  'beats': summary.beatCount,
  if (summary.problem != null) 'problem': summary.problem,
};

/// The JSON face of a whole story.
///
/// The three entities are separate keys — `chars`, `beats`, `appearances` —
/// because a caller that wants the relation between a character and a beat
/// should not have to re-derive it from nested clusters.
Map<String, Object?> storyJson(Story story) => {
  'slug': story.slug,
  'title': story.title,
  'shape': story.shape.name,
  'work': story.work.name,
  'year': story.year,
  'runtime_min': story.runtimeMinutes,
  'score': story.score,
  'legend_object': story.legendObject,
  'order': story.laneOrder,
  'chars': [
    for (final character in story.characters)
      {
        'id': character.id,
        'name': character.name,
        'kind': character.kind.name,
        'width': character.weight,
        'colour': character.colour,
        if (character.extra.isNotEmpty) 'extra': character.extra,
      },
  ],
  'beats': [
    for (final beat in story.beats)
      {
        'id': beat.id,
        'name': beat.name,
        'kind': beat.kind.name,
        'order': beat.order,
        if (beat.parentRef != null) 'parent': beat.parentRef,
        'at': beat.at,
        if (beat.happenedAt != null) 'happened': beat.happenedAt,
        'cap': beat.caption,
        'tag': beat.tag,
        'cats': beat.categories,
        if (beat.threadId != null) 'thread': beat.threadId,
        if (beat.minutes != null) 'mins': beat.minutes,
        'parties': [
          for (final party in story.partiesIn(beat.id))
            [for (final character in party) character.id],
        ],
        'off_page': [
          for (final character in story.offPageIn(beat.id)) character.id,
        ],
        if (beat.extra.isNotEmpty) 'extra': beat.extra,
      },
  ],
  'appearances': [
    for (final appearance in story.appearances)
      {
        'character': appearance.characterId,
        'beat': appearance.beatId,
        'order': appearance.order,
        if (appearance.party != null) 'party': appearance.party,
        if (appearance.laneY != null) 'lane_y': appearance.laneY,
        'state': appearance.state.name,
      },
  ],
  if (story.extra.isNotEmpty) 'extra': story.extra,
};

/// The JSON face of a story's beat-by-beat relation view.
Map<String, Object?> timelineJson(Timeline timeline) => {
  'slug': timeline.slug,
  'title': timeline.title,
  'characters': [
    for (final character in timeline.characters)
      {
        'id': character.id,
        'name': character.name,
        'kind': character.kind.name,
        'width': character.weight,
      },
  ],
  'beats': [
    for (final beat in timeline.beats)
      {
        'order': beat.order,
        'id': beat.id,
        'name': beat.name,
        'at': beat.at,
        'cap': beat.caption,
        'tag': beat.tag,
        'parties': [
          for (final party in beat.parties)
            {
              'index': party.index,
              'members': [
                for (final actor in party.members)
                  {
                    'character': actor.characterId,
                    'name': actor.name,
                    'kind': actor.kind.name,
                    'sequence': actor.sequence,
                    'state': actor.state.name,
                  },
              ],
            },
        ],
        'off_page': beat.offPage,
      },
  ],
};

/// The JSON face of one story's validation report.
Map<String, Object?> reportJson(StoryReport report) => {
  'key': report.key,
  'title': report.title,
  'ok': report.findings.every((finding) => finding.isWarning),
  'errors': [
    for (final finding in report.findings)
      if (!finding.isWarning)
        {'path': finding.path, 'message': finding.message},
  ],
  'warnings': [
    for (final finding in report.findings)
      if (finding.isWarning) {'path': finding.path, 'message': finding.message},
  ],
};

/// The JSON face of one story's round-trip result.
Map<String, Object?> roundtripJson(RoundtripReport report) => {
  'key': report.key,
  'stable': report.stable,
  if (report.detail != null) 'detail': report.detail,
};

/// The JSON face of a failure.
Map<String, Object?> failureJson(DomainFailure failure) => {
  'error': failure.code,
  'message': failure.describe,
};

/// One listing row as a line of text.
String summaryLine(StorySummary summary) {
  final counts = summary.problem != null
      ? 'unreadable: ${summary.problem}'
      : '${summary.characterCount} lanes, ${summary.beatCount} beats, '
            '${summary.shape?.name}, ${summary.year ?? '—'}';
  return '${summary.slug}  ${summary.title ?? ''}  ($counts)';
}

/// A whole story as text, beat by beat.
String storyText(Story story) {
  final lines = <String>[
    '${story.title} (${story.slug}) — ${story.shape.name}, ${story.work.name}',
    '${story.characters.length} strands, ${story.beats.length} beats',
    '',
  ];
  for (final beat in story.beats) {
    final parties = story
        .partiesIn(beat.id)
        .map((party) => party.map((c) => c.name).join(' + '))
        .join('  |  ');
    lines.add(
      '${beat.order}. ${beat.name}${beat.at == null ? '' : '  ${beat.at}'}',
    );
    lines.add('   $parties');
    for (final caption in beat.caption) {
      lines.add('   $caption');
    }
    if (beat.tag != null) lines.add('   ${beat.tag}');
  }
  return lines.join('\n');
}

/// A story's relation view as text.
String timelineText(Timeline timeline) {
  final lines = <String>[
    '${timeline.title} (${timeline.slug})',
    'lanes: ${timeline.characters.map((c) => c.name).join(', ')}',
    '',
  ];
  for (final beat in timeline.beats) {
    lines.add(
      '${beat.order}. ${beat.name}${beat.at == null ? '' : '  ${beat.at}'}',
    );
    for (final party in beat.parties) {
      lines.add(
        '   [${party.index}] ${party.members.map((m) => '${m.sequence}:${m.name}').join(', ')}',
      );
    }
    if (beat.offPage.isNotEmpty) {
      lines.add('   off page: ${beat.offPage.join(', ')}');
    }
  }
  return lines.join('\n');
}

/// A validation run as text.
String validationText(List<StoryReport> reports) {
  final lines = <String>[];
  for (final report in reports) {
    final errors = report.findings
        .where((finding) => !finding.isWarning)
        .toList();
    final warnings = report.findings
        .where((finding) => finding.isWarning)
        .toList();
    lines.add(
      '${errors.isEmpty ? 'ok  ' : 'FAIL'} ${report.key}'
      '${report.title == null ? '' : ' — ${report.title}'}'
      ' (${errors.length} errors, ${warnings.length} warnings)',
    );
    for (final finding in [...errors, ...warnings]) {
      lines.add('  ${finding.isWarning ? 'warn' : 'err '} ${finding.describe}');
    }
  }
  final failed = reports
      .where((report) => report.findings.any((finding) => !finding.isWarning))
      .length;
  lines.add('${reports.length - failed} valid, $failed invalid');
  return lines.join('\n');
}

/// A round-trip run as text.
String roundtripText(List<RoundtripReport> reports) {
  final lines = <String>[];
  for (final report in reports) {
    lines.add(
      '${report.stable ? 'stable  ' : 'CHANGED '} ${report.key}'
      '${report.detail == null ? '' : ' — ${report.detail}'}',
    );
  }
  final changed = reports.where((report) => !report.stable).length;
  lines.add('${reports.length - changed} stable, $changed changed');
  return lines.join('\n');
}
