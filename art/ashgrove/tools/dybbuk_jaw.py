"""Talking jaw for the Dybbuk (Fable brief: FABLE_MONSTER_JAW_BLENDER_PROMPT.md).

    python3 dybbuk_jaw.py rig            # hinge, Head/Jaw weights, EyeL/EyeR; saves the .blend
    python3 dybbuk_jaw.py range          # renders the mouth at 0..45 deg, measures clipping
    python3 dybbuk_jaw.py final <max>    # closed / 8 deg / max screenshots + FBX export

The jaw is driven live by a game script, so every exported clip leaves `Jaw` unkeyed.
"""
import math
import os
import sys

import bpy
import bmesh  # noqa: E402  (needs bpy loaded first)
import numpy as np
from mathutils import Quaternion, Vector
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blendkit as bk  # noqa: E402
import build_dybbuk as D  # noqa: E402
import review  # noqa: E402
from sdf import Scene  # noqa: E402

ASSET = 'AH_Ent_Dybbuk'
OD = os.path.join(bk.ROOT, 'Entities', 'Dybbuk')
BLEND = os.path.join(OD, 'Source', f'{ASSET}.blend')
OUT = os.path.join(OD, 'Review', 'Jaw')
HINGE = Vector((0.0, 0.02, 8.44))   # behind and just above the grin corners (corners: z 8.41, y -0.09)
CHIN = Vector((0.0, -0.40, 7.98))
CORNER_DEG = 86.0                    # the grin runs +-86 deg around the head (see build_dybbuk.mouth_arc)


def load():
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    arm = bpy.data.objects[f'{ASSET}_Rig']
    body = bpy.data.objects[ASSET]
    return arm, body


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def jaw_fraction(P):
    """0 = upper head, 1 = lower jaw, for points on the head surface (rest pose)."""
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    th = np.degrees(np.abs(np.arctan2(x, -(y + 0.06))))
    zarc = D.MOUTH_Z + 0.24 * (np.minimum(th, CORNER_DEG) / CORNER_DEG) ** 2.4
    below = 1.0 - smoothstep(zarc - 0.025, zarc + 0.025, z)
    front = 1.0 - smoothstep(CORNER_DEG - 2, CORNER_DEG + 20, th)   # corners blend into the cheeks
    return below * front


def jaw_fraction_hard(P):
    """1 below the grin line, 0 above (teeth and gums), any angle around the head."""
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    th = np.degrees(np.abs(np.arctan2(x, -(y + 0.06))))
    zarc = D.MOUTH_Z + 0.24 * (np.minimum(th, CORNER_DEG) / CORNER_DEG) ** 2.4
    return (z < zarc).astype(float)


TEETH_GAP = 0.012


def replace_teeth(body, comps, W, ih, ij):
    """Swap the fused teeth for rows rebuilt with a small gap between the tips, so each row is
    its own watertight piece and can be weighted 100% to Head or Jaw. The new teeth take their
    UVs from the old ones, so they keep the baked texture."""
    from sdf import Scene as SScene
    old_idx = np.concatenate([np.array(c) for c in comps[1:]
                              if (W[np.array(c), ih] + W[np.array(c), ij]).sum() > 0.5 * len(c)])
    old_tris = sum(len(p.vertices) - 2 for p in body.data.polygons if all(v in set(old_idx) for v in p.vertices))
    # 1 - copy of the old teeth as the UV source
    bk.activate(body)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='DESELECT')
    bpy.ops.object.mode_set(mode='OBJECT')
    sel = set(int(i) for i in old_idx)
    for v in body.data.vertices:
        v.select = v.index in sel
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.separate(type='SELECTED')
    bpy.ops.object.mode_set(mode='OBJECT')
    src = [o for o in bpy.context.selected_objects if o != body][0]
    src.name = 'OldTeeth'
    # 2 - new rows from the creature's own SDF description
    sc = SScene(D.teeth_prims(gap=TEETH_GAP))
    v, f = sc.mesh(0.004, verbose=False)
    new = bk.mesh_from_arrays('NewTeeth', v, f)
    bk.smooth_mesh(new, 1, 0.3)
    bk.decimate_to(new, old_tris)
    bk.shade_smooth(new)
    new.data.uv_layers.new(name=body.data.uv_layers.active.name)
    dt = new.modifiers.new('uv', 'DATA_TRANSFER')
    dt.object = src
    dt.use_loop_data = True
    dt.data_types_loops = {'UV'}
    dt.loop_mapping = 'POLYINTERP_NEAREST'
    bk.apply_mods(new)
    # 3 - rigid row weights from the primitives that built each tooth
    P = np.array([x.co[:] for x in new.data.vertices])
    bones, BW = sc.bone_weights(P, 0.02)
    jaw_v = BW[:, bones.index('Jaw')] > BW[:, bones.index('Head')]
    jaw = np.zeros(len(P), bool)
    for comp in components(new.data):  # the rows no longer touch: each piece goes whole to one bone
        c = np.array(comp)
        jaw[c] = jaw_v[c].mean() > 0.5
    gH, gJ = new.vertex_groups.new(name='Head'), new.vertex_groups.new(name='Jaw')
    gJ.add([int(i) for i in np.nonzero(jaw)[0]], 1.0, 'REPLACE')
    gH.add([int(i) for i in np.nonzero(~jaw)[0]], 1.0, 'REPLACE')
    new.data.materials.append(body.data.materials[0])
    new.parent = body.parent
    bpy.data.objects.remove(src)
    bk.activate(body)
    new.select_set(True)
    bpy.ops.object.join()
    bk.log(f'  rebuilt teeth with a {TEETH_GAP} gap: {old_tris} -> {sum(len(p.vertices) - 2 for p in new.data.polygons) if False else old_tris} tris budget, '
           f'{int(jaw.sum())} lower-row verts')


