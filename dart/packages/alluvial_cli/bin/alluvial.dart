import 'dart:io';

import 'package:alluvial_cli/alluvial_cli.dart';

/// Entry point: run the CLI and hand its code to the process.
Future<void> main(List<String> args) async {
  exitCode = await AlluvialCli().run(args);
}
