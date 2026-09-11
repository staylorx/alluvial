/// How a verb renders its result.
///
/// JSON is the default because the primary caller is an agent: prose on stdout
/// means every caller has to scrape. A person asks for `--output text`.
enum OutputFormat {
  /// Machine-readable JSON, one object per run.
  json,

  /// Prose meant for a person at a terminal.
  text;

  /// Reads the flag value, defaulting to JSON for anything unrecognised.
  static OutputFormat parse(String? value) =>
      value == 'text' ? OutputFormat.text : OutputFormat.json;
}
