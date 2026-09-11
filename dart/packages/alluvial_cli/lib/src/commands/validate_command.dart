import 'dart:convert';
import 'dart:io';

import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_usecases/alluvial_usecases.dart';

import '../output_format.dart';
import '../store_command.dart';
import '../views.dart';

/// `alluvial validate [slug...]` — check stories against the store's limits.
final class ValidateCommand extends StoreCommand {
  /// Creates the verb over a store factory.
  ValidateCommand(super.repository);

  @override
  String get name => 'validate';

  @override
  String get description =>
      'Check stories against the schema and the authored limits.';

  @override
  Future<int> execute() async {
    final result = await ValidateStories(
      open(),
      const StoryValidator(),
    ).call(keys: argResults!.rest);
    return result.match(
      (failure) {
        stdout.writeln(jsonEncode(failureJson(failure)));
        return 1;
      },
      (reports) {
        final failed = reports
            .where(
              (report) => report.findings.any((finding) => !finding.isWarning),
            )
            .length;
        if (format == OutputFormat.json) {
          stdout.writeln(
            jsonEncode({
              'store': directory,
              'count': reports.length,
              'invalid': failed,
              'stories': [for (final report in reports) reportJson(report)],
            }),
          );
        } else {
          stdout.writeln(validationText(reports));
        }
        return failed == 0 ? 0 : 1;
      },
    );
  }
}
