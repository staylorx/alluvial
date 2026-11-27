// Where the gates look for the Python-generated reference corpus and the store
// under test — the one place both suites read it from.
//
// Doctrine (§6 pitfalls): never hardcode absolute paths in tests — no `/tmp/foo`
// literals, which are also not the same place on every platform. The defaults
// are built from `Directory.systemTemp` and the `path` package, and both are
// overridable by environment variable so a corpus can live anywhere.
//
// `dart/tool/render_reference.py` and `number_corpus.py` write to the same
// default, so `python3 dart/tool/render_reference.py` with no argument lands
// exactly where these tests look.
import 'dart:io';

import 'package:path/path.dart' as p;

/// The directory the Python pipeline wrote the reference corpus into.
final String referenceDirectory =
    Platform.environment['ALLUVIAL_REFERENCE'] ??
    p.join(Directory.systemTemp.path, 'alluvial-reference');

/// The store the gates are driven over: the repo's `stories/`, which sits three
/// levels up from this package (`dart/packages/alluvial_render`).
final String storeDirectory =
    Platform.environment['ALLUVIAL_STORE'] ??
    p.normalize(p.join(Directory.current.path, '..', '..', '..', 'stories'));

/// The CPython number corpus, inside [referenceDirectory].
final String numberCorpusPath =
    Platform.environment['ALLUVIAL_NUMBERS'] ??
    p.join(referenceDirectory, 'numbers.tsv');
