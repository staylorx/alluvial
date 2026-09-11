import 'dart:convert';
import 'dart:io';

import 'package:alluvial_usecases/alluvial_usecases.dart';

import '../output_format.dart';
import '../store_command.dart';
import '../views.dart';

/// `alluvial list` — every story in the store, summarised.
final class ListCommand extends StoreCommand {
  /// Creates the verb over a store factory.
  ListCommand(super.repository);

  @override
  String get name => 'list';

  @override
  String get description => 'List every story in the store.';

  @override
  Future<int> execute() async {
    final result = await ListStories(open()).call();
    return result.match(
      (failure) {
        stdout.writeln(jsonEncode(failureJson(failure)));
        return 1;
      },
      (stories) {
        if (format == OutputFormat.json) {
          stdout.writeln(
            jsonEncode({
              'store': directory,
              'count': stories.length,
              'stories': [for (final story in stories) summaryJson(story)],
            }),
          );
        } else {
          for (final story in stories) {
            stdout.writeln(summaryLine(story));
          }
          stdout.writeln('${stories.length} stories');
        }
        return 0;
      },
    );
  }
}
