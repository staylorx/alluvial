/// Byte-identity of the Dart renderer against the Python engine.
///
/// The Python engine produced every approved chart, so the port's gate is not
/// "looks right" but "identical bytes". This tool renders every braid film in
/// the store — default, colour-blind, mini — and diffs against the reference
/// corpus, then compares the drawn layout field by field so a mismatch can be
/// traced to the builder (layout) or the engine (markup) without guessing.
///
/// Usage: dart run tool/parity_report.dart [store-dir] [reference-dir] [key]
library;

import 'dart:convert';
import 'dart:io';

import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_render/alluvial_render.dart';
import 'package:alluvial_store_yaml/alluvial_store_yaml.dart';

Future<void> main(List<String> args) async {
  final store = args.isNotEmpty ? args[0] : '/tmp/alluvial-dart/films';
  final reference = args.length > 1 ? args[1] : '/tmp/ref';
  final only = args.length > 2 ? args[2] : null;

  final repository = FolderStoryRepository(
    datasource: YamlFolderDatasource(directory: store),
  );
  final keys =
      Directory(store)
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => p.endsWith('.yaml'))
          .map((p) => p.split('/').last.replaceAll(RegExp(r'\.yaml$'), ''))
          .where((k) => only == null || k == only)
          .toList()
        ..sort();

  final variants = <String, bool Function()>{
    '': () => false,
    '.cb': () => true,
  };

  var identical = 0;
  var differing = 0;
  var missing = 0;
  var skipped = 0;
  final failures = <Map<String, Object?>>[];

  for (final key in keys) {
    final loaded = await repository.load(key);
    final story = loaded.getRight().toNullable();
    if (story == null) {
      skipped += 1;
      continue;
    }
    if (story.shape == StoryShape.twoClock) {
      final file = File('$reference/twoclock/$key.svg');
      if (!file.existsSync()) {
        missing += 1;
        skipped += 1;
        continue;
      }
      final expected = file.readAsStringSync();
      final rendered = renderTwoClock(story);
      if (rendered == expected) {
        identical += 1;
      } else {
        differing += 1;
        if (failures.length < 6) {
          failures.add(_describe('$key (two-clock)', expected, rendered));
        }
      }
      continue;
    }
    for (final entry in variants.entries) {
      final file = File('$reference/$key${entry.key}.svg');
      if (!file.existsSync()) {
        missing += 1;
        continue;
      }
      final expected = file.readAsStringSync();
      final rendered = renderFilmChart(story, cb: entry.value()).svg;
      if (rendered == expected) {
        identical += 1;
      } else {
        differing += 1;
        if (failures.length < 6) {
          failures.add(_describe(key + entry.key, expected, rendered));
        }
      }
    }
    // mini is rendered from the same spec with collapsed rows
    final miniFile = File('$reference/$key.mini.svg');
    if (miniFile.existsSync()) {
      final expected = miniFile.readAsStringSync();
      final rendered = renderFilmChart(story, mini: true).svg;
      if (rendered == expected) {
        identical += 1;
      } else {
        differing += 1;
        if (failures.length < 6) {
          failures.add(_describe('$key.mini', expected, rendered));
        }
      }
    }
  }

  final layout = <String>[];
  for (final key in keys) {
    final specFile = File('$reference/$key.spec.json');
    if (!specFile.existsSync()) continue;
    final loaded = await repository.load(key);
    final story = loaded.getRight().toNullable();
    if (story == null || story.shape == StoryShape.twoClock) continue;
    final expected =
        jsonDecode(specFile.readAsStringSync()) as Map<String, Object?>;
    final spec = buildChartSpec(story);
    layout.addAll(_compareLayout(key, expected, spec));
  }

  stdout.writeln(
    jsonEncode({
      'films': keys.length,
      'svg_identical': identical,
      'svg_differing': differing,
      'svg_missing_reference': missing,
      'skipped': skipped,
      'layout_differences': layout.length,
    }),
  );
  for (final failure in failures) {
    stdout.writeln(
      '\n--- ${failure['name']} (${failure['kind']}) ---\n${failure['detail']}',
    );
  }
  for (final line in layout.take(20)) {
    stdout.writeln('LAYOUT $line');
  }
}

