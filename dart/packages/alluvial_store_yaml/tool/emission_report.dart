// Measures how faithful the Dart writer is to the store it reads.
//
// For every file in the store this reports two things: whether the emitted
// text is byte-identical to what is on disk, and whether the content survives
// the pass (decode → encode → decode lands on the same story). Byte-identity
// is the stronger claim and the one a writer has to earn file by file; content
// stability is the one that must never fail.
//
// Usage: dart run tool/emission_report.dart <store-directory>
import 'dart:convert';
import 'dart:io';

import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_store_yaml/alluvial_store_yaml.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final store = args.isEmpty ? 'films' : args.first;
  final codec = const StoryDocumentCodec();
  final datasource = YamlFolderDatasource(directory: store);
  final keys = (await datasource.slugs().run()).getRight().toNullable()!;

  // `dart run tool/emission_report.dart <store> <key>` prints one story's
  // emitted text instead of the report, for diffing against the file on disk.
  if (args.length > 1) {
    final key = args[1];
    final file = File(p.join(store, '$key.yaml'));
    final document = (await datasource.read(key).run())
        .getRight()
        .toNullable()!;
    final story = codec.decode(document).getRight().toNullable()!;
    stdout.write(
      writeYamlDocument(
        codec.encode(story),
        header: leadingCommentBlock(file.readAsStringSync()),
      ),
    );
    return;
  }

  var identical = 0;
  var stable = 0;
  final byteDiffers = <String>[];
  final contentDiffers = <String>[];

  for (final key in keys) {
    final file = File(p.join(store, '$key.yaml'));
    if (!file.existsSync()) {
      contentDiffers.add('$key: no YAML file on disk');
      continue;
    }
    final document = (await datasource.read(key).run())
        .getRight()
        .toNullable()!;
    final first = codec.decode(document).getRight().toNullable()!;
    final emitted = writeYamlDocument(
      codec.encode(first),
      header: leadingCommentBlock(file.readAsStringSync()),
    );
    final again = codec.decode(codec.encode(first)).getRight().toNullable()!;

    if (again == first) {
      stable++;
    } else {
      contentDiffers.add(key);
    }
    if (emitted == file.readAsStringSync()) {
      identical++;
    } else {
      byteDiffers.add(key);
    }
  }

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'store': store,
      'files': keys.length,
      'byte_identical': identical,
      'content_stable': stable,
      'byte_differs': byteDiffers,
      'content_differs': contentDiffers,
    }),
  );
  exitCode = contentDiffers.isEmpty ? 0 : 1;
}
