import 'dart:convert';
import 'dart:io';

import 'package:alluvial_domain/alluvial_domain.dart';
import 'package:alluvial_usecases/alluvial_usecases.dart';

import '../output_format.dart';
import '../store_command.dart';
import '../views.dart';

/// `alluvial roundtrip [slug...]` — prove the store is a fixed point.
final class RoundtripCommand extends StoreCommand {
  /// Creates the verb over a store factory.
  RoundtripCommand(super.repository);

  @override
  String get name => 'roundtrip';

  @override
  String get description =>
      'Read every story, write it back out, read that again, and report what '
      'changed.';

  @override
  Future<int> execute() async {
    final result = await RoundtripStories(
      open(),
      const StoryDocumentCodec(),
    ).call(keys: argResults!.rest);
    return result.match(
      (failure) {
        stdout.writeln(jsonEncode(failureJson(failure)));
        return 1;
      },
      (reports) {
        final changed = reports.where((report) => !report.stable).length;
        if (format == OutputFormat.json) {
          stdout.writeln(
            jsonEncode({
              'store': directory,
              'count': reports.length,
              'changed': changed,
              'stories': [for (final report in reports) roundtripJson(report)],
            }),
          );
        } else {
          stdout.writeln(roundtripText(reports));
        }
        return changed == 0 ? 0 : 1;
      },
    );
  }
}
