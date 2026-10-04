"""Runs one creature description end to end.

    python3 build_<creature>.py [--fast] [--skip-bake] [--only-anim]

Outputs land in art/ashgrove/Entities/<Name>/ (see README there).
"""
import json
import math
import os
import sys
import time

import bpy
import numpy as np
from mathutils import Vector

import blendkit as bk

FAST = '--fast' in sys.argv


def out_dir(name):
    return os.path.join(bk.ROOT, 'Entities', name)


def camel(g):
    return ''.join(w.capitalize() for w in g.split('_'))


def build(C):
    """C: creature module (see build_dybbuk.py for the contract)."""
    t0 = time.time()
    name = C.NAME
    asset = f'AH_Ent_{name}'
    od = out_dir(name)
    for sub in ('Animations', 'Textures', 'Review', 'Source'):
        os.makedirs(os.path.join(od, sub), exist_ok=True)
    bk.reset()

    # ---------------------------------------------------------- geometry
    pieces = C.pieces()
    if FAST:
        for p in pieces:
            p.voxel *= 2.0
    for p in pieces:
        p.build()
    mats = {k: fn(bpy.data.materials.new(f'{name}_{k}')) for k, fn in C.MATERIALS.items()}
    for p in pieces:
        p.hi.data.materials.append(mats[p.mat] if not isinstance(mats[p.mat], tuple) else mats[p.mat][0])

    if '--preview' in sys.argv:
        preview(C, pieces, od)
        return None

    # ---------------------------------------------------------- skeleton
    arm = bk.build_armature(f'{asset}_Rig', C.bones())
    arm.name = asset + '_Rig'
    bone_names = [b.name for b in arm.data.bones]
    for p in pieces:
        p.skin(bone_names)
        p.lo['group'] = p.group
        vg = p.lo.vertex_groups.new(name='__grp_' + p.group)
        vg.add(list(range(len(p.lo.data.vertices))), 1.0, 'REPLACE')

    # ---------------------------------------------------------- game meshes
    tex_pieces = [p for p in pieces if 'glow' not in p.group]
    glow_pieces = [p for p in pieces if 'glow' in p.group]
    low = bk.join([p.lo for p in tex_pieces], asset + '_LOW')
    bk.unwrap(low, margin=0.003, angle=58)
    bk.shade_smooth(low)
    maps = {}
    tex_dir = os.path.join(od, 'Textures')
    if '--skip-bake' in sys.argv:
        maps = {k: os.path.join(tex_dir, f'{asset}_{n}.png') for k, n in
                (('albedo', 'Color'), ('rough', 'Roughness'), ('metal', 'Metalness'), ('normal', 'Normal'))}
    else:
        bk.log('baking ...')
        maps = bk.bake_maps(low, [p.hi for p in tex_pieces], tex_dir, asset,
                            size=1024 if not FAST else 512, extrusion=C.BAKE.get('extrusion', 0.03),
                            ray=C.BAKE.get('ray', 0.12), samples=C.BAKE.get('samples', 6))
    gm = bk.game_material(asset + '_Mat', maps)
    low.data.materials.clear()
    low.data.materials.append(gm)

    # split by group (e.g. the Dullahan's carried head) after the shared bake
    meshes = []
    groups = sorted({p.group for p in tex_pieces})
    if len(groups) > 1:
        import bmesh
        for g in groups:
            if g == 'body':
                continue
            bk.activate(low)
            bpy.ops.object.mode_set(mode='EDIT')
            bpy.ops.mesh.select_all(action='DESELECT')
            bpy.ops.object.vertex_group_set_active(group='__grp_' + g)
            bpy.ops.object.vertex_group_select()
            bpy.ops.mesh.separate(type='SELECTED')
            bpy.ops.object.mode_set(mode='OBJECT')
            part = [o for o in bpy.context.selected_objects if o != low][0]
            part.name = part.data.name = f'{asset}_{camel(g)}'
            meshes.append(part)
    low.name = low.data.name = asset
    meshes.insert(0, low)
    for g in sorted({p.group for p in glow_pieces}):
        glow = bk.join([p.lo for p in glow_pieces if p.group == g], f'{asset}_{camel(g)}')
        bk.unwrap(glow)
        glow.data.materials.clear()
        glow.data.materials.append(bk.glow_material(f'{asset}_{camel(g)}Mat', C.GLOW_COLOR, C.GLOW_STRENGTH))
        meshes.append(glow)
    for m in meshes:
        for vg in list(m.vertex_groups):
            if vg.name.startswith('__grp_') or (vg.name not in bone_names):
                m.vertex_groups.remove(vg)
        bk.bind(m, arm)

    # remove the sculpts from the scene (kept only long enough to bake)
    for p in pieces:
        bpy.data.objects.remove(p.hi)

    # ---------------------------------------------------------- stats / checks
    stats = {'asset': asset, 'meshes': {}, 'bones': len(arm.data.bones),
             'deform_bones': sum(1 for b in arm.data.bones if b.use_deform)}
    for m in meshes:
        me = m.data
        inf = [sum(1 for g in v.groups if g.weight > 0) for v in me.vertices]
        stats['meshes'][m.name] = {'tris': bk.tri_count(m), 'verts': len(me.vertices),
                                   'max_influences': max(inf), 'unweighted_verts': inf.count(0)}
    lo, hi = bk.bbox_world(meshes)
    stats['size_studs'] = {'width_x': round(float(hi[0] - lo[0]), 2), 'height_z': round(float(hi[2] - lo[2]), 2),
                           'depth_y': round(float(hi[1] - lo[1]), 2), 'min_z': round(float(lo[2]), 3)}
    bk.log('stats', json.dumps(stats, indent=1))

    # ---------------------------------------------------------- animation
    an = bk.Animator(arm)
    clips = []
    for clip in C.clips(an):
        cname, frames, fn, loop = clip
        act = an.bake_fn(f'{asset}_Anim_{cname}', frames, fn, loop)
        clips.append((cname, act))
    stats['clips'] = {c: {'frames': int(a['frames']), 'seconds': round(a['frames'] / 30, 2), 'loop': bool(a['loop'])}
                      for c, a in clips}

    # ---------------------------------------------------------- export
    bk.export_fbx(os.path.join(od, f'{asset}.fbx'), [arm] + meshes, action=None)
    for cname, act in clips:
        bk.export_fbx(os.path.join(od, 'Animations', f'{asset}_Anim_{cname}.fbx'), [arm], action=act, anim=True)

    with open(os.path.join(od, 'Source', 'stats.json'), 'w') as f:
        json.dump(stats, f, indent=1)

    # ---------------------------------------------------------- renders
    if '--no-render' not in sys.argv:
        import review
        if '--anim-sheet-only' not in sys.argv:
            review.reference_sheet(C, arm, meshes, os.path.join(od, 'Review'), stats)
            review.mood_shot(C, arm, meshes, dict(clips), os.path.join(od, 'Review'))
        review.anim_sheet(C, arm, meshes, clips, os.path.join(od, 'Review'))

    arm.animation_data.action = None
    blend = os.path.join(od, 'Source', f'{asset}.blend')
    bpy.ops.wm.save_as_mainfile(filepath=blend, compress=True)
    bpy.ops.file.make_paths_relative()
    bpy.ops.wm.save_as_mainfile(filepath=blend, compress=True)
    bk.log(f'done {name} in {(time.time()-t0)/60:.1f} min')
    return stats