def boundary_loops(bm):
    seen, loops = set(), []
    for e in bm.edges:
        if not e.is_boundary or e in seen:
            continue
        stack, comp = [e], []
        seen.add(e)
        while stack:
            x = stack.pop()
            comp.append(x)
            for v in x.verts:
                for y in v.link_edges:
                    if y.is_boundary and y not in seen:
                        seen.add(y)
                        stack.append(y)
        loops.append(comp)
    return loops


def components(me):
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    seen, comps = set(), []
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, comp = [v], []
        seen.add(v.index)
        while stack:
            a = stack.pop()
            comp.append(a.index)
            for e in a.link_edges:
                b = e.other_vert(a)
                if b.index not in seen:
                    seen.add(b.index)
                    stack.append(b)
        comps.append(comp)
    bm.free()
    return sorted(comps, key=len, reverse=True)


def weights_of(obj):
    names = [g.name for g in obj.vertex_groups]
    W = np.zeros((len(obj.data.vertices), len(names)))
    for v in obj.data.vertices:
        for g in v.groups:
            W[v.index, g.group] = g.weight
    return names, W


def write_weights(obj, names, W):
    for i, n in enumerate(names):
        vg = obj.vertex_groups[n]
        vg.remove(list(range(len(obj.data.vertices))))
        idx = np.nonzero(W[:, i] > 1e-4)[0]
        for vi in idx:
            vg.add([int(vi)], float(W[vi, i]), 'REPLACE')


def stage_rig():
    arm, body = load()
    # 1 - hinge
    bk.activate(arm)
    bpy.ops.object.mode_set(mode='EDIT')
    eb = arm.data.edit_bones['Jaw']
    eb.head, eb.tail = HINGE, CHIN
    eb.align_roll(Vector((0, 0, 1)))
    bpy.ops.object.mode_set(mode='OBJECT')
    # 2 - weights: split each vertex's Head+Jaw share along the grin line
    names, W = weights_of(body)
    ih, ij = names.index('Head'), names.index('Jaw')
    replace_teeth(body, components(body.data), W, ih, ij)
    names, W = weights_of(body)
    ih, ij = names.index('Head'), names.index('Jaw')
    P = np.array([v.co[:] for v in body.data.vertices])
    comps = components(body.data)
    main = np.array(comps[0])
    share = W[main, ih] + W[main, ij]
    f = jaw_fraction(P[main])
    W[main, ij] = share * f
    W[main, ih] = share * (1 - f)
    rigid = int(sum((W[np.array(c), ij] > 0.5).sum() for c in comps[1:]))
    W = bk.limit_weights(W, 4)
    write_weights(body, names, W)
    bk.log(f'reweighted head: {int((W[main, ij] > 0.5).sum())} jaw-led mask verts, {rigid} lower-row teeth verts')
    # 3 - eyes: one object per eye + an "Eyes" material
    glow = bpy.data.objects.get(f'{ASSET}_Glow')
    if glow is not None:
        mat = glow.data.materials[0]
        mat.name = 'Eyes'
        bk.activate(glow)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.separate(type='LOOSE')
        bpy.ops.object.mode_set(mode='OBJECT')
        for o in [o for o in bpy.data.objects if o.name.startswith(f'{ASSET}_Glow')]:
            x = np.mean([v.co.x for v in o.data.vertices])
            o.name = o.data.name = 'EyeL' if x > 0 else 'EyeR'
    bpy.ops.wm.save_as_mainfile(filepath=BLEND, compress=True)
    bk.log('saved', BLEND)


# ---------------------------------------------------------------- measuring
def pose_jaw(arm, deg):
    pb = arm.pose.bones['Jaw']
    pb.rotation_mode = 'QUATERNION'
    pb.rotation_quaternion = Quaternion((1, 0, 0), math.radians(deg))  # local X
    for b in arm.pose.bones:
        if b.name != 'Jaw':
            b.rotation_quaternion = Quaternion()
            b.location = (0, 0, 0)
    if arm.animation_data:
        arm.animation_data.action = None
    bpy.context.view_layer.update()


