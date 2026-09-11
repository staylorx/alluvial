import 'dart:convert';
import 'dart:io';

import 'package:alluvial_usecases/alluvial_usecases.dart';

import '../output_format.dart';
import '../store_command.dart';
import '../views.dart';

/// `alluvial timeline <slug>` — who is in each beat, in sequence, beside whom.
final class TimelineCommand extends StoreCommand {
  /// Creates the verb over a store factory.
  TimelineCommand(super.repository);

  @override
  String get name => 'timeline';

  @override
  String get description =>
      'Lay one story out beat by beat: sequence, parties, and who is off page.';

  @override
  Future<int> execute() async {
    final slug = argResults!.rest.isEmpty ? null : argResults!.rest.first;
    if (slug == null) {
      stderr.writeln(
        'timeline needs a story slug: alluvial timeline <slug> --store <dir>',
      );
      return 64;
    }
    final result = await StoryTimeline(open()).call(slug: slug);
    return result.match(
      (failure) {
        stdout.writeln(jsonEncode(failureJson(failure)));
        return 1;
      },
      (timeline) {
        stdout.writeln(
          format == OutputFormat.json
              ? jsonEncode(timelineJson(timeline))
              : timelineText(timeline),
        );
        return 0;
      },
    );
  }
}
