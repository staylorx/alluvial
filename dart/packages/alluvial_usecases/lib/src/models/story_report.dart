import 'package:alluvial_domain/alluvial_domain.dart';

/// What a validation run found in one story.
///
/// [key] is the store key the story was loaded by — the handle to pass back.
/// `title` is null when the story could not be decoded at all, in which case
/// the single finding carries the reason.
typedef StoryReport = ({
  String key,
  String? title,
  List<ValidationFinding> findings,
});
