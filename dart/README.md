# alluvial (Dart)

The story store and its CLI, as a Dart pub workspace. One file per story in a
folder is the repository; the CLI reads it, checks it, and writes it back.

**Read `BACKLOG.md` first** — it holds what is built, what is proven, what is
deliberately absent, and the open questions.

## Layout

| Path | What |
|---|---|
| `packages/alluvial_domain/` | The three entities (characters, beats, appearances), the failures, the contracts, the codec, the validator, the shared repository orchestration. |
| `packages/alluvial_usecases/` | The application layer: list, load, save, validate, timeline, round-trip. |
| `packages/alluvial_store_yaml/` | The folder-of-YAML store: the datasource, the writer, and the emission tool. |
| `packages/alluvial_store_memory/` | The in-memory store, for tests and dry runs. |
| `packages/alluvial_testing/` | The repository contract suite every store adapter must pass. |
| `packages/alluvial_render/` | The SVG engines: the braid chart, the two-clock chart, and the builder that lays a story out. |
| `packages/alluvial_cli/` | The command line and the `alluvial` binary. |

## Running

```bash
dart pub get                                  # from this directory (the workspace root)
dart test                                     # per package: cd packages/<name> && dart test
dart analyze --fatal-infos --fatal-warnings   # must report nothing at all
dart format .

# against a store
cd packages/alluvial_cli
dart run bin/alluvial.dart list --store ../../films
dart run bin/alluvial.dart timeline when-harry-met-sally --store ../../films --output text
dart run bin/alluvial.dart chart when-harry-met-sally --store ../../films --out /tmp/whms.svg
dart run bin/alluvial.dart chart --out-dir /tmp/charts --store ../../films

# the artifact an agent drives (tens of ms a call, not a compile each time)
cd ../.. && dart build cli -t packages/alluvial_cli/bin/alluvial.dart -o build/cli
```

## Measure the writer

```bash
cd packages/alluvial_store_yaml
dart run tool/emission_report.dart <store-dir>        # byte-identity + content stability
dart run tool/emission_report.dart <store-dir> <key>  # one story's emitted text, to diff
```

## Prove the renderer

Both renderers are byte-identical to the Python engine that produced every
approved chart, and the gate is a corpus rather than a fixture:

```bash
python3 /tmp/gen_ref.py                                   # Python renders the reference set
cd packages/alluvial_render
dart run tool/parity_report.dart <store-dir> /tmp/ref     # every chart, every treatment
dart test                                                 # the same gate as a test
```

The reference corpus holds each braid film three ways (default, colour-blind,
mini — that is what the pages embed) plus every two-clock chart, and the spec
JSON beside each one so a mismatch is traceable to the builder (layout) or the
engine (markup).

The doctrine (clean architecture, fpdart, testing) lives in
`~/hermes/projects/dart-flutter-bible` — this package follows it and does not
restate it.
