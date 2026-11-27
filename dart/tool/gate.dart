// The workspace gate.
//
// The workspace root is not a package with a `test/` directory of its own, so
// `dart test` run at `dart/` exits 65 ("No test files were passed and the
// default test/ directory doesn't exist") — the gate only ever existed per
// package. This is the one command that covers all of them, in the order the
// doctrine asks for: analyze clean (fatal infos, fatal warnings), then every
// package's suite green.
//
//   cd dart && dart run tool/gate.dart
//
// Exits 0 only when analysis is clean AND every package's suite passes.
//
// It is a plain `dart:io` script on purpose: it needs no dependency of its own,
// so it changes neither the root pubspec nor the lock file, and it runs the same
// on the Windows lane as here.
import 'dart:io';

/// Runs the workspace gate and exits non-zero on the first failure.
Future<void> main(List<String> arguments) async {
  final dart = Platform.resolvedExecutable;

  stdout.writeln('== analyze (--fatal-infos --fatal-warnings)');
  final analyze = Process.runSync(dart, [
    'analyze',
    '--fatal-infos',
    '--fatal-warnings',
  ], workingDirectory: Directory.current.path);
  stdout.write(analyze.stdout);
  stderr.write(analyze.stderr);
  if (analyze.exitCode != 0) {
    stderr.writeln('gate: analyze failed (exit ${analyze.exitCode})');
    exit(1);
  }

  // A package counts when it has a test/ directory; `alluvial_testing` is a
  // shared-fixture package with none, so it is skipped rather than failed.
  final packages =
      Directory('packages')
          .listSync()
          .whereType<Directory>()
          .where((d) => Directory('${d.path}/test').existsSync())
          .map((d) => d.path)
          .toList()
        ..sort();

  final failed = <String>[];
  for (final package in packages) {
    stdout.writeln('== $package');
    final suite = Process.runSync(dart, [
      'test',
      '--reporter',
      'failures-only',
    ], workingDirectory: package);
    stdout.write(suite.stdout);
    stderr.write(suite.stderr);
    if (suite.exitCode != 0) {
      failed.add('$package (exit ${suite.exitCode})');
    }
  }

  if (failed.isNotEmpty) {
    stderr.writeln('gate: FAILED — ${failed.join(', ')}');
    exit(1);
  }
  stdout.writeln(
    'gate: clean — analysis and ${packages.length} package suite(s) passed',
  );
}
