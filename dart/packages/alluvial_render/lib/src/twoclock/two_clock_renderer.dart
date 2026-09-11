import 'package:alluvial_domain/alluvial_domain.dart';

import '../py_num.dart';

/// Thread colours, matched to the braid charts' palette.
///
/// The order of this map IS the legend order, and an id that is absent here
/// falls back to grey — which is what the Python renderer does.
const Map<String, String> threadColours = {
  'jules': '#1b57c4', // Jules & Vincent
  'butch': '#d0316a', // Butch
  'mia': '#6e9078', // Mia
  'diners': '#b09a4e', // Pumpkin & Honey Bunny
  'wolf': '#8d7fa8', // the Wolf / the cleanup
};

const String _background = '#faf7f2';
const String _ink = '#22201d';
const String _muted = '#7d7568';
const String _fallbackThread = '#888';

const double _top = 250.0;
const double _pitch = 176.0;
const double _nodeHeight = 62.0;
const double _leftX = 56.0;
const double _rightX = 584.0;
const double _nodeWidth = 370.0;
const int _canvas = 1010;

/// Which thread a scene belongs to, as a colour.
String threadColour(String? thread) => threadColours[thread] ?? _fallbackThread;

/// The two-clock chart: the order the work screens its scenes on the left spine,
/// the order they happen to the people in them on the right.
///
/// A scene is one node on each side, joined by a ribbon — so a ribbon that runs
/// straight means the story is telling itself in order, and a ribbon that
/// crosses means the work cut time. The crossings are the finding.
///
/// Byte-identical to the Python renderer that produced the approved chart.
String renderTwoClock(Story story) {
  final scenes = story.beats;
  final count = scenes.length;
  final screened = List<Beat>.of(scenes)
    ..sort((a, b) => a.order.compareTo(b.order));
  final happened = List<Beat>.of(scenes)
    ..sort((a, b) => (a.happenedAt ?? 0).compareTo(b.happenedAt ?? 0));

  final height = _top + _pitch * count + 190.0;
  final screenY = <String, double>{
    for (var i = 0; i < screened.length; i++) screened[i].id: _top + i * _pitch,
  };
  final realY = <String, double>{
    for (var i = 0; i < happened.length; i++) happened[i].id: _top + i * _pitch,
  };

  final out = <String>[];
  out.add(
    '<svg class="chart" preserveAspectRatio="xMidYMin meet" '
    'xmlns="http://www.w3.org/2000/svg" width="${PyNum.fixedNum(_canvas, 0)}" '
    'height="${PyNum.fixedNum(height, 0)}" '
    'viewBox="0 0 ${PyNum.fixedNum(_canvas, 0)} ${PyNum.fixedNum(height, 0)}" '
    'font-family="Helvetica, Arial, sans-serif">',
  );
  out.add(
    '<rect width="${PyNum.fixedNum(_canvas, 0)}" '
    'height="${PyNum.fixedNum(height, 0)}" fill="$_background"/>',
  );

  out.add(
    '<text x="56" y="92" font-size="31" font-weight="700" fill="$_ink">'
    '${story.title} \u2014 two clocks</text>',
  );
  final sub = story.extra['sub'];
  out.add(
    '<text x="56" y="126" font-size="15.5" fill="#4a453f">${sub ?? ''}</text>',
  );
  final notes = story.extra['notes'];
  if (notes is List) {
    var i = 0;
    for (final line in notes) {
      out.add(
        '<text x="56" y="${158 + i * 24}" font-size="14.5" fill="$_muted">'
        '$line</text>',
      );
      i += 1;
    }
  }

  out.add(
    '<text x="${PyNum.repr(_leftX)}" '
    'y="${PyNum.fixedNum(_top - 42, 0)}" font-size="13" font-weight="700" '
    'letter-spacing="1.2" fill="#9a9086">AS SCREENED</text>',
  );
  out.add(
    '<text x="${PyNum.repr(_rightX + _nodeWidth)}" '
    'y="${PyNum.fixedNum(_top - 42, 0)}" font-size="13" font-weight="700" '
    'letter-spacing="1.2" fill="#9a9086" text-anchor="end">AS IT HAPPENED</text>',
  );

  // Ribbons first, so the nodes sit on top of them.
  for (final scene in scenes) {
    final y0 = screenY[scene.id]! + _nodeHeight / 2;
    final y1 = realY[scene.id]! + _nodeHeight / 2;
    final colour = threadColour(scene.threadId);
    final x0 = _leftX + _nodeWidth;
    final x1 = _rightX;
    final dx = (x1 - x0) * 0.45;
    final minutes = scene.minutes ?? 10;
    final thickness = (minutes * 0.5).clamp(6.0, 14.0);
    out.add(
      '<path d="M ${PyNum.fixedNum(x0, 0)} ${PyNum.fixedNum(y0, 1)} '
      'C ${PyNum.fixedNum(x0 + dx, 0)} ${PyNum.fixedNum(y0, 1)} '
      '${PyNum.fixedNum(x1 - dx, 0)} ${PyNum.fixedNum(y1, 1)} '
      '${PyNum.fixedNum(x1, 0)} ${PyNum.fixedNum(y1, 1)}" '
      'fill="none" stroke="$colour" '
      'stroke-width="${PyNum.fixedNum(thickness, 1)}" stroke-opacity="0.55" '
      'stroke-linecap="round"/>',
    );
  }

  // Nodes on both spines, with the position numbers so the crossing is
  // countable.
  for (final (side, spine, ordered) in [
    ('l', screenY, screened),
    ('r', realY, happened),
  ]) {
    for (final scene in ordered) {
      final y = spine[scene.id]!;
      final colour = threadColour(scene.threadId);
      final x = side == 'l' ? _leftX : _rightX;
      out.add(
        '<rect x="${PyNum.fixedNum(x, 0)}" y="${PyNum.fixedNum(y, 1)}" '
        'width="${PyNum.fixedNum(_nodeWidth, 0)}" '
        'height="${PyNum.fixedNum(_nodeHeight, 0)}" rx="8" fill="#ffffff" '
        'stroke="$colour" stroke-width="2"/>',
      );
      out.add(
        '<rect x="${PyNum.fixedNum(x, 0)}" y="${PyNum.fixedNum(y, 1)}" '
        'width="7" height="${PyNum.fixedNum(_nodeHeight, 0)}" rx="3" '
        'fill="$colour"/>',
      );
      out.add(
        '<text x="${PyNum.fixedNum(x + 18, 0)}" '
        'y="${PyNum.fixedNum(y + 26, 1)}" font-size="17" font-weight="700" '
        'fill="$_ink">${scene.name}</text>',
      );
      out.add(
        '<text x="${PyNum.fixedNum(x + 18, 0)}" '
        'y="${PyNum.fixedNum(y + 48, 1)}" font-size="13.5" '
        'fill="$_muted">${scene.parentRef ?? ''}</text>',
      );
      final position = side == 'l' ? scene.order : (scene.happenedAt ?? 0);
      out.add(
        '<text x="${PyNum.fixedNum(x + _nodeWidth - 16, 0)}" '
        'y="${PyNum.fixedNum(y + _nodeHeight / 2 + 6, 1)}" font-size="16" '
        'font-weight="700" fill="$colour" text-anchor="end">$position</text>',
      );
    }
  }

  final legendY = _top + _pitch * count + 40;
  out.add(
    '<text x="56" y="${PyNum.fixedNum(legendY, 0)}" font-size="13" '
    'font-weight="700" letter-spacing="1.1" fill="#9a9086">THREADS</text>',
  );
  var cx = 56.0;
  for (final entry in threadColours.entries) {
    final used = scenes.any((scene) => scene.threadId == entry.key);
    if (!used) continue;
    final label = story.character(entry.key)?.name ?? entry.key;
    out.add(
      '<rect x="${PyNum.fixedNum(cx, 0)}" '
      'y="${PyNum.fixedNum(legendY + 14, 0)}" width="22" height="9" rx="2" '
      'fill="${entry.value}" fill-opacity="0.85"/>',
    );
    out.add(
      '<text x="${PyNum.fixedNum(cx + 30, 0)}" '
      'y="${PyNum.fixedNum(legendY + 23, 0)}" font-size="14" '
      'font-weight="600" fill="#2b2622">$label</text>',
    );
    cx += 30 + pyLen(label) * 8.4 + 26;
  }
  final legendNote = story.extra['legend_note'];
  out.add(
    '<text x="56" y="${PyNum.fixedNum(legendY + 58, 0)}" font-size="14" '
    'font-style="italic" fill="#8b8377">${legendNote ?? ''}</text>',
  );

  out.add('</svg>');
  return out.join('\n');
}

/// Whether [story] draws with the two-clock renderer.
bool isTwoClock(Story story) => story.shape == StoryShape.twoClock;
