"""Builds the Entity Pack review page (HTML + JPEG copies of the review sheets).

    python3 make_review_page.py <out_dir>
"""
import html
import json
import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'review_page')

E = [
    dict(name='Dybbuk', origin='Ashkenazi Jewish folklore', where='The opened box in the cellar vault',
         glow=('#FFD18C', 'pinprick eyes'),
         concept='A dislocated, malicious soul that cannot move on. A starved, too-tall ash-grey figure on stilt legs '
                 'that end in spikes, with arms that reach its knees, three hooked fingers and torn grave linen at '
                 'the hips. The head is soot-black and featureless apart from a crooked grin and two pinprick eyes. '
                 'In the dark, the pale body against the black head reads first.',
         notes={'Attack': 'Hands close on frame 24', 'ThrowCorpse': 'Grips on frame 25, releases on frame 55',
                'Stunned': 'Music box: recoil, clutch head, freeze', 'StunnedLoop': 'Hold for the stun duration',
                'Idle': 'Breathing, two sharp head twitches', 'Walk': 'Stiff stilt gait',
                'Run': 'Bent double, arms reaching', 'Manifest': 'Unfolds from a heap on the floor',
                'Vanish': 'Arches, collapses through the floor line'},
         change='Spike legs instead of feet: the brief had no foot spec, so the scarier option won. Footsteps become a tap.'),
    dict(name='Dullahan', origin='Irish folklore', where='The portrait gallery', glow=('#FF5220', 'eyes of the carried head'),
         concept='The headless rider, on foot. A soaked, caped coachman\'s greatcoat with tarnished brass buttons and '
                 'oxblood cuffs. The hood stands up stiff around nothing but a dark neck stump. It carries its own '
                 'mould-pale head by the hair, grinning ear to ear, and a whip made from a human spine.',
         notes={'Idle': 'Head turns in its hand, jaw twitches', 'Walk': 'Coat follows the legs, head swings',
                'Stride': 'Faster: it has been watching you', 'Run': 'Coat flaring, whip trailing',
                'AttackWhip': 'Whip cracks forward around frame 24', 'Reveal': 'Lifts the head to your face, frame 26',
                'Manifest': 'Rises from one knee', 'Vanish': 'Turns away, coat swirls, sinks'},
         change='No horse, because the gallery is indoors. The carried head is its own mesh, so photos can hide it and '
                'the Dullahan appears headless.'),
    dict(name='Demon', origin='European demonology, no single culture', where='Later story', glow=('#FF6610', 'eye slits and throat'),
         concept='Charred black skin split by ember cracks on the chest and throat, goat legs on cloven hooves, a waist '
                 'you could close a hand around, long taloned arms, an elongated skull that is mostly teeth, and ribbed '
                 'horns sweeping up into a crescent. There are no religious symbols: the crucifix belongs to the player.',
         notes={'Idle': 'Breathing through the teeth, a jaw snap', 'Walk': 'Predatory stalk, stooped',
                'Run': 'Low and bounding', 'Attack': 'Double claw slash lands on frame 20', 'Roar': 'Hunt start',
                'RepelledCross': 'Arm over its face, staggers back', 'Manifest': 'Uncurls from a crouched knot',
                'Vanish': 'Folds down into the floor'},
         change='Ten studs to the horn tips at rest; every locomotion clip stoops it under 8.2 studs for doorways.'),
    dict(name='Siren', origin='Greek myth, later European fish-tail tradition', where='Later story', glow=('#B3E0FF', 'pinprick pupils'),
         concept='Drowned: waterlogged blue-grey skin over bone, black eyes, a lipless mouth of needle teeth, '
                 'spined fin-frills for ears, webbed hands, wet clumped hair and a long eel tail with a ragged fluke. '
                 'A corroded bronze circlet is all that is left of who she was. She swims through the air as if the '
                 'house were underwater.',
         notes={'Idle': 'Hovering, tail undulating', 'Swim': 'Roaming', 'SwimFast': 'Hunting, jaw open',
                'Sing': 'Loop while she slows players', 'Attack': 'Hands clamp on frame 24',
                'Scream': 'Jaw unhinges, frills snap open', 'Manifest': 'Surfaces out of the floor',
                'Vanish': 'Dives back down'},
         change='She floats and swims instead of dragging herself, which reads as stranger inside a house.'),
    dict(name='Nightmare', origin='Germanic and Slavic mara / mora', where='Later story', glow=('#D9CCFF', 'pinprick eyes'),
         concept='The spirit that sits on a sleeper\'s chest, given form. A floating cage of bone ribs around a core of '
                 'black tar that drips away beneath it. A long vertebral neck leads to a cracked porcelain skull with '
                 'two crowded rows of teeth and a crescent of bone over the brow. Long black arms end in needle fingers.',
         notes={'Idle': 'Hovering, sudden head twitch', 'Drift': 'Roaming glide, drips trail',
                'Hunt': 'Fast glide, arms reaching', 'Attack': 'Rides its victim: pins on frame 24',
                'Hallucinate': 'Head snaps through impossible angles', 'Manifest': 'Pours up out of the floor',
                'Vanish': 'Melts back down'},
         change='Given arms so the folklore attack, sitting on the victim\'s chest, can be animated.'),
]


