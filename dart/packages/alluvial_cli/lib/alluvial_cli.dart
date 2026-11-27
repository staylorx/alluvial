/// The alluvial CLI: a binary that reads a folder of stories.
///
/// **This package presents plain values**: `AlluvialCli.run` answers an exit
/// code — `0` fine, `1` the operation failed, `64` the arguments were unusable.
/// As the composition root it *is* the ring, and the one place an arguments
/// exception is caught (§4.8).
library;

export 'src/cli.dart';
export 'src/output_format.dart';
export 'src/store_command.dart';
export 'src/views.dart';
