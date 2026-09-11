import 'dart:convert';
import 'dart:io';

import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_render/alluvial_render.dart';
import 'package:alluvial_usecases/alluvial_usecases.dart';

import '../output_format.dart';
import '../store_command.dart';
import '../views.dart';

/// `alluvial chart <key>` — draw a story as an SVG.
///
/// Nothing is written without `--out`, and no path outside the one the caller
/// names is ever touched: the store is the authored source, and a renderer that
/// quietly rewrites it is a renderer that loses work.
final class ChartCommand extends StoreCommand {
  /// Creates the verb over a store factory.
  ChartCommand(super.repository) {
    argParser
      ..addOption(
        'variant',
        abbr: 'v',
        help: 'Which treatment to draw.',
        allowed: ['braid', 'colour-blind', 'mini', 'two-clock'],
        defaultsTo: 'braid',
      )
      ..addOption('out', help: 'Write the SVG to this file.')
      ..addOption(
        'out-dir',
        help: 'Draw every story in the store into this directory.',
      )
      ..addFlag(
        'svg',
        help: 'Print the SVG itself on stdout, not a report about it.',
        negatable: false,
      );
  }

  @override
  String get name => 'chart';

  @override
  String get description =>
      'Draw a story as an SVG: the braid, its colour-blind treatment, the '
      'page mini-map, or a two-clock chart.';

  @override
  Future<int> execute() async {
    final variant = argResults!['variant'] as String;
    final outDir = argResults!['out-dir'] as String?;

    if (outDir != null) return _renderAll(variant, outDir);

    final key = argResults!.rest.isEmpty ? null : argResults!.rest.first;
    if (key == null) {
      stderr.writeln(
        'chart needs a story key, or --out-dir <dir> for every story:\n'
        '  alluvial chart when-harry-met-sally --store films --out chart.svg',
      );
      return 64;
    }
    final result = await LoadStory(open()).call(slug: key);
    return result.match((failure) {
      stdout.writeln(jsonEncode(failureJson(failure)));
      return 1;
    }, (story) => _draw(key, story, variant));
  }

  int _draw(String key, Story story, String variant) {
    final twoClock = story.shape == StoryShape.twoClock;
    if (twoClock && variant != 'two-clock' && variant != 'braid') {
      stderr.writeln(
        '"$key" is two-clock: its scenes carry no clusters, so it has no braid '
        'to draw. Use --variant two-clock.',
      );
      return 64;
    }
    if (!twoClock && variant == 'two-clock') {
      stderr.writeln(
        '"$key" is a braid: its beats carry clusters, not two orderings. Use '
        '--variant braid or leave the variant off.',
      );
      return 64;
    }

    final String svg;
    final int height;
    final int overlaps;
    if (twoClock) {
      svg = renderTwoClock(story);
      height = _heightAttribute(svg);
      overlaps = 0;
    } else {
      final rendered = renderFilmChart(
        story,
        cb: variant == 'colour-blind',
        mini: variant == 'mini',
      );
      svg = rendered.svg;
      height = rendered.height;
      overlaps = rendered.checks.laneOverlaps.length;
    }

    final out = argResults!['out'] as String?;
    String? written;
    if (out != null) {
      File(out).writeAsStringSync(svg);
      written = out;
    }

    if (argResults!['svg'] as bool) {
      stdout.write(svg);
      return overlaps == 0 ? 0 : 1;
    }

    stdout.writeln(
      format == OutputFormat.json
          ? jsonEncode({
              'key': key,
              'title': story.title,
              'shape': twoClock ? 'two-clock' : 'braid',
              'variant': twoClock ? 'two-clock' : variant,
              'beats': story.beats.length,
              'lanes': story.characters.length,
              'height': height,
              'svg_bytes': svg.length,
              'lane_overlaps': overlaps,
              'written_to': ?written,
            })
          : '${story.title}: ${svg.length} bytes, height $height, '
                '${story.beats.length} beats, ${story.characters.length} lanes'
                '${overlaps == 0 ? '' : ', $overlaps lane overlap(s)'}'
                '${written == null ? '' : '\n  written to $written'}',
    );
    return overlaps == 0 ? 0 : 1;
  }

  Future<int> _renderAll(String variant, String directory) async {
    final listed = await ListStories(open()).call();
    final summaries = listed.getRight().toNullable();
    if (summaries == null) {
      stdout.writeln(jsonEncode(failureJson(listed.getLeft().toNullable()!)));
      return 1;
    }
    final target = Directory(directory)..createSync(recursive: true);
    final written = <Map<String, Object?>>[];
    var overlaps = 0;
    var failed = 0;
    for (final summary in summaries) {
      final loaded = await LoadStory(open()).call(slug: summary.key);
      final story = loaded.getRight().toNullable();
      if (story == null) {
        failed += 1;
        continue;
      }
      final twoClock = story.shape == StoryShape.twoClock;
      if (twoClock && variant != 'braid' && variant != 'two-clock') continue;
      if (!twoClock && variant == 'two-clock') continue;
      final String svg;
      final int height;
      final int collisions;
      if (twoClock) {
        svg = renderTwoClock(story);
        height = _heightAttribute(svg);
        collisions = 0;
      } else {
        final rendered = renderFilmChart(
          story,
          cb: variant == 'colour-blind',
          mini: variant == 'mini',
        );
        svg = rendered.svg;
        height = rendered.height;
        collisions = rendered.checks.laneOverlaps.length;
      }
      overlaps += collisions;
      final path = '${target.path}/${summary.key}.svg';
      File(path).writeAsStringSync(svg);
      written.add({
        'key': summary.key,
        'shape': twoClock ? 'two-clock' : 'braid',
        'height': height,
        'svg_bytes': svg.length,
        'lane_overlaps': collisions,
        'path': path,
      });
    }
    stdout.writeln(
      format == OutputFormat.json
          ? jsonEncode({
              'variant': variant,
              'directory': target.path,
              'count': written.length,
              'unreadable': failed,
              'lane_overlaps': overlaps,
              'charts': written,
            })
          : 'drew ${written.length} chart(s) into ${target.path}'
                '${failed == 0 ? '' : ', $failed unreadable'}',
    );
    return overlaps == 0 ? 0 : 1;
  }

  int _heightAttribute(String svg) {
    final match = RegExp(r'height="(\d+)"').firstMatch(svg);
    return match == null ? 0 : int.parse(match.group(1)!);
  }
}
