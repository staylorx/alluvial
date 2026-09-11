/// Renders a story document as block YAML in the layout the store uses.
///
/// The layout is deliberate and matches the authored files: a sequence sits at
/// its parent key's indent rather than under it, a mapping inside a sequence
/// starts on the dash line, and a nested sequence starts on the dash line too.
/// Only the scalar forms need thought — a colour like `#1b57c4` has to be
/// quoted or the `#` opens a comment, which is exactly the bug this writer
/// exists to avoid.
///
/// [header] is written verbatim, one raw comment line per entry, so an
/// authored block keeps its own alignment instead of being reflowed.
String writeYamlDocument(Object? document, {List<String> header = const []}) {
  final buffer = StringBuffer();
  for (final line in header) {
    buffer.writeln(line.trimRight());
  }
  for (final line in _lines(document, 0)) {
    buffer.writeln(line);
  }
  return buffer.toString();
}

/// The leading comment block of [text], verbatim, so a rewrite keeps it.
List<String> leadingCommentBlock(String text) {
  final header = <String>[];
  for (final line in text.split('\n')) {
    if (!line.startsWith('#')) break;
    header.add(line);
  }
  return header;
}

List<String> _lines(Object? value, int indent) {
  final pad = ' ' * indent;
  if (value is Map) {
    if (value.isEmpty) return ['$pad{}'];
    final out = <String>[];
    for (final entry in value.entries) {
      final key = _key(entry.key);
      final child = entry.value;
      if (_isInline(child)) {
        out.addAll(_wrapped('$pad$key: ', _inline(child), '$pad  '));
      } else if (child is Map) {
        out.add('$pad$key:');
        out.addAll(_lines(child, indent + 2));
      } else {
        out.add('$pad$key:');
        out.addAll(_lines(child, indent));
      }
    }
    return out;
  }
  if (value is List) {
    if (value.isEmpty) return ['$pad[]'];
    final out = <String>[];
    for (final item in value) {
      if (_isInline(item)) {
        out.addAll(_wrapped('$pad- ', _inline(item), '$pad  '));
        continue;
      }
      final inner = _lines(item, indent + 2);
      out.add('$pad- ${inner.first.substring(indent + 2)}');
      out.addAll(inner.skip(1));
    }
    return out;
  }
  return ['$pad${_inline(value)}'];
}

/// The column past which the store's writer folds a long scalar onto the next
/// line. It folds at the first *single* space beyond it, and only in block
/// context, which is why a long line with no space that far out stays long.
const _foldColumn = 110;

/// Folds a rendered scalar across lines, [continuation] prefixing each
/// continuation line. The fold is a line break in YAML, so it reads back as the
/// same space and no content moves.
List<String> _wrapped(String prefix, String rendered, String continuation) {
  final lines = <String>[];
  var head = prefix;
  var rest = rendered;
  while (true) {
    final at = _foldPoint(head.length, rest);
    if (at == null) break;
    lines.add(head + rest.substring(0, at));
    head = continuation;
    rest = rest.substring(at + 1);
  }
  lines.add(head + rest);
  return lines;
}

/// The index of the first single space sitting past [_foldColumn], or null.
int? _foldPoint(int column, String rest) {
  for (var i = 0; i < rest.length; i++) {
    if (rest[i] != ' ') continue;
    if (column + i <= _foldColumn) continue;
    if (i == 0 || i + 1 >= rest.length) continue;
    if (rest[i - 1] == ' ' || rest[i + 1] == ' ') continue;
    return i;
  }
  return null;
}

bool _isInline(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return true;
  }
  if (value is List) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return true;
}

String _inline(Object? value) {
  if (value == null) return 'null';
  if (value is bool) return '$value';
  if (value is num) return _number(value);
  if (value is List) return '[]';
  if (value is Map) return '{}';
  return _quote('$value');
}

/// Renders a number the way the store writes it: a whole float is printed
/// without a fractional part, because the authored files carry lane positions
/// as integers and `120.0` where the file said `120` is a needless diff on
/// every hand-tuned beat.
String _number(num value) {
  if (value is double &&
      value.isFinite &&
      value == value.truncateToDouble() &&
      value.abs() < 1e15) {
    return value.truncate().toString();
  }
  return '$value';
}

String _key(Object? key) => _quote('$key');

const _leadingSpecials = '-?:,[]{}#&*!|>\'"%@`';

const _reserved = {
  'true',
  'false',
  'null',
  'yes',
  'no',
  'on',
  'off',
  '~',
  'y',
  'n',
};

String _quote(String value) {
  if (!_needsQuotes(value)) return value;
  if (value.contains('\n') || value.contains('\t')) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\t', r'\t');
    return '"$escaped"';
  }
  return "'${value.replaceAll("'", "''")}'";
}

bool _needsQuotes(String value) {
  if (value.isEmpty) return true;
  if (value.trim() != value) return true;
  if (_leadingSpecials.contains(value[0])) return true;
  if (value.contains(': ') || value.endsWith(':')) return true;
  if (value.contains(' #')) return true;
  if (value.contains('\t') || value.contains('\n')) return true;
  if (_reserved.contains(value.toLowerCase())) return true;
  if (num.tryParse(value) != null) return true;
  return false;
}
