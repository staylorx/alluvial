import 'dart:convert';
import 'dart:io';

import 'package:alluvial_usecases/alluvial_usecases.dart';

import '../output_format.dart';
import '../store_command.dart';
import '../views.dart';

/// `alluvial show <slug>` — one whole story as the model sees it.
final class ShowCommand extends StoreCommand {
  /// Creates the verb over a store factory.
  ShowCommand(super.repository);

  @override
  String get name => 'show';

  @override
  String get description => 'Show one story: strands, beats and appearances.';

  @override
  Future<int> execute() async {
    final slug = argResults!.rest.isEmpty ? null : argResults!.rest.first;
    if (slug == null) {
      stderr.writeln(
        'show needs a story slug: alluvial show <slug> --store <dir>',
      );
      return 64;
    }
    final result = await LoadStory(open()).call(slug: slug);
    return result.match(
      (failure) {
        stdout.writeln(jsonEncode(failureJson(failure)));
        return 1;
      },
      (story) {
        stdout.writeln(
          format == OutputFormat.json
              ? jsonEncode(storyJson(story))
              : storyText(story),
        );
        return 0;
      },
    );
  }
}
