import 'dart:convert';
import 'dart:io';

import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_usecases/alluvial_usecases.dart';

import '../output_format.dart';
import '../store_command.dart';
import '../views.dart';

/// `alluvial format [key...] [--apply]` — write stories back in canonical form.
///
/// Without `--apply` it reports what a write would do and touches nothing; with
/// it, each story that passes the validator is rewritten. The write goes
/// through the repository, so a story with errors is refused rather than
/// written — that guard is the whole reason this verb is safe to point at a
/// store someone else authored.
final class FormatCommand extends StoreCommand {
  /// Creates the verb over a store factory.
  FormatCommand(super.repository) {
    argParser.addFlag(
      'apply',
      help: 'Write the canonical form. Without it, report only.',
      negatable: false,
    );
  }

  @override
  String get name => 'format';

  @override
  String get description =>
      'Rewrite stories in the canonical form the writer produces.';

  @override
  Future<int> execute() async {
    final apply = argResults!['apply'] as bool;
    final keys = argResults!.rest;
    final repository = open();
    final listed = await ListStories(repository).call();
    if (listed.isLeft()) {
      stdout.writeln(jsonEncode(failureJson(listed.getLeft().toNullable()!)));
      return 1;
    }
    final wanted = keys.isEmpty
        ? listed.getRight().toNullable()!.map((summary) => summary.key).toList()
        : keys;

    final results = <Map<String, Object?>>[];
    var refused = 0;
    for (final key in wanted) {
      final loaded = await LoadStory(repository).call(slug: key);
      final failure = loaded.getLeft().toNullable();
      if (failure != null) {
        refused++;
        results.add({
          'key': key,
          'outcome': 'unreadable',
          'detail': failure.describe,
        });
        continue;
      }
      if (!apply) {
        final findings = const StoryValidator().validate(
          loaded.getRight().toNullable()!,
        );
        final errors = findings.where((finding) => !finding.isWarning).toList();
        if (errors.isEmpty) {
          results.add({'key': key, 'outcome': 'would-write'});
        } else {
          refused++;
          results.add({
            'key': key,
            'outcome': 'would-refuse',
            'detail': errors.first.describe,
          });
        }
        continue;
      }
      final saved = await SaveStory(
        repository,
      ).call(story: loaded.getRight().toNullable()!, key: key);
      final writeFailure = saved.getLeft().toNullable();
      if (writeFailure == null) {
        results.add({'key': key, 'outcome': 'written'});
      } else {
        refused++;
        results.add({
          'key': key,
          'outcome': 'refused',
          'detail': writeFailure.describe,
        });
      }
    }

    if (format == OutputFormat.json) {
      stdout.writeln(
        jsonEncode({
          'store': directory,
          'applied': apply,
          'count': results.length,
          'refused': refused,
          'stories': results,
        }),
      );
    } else {
      for (final result in results) {
        stdout.writeln(
          '${result['outcome']}  ${result['key']}'
          '${result['detail'] == null ? '' : ' — ${result['detail']}'}',
        );
      }
      stdout.writeln(
        '${results.length} stories, $refused refused'
        '${apply ? '' : ' (dry run — pass --apply to write)'}',
      );
    }
    return refused == 0 ? 0 : 1;
  }
}
