"""Review renders: reference sheet, flashlight mood shots, animation sheet."""
import math
import os

import bpy
import numpy as np
from mathutils import Vector
from PIL import Image, ImageDraw, ImageFont

import blendkit as bk

FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
FONT_B = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
if not os.path.exists(FONT_B):
    FONT_B = FONT


def font(sz, bold=False):
    return ImageFont.truetype(FONT_B if bold else FONT, sz)


def _set_pose(arm, action=None, frame=1):
    arm.animation_data.action = action
    if action is None:
        for pb in arm.pose.bones:
            pb.rotation_quaternion = (1, 0, 0, 0)
            pb.location = (0, 0, 0)
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()


def _hide_extras(show_floor=False):
    for o in bpy.data.objects:
        if o.name.startswith('REV_'):
            o.hide_render = not show_floor


def _floor(material_color=(0.05, 0.045, 0.04), rough=0.6, wall=False):
    if 'REV_Floor' not in bpy.data.objects:
        me = bpy.data.meshes.new('REV_Floor')
        s = 40
        me.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0)], [], [(0, 1, 2, 3)])
        fl = bk.link(bpy.data.objects.new('REV_Floor', me))
        mat = bpy.data.materials.new('REV_FloorMat')
        nk = bk.NodeKit(mat)
        n = nk.noise(nk.coord('Object'), 1.5, 6, 0.6)
        planks = nk.wave(nk.coord('Object'), 0.35, 6.0, 3.0, 'BANDS', 'X')
        col = nk.mix(0.5, nk.mix(n.outputs['Fac'], (0.05, 0.035, 0.025), (0.11, 0.08, 0.055)),
                     planks.outputs['Color'], 'MULTIPLY')
        bs = nk.node('ShaderNodeBsdfPrincipled')
        nk.set(bs.inputs['Base Color'], col)
        bs.inputs['Roughness'].default_value = rough
        out = nk.node('ShaderNodeOutputMaterial')
        nk.nt.links.new(bs.outputs[0], out.inputs['Surface'])
        me.materials.append(mat)
        # back wall
        me2 = bpy.data.meshes.new('REV_Wall')
        me2.from_pydata([(-s, 9, 0), (s, 9, 0), (s, 9, 20), (-s, 9, 20)], [], [(0, 1, 2, 3)])
        wl = bk.link(bpy.data.objects.new('REV_Wall', me2))
        m2 = bpy.data.materials.new('REV_WallMat')
        nk = bk.NodeKit(m2)
        n = nk.noise(nk.coord('Object'), 0.8, 8, 0.65)
        stripes = nk.wave(nk.coord('Object'), 1.2, 0.5, 1.0, 'BANDS', 'X')
        col = nk.mix(0.25, nk.mix(n.outputs['Fac'], (0.06, 0.07, 0.06), (0.14, 0.15, 0.12)),
                     stripes.outputs['Color'], 'MULTIPLY')
        bs = nk.node('ShaderNodeBsdfPrincipled')
        nk.set(bs.inputs['Base Color'], col)
        bs.inputs['Roughness'].default_value = 0.85
        out = nk.node('ShaderNodeOutputMaterial')
        nk.nt.links.new(bs.outputs[0], out.inputs['Surface'])
        me2.materials.append(m2)
    bpy.data.objects['REV_Wall'].hide_render = not wall


def _studio(center, height):
    bk.clear_lights()
    bk.set_world((0.42, 0.42, 0.43), 0.55)
    c = Vector(center)
    h = height
    bk.add_light('Key', 'AREA', c + Vector((-1.2 * h, -1.4 * h, 0.9 * h)), c, 2600 * (h / 8) ** 2, size=h * 0.8)
    bk.add_light('Fill', 'AREA', c + Vector((1.4 * h, -0.9 * h, 0.2 * h)), c, 700 * (h / 8) ** 2, size=h)
    bk.add_light('Rim', 'AREA', c + Vector((0.6 * h, 1.4 * h, 0.8 * h)), c, 1800 * (h / 8) ** 2, size=h * 0.6)


