import 'dart:io';

import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_store_yaml/alluvial_store_yaml.dart';
import 'package:args/command_runner.dart';

import 'commands/chart_command.dart';
import 'commands/format_command.dart';
import 'commands/list_command.dart';
import 'commands/roundtrip_command.dart';
import 'commands/show_command.dart';
import 'commands/timeline_command.dart';
import 'commands/validate_command.dart';
import 'commands/version_command.dart';

/// The version this build reports.
const alluvialVersion = '0.1.0';

/// The alluvial command line.
///
/// Non-interactive by construction: nothing here reads stdin, every verb writes
/// its result to stdout as JSON unless asked for text, and failures are
/// reported as a parsed object with a stable `error` code plus a non-zero exit
/// code. The store is passed in so a test can drive the same surface over a
/// throwaway store.
final class AlluvialCli {
  /// Creates the CLI over [repository], defaulting to a folder of YAML files.
  AlluvialCli({StoryRepository Function(String directory)? repository})
    : _repository = repository ?? _folder;

  final StoryRepository Function(String directory) _repository;

  /// Runs [args] and returns the process exit code.
  ///
  /// `0` success, `1` the operation failed but the arguments were fine, `64`
  /// the arguments were not usable. A bare invocation or an unknown verb is a
  /// usage error rather than a silent success, so a caller that mistypes a
  /// command sees it.
  Future<int> run(List<String> args) async {
    final runner = _runner();
    try {
      final code = await runner.run(args);
      if (code != null) return code;
      return _unknownVerb(runner, args) ? 64 : 0;
    } on UsageException catch (error) {
      stderr.writeln(error.message);
      stderr.writeln(error.usage);
      return 64;
    }
  }

  CommandRunner<int> _runner() =>
      CommandRunner<int>(
          'alluvial',
          'Read a store of stories: the characters, the beats, and who stands '
              'with whom.',
        )
        ..addCommand(ListCommand(_repository))
        ..addCommand(ShowCommand(_repository))
        ..addCommand(ValidateCommand(_repository))
        ..addCommand(TimelineCommand(_repository))
        ..addCommand(RoundtripCommand(_repository))
        ..addCommand(FormatCommand(_repository))
        ..addCommand(ChartCommand(_repository))
        ..addCommand(VersionCommand(alluvialVersion));

  bool _unknownVerb(CommandRunner<int> runner, List<String> args) {
    if (args.isEmpty) return true;
    final verb = args.firstWhere(
      (arg) => !arg.startsWith('-'),
      orElse: () => '',
    );
    if (verb.isEmpty) return false;
    return !runner.commands.containsKey(verb);
  }

  static StoryRepository _folder(String directory) => FolderStoryRepository(
    datasource: YamlFolderDatasource(directory: directory),
  );
}
