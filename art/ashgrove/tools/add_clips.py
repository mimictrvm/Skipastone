"""Adds animation clips to a finished entity without rebuilding its model.

    python3 add_clips.py Dybbuk Roar Grab StoopWalk ...

Opens Entities/<Name>/Source/AH_Ent_<Name>.blend, bakes the named clips from
build_<name>.clips() onto the existing rig (existing clips are left alone,
named ones are replaced), exports each clip FBX under the Roblox contract
(skinned meshes + bind pose), updates stats.json and renders
Review/AH_Ent_<Name>_AnimSheet_<label>.png.  Clips that use the station
platform are rendered on a platform/track set.
"""
import importlib
import json
import math
import os
import sys

import bpy
from mathutils import Vector
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blendkit as bk  # noqa: E402
import review  # noqa: E402

STATION_CLIPS = {'EdgeLean', 'Fall', 'FallenLoop', 'PanicClimb'}


def box(name, lo, hi, color, rough=0.8):
    lo, hi = Vector(lo), Vector(hi)
    me = bpy.data.meshes.new(name)
    v = [(x, y, z) for x in (lo.x, hi.x) for y in (lo.y, hi.y) for z in (lo.z, hi.z)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    ob = bk.link(bpy.data.objects.new(name, me))
    mat = bpy.data.materials.new(name + '_m')
    nk = bk.NodeKit(mat)
    n = nk.noise(nk.coord('Object'), 2.5, 6, 0.6).outputs['Fac']
    col = nk.mix(n, tuple(c * 0.7 for c in color), color)
    bs = nk.node('ShaderNodeBsdfPrincipled')
    nk.set(bs.inputs['Base Color'], col)
    bs.inputs['Roughness'].default_value = rough
    out = nk.node('ShaderNodeOutputMaterial')
    nk.nt.links.new(bs.outputs[0], out.inputs['Surface'])
    me.materials.append(mat)
    ob['station'] = True
    return ob


def station_set(H, E):
    objs = [box('ST_Platform', (-9, -E, -H), (9, 12, 0), (0.30, 0.29, 0.27), 0.9),
            box('ST_SafetyLine', (-9, -E, 0), (9, -E + 0.35, 0.01), (0.55, 0.45, 0.08), 0.6),
            box('ST_Bed', (-9, -E - 9, -H - 0.3), (9, -E, -H), (0.13, 0.12, 0.11), 1.0)]
    for y in (-E - 1.6, -E - 3.9):
        objs.append(box(f'ST_Rail{y:.1f}', (-9, y - 0.08, -H), (9, y + 0.08, -H + 0.28), (0.35, 0.33, 0.32), 0.35))
    for i in range(15):
        x = -8.4 + i * 1.2
        objs.append(box(f'ST_Sleeper{i}', (x - 0.25, -E - 4.6, -H), (x + 0.25, -E - 0.9, -H + 0.12),
                        (0.16, 0.11, 0.07), 0.9))
    return objs


def sheet(C, arm, meshes, clips, out_path, station, per=6):
    asset = f'AH_Ent_{C.NAME}'
    for o in bpy.data.objects:
        if o.name.startswith('REV_'):
            o.hide_render = True
        if o.get('station'):
            o.hide_render = not station
    if not station:
        review._floor()
        bpy.data.objects['REV_Floor'].hide_render = False
    review._set_pose(arm, None)
    review._studio(Vector((0, -1.5, 3.5)), 9.0)
    bk.set_world((0.32, 0.32, 0.34), 0.6)
    cam = bk.make_camera('ClipCam')
    cam.data.type = 'PERSP'
    cam.data.lens = 28
    aim = Vector((0, -2.2, 1.2)) if station else Vector((0, -0.6, 4.2))
    cam.location = aim + (Vector((-9.5, -10.5, 3.0)) if station else Vector((-9.0, -11.0, 1.2)))
    bk.look_at(cam, aim)
    w, h = 300, 330
    rows = []
    for cname, act in clips:
        n = int(act['frames'])
        idx = getattr(C, 'SHEET_FRAMES', {}).get(cname) or \
            ([1 + round(i * n / per) for i in range(per)] if act['loop'] else
             [1 + round(i * (n - 1) / (per - 1)) for i in range(per)])
        ims = []
        for k, f in enumerate(idx):
            review._set_pose(arm, act, f)
            p = out_path + f'_{k}.png'
            bk.render(p, res=(w, h), samples=14)
            ims.append(Image.open(p).convert('RGB'))
            os.remove(p)
        rows.append((cname, act, idx, ims))
    lab = 210
    per = max(len(r[3]) for r in rows)
    img = Image.new('RGB', (lab + per * (w + 6), len(rows) * (h + 6) + 60), (22, 22, 24))
    d = ImageDraw.Draw(img)
    title = 'station clips (platform set)' if station else 'new clips'
    d.text((12, 14), f'{asset} — {title} · 30 fps', font=review.font(26, True), fill=(230, 226, 220))
    for r, (cname, act, idx, ims) in enumerate(rows):
        y = 60 + r * (h + 6)
        d.text((12, y + 10), cname, font=review.font(20, True), fill=(230, 226, 220))
        d.text((12, y + 40), f"{int(act['frames'])} f · {act['frames'] / 30:.2f}s", font=review.font(16),
               fill=(160, 160, 160))
        d.text((12, y + 62), 'loop' if act['loop'] else 'one-shot', font=review.font(16), fill=(160, 160, 160))
        for k, im in enumerate(ims):
            img.paste(im, (lab + k * (w + 6), y))
            d.text((lab + k * (w + 6) + 6, y + 4), f'f{idx[k]}', font=review.font(13), fill=(40, 40, 40))
    img.save(out_path)
    review._set_pose(arm, None)
    bk.log('  sheet', out_path)


def main():
    name = sys.argv[1]
    wanted = [a for a in sys.argv[2:] if not a.startswith('-')]
    C = importlib.import_module(f'build_{name.lower()}')
    asset = f'AH_Ent_{name}'
    od = os.path.join(bk.ROOT, 'Entities', name)
    blend = os.path.join(od, 'Source', f'{asset}.blend')
    bpy.ops.wm.open_mainfile(filepath=blend)
    arm = bpy.data.objects[f'{asset}_Rig']
    meshes = [o for o in bpy.data.objects if o.type == 'MESH' and o.parent == arm]
    an = bk.Animator(arm)
    defs = {c[0]: c for c in C.clips(an)}
    missing = [w for w in wanted if w not in defs]
    assert not missing, f'no such clips: {missing}'
    made = []
    for cname in wanted:
        _, frames, fn, loop = defs[cname]
        old = bpy.data.actions.get(f'{asset}_Anim_{cname}')
        if old is not None:
            bpy.data.actions.remove(old)
        made.append((cname, an.bake_fn(f'{asset}_Anim_{cname}', frames, fn, loop)))
    with bk.RobloxSpace(arm, meshes):
        for cname, act in made:
            bk.export_fbx(os.path.join(od, 'Animations', f'{asset}_Anim_{cname}.fbx'), [arm] + meshes,
                          action=act, anim=True, unkeyed=getattr(C, 'UNKEYED_BONES', ()))
    arm.animation_data.action = None
    stats_p = os.path.join(od, 'Source', 'stats.json')
    stats = json.load(open(stats_p))
    for cname, act in made:
        stats['clips'][cname] = {'frames': int(act['frames']), 'seconds': round(act['frames'] / 30, 2),
                                 'loop': bool(act['loop'])}
    json.dump(stats, open(stats_p, 'w'), indent=1)
    if '--no-render' not in sys.argv:
        if any(c in STATION_CLIPS for c, _ in made):
            station_set(C.PLATFORM_H, C.EDGE)
        rv = os.path.join(od, 'Review')
        flat = [(c, a) for c, a in made if c not in STATION_CLIPS]
        stat = [(c, a) for c, a in made if c in STATION_CLIPS]
        if flat:
            sheet(C, arm, meshes, flat, os.path.join(rv, f'{asset}_AnimSheet_NewClips.png'), False)
        if stat:
            sheet(C, arm, meshes, stat, os.path.join(rv, f'{asset}_AnimSheet_Station.png'), True)
        for o in list(bpy.data.objects):
            if o.get('station'):
                bpy.data.objects.remove(o)
    bpy.ops.wm.save_as_mainfile(filepath=blend, compress=True)
    bk.log(f'added {[c for c, _ in made]} to {asset}')


if __name__ == '__main__':
    main()