def reference_sheet(C, arm, meshes, out, stats):
    _set_pose(arm, None)
    _hide_extras(False)
    lo, hi = bk.bbox_world(meshes)
    ctr = (lo + hi) / 2
    H = hi[2] - min(lo[2], 0)
    W = max(hi[0] - lo[0], hi[1] - lo[1])
    _studio(ctr, max(H, W))
    cam = bk.make_camera('RefCam')
    cam.data.type = 'ORTHO'
    span = H * 1.10
    cam.data.ortho_scale = span
    zc = min(lo[2], 0) + span / 2 - 0.04 * span
    PH = 960
    views = []
    asset = f'AH_Ent_{C.NAME}'
    for label, d, ext in (('FRONT', (0, -1, 0), hi[0] - lo[0]), ('SIDE (left)', (1, 0, 0), hi[1] - lo[1]),
                          ('BACK', (0, 1, 0), hi[0] - lo[0])):
        pw = int(min(max(PH * (ext * 1.12) / span, 360), 1100))
        pw += pw % 2
        bk.render_size = (pw, PH)
        cam.data.sensor_fit = 'VERTICAL'
        cx = ctr[0] if d[0] == 0 else ctr[1]
        cam.location = Vector((ctr[0], ctr[1], zc)) + Vector(d) * 60
        bk.look_at(cam, (ctr[0], ctr[1], zc))
        cam.data.clip_end = 200
        p = os.path.join(out, f'_ref_{label.split()[0].lower()}.png')
        bk.render(p, res=(pw, PH), samples=40)
        views.append((label, p, pw))
    # composite
    px_per_stud = PH / span
    ground_y = PH - (min(lo[2], 0) - (zc - span / 2)) * px_per_stud
    pad, top = 30, 120
    lead = int(max(190, 4.3 * px_per_stud + 70))
    total_w = lead + sum(v[2] for v in views) + 20 * len(views) + pad
    sheet = Image.new('RGB', (max(total_w, 1500), PH + top + 230), (26, 26, 28))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 28), f'{asset}  —  reference sheet', font=font(40, True), fill=(235, 232, 225))
    d.text((pad, 80), C.TAGLINE, font=font(20), fill=(170, 168, 160))
    sil_x = int(lead / 2) - 10
    _draw_player(d, sil_x, ground_y + top, px_per_stud)
    d.text((sil_x - 50, ground_y + top + 10), 'player 5.5', font=font(16), fill=(150, 150, 150))
    x = lead
    for label, p, pw in views:
        im = Image.open(p).convert('RGB')
        sheet.paste(im, (x, top))
        d.text((x + 10, top + 8), label, font=font(22, True), fill=(30, 30, 30))
        x += pw + 20
    views = [(a, b) for a, b, _ in views]
    # stud ruler on the right edge of the front view
    rx = lead - 34
    for s in range(0, int(math.floor(H)) + 1):
        yy = top + ground_y - s * px_per_stud
        d.line([(rx, yy), (rx + (14 if s % 5 == 0 else 7), yy)], fill=(190, 190, 190), width=2)
        d.text((rx - 24, yy - 9), f'{s}', font=font(14), fill=(190, 190, 190))
    d.line([(rx, top + ground_y), (rx, top + ground_y - H * px_per_stud)], fill=(190, 190, 190), width=2)
    # info block
    yb = top + PH + 16
    sz = stats['size_studs']
    tris = ', '.join(f"{k.replace(asset, '').strip('_') or 'body'} {v['tris']:,}" for k, v in stats['meshes'].items())
    lines = [
        f"Size (W×H×D): {sz['width_x']} × {sz['height_z']} × {sz['depth_y']} studs   ·   "
        f"Triangles: {tris} = {sum(v['tris'] for v in stats['meshes'].values()):,} (budget 12,000)   ·   "
        f"Bones: {stats['bones']} ({stats['deform_bones']} deforming)",
        f"Textures: 1024² Color / Normal (OpenGL +Y) / Roughness / Metalness   ·   Glow parts: Neon {C.GLOW_NOTE}",
    ]
    lines += C.SHEET_NOTES
    for ln in lines:
        d.text((pad, yb), ln, font=font(18), fill=(205, 202, 195))
        yb += 30
    path = os.path.join(out, f'{asset}_RefSheet.png')
    sheet.save(path)
    for _, p in views:
        os.remove(p)
    bk.log('  ref sheet', path)
    return path