def deformed(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = ev.to_mesh()
    P = np.array([v.co[:] for v in me.vertices])
    ev.to_mesh_clear()
    return P


def measure(arm, body, angles):
    """Chin travel and how deep jaw vertices sink into the neck / chest at each angle."""
    names, W = weights_of(body)
    main = np.zeros(len(body.data.vertices), bool)
    main[components(body.data)[0]] = True
    jaw = (W[:, names.index('Jaw')] > 0.9) & main
    rest = np.array([v.co[:] for v in body.data.vertices])
    chin = np.argmin(np.where(jaw & (rest[:, 1] < -0.15), rest[:, 2], 1e9))
    blockers = Scene([p for p in D.body_prims() if p.op == 'add' and p.bone in ('Neck', 'Chest', 'Clavicle_L',
                                                                                 'Clavicle_R')])
    rows = []
    for a in angles:
        pose_jaw(arm, a)
        P = deformed(body)
        d = blockers.eval(P[jaw])
        depth = float(max(0.0, -d.min()))
        rows.append((a, float(P[chin, 2] - rest[chin, 2]), float(P[chin, 1] - rest[chin, 1]), depth,
                     int((d < -0.01).sum())))
    pose_jaw(arm, 0)
    return rows


# ---------------------------------------------------------------- renders
def shots(arm, angles, path, views=('front', 'q', 'side'), size=520, label=''):
    for o in bpy.data.objects:
        if o.name.startswith('REV_') or o.get('station'):
            o.hide_render = True
    ctr = Vector((0, -0.18, 8.32))
    review._studio(ctr, 2.2)
    bk.set_world((0.30, 0.30, 0.32), 0.5)
    for m in ('EyeL', 'EyeR'):
        if m in bpy.data.objects:
            bpy.data.objects[m].hide_render = False
    cam = bk.make_camera('JawCam')
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = 1.45
    dirs = {'front': Vector((0, -1, 0.04)), 'q': Vector((-0.75, -1, 0.12)), 'side': Vector((-1, 0, 0.02))}
    tiles = []
    for a in angles:
        pose_jaw(arm, a)
        row = []
        for v in views:
            cam.location = ctr + dirs[v].normalized() * 30
            bk.look_at(cam, ctr)
            p = path + f'_{a}_{v}.png'
            bk.render(p, res=(size, size), samples=40)
            row.append(Image.open(p).convert('RGB'))
            os.remove(p)
        tiles.append((a, row))
    pose_jaw(arm, 0)
    top = 64
    W = len(views) * (size + 8) + 150
    H = top + len(tiles) * (size + 8)
    sheet = Image.new('RGB', (W, H), (22, 22, 24))
    d = ImageDraw.Draw(sheet)
    d.text((14, 16), label or 'AH_Ent_Dybbuk — Jaw', font=review.font(28, True), fill=(232, 228, 220))
    for r, (a, row) in enumerate(tiles):
        y = top + r * (size + 8)
        d.text((14, y + 12), f'{abs(a):g}°', font=review.font(34, True), fill=(232, 228, 220))
        for k, im in enumerate(row):
            sheet.paste(im, (150 + k * (size + 8), y))
    sheet.save(path + '.png')
    bk.log('  wrote', path + '.png')


def opening_sign(arm, body):
    """+1 if a positive rotation about the Jaw bone's local X drops the chin, else -1."""
    a, b = measure(arm, body, [10, -10])
    return 1 if a[1] < b[1] else -1


def stage_range():
    arm, body = load()
    os.makedirs(OUT, exist_ok=True)
    sgn = opening_sign(arm, body)
    print('OPENING SIGN (local X):', '+' if sgn > 0 else '-')
    rows = measure(arm, body, [sgn * a for a in (0, 8, 15, 20, 25, 30, 35, 40, 45)])
    print('angle  chin_dz  chin_dy  into_neck_depth  verts_inside')
    for a, dz, dy, depth, n in rows:
        print(f'{a:5.0f} {dz:8.3f} {dy:8.3f} {depth:14.3f} {n:8d}')
    shots(arm, [sgn * a for a in (0, 15, 25, 30, 35, 40)], os.path.join(OUT, '_range'),
          label='AH_Ent_Dybbuk — jaw range test')


def stage_final(max_deg):
    arm, body = load()
    os.makedirs(OUT, exist_ok=True)
    sgn = opening_sign(arm, body)
    sign = '+' if sgn > 0 else '−'
    shots(arm, [0, sgn * 8, sgn * max_deg], os.path.join(OUT, 'AH_Ent_Dybbuk_Jaw'), views=('front', 'q', 'side'),
          label=f'AH_Ent_Dybbuk — Jaw closed / 8° / {max_deg:g}° max (local X, {sign} opens)')
    meshes = [o for o in bpy.data.objects if o.type == 'MESH' and o.parent == arm]
    import json
    stats = json.load(open(os.path.join(OD, 'Source', 'stats.json')))
    clips = [(c, bpy.data.actions[f'{ASSET}_Anim_{c}']) for c in stats['clips']]
    bk.export_roblox(OD, ASSET, arm, meshes, clips, embed=True, unkeyed=('Jaw',))
    bpy.ops.wm.save_as_mainfile(filepath=BLEND, compress=True)


if __name__ == '__main__':
    stage = sys.argv[1]
    if stage == 'rig':
        stage_rig()
    elif stage == 'range':
        stage_range()
    elif stage == 'final':
        stage_final(float(sys.argv[2]))
