import 'dart:io';

import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:args/command_runner.dart';

import 'output_format.dart';

/// Base for every verb that works on a store.
///
/// `--store` and `--output` are declared on the verb rather than only on the
/// runner, so `alluvial list --store stories` and `alluvial --store stories list`
/// both work — an agent that puts the flag after the verb is not punished for
/// it.
///
/// The store flag is *not* declared `mandatory`: in this version of the args
/// package a missing mandatory option does not fail the parse, it throws when
/// the value is read — which turns "the caller forgot a flag" into an unhandled
/// exception and exit code 255. The check lives in [run], where a missing flag
/// becomes a usage error the caller can act on.
abstract class StoreCommand extends Command<int> {
  /// Creates the verb over [repository].
  StoreCommand(this.repository) {
    argParser
      ..addOption(
        'store',
        abbr: 's',
        help: 'Directory holding one file per story.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output format.',
        allowed: ['json', 'text'],
        defaultsTo: 'json',
      );
  }

  /// Builds a repository over a store directory.
  final StoryRepository Function(String directory) repository;

  String? _directory;
  OutputFormat _format = OutputFormat.json;

  /// The store this run is working on, once [run] has checked it is there.
  String get directory => _directory!;

  /// How this run renders its result.
  OutputFormat get format => _format;

  /// The repository for this run.
  StoryRepository open() => repository(directory);

  @override
  Future<int> run() async {
    final store = argResults!['store'];
    if (store is! String || store.isEmpty) {
      stderr.writeln(
        '$name needs --store <dir>, the folder that holds the stories.',
      );
      return 64;
    }
    _directory = store;
    _format = OutputFormat.parse(argResults!['output'] as String?);
    return execute();
  }

  /// Does the verb's work, with the store present and the format resolved.
  Future<int> execute();
}
