import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../output_format.dart';

/// `alluvial version` — what is running, in a form a caller can parse.
final class VersionCommand extends Command<int> {
  /// Creates the verb reporting [version].
  VersionCommand(this.version) {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output format.',
      allowed: ['json', 'text'],
      defaultsTo: 'json',
    );
  }

  /// The version this build reports.
  final String version;

  @override
  String get name => 'version';

  @override
  String get description => 'Print the CLI version.';

  @override
  Future<int> run() async {
    final format = OutputFormat.parse(argResults!['output'] as String?);
    stdout.writeln(
      format == OutputFormat.json
          ? jsonEncode({'name': 'alluvial', 'version': version})
          : 'alluvial $version',
    );
    return 0;
  }
}
