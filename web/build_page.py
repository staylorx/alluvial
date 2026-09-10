#!/usr/bin/env python3
"""Build a static, self-contained chart page: diagram + clickable beats + prose.

The page is ONE html file with the SVG inlined three ways:

  1. the full chart (with captions, clickable beat rows)   -> the long scroll
  2. the same chart in colour-blind mode                    -> CSS-toggled
  3. a compact "mini" version, pinned while you read        -> the map

No build step, no CDN, no framework, no fonts to fetch. Inline SVG is the whole
trick: because it is inline rather than an <img>, every beat row is a real DOM
node, so it can be a link, take a hover state, be focusable from the keyboard,
and be highlighted by page CSS while you read.

Relationship changes are DERIVED from the lane geometry, not authored by hand:
compare each beat's lane gaps to the previous beat's and report what moved.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "scripts"))

import dresses27_vertical as FILM                        # the film we're demoing
from alluvial_vlib import render_v

OUT = os.path.join(HERE, "27-dresses.html")


# --------------------------------------------------------------- geometry ---
def lane_gap(row, a, b, char, S):
    """Edge-to-edge horizontal gap between two lanes in one beat."""
    return abs(row[a] - row[b]) - (char[a][1] * S + char[b][1] * S) / 2


def pair_class(row, a, b, char, S):
    g = lane_gap(row, a, b, char, S)
    if g <= 8:
        return "together"
    if g <= 70:
        return "near"
    return "apart"


def events_for(i, char, S, rows):
    """What changes at beat i, derived from the lane geometry."""
    prev, row = rows[i - 1], rows[i]
    label = lambda c: char[c][0]
    out = []
    for cid in row:
        if cid not in prev:
            out.append(f"{label(cid)} enters")
    for cid in prev:
        if cid not in row:
            out.append(f"{label(cid)} leaves")
    both = [c for c in row if c in prev]
    for x, a in enumerate(both):
        for b in both[x + 1:]:
            c0 = pair_class(prev, a, b, char, S)
            c1 = pair_class(row, a, b, char, S)
            if c0 != c1:
                out.append(f"{label(a)} &amp; {label(b)}: {c0} &rarr; {c1}")
    return out


# ------------------------------------------------------------------ specs ---
def chart_svg(cb=False, mini=False):
    spec = FILM.build(cb)
    spec["beat_links"] = lambda i, c: f"#beat-{i+1:02d}"
    spec["rowmark_prefix"] = "cbchart" if cb else "chart"
    spec["pattern_prefix"] = ("-alt" if cb else "") + ("-mini" if mini else "")
    if mini:
        step = spec.get("mini_step", 15.0)
        spec["ys"] = [spec["ys"][0] + i * step for i in range(len(spec["ys"]))]
        spec["mini"] = True
        spec["W"] = 560
        spec["rowmark_prefix"] = "mini"
        spec["beat_hit_half"] = step / 2
    else:
        spec["font_scale_note"] = True
    svg, checks = render_v(spec)
    svg = svg.replace("<svg ", '<svg class="chart" preserveAspectRatio="xMidYMin meet" ', 1)
    return svg, spec, checks["H"]


def lane_rows(spec):
    """Re-derive the lane x per beat so events can be computed."""
    from alluvial_vlib import width_fonts
    char, cols, S = spec["char"], spec["cols"], spec["scale"]
    origin, spine_old = spec["origin"], spec["spine_old"]
    mirror = spec.get("mirror", True)
    fx = (lambda y: origin + (spine_old - y) * S) if mirror else (lambda y: origin + (y - spine_old) * S)
    GAP = 5 * S
    rows = []
    for c in cols:
        row = {}
        for centre, ids in c["groups"]:
            ids = list(reversed(ids)) if mirror else list(ids)
            total = sum(char[k][1] * S for k in ids) + GAP * (len(ids) - 1)
            x = fx(centre) - total / 2
            for cid in ids:
                w = char[cid][1] * S
                row[cid] = x + w / 2
                x += w + GAP
        rows.append(row)
    return rows


# ------------------------------------------------------------------- page ---
def overlay(cols, ys, H, half):
    """Real HTML anchors laid over the chart. SVG <a> does not implement
    .click() and is not uniformly reliable; an HTML overlay is keyboard
    focusable, screen-reader named, and clicks like any other link."""
    out = []
    for i, c in enumerate(cols):
        top = (ys[i] - half) / H * 100
        h = (2 * half) / H * 100
        out.append(f'<a class="row-hit" href="#beat-{i+1:02d}" '
                   f'style="top:{top:.3f}%;height:{h:.3f}%">'
                   f'<span class="sr">{c["beat"]}</span></a>')
    return "\n        ".join(out)


def build_page():
    svg_full, spec, H = chart_svg(False)
    svg_cb, _, Hcb = chart_svg(True)
    svg_mini, mini_spec, Hmini = chart_svg(False, mini=True)
    hits_full = overlay(spec["cols"], spec["ys"], H, spec.get("beat_hit_half", 78))
    hits_mini = overlay(mini_spec["cols"], mini_spec["ys"], Hmini, mini_spec["beat_hit_half"])

    char, S = spec["char"], spec["scale"]
    rows = lane_rows(spec)
    cols = spec["cols"]

    articles = []
    for i, c in enumerate(cols):
        ev = events_for(i, char, S, rows) if i else [f"{char[k][0]} enters" for k in spec["order"] if k in rows[0]]
        tag = c.get("cap_extra", ("", ""))[0].replace("\u25b8 ", "")
        articles.append(f"""      <article id="beat-{i+1:02d}">
        <p class="kicker">{c['beat']} &middot; {c['loc']}</p>
        <h2>{c['cap'][0]}</h2>
        <p class="struct">{'; '.join(ev) if ev else 'no lane changes this beat'}</p>
        <p class="tag">{tag}</p>
        <p class="prose">[{i+1:02d}]</p>
        <p class="back"><a href="#chart-{i+1:02d}">&uarr; back to the map</a></p>
      </article>""")

    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>27 Dresses &mdash; a braid you can click</title>
<style>
  :root {{ --ink:#22201d; --mut:#7d7568; --faint:#b3aa9d; --rule:#ded7cb;
           --bg:#faf7f2; --accent:#1b57c4; --tag:#8a6a1f; }}
  * {{ box-sizing:border-box; }}
  html {{ scroll-behavior:smooth; }}
  body {{ margin:0; background:var(--bg); color:var(--ink);
          font:15px/1.6 ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace; }}
  .wrap {{ max-width:1180px; margin:0 auto; padding:2.2rem 1.4rem 5rem; }}
  header h1 {{ font-weight:700; font-size:1.5rem; letter-spacing:.02em; margin:0 0 .4rem; }}
  header p {{ color:var(--mut); margin:0 0 1.6rem; max-width:62ch; }}
  .chart {{ display:block; width:100%; height:auto; }}
  .cbtoggle {{ position:absolute; opacity:0; pointer-events:none; }}
  .cbtoggle + label {{ display:inline-block; cursor:pointer; margin:0 0 1rem;
      border:1px solid var(--rule); border-radius:999px; padding:.3rem .8rem;
      color:var(--mut); font-size:.8rem; user-select:none; }}
  .cbtoggle:focus-visible + label {{ outline:2px solid var(--accent); outline-offset:2px; }}
  .cbtoggle:checked + label {{ border-color:var(--accent); color:var(--accent); }}
  .cb-on {{ display:none; }}
  .cbtoggle:checked ~ .charts .cb-off {{ display:none; }}
  .cbtoggle:checked ~ .charts .cb-on {{ display:block; }}
  .chartwrap {{ position:relative; }}
  .row-hit {{ position:absolute; left:0; right:0; display:block; border-radius:6px;
              transition:background .12s ease; }}
  .row-hit:hover, .row-hit:focus-visible {{ background:rgba(27,87,196,.09); outline:none; }}
  .row-hit:focus-visible {{ outline:2px solid var(--accent); outline-offset:-2px; }}
  .sr {{ position:absolute; width:1px; height:1px; overflow:hidden;
         clip-path:inset(50%); white-space:nowrap; }}
  .hit {{ transition:fill .12s ease; }}
  .beat-link:hover .hit, .beat-link:focus-visible .hit {{ fill:rgba(27,87,196,.10); }}
  .beat-link:focus {{ outline:none; }}
  .beat-link:focus-visible {{ outline:2px solid var(--accent); outline-offset:-2px; }}
  .rowmark.active {{ fill:rgba(138,106,31,.13); }}
  .reading {{ display:grid; grid-template-columns:300px 1fr; gap:2.6rem; align-items:start;
              margin-top:3rem; border-top:1px solid var(--rule); padding-top:2rem; }}
  .map {{ position:sticky; top:1rem; }}
  .map p {{ color:var(--faint); font-size:.72rem; letter-spacing:.08em; text-transform:uppercase;
            margin:0 0 .5rem; }}
  .map svg {{ display:block; width:100%; height:auto; }}
  article {{ scroll-margin-top:130px; padding-bottom:2.2rem; margin-bottom:2.2rem;
             border-bottom:1px dotted var(--rule); }}
  article:last-child {{ border-bottom:0; }}
  .kicker {{ color:var(--faint); font-size:.75rem; letter-spacing:.1em; text-transform:uppercase;
             margin:0 0 .3rem; }}
  article h2 {{ font-size:1.05rem; margin:0 0 .5rem; font-weight:700; }}
  .struct {{ color:var(--mut); font-size:.85rem; margin:0 0 .3rem; }}
  .tag {{ color:var(--tag); font-size:.8rem; font-weight:700; margin:0 0 1rem; }}
  .prose {{ min-height:4.5em; border-left:2px solid var(--rule); padding-left:1rem;
            color:var(--faint); font-style:italic; margin:0 0 .9rem; }}
  .back {{ margin:0; font-size:.78rem; }}
  .back a, a {{ color:var(--accent); }}
  @media (max-width:820px) {{
    .reading {{ grid-template-columns:1fr; gap:1.2rem; }}
    .map {{ top:0; background:var(--bg); padding:.4rem 0; border-bottom:1px solid var(--rule); }}
    .map svg {{ max-height:104px; }}
    .map .row-hit {{ pointer-events:none; }}
  }}
</style>
</head>
<body>
<div class="wrap">
  <header>
    <h1>27 Dresses &mdash; the braid, on the web</h1>
    <p>One static page. The diagram is inline SVG, so every beat row is a link: click a
       beat and you land in the writing for it. Scroll on; the map on the left follows you.
       Nothing here needs a server, a build step, or a CDN.</p>
  </header>

  <input type="checkbox" id="cb" class="cbtoggle" autocomplete="off">
  <label for="cb">colour-blind mode &mdash; symbols + darkness</label>
  <div class="charts">
    <div class="cb-off"><div class="chartwrap">{svg_full}
        {hits_full}</div></div>
    <div class="cb-on"><div class="chartwrap">{svg_cb}</div></div>
  </div>

  <section class="reading">
    <div class="map">
      <p>the map</p>
      <div class="chartwrap">{svg_mini}
        {hits_mini}</div>
    </div>
    <div class="beats">
      <p class="kicker" style="margin-bottom:1.4rem">each beat below is a link target &mdash;
        the <em>what changes</em> line is computed from the lane geometry, not typed by hand</p>
{chr(10).join(articles)}
    </div>
  </section>
</div>

<script>
(function () {{
  var cb = document.getElementById('cb');
  try {{ cb.checked = localStorage.getItem('cb') === '1'; }} catch (e) {{}}
  cb.addEventListener('change', function () {{
    try {{ localStorage.setItem('cb', cb.checked ? '1' : '0'); }} catch (e) {{}}
  }});

  // highlight the beat you are reading, on both the full chart and the map
  var marks = document.querySelectorAll('.rowmark');
  function setActive(n) {{
    marks.forEach(function (m) {{ m.classList.remove('active'); }});
    document.querySelectorAll('.rowmark[data-beat="' + n + '"]').forEach(function (m) {{
      m.classList.add('active');
    }});
  }}
  window.__chartSetActive = setActive;   // testable hook; also handy for site JS

  var arts = Array.prototype.slice.call(document.querySelectorAll('article'));
  if ('IntersectionObserver' in window) {{
    var io = new IntersectionObserver(function (es) {{
      es.forEach(function (e) {{
        if (e.isIntersecting) setActive(e.target.id.slice(-2));
      }});
    }}, {{ rootMargin: '-45% 0px -45% 0px' }});
    arts.forEach(function (a) {{ io.observe(a); }});
  }}
}})();
</script>
</body>
</html>
"""


def main():
    html = build_page()
    open(OUT, "w").write(html)
    n_links = html.count('class="beat-link"')
    print(f"{OUT}: {len(html)/1024:.0f} KB, {n_links} clickable beat rows, "
          f"3 inline SVGs ({html.count('<svg ')} svg tags)")


if __name__ == "__main__":
    main()