def _draw_player(d, cx, gy, s):
    """Simple 5.5-stud Roblox-ish block figure outline."""
    col = (95, 95, 100)
    leg_h, torso_h, head_h = 2.0 * s, 2.0 * s, 1.2 * s
    w = 2.0 * s
    d.rectangle([cx - w / 2, gy - leg_h, cx - 0.05 * s, gy], fill=col)
    d.rectangle([cx + 0.05 * s, gy - leg_h, cx + w / 2, gy], fill=col)
    d.rectangle([cx - w / 2, gy - leg_h - torso_h, cx + w / 2, gy - leg_h], fill=col)
    d.rectangle([cx - w / 2 - 1.0 * s, gy - leg_h - torso_h, cx - w / 2 - 0.05 * s, gy - leg_h], fill=col)
    d.rectangle([cx + w / 2 + 0.05 * s, gy - leg_h - torso_h, cx + w / 2 + 1.0 * s, gy - leg_h], fill=col)
    d.ellipse([cx - 0.6 * s, gy - 5.5 * s, cx + 0.6 * s, gy - leg_h - torso_h - 0.1 * s], fill=col)


def mood_shot(C, arm, meshes, clips, out):
    """Two in-game-like frames: flashlight from the player, lightning backlight."""
    asset = f'AH_Ent_{C.NAME}'
    clip, t = C.MOOD_POSE
    act = clips[clip]
    _set_pose(arm, act, 1 + int(round(t * act['frames'])))
    _floor(wall=True)
    bpy.data.objects['REV_Floor'].hide_render = False
    lo, hi = bk.bbox_world(meshes)
    ctr = (lo + hi) / 2
    H = hi[2]
    cam = bk.make_camera('MoodCam')
    cam.data.type = 'PERSP'
    cam.data.lens = 24
    dist = C.MOOD_DIST
    eye = Vector((ctr[0] + dist * 0.18, ctr[1] - dist, 4.6))
    cam.location = eye
    bk.look_at(cam, (ctr[0], ctr[1], H * 0.55))
    frames = []
    # 1 - flashlight
    bk.clear_lights()
    bk.set_world((0.01, 0.012, 0.018), 0.15)
    tgt = Vector((ctr[0], ctr[1], H * 0.6))
    bk.add_light('Flash', 'SPOT', eye + Vector((0.6, 0.3, -0.6)), tgt, 2600, spot=(34, 0.35), color=(1.0, 0.93, 0.8))
    bk.add_light('Moon', 'AREA', Vector((ctr[0] - 8, ctr[1] + 6, 12)), tgt, 300, size=3, color=(0.55, 0.65, 1.0))
    p1 = bk.render(os.path.join(out, '_mood1.png'), res=(720, 960), samples=64)
    frames.append(('FLASHLIGHT', p1))
    # 2 - lightning through a window behind
    bk.clear_lights()
    bk.set_world((0.006, 0.008, 0.012), 0.1)
    bpy.data.objects['REV_Wall'].hide_render = True
    bk.add_light('Bolt', 'AREA', Vector((ctr[0] + 1.5, ctr[1] + 7.0, H * 1.05)), Vector((ctr[0], ctr[1], H * 0.55)),
                 4200 * (H / 8) ** 2, size=4, color=(0.75, 0.82, 1.0))
    bk.add_light('Flash', 'SPOT', eye + Vector((0.6, 0.3, -0.6)), tgt + Vector((0, 0, -2.5)), 500, spot=(30, 0.4),
                 color=(1.0, 0.93, 0.8))
    p2 = bk.render(os.path.join(out, '_mood2.png'), res=(720, 960), samples=64)
    frames.append(('LIGHTNING (silhouette)', p2))
    sheet = Image.new('RGB', (720 * 2 + 30, 960 + 70), (12, 12, 14))
    d = ImageDraw.Draw(sheet)
    for i, (label, p) in enumerate(frames):
        sheet.paste(Image.open(p).convert('RGB'), (10 + i * 730, 60))
        d.text((14 + i * 730, 18), label, font=font(24, True), fill=(220, 215, 205))
        os.remove(p)
    path = os.path.join(out, f'{asset}_InGameLight.png')
    sheet.save(path)
    _hide_extras(False)
    bk.log('  mood', path)
    return path