def preview(C, pieces, od):
    """Quick look at the sculpt with procedural materials (no bake/rig)."""
    from PIL import Image
    import review
    objs = [p.hi for p in pieces]
    for p in pieces:
        p.lo.hide_render = True
    for p in pieces:
        if 'glow' in p.group:
            p.hi.data.materials.clear()
            p.hi.data.materials.append(bk.glow_material('pv_glow', C.GLOW_COLOR, C.GLOW_STRENGTH))
    lo, hi = bk.bbox_world(objs)
    ctr = (lo + hi) / 2
    H = hi[2] - min(0, lo[2])
    review._studio(ctr, H)
    cam = bk.make_camera('PV')
    shots = []
    views = [('front', (0, -1, 0), ctr, H * 1.05), ('side', (1, 0, 0), ctr, H * 1.05),
             ('q', (-0.6, -1, 0.2), ctr, H * 1.05)]
    views += getattr(C, 'PREVIEW_CLOSEUPS', [])
    for name, d, c, span in views:
        cam.data.type = 'ORTHO'
        cam.data.ortho_scale = span
        c = Vector(c)
        cam.location = c + Vector(d).normalized() * 40
        bk.look_at(cam, c)
        p = os.path.join(od, 'Review', f'_pv_{name}.png')
        bk.render(p, res=(560, 800) if span > 3 else (560, 560), samples=24)
        shots.append(Image.open(p).convert('RGB'))
        os.remove(p)
    W = sum(i.width for i in shots)
    sheet = Image.new('RGB', (W, max(i.height for i in shots)), (20, 20, 20))
    x = 0
    for im in shots:
        sheet.paste(im, (x, 0))
        x += im.width
    sheet.save(os.path.join(od, 'Review', '_preview.png'))
    bk.log('preview written')