Map<String, Object?> _describe(String name, String expected, String actual) {
  final want = expected.split('\n');
  final got = actual.split('\n');
  final detail = StringBuffer();
  if (want.length != got.length) {
    detail.writeln('lines: want ${want.length}, got ${got.length}');
  }
  var reported = 0;
  for (var i = 0; i < want.length && i < got.length; i++) {
    if (want[i] == got[i]) continue;
    detail.writeln('line ${i + 1}:');
    detail.writeln('  want: ${want[i]}');
    detail.writeln('  got : ${got[i]}');
    if (i + 1 < want.length) detail.writeln('  want+: ${want[i + 1]}');
    if (i + 1 < got.length) detail.writeln('  got +: ${got[i + 1]}');
    reported += 1;
    if (reported == 2) break;
  }
  if (reported == 0) {
    detail.writeln(
      'bytes differ but every shared line matches: lengths '
      '${expected.length} vs ${actual.length}',
    );
  }
  return {'name': name, 'kind': 'svg', 'detail': detail.toString()};
}

List<String> _compareLayout(
  String key,
  Map<String, Object?> expected,
  ChartSpec actual,
) {
  final out = <String>[];
  final spec = expected['spec']! as Map<String, Object?>;
  final wantYs = (spec['ys']! as List).cast<num>();
  if (wantYs.length != actual.ys.length) {
    out.add('$key ys length ${wantYs.length} vs ${actual.ys.length}');
  } else {
    for (var i = 0; i < wantYs.length; i++) {
      if (wantYs[i].toDouble() != actual.ys[i]) {
        out.add('$key ys[$i] ${wantYs[i]} vs ${actual.ys[i]}');
        break;
      }
    }
  }
  final wantFonts = (spec['label_font']! as Map).cast<String, Object?>();
  for (final entry in wantFonts.entries) {
    final want = (entry.value! as num).toDouble();
    final got = actual.labelFont[entry.key];
    if (got != want) out.add('$key font ${entry.key} $want vs $got');
  }
  final wantCols = (spec['cols']! as List).cast<Map<String, Object?>>();
  if (wantCols.length != actual.columns.length) {
    out.add('$key cols ${wantCols.length} vs ${actual.columns.length}');
  } else {
    for (var i = 0; i < wantCols.length; i++) {
      final wantGroups = (wantCols[i]['groups']! as List)
          .map((g) => (g as List)[0] as num)
          .toList();
      final gotGroups = [for (final g in actual.columns[i].groups) g.centre];
      if (wantGroups.length != gotGroups.length) {
        out.add(
          '$key col[$i] groups ${wantGroups.length} vs ${gotGroups.length}',
        );
        continue;
      }
      for (var j = 0; j < wantGroups.length; j++) {
        if (wantGroups[j].toDouble() != gotGroups[j]) {
          out.add(
            '$key col[$i] group[$j] centre ${wantGroups[j]} vs ${gotGroups[j]}',
          );
          break;
        }
      }
      final wantCap = (wantCols[i]['cap']! as List).cast<String>();
      if (wantCap.join('|') != actual.columns[i].caption.join('|')) {
        out.add(
          '$key col[$i] caption "${wantCap.join('|')}" vs '
          '"${actual.columns[i].caption.join('|')}"',
        );
      }
      final wantEnter = (wantCols[i]['enter']! as List).cast<String>();
      if (wantEnter.join('|') != actual.columns[i].enter.join('|')) {
        out.add(
          '$key col[$i] enter "${wantEnter.join('|')}" vs '
          '"${actual.columns[i].enter.join('|')}"',
        );
      }
      final wantStubs = (wantCols[i]['stubs']! as List)
          .map((s) => (s as List)[0] as String)
          .toList();
      final gotStubs = [for (final s in actual.columns[i].stubs) s.id];
      if (wantStubs.join('|') != gotStubs.join('|')) {
        out.add(
          '$key col[$i] stubs "${wantStubs.join('|')}" vs '
          '"${gotStubs.join('|')}"',
        );
      }
    }
  }
  return out;
}