def jpeg(src, dst, max_w):
    im = Image.open(src).convert('RGB')
    if im.width > max_w:
        im = im.resize((max_w, round(im.height * max_w / im.width)), Image.LANCZOS)
    im.save(dst, quality=82, optimize=True, progressive=True)


def main():
    os.makedirs(os.path.join(OUT, 'img'), exist_ok=True)
    rows, arts, nav = [], [], []
    for e in E:
        n = e['name']
        rv = os.path.join(ROOT, 'Entities', n, 'Review')
        s = json.load(open(os.path.join(ROOT, 'Entities', n, 'Source', 'stats.json')))
        key = n.lower()
        for kind, fn, w in (('ref', f'AH_Ent_{n}_RefSheet.png', 2000), ('light', f'AH_Ent_{n}_InGameLight.png', 1470),
                            ('anim', f'AH_Ent_{n}_AnimSheet.png', 1400)):
            jpeg(os.path.join(rv, fn), os.path.join(OUT, 'img', f'{key}_{kind}.jpg'), w)
        tris = sum(v['tris'] for v in s['meshes'].values())
        sz = s['size_studs']
        top = sz['height_z'] + max(sz['min_z'], 0)
        rows.append(f'<tr><th scope="row"><a href="#{key}">{n}</a></th><td class="num">{top:.1f}</td>'
                    f'<td class="num">{tris:,}</td><td class="num">{s["bones"]}</td><td class="num">{len(s["clips"])}</td>'
                    f'<td><span class="sw" style="--c:{e["glow"][0]}"></span>{e["glow"][0]}</td></tr>')
        nav.append(f'<a href="#{key}">{n}</a>')
        clip_rows = ''.join(
            f'<tr><td class="mono">{c}</td><td class="num">{v["frames"]}</td><td class="num">{v["seconds"]:.2f}s</td>'
            f'<td>{"loop" if v["loop"] else "once"}</td><td>{html.escape(e["notes"].get(c, ""))}</td></tr>'
            for c, v in s['clips'].items())
        meshes = ', '.join(f'<span class="mono">{k}</span>' for k in s['meshes'])
        arts.append(f'''
<article id="{key}" class="entry">
  <header class="entry-head">
    <p class="code mono">AH_Ent_{n}</p>
    <h2>{n}</h2>
    <p class="origin">{html.escape(e["origin"])} · {html.escape(e["where"])}</p>
  </header>
  <div class="entry-body">
    <div class="text">
      <p class="concept">{html.escape(e["concept"])}</p>
      <dl class="facts">
        <div><dt>Height</dt><dd class="num">{top:.1f} studs</dd></div>
        <div><dt>Triangles</dt><dd class="num">{tris:,} / 12,000</dd></div>
        <div><dt>Bones</dt><dd class="num">{s["bones"]}</dd></div>
        <div><dt>Glow (Neon)</dt><dd><span class="sw" style="--c:{e["glow"][0]}"></span>{e["glow"][0]} · {e["glow"][1]}</dd></div>
      </dl>
      <p class="meshes">Meshes: {meshes}</p>
      <p class="change"><strong>Change from the brief.</strong> {html.escape(e["change"])}</p>
    </div>
    <div class="clips">
      <div class="scroll"><table>
        <caption>Animation clips · 30 fps · in place</caption>
        <thead><tr><th>Clip</th><th class="num">Frames</th><th class="num">Length</th><th>Plays</th><th>Notes</th></tr></thead>
        <tbody>{clip_rows}</tbody>
      </table></div>
    </div>
  </div>
  <div class="views" role="tablist" aria-label="{n} review images">
    <button role="tab" aria-selected="true" data-v="ref" id="{key}-t-ref">Reference sheet</button>
    <button role="tab" aria-selected="false" data-v="light" id="{key}-t-light">In-game light</button>
    <button role="tab" aria-selected="false" data-v="anim" id="{key}-t-anim">Animation frames</button>
  </div>
  <figure class="plate" data-k="{key}">
    <a href="img/{key}_ref.jpg" target="_blank" rel="noopener"><img src="img/{key}_ref.jpg" alt="{n} reference sheet: front, side and back views beside a 5.5-stud player for scale" loading="lazy"></a>
  </figure>
</article>''')

    page = TEMPLATE.replace('{{ROWS}}', '\n'.join(rows)).replace('{{ARTICLES}}', '\n'.join(arts)) \
        .replace('{{NAV}}', ''.join(nav))
    open(os.path.join(OUT, 'index.html'), 'w').write(page)
    print('wrote', OUT)


