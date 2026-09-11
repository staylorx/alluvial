import 'dart:convert';
import 'dart:io';

import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'yaml_writer.dart';

/// A folder of story files as the datasource behind the store.
///
/// One file per story, `<slug>.yaml`; a `<slug>.json` beside it is read as a
/// fallback so a store mid-conversion still loads. Writes always land as YAML
/// and keep the file's existing leading comment block, which is where the
/// authoring rules live.
final class YamlFolderDatasource implements StoryDatasource {
  /// Creates a datasource over [directory].
  const YamlFolderDatasource({required this.directory});

  /// The folder that holds one file per story.
  final String directory;

  @override
  TaskEither<DatasourceFailure, List<String>> slugs() =>
      _list(Directory(directory)).map(_keys);

  @override
  TaskEither<DatasourceFailure, Map<String, Object?>> read(String slug) {
    final yamlFile = File(p.join(directory, '$slug.yaml'));
    if (yamlFile.existsSync()) {
      return _readText(
        yamlFile,
      ).flatMap((text) => _parseYaml(text, yamlFile.path));
    }
    final jsonFile = File(p.join(directory, '$slug.json'));
    if (jsonFile.existsSync()) {
      return _readText(
        jsonFile,
      ).flatMap((text) => _parseJson(text, jsonFile.path));
    }
    return _left(DocumentMissing(yamlFile.path));
  }

  @override
  TaskEither<DatasourceFailure, Unit> write(
    String slug,
    Map<String, Object?> document,
  ) {
    final target = File(p.join(directory, '$slug.yaml'));
    final header = target.existsSync()
        ? leadingCommentBlock(_textOrNull(target))
        : const <String>[];
    final text = writeYamlDocument(document, header: header);
    final temp = File('${target.path}.writing');
    return _ensureDirectory(directory)
        .flatMap((_) => _writeFile(temp, text))
        .flatMap((_) => _replace(temp, target.path));
  }

  TaskEither<DatasourceFailure, Unit> _ensureDirectory(String path) =>
      TaskEither<DatasourceFailure, Unit>.tryCatch(() async {
        await Directory(path).create(recursive: true);
        return unit;
      }, (error, stack) => DocumentUnwritable(path, '$error'));

  TaskEither<DatasourceFailure, Unit> _writeFile(File file, String text) =>
      TaskEither<DatasourceFailure, Unit>.tryCatch(() async {
        await file.writeAsString(text, flush: true);
        return unit;
      }, (error, stack) => DocumentUnwritable(file.path, '$error'));

  TaskEither<DatasourceFailure, Unit> _replace(File temp, String target) =>
      TaskEither<DatasourceFailure, Unit>.tryCatch(() async {
        await temp.rename(target);
        return unit;
      }, (error, stack) => DocumentUnwritable(target, '$error'));

  TaskEither<DatasourceFailure, List<FileSystemEntity>> _list(Directory dir) {
    if (!dir.existsSync()) {
      return _right(const <FileSystemEntity>[]);
    }
    return TaskEither<DatasourceFailure, List<FileSystemEntity>>.tryCatch(
      () async => dir.listSync(),
      (error, stack) => DocumentUnreadable(dir.path, '$error'),
    );
  }

  TaskEither<DatasourceFailure, String> _readText(File file) =>
      TaskEither<DatasourceFailure, String>.tryCatch(
        () => file.readAsString(),
        (error, stack) => DocumentUnreadable(file.path, '$error'),
      );

  TaskEither<DatasourceFailure, Map<String, Object?>> _parseYaml(
    String text,
    String path,
  ) => TaskEither<DatasourceFailure, Object?>.tryCatch(
    () async => loadYaml(text),
    (error, stack) => DocumentMalformed(path, _reason(error)),
  ).flatMap((document) => _asDocument(document, path));

  TaskEither<DatasourceFailure, Map<String, Object?>> _parseJson(
    String text,
    String path,
  ) => TaskEither<DatasourceFailure, Object?>.tryCatch(
    () async => jsonDecode(text),
    (error, stack) => DocumentMalformed(path, _reason(error)),
  ).flatMap((document) => _asDocument(document, path));

  TaskEither<DatasourceFailure, Map<String, Object?>> _asDocument(
    Object? document,
    String path,
  ) {
    if (document is! Map) {
      return _left(DocumentMalformed(path, 'the document is not a mapping'));
    }
    return _right(<String, Object?>{
      for (final entry in document.entries) '${entry.key}': entry.value,
    });
  }

  String _textOrNull(File file) => Either<String, String>.tryCatch(
    () => file.readAsStringSync(),
    (error, stack) => '$error',
  ).getOrElse((_) => '');

  List<String> _keys(List<FileSystemEntity> entities) {
    final keys = <String>{};
    for (final entity in entities) {
      if (entity is! File) continue;
      final extension = p.extension(entity.path);
      if (extension != '.yaml' && extension != '.json') continue;
      keys.add(p.basenameWithoutExtension(entity.path));
    }
    return keys.toList()..sort();
  }
}

/// Strips a decoder's type prefix so the reported reason reads as a sentence.
String _reason(Object error) {
  final text = '$error';
  final marker = text.indexOf(': ');
  return marker == -1 ? text : text.substring(marker + 2);
}

/// A `TaskEither` that is already a failure, with both types spelled out.
TaskEither<L, R> _left<L, R>(L value) =>
    TaskEither<L, R>(() async => Either<L, R>.left(value));

/// A `TaskEither` that is already a success, with both types spelled out.
TaskEither<L, R> _right<L, R>(R value) =>
    TaskEither<L, R>(() async => Either<L, R>.right(value));