def anim_sheet(C, arm, meshes, clips, out, per=6):
    asset = f'AH_Ent_{C.NAME}'
    _floor()
    _hide_extras(False)
    bpy.data.objects['REV_Floor'].hide_render = False
    _set_pose(arm, None)
    lo, hi = bk.bbox_world(meshes)
    ctr = (lo + hi) / 2
    H = hi[2]
    _studio(ctr, H)
    bk.set_world((0.32, 0.32, 0.34), 0.6)
    cam = bk.make_camera('AnimCam')
    cam.data.type = 'PERSP'
    cam.data.lens = 35
    span = max(H, hi[0] - lo[0], hi[1] - lo[1]) * C.ANIM_ZOOM
    dist = span * 1.45
    aim = Vector(getattr(C, 'ANIM_TARGET', (ctr[0], ctr[1], H * 0.47)))
    cam.location = aim + Vector((-dist * 0.62, -dist * 0.78, H * 0.08))
    bk.look_at(cam, aim)
    w, h = 240, 300
    rows = []
    for cname, act in clips:
        n = int(act['frames'])
        idx = [1 + round(i * (n - (0 if act['loop'] else 1)) / per) for i in range(per)] if act['loop'] else \
            [1 + round(i * (n) / (per - 1)) for i in range(per)]
        ims = []
        for k, f in enumerate(idx):
            _set_pose(arm, act, f)
            p = os.path.join(out, f'_a_{k}.png')
            bk.render(p, res=(w, h), samples=14)
            ims.append(Image.open(p).convert('RGB'))
            os.remove(p)
        rows.append((cname, act, idx, ims))
    lab = 210
    sheet = Image.new('RGB', (lab + per * (w + 6), len(rows) * (h + 6) + 60), (22, 22, 24))
    d = ImageDraw.Draw(sheet)
    d.text((12, 14), f'{asset} — animation clips (30 fps, in place)', font=font(26, True), fill=(230, 226, 220))
    for r, (cname, act, idx, ims) in enumerate(rows):
        y = 60 + r * (h + 6)
        d.text((12, y + 10), cname, font=font(20, True), fill=(230, 226, 220))
        d.text((12, y + 40), f"{int(act['frames'])} f · {act['frames']/30:.2f}s", font=font(16), fill=(160, 160, 160))
        d.text((12, y + 62), 'loop' if act['loop'] else 'one-shot', font=font(16), fill=(160, 160, 160))
        for k, im in enumerate(ims):
            sheet.paste(im, (lab + k * (w + 6), y))
            d.text((lab + k * (w + 6) + 6, y + 4), f'f{idx[k]}', font=font(13), fill=(40, 40, 40))
    path = os.path.join(out, f'{asset}_AnimSheet.png')
    sheet.save(path)
    _set_pose(arm, None)
    bk.log('  anim sheet', path)
    return path