TEMPLATE = r'''<title>Ashgrove Entity Pack</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IM+Fell+English+SC&family=Spectral:ital,wght@0,400;0,600;1,400&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
/* Layout: a collector's catalogue read by torchlight. One column of entries, each a label, a
   description, its clip ledger, then a plate you can switch between three views. */
:root {
  --ink: #0e1013;        /* page */
  --vault: #16191e;      /* raised panels */
  --rule: #2b2f36;
  --bone: #e4dccb;       /* text */
  --dust: #9d9686;       /* secondary text */
  --brass: #c09a52;      /* accent: tarnished brass */
  --display: "IM Fell English SC", "Iowan Old Style", Georgia, serif;
  --body: "Spectral", "Iowan Old Style", Georgia, serif;
  --mono: "IBM Plex Mono", ui-monospace, "SFMono-Regular", Menlo, monospace;
  color-scheme: dark;
}
html, body { background: var(--ink); color: var(--bone); }
body { font-family: var(--body); font-size: 17px; line-height: 1.6; padding-inline: 20px; padding-block: 0 64px; }
.wrap { max-width: 1180px; margin-inline: auto; }
a { color: var(--brass); }
a:focus-visible, button:focus-visible { outline: 2px solid var(--brass); outline-offset: 3px; }
.mono { font-family: var(--mono); font-size: 0.82em; letter-spacing: 0.01em; }
.num { font-variant-numeric: tabular-nums; }

.mast { padding-block: 56px 28px; border-bottom: 1px solid var(--rule); display: grid; gap: 14px; }
.mast .eyebrow { font-family: var(--mono); font-size: 12px; letter-spacing: 0.16em; text-transform: uppercase; color: var(--dust); margin: 0; }
.mast h1 { font-family: var(--display); font-weight: 400; font-size: clamp(40px, 7vw, 76px); line-height: 1.0; margin: 0; text-wrap: balance; }
.mast h1 span { color: var(--brass); }
.mast p.lede { max-width: 62ch; margin: 0; color: var(--dust); }

nav.index { position: sticky; top: env(safe-area-inset-top, 0px); z-index: 2; background: var(--ink); border-bottom: 1px solid var(--rule);
  display: flex; flex-wrap: wrap; gap: 6px 22px; padding-block: 12px; }
nav.index a { font-family: var(--display); font-size: 20px; text-decoration: none; color: var(--bone); }
nav.index a:hover { color: var(--brass); }

section.summary { padding-block: 32px 8px; display: grid; gap: 14px; }
h3 { font-family: var(--display); font-weight: 400; font-size: 26px; margin: 0; }
.scroll { overflow-x: auto; }
table { border-collapse: collapse; width: 100%; font-size: 15px; }
caption { text-align: left; font-family: var(--mono); font-size: 12px; letter-spacing: 0.12em; text-transform: uppercase; color: var(--dust); padding-bottom: 8px; }
th, td { text-align: left; padding: 7px 12px 7px 0; border-bottom: 1px solid var(--rule); vertical-align: top; }
thead th { font-weight: 600; color: var(--dust); font-size: 13px; }
td.num, th.num { text-align: right; padding-right: 18px; }
tbody th a { font-family: var(--display); font-size: 18px; text-decoration: none; font-weight: 400; }
.sw { display: inline-block; width: 0.8em; height: 0.8em; border-radius: 50%; background: var(--c); box-shadow: 0 0 10px var(--c); margin-right: 0.5em; vertical-align: -0.05em; }

.entry { padding-block: 64px 8px; border-bottom: 1px solid var(--rule); display: grid; gap: 22px; scroll-margin-top: 64px; }
.entry-head { display: grid; gap: 4px; }
.entry-head .code { margin: 0; color: var(--brass); letter-spacing: 0.08em; }
.entry-head h2 { font-family: var(--display); font-weight: 400; font-size: clamp(44px, 8vw, 84px); line-height: 0.95; margin: 0; }
.entry-head .origin { margin: 0; color: var(--dust); font-style: italic; }
.entry-body { display: grid; grid-template-columns: minmax(0, 5fr) minmax(0, 6fr); gap: 36px; }
.text { display: grid; gap: 16px; align-content: start; min-width: 0; }
.concept { margin: 0; max-width: 62ch; }
.facts { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px 20px; margin: 0; }
.facts div { border-top: 1px solid var(--rule); padding-top: 6px; }
.facts dt { font-family: var(--mono); font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--dust); }
.facts dd { margin: 2px 0 0; }
.meshes { margin: 0; font-size: 14px; color: var(--dust); overflow-wrap: anywhere; }
.change { margin: 0; font-size: 15px; padding: 12px 14px; background: var(--vault); border-left: 2px solid var(--brass); }
.clips { min-width: 0; }
.clips td:last-child { color: var(--dust); }

.views { display: flex; flex-wrap: wrap; gap: 8px; }
.views button { font: inherit; font-size: 14px; background: transparent; color: var(--dust); border: 1px solid var(--rule);
  border-radius: 999px; padding: 6px 14px; cursor: pointer; }
.views button[aria-selected="true"] { color: var(--ink); background: var(--brass); border-color: var(--brass); }
.plate { margin: 0; background: #08090b; border: 1px solid var(--rule); }
.plate img { display: block; width: 100%; height: auto; }

section.import { padding-block: 56px 0; display: grid; gap: 14px; max-width: 72ch; }
section.import ol { margin: 0; padding-left: 1.3em; display: grid; gap: 8px; }
footer { padding-block: 40px 0; color: var(--dust); font-size: 14px; }

@media (max-width: 860px) {
  .entry-body { grid-template-columns: minmax(0, 1fr); gap: 24px; }
  body { font-size: 16px; padding-inline: 16px; }
}
@media (prefers-reduced-motion: no-preference) {
  .plate img { transition: opacity 0.25s ease; }
}
</style>

<div class="wrap">
  <header class="mast">
    <p class="eyebrow">Ashgrove House · art drop · Oct 2026</p>
    <h1>Entity Pack <span>One</span></h1>
    <p class="lede">Five of the collection's entities, built to the art &amp; model brief: Roblox-ready FBX rigs in studs,
      1024² PBR texture sets, and every animation as its own clip. Each entry has its reference sheet, a check under
      flashlight and lightning, and frames from every clip. The Banshee and Aswang follow in Pack Two.</p>
  </header>

  <nav class="index" aria-label="Entities">{{NAV}}</nav>

  <section class="summary" aria-labelledby="spec-h">
    <h3 id="spec-h">Against the brief</h3>
    <div class="scroll"><table>
      <caption>Every entity is under the hard limits: ≤ 12,000 triangles, ≤ ~50 bones, ≤ 4 influences, 1024² textures</caption>
      <thead><tr><th>Entity</th><th class="num">Top (studs)</th><th class="num">Triangles</th><th class="num">Bones</th><th class="num">Clips</th><th>Glow</th></tr></thead>
      <tbody>
{{ROWS}}
      </tbody>
    </table></div>
  </section>

{{ARTICLES}}

  <section class="import" aria-labelledby="imp-h">
    <h3 id="imp-h">Bringing them into Studio</h3>
    <ol>
      <li><strong>Import the model.</strong> Use File → Import 3D with <span class="mono">AH_Ent_&lt;Name&gt;.fbx</span>, rig type Custom. Files are authored at 1 unit = 1 stud: import at scale 1, with no 0.01 factor. Each entity should match the height in the table above.</li>
      <li><strong>Add the textures.</strong> Give each textured MeshPart a SurfaceAppearance with Color, Normal, Roughness and Metalness from <span class="mono">Textures/</span>. The Dullahan's head shares the body's set.</li>
      <li><strong>Set up the glow parts.</strong> Set Material to Neon on <span class="mono">*_Glow</span> and <span class="mono">*_HeadGlow</span>, using the colours listed above.</li>
      <li><strong>Import the animations.</strong> In the Animation Editor, choose Import → From File for each file in <span class="mono">Animations/</span>, then publish and play through an Animator.</li>
      <li><strong>Dullahan photos.</strong> Hide <span class="mono">AH_Ent_Dullahan_Head</span> and <span class="mono">_HeadGlow</span> in the photo render, and it appears headless.</li>
    </ol>
    <p>The full notes, sources and the procedural pipeline that rebuilds everything are in <span class="mono">art/ashgrove/</span> on the <span class="mono">claude/new-session-qygf32</span> branch.</p>
  </section>

  <footer>Ashgrove House · Entity Pack One · built for Roblox, review renders from Blender Cycles.</footer>
</div>

<script>
document.querySelectorAll('.entry').forEach(function (art) {
  var key = art.id, img = art.querySelector('.plate img'), link = art.querySelector('.plate a');
  var alts = { ref: ' reference sheet: front, side and back views beside a 5.5-stud player for scale',
               light: ' lit only by a flashlight, and silhouetted by a lightning flash',
               anim: ' animation clips, six frames each' };
  var name = art.querySelector('h2').textContent;
  art.querySelectorAll('.views button').forEach(function (b) {
    b.addEventListener('click', function () {
      art.querySelectorAll('.views button').forEach(function (o) { o.setAttribute('aria-selected', o === b ? 'true' : 'false'); });
      var v = b.dataset.v, src = 'img/' + key + '_' + v + '.jpg';
      img.src = src; link.href = src; img.alt = name + alts[v];
    });
  });
});
</script>
'''

if __name__ == '__main__':
    main()
