// Architecture & boundary rules for the alluvial workspace, via dart_arch_test.
// Doctrine: docs/02-toolchain.md "Package-boundary rules: dart_arch_test, not
// melos" (§2.9), §9 step 7, §10.1.
//
// Two rules, both encoded as plain `package:` URI assertions rather than the
// glob DSL — the glob matcher strips the `package:<name>/` prefix, so it is
// blind across workspace members and a real violation would pass (§2 pitfall).
//
//   1. Dependencies point inward. Each package reaches only the packages the
//      four laws allow it, so domain can never acquire a usecase, a store or
//      the CLI.
//   2. The barrel is the only door. `lib/src/` is private: nothing outside a
//      package may import it, and no cycles anywhere in the workspace.
//
// This is a rule test, not a behavior test: GWT naming and the shouldly idiom
// apply to behavior suites (docs/06-testing.md), not to architecture asserts.
library;

import 'dart:io';

import 'package:dart_arch_test/dart_arch_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The dependencies a library under [packagePrefix] may carry, as URI prefixes.
///
/// `package:<self>/` is always allowed (a package may import itself); the dart:
/// SDK is skipped by the checker. Only libraries under `lib/` are inspected —
/// the graph keys test, tool and bin files by `file:` URI, so filtering on the
/// `package:` prefix already excludes them, which is exactly right: test code
/// legitimately uses dev_dependencies a library may not.
void checkBoundary(
  DependencyGraph graph,
  String packagePrefix,
  Set<String> allowed,
) {
  final violations = <String>[];
  for (final caller in Collector.allLibraries(graph)) {
    if (!caller.startsWith(packagePrefix)) continue;
    for (final dep in Collector.dependenciesOf(graph, caller)) {
      if (dep.startsWith('dart:')) continue;
      if (!allowed.any(dep.startsWith)) violations.add('$caller -> $dep');
    }
  }
  if (violations.isNotEmpty) {
    fail('BOUNDARY VIOLATIONS:\n${violations.join('\n')}');
  }
}

/// Fails if any library outside a package imports that package's `lib/src/`.
///
/// The barrel (`lib/<pkg>.dart`) is the single public door; reaching into
/// another package's `src/` bypasses it, which is how a private contract leaks.
void checkSrcIsPrivate(DependencyGraph graph, Iterable<String> packages) {
  final violations = <String>[];
  for (final packagePrefix in packages) {
    final privatePrefix = '${packagePrefix}src/';
    for (final caller in Collector.allLibraries(graph)) {
      if (!caller.startsWith('package:')) continue;
      final callerIsInside = caller.startsWith(privatePrefix);
      for (final dep in Collector.dependenciesOf(graph, caller)) {
        if (!dep.startsWith(privatePrefix)) continue;
        if (!callerIsInside) violations.add('$caller -> $dep');
      }
    }
  }
  if (violations.isNotEmpty) {
    fail('PRIVATE-IMPORT VIOLATIONS:\n${violations.join('\n')}');
  }
}

/// The workspace root: the nearest ancestor of CWD whose `pubspec.yaml`
/// declares `workspace:`. Never derive it from `Platform.script` — under some
/// runners that points at the kernel snapshot in a scratch dir, the graph comes
/// back empty, and every rule passes vacuously (§2 pitfall).
String workspaceRoot() {
  var dir = Directory.current;
  while (true) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync() &&
        RegExp(
          r'^workspace:',
          multiLine: true,
        ).hasMatch(pubspec.readAsStringSync())) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return dir.path;
    dir = parent;
  }
}

/// Every first-party package prefix, in one place so the private-import rule
/// cannot miss one.
const List<String> packages = <String>[
  'package:alluvial_domain/',
  'package:alluvial_usecases/',
  'package:alluvial_store_yaml/',
  'package:alluvial_store_memory/',
  'package:alluvial_testing/',
  'package:alluvial_render/',
  'package:alluvial_cli/',
];

void main() {
  late DependencyGraph graph;

  setUpAll(() async {
    graph = await Collector.buildGraph(workspaceRoot());
  });

  test('the graph is not empty (a vacuous graph proves nothing)', () {
    final libraries = Collector.allLibraries(
      graph,
    ).where((uri) => uri.startsWith('package:alluvial_')).toSet();
    if (libraries.length < 50) {
      fail('only ${libraries.length} first-party libraries in the graph');
    }
  });

  test('domain reaches only itself + fpdart + equatable', () {
    checkBoundary(graph, 'package:alluvial_domain/', {
      'package:alluvial_domain/',
      'package:fpdart/',
      'package:equatable/',
    });
  });

  test('usecases reach only domain + fpdart + equatable', () {
    checkBoundary(graph, 'package:alluvial_usecases/', {
      'package:alluvial_usecases/',
      'package:alluvial_domain/',
      'package:fpdart/',
      'package:equatable/',
    });
  });

  test('the folder store reaches only domain + yaml + path', () {
    checkBoundary(graph, 'package:alluvial_store_yaml/', {
      'package:alluvial_store_yaml/',
      'package:alluvial_domain/',
      'package:fpdart/',
      'package:yaml/',
      'package:path/',
    });
  });

  test('the memory store reaches only domain', () {
    checkBoundary(graph, 'package:alluvial_store_memory/', {
      'package:alluvial_store_memory/',
      'package:alluvial_domain/',
      'package:fpdart/',
    });
  });

  test('the renderers reach only domain (no store, no usecases)', () {
    checkBoundary(graph, 'package:alluvial_render/', {
      'package:alluvial_render/',
      'package:alluvial_domain/',
      'package:equatable/',
    });
  });

  test('the CLI is the ring: it may reach every layer below it', () {
    checkBoundary(graph, 'package:alluvial_cli/', {
      'package:alluvial_cli/',
      'package:alluvial_domain/',
      'package:alluvial_usecases/',
      'package:alluvial_store_yaml/',
      'package:alluvial_render/',
      'package:args/',
      'package:fpdart/',
    });
  });

  test('the contract suite reaches only domain', () {
    checkBoundary(graph, 'package:alluvial_testing/', {
      'package:alluvial_testing/',
      'package:alluvial_domain/',
      'package:fpdart/',
      'package:test/',
      'package:shouldly/',
    });
  });

  test('lib/src/ is private: the barrel is the only door', () {
    checkSrcIsPrivate(graph, packages);
  });

  test('no import cycles anywhere in the workspace', () {
    shouldBeFreeOfCycles(allFiles(), graph);
  });
}
