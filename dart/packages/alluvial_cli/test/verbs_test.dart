import 'dart:convert';
import 'dart:io';

import 'package:alluvial_store_yaml/alluvial_store_yaml.dart';
import 'package:alluvial_testing/alluvial_testing.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// Drives the shipped surface the way a skill does: a real process, arguments
/// after the verb, stdout captured alone and parsed. A verb that falls back to
/// printing usage fails here, which is the failure this file exists to catch.
void main() {
  late Directory store;

  setUp(() async {
    store = await Directory.systemTemp.createTemp('alluvial_cli_');
    await FolderStoryRepository(
      datasource: YamlFolderDatasource(directory: store.path),
    ).save(sampleStory(), key: 'a-sample');
  });

  tearDown(() async {
    if (store.existsSync()) await store.delete(recursive: true);
  });

  Future<ProcessResult> drive(List<String> args) => Process.run(
    Platform.resolvedExecutable,
    ['run', 'bin/alluvial.dart', ...args],
    workingDirectory: Directory.current.path,
  );

  Map<String, Object?> jsonOf(ProcessResult result) {
    final out = (result.stdout as String).trim();
    out.contains('Usage:').should.be(false);
    out.isEmpty.should.be(false);
    return jsonDecode(out) as Map<String, Object?>;
  }

  test(
    'Given the version verb, when driven, then it answers with JSON',
    () async {
      final result = await drive(['version', '--output', 'json']);

      result.exitCode.should.be(0);
      jsonOf(result)['version'].should.be('0.1.0');
    },
  );

  test(
    'Given the list verb with the store flag after it, when driven, then it counts the store',
    () async {
      final result = await drive([
        'list',
        '--store',
        store.path,
        '--output',
        'json',
      ]);

      result.exitCode.should.be(0);
      final answer = jsonOf(result);
      answer['count'].should.be(1);
      (answer['stories']! as List).length.should.be(1);
    },
  );

  test(
    'Given the show verb, when driven, then it serves the three entities separately',
    () async {
      final result = await drive([
        'show',
        'a-sample',
        '--store',
        store.path,
        '--output',
        'json',
      ]);

      result.exitCode.should.be(0);
      final answer = jsonOf(result);
      answer['slug'].should.be('a-sample');
      (answer['chars']! as List).length.should.be(2);
      (answer['beats']! as List).length.should.be(6);
      (answer['appearances']! as List).length.should.be(12);
    },
  );

  test(
    'Given the validate verb, when driven, then a clean story is clean',
    () async {
      final result = await drive([
        'validate',
        '--store',
        store.path,
        '--output',
        'json',
      ]);

      result.exitCode.should.be(0);
      final answer = jsonOf(result);
      answer['count'].should.be(1);
      answer['invalid'].should.be(0);
    },
  );

  test(
    'Given the timeline verb, when driven, then each beat carries its parties and its off-page list',
    () async {
      final result = await drive([
        'timeline',
        'a-sample',
        '--store',
        store.path,
        '--output',
        'json',
      ]);

      result.exitCode.should.be(0);
      final answer = jsonOf(result);
      final beats = answer['beats']! as List;
      beats.length.should.be(6);
      final first = beats.first as Map<String, Object?>;
      (first['parties']! as List).length.should.be(1);
      (first['off_page']! as List).should.beEmpty();
    },
  );

  test(
    'Given the roundtrip verb, when driven, then the store is a fixed point',
    () async {
      final result = await drive([
        'roundtrip',
        '--store',
        store.path,
        '--output',
        'json',
      ]);

      result.exitCode.should.be(0);
      final answer = jsonOf(result);
      answer['changed'].should.be(0);
    },
  );

  test(
    'Given an unknown slug, when shown, then it fails with a parseable code',
    () async {
      final result = await drive([
        'show',
        'nobody-here',
        '--store',
        store.path,
        '--output',
        'json',
      ]);

      result.exitCode.should.be(1);
      jsonOf(result)['error'].should.be('story-not-found');
    },
  );

  test(
    'Given a slug missing from show, when driven, then it is a usage error',
    () async {
      final result = await drive(['show', '--store', store.path]);

      result.exitCode.should.be(64);
    },
  );

  test(
    'Given no store flag at all, when driven, then it is a usage error',
    () async {
      final result = await drive(['list']);

      result.exitCode.should.be(64);
    },
  );

  test(
    'Given an unknown verb, when driven, then it is a usage error rather than a silent success',
    () async {
      final result = await drive(['frobnicate', '--store', store.path]);

      result.exitCode.should.be(64);
    },
  );

  test(
    'Given no arguments at all, when driven, then it is a usage error',
    () async {
      final result = await drive([]);

      result.exitCode.should.be(64);
    },
  );

  test(
    'Given the help flag, when driven, then it succeeds and prints usage',
    () async {
      final result = await drive(['--help']);

      result.exitCode.should.be(0);
      (result.stdout as String).should.contain('list');
    },
  );

  test(
    'Given the format verb without apply, when driven, then it reports and changes nothing',
    () async {
      final before = File('${store.path}/a-sample.yaml').readAsStringSync();

      final result = await drive([
        'format',
        '--store',
        store.path,
        '--output',
        'json',
      ]);

      result.exitCode.should.be(0);
      final answer = jsonOf(result);
      answer['applied'].should.be(false);
      final entry = (answer['stories']! as List).single;
      (entry as Map<String, Object?>)['key'].should.be('a-sample');
      entry['outcome'].should.be('would-write');
      File('${store.path}/a-sample.yaml').readAsStringSync().should.be(before);
    },
  );

  test(
    'Given the format verb with apply, when driven, then the file is rewritten in canonical form',
    () async {
      final result = await drive([
        'format',
        '--apply',
        '--store',
        store.path,
        '--output',
        'json',
      ]);

      result.exitCode.should.be(0);
      final text = File('${store.path}/a-sample.yaml').readAsStringSync();
      text.should.contain('slug: a-sample');
      text.should.contain("colour: '#1b57c4'");
    },
  );

  test(
    'Given a story, when charted, then the SVG lands where the caller asked',
    () async {
      final out = File('${store.path}/chart.svg');
      final result = await drive([
        'chart',
        'a-sample',
        '--store',
        store.path,
        '--out',
        out.path,
      ]);

      result.exitCode.should.be(0);
      final svg = out.readAsStringSync();
      svg.startsWith('<svg class="chart"').should.be(true);
      svg.endsWith('</svg>').should.be(true);

      final summary = jsonOf(result);
      summary['key'].should.be('a-sample');
      summary['shape'].should.be('braid');
      ((summary['height']! as int) > 0).should.be(true);
      ((summary['svg_bytes']! as int) > 1000).should.be(true);
      summary['lane_overlaps'].should.be(0);
    },
  );

  test(
    'Given the svg flag, when charted, then the bytes go to stdout',
    () async {
      final result = await drive([
        'chart',
        'a-sample',
        '--store',
        store.path,
        '--svg',
      ]);

      result.exitCode.should.be(0);
      (result.stdout as String)
          .startsWith('<svg class="chart"')
          .should
          .be(true);
    },
  );

  test('Given no key, when charted, then it is a usage error', () async {
    final result = await drive(['chart', '--store', store.path]);
    result.exitCode.should.be(64);
  });

  test(
    'Given a braid story, when the two-clock variant is asked for, then it is refused',
    () async {
      final result = await drive([
        'chart',
        'a-sample',
        '--store',
        store.path,
        '--variant',
        'two-clock',
      ]);
      result.exitCode.should.be(64);
    },
  );

  test(
    'Given the out-dir flag, when charted, then every story is drawn',
    () async {
      final dir = await Directory.systemTemp.createTemp('alluvial_charts_');
      final result = await drive([
        'chart',
        '--out-dir',
        dir.path,
        '--store',
        store.path,
      ]);

      result.exitCode.should.be(0);
      final summary = jsonOf(result);
      summary['count'].should.be(1);
      File('${dir.path}/a-sample.svg').existsSync().should.be(true);
      await dir.delete(recursive: true);
    },
  );

  test(
    'Given the text output flag, when driven, then a person gets prose',
    () async {
      final result = await drive([
        'timeline',
        'a-sample',
        '--store',
        store.path,
        '--output',
        'text',
      ]);

      result.exitCode.should.be(0);
      final out = result.stdout as String;
      out.should.contain('A Sample (a-sample)');
      out.should.contain('lanes: Lea, Sam');
    },
  );
}
