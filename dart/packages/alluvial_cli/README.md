# alluvial_cli

The `alluvial` command line and the binary an agent drives: `list`, `show`,
`validate`, `timeline`, `roundtrip`, `format`, `chart`, `version`. JSON on
stdout by default.

**Error style.** This package presents **plain values**: `AlluvialCli.run`
answers an exit code — `0` fine, `1` the operation failed, `64` the arguments
were unusable. As the composition root it *is* the ring, and the one place an
arguments exception is caught (§4.8, §4.9).
Doctrine: `~/hermes/projects/dart-flutter-bible` — this package follows it and
does not restate it. This repo's deviations and local wiring: [`AGENTS.md`](../../AGENTS.md).
What is built, proven and open: [`backlog/`](../../backlog/).
