"""AH_Ent_Demon — the most hostile thing in the collection.

No single culture: a 'demon' in the broad European sense, pushed toward the
burnt and starved.  Charred skin split by ember cracks, goat legs on cloven
hooves, ribbed horns sweeping up, an elongated skull that is mostly teeth.
No religious symbols anywhere (the cross is the player's item, not ours).

Run:  python3 build_demon.py   (--preview for a quick sculpt check)
"""
import math
import sys

import numpy as np

sys.path.insert(0, __file__.rsplit('/', 1)[0])
import blendkit as bk  # noqa: E402
import motion as mo  # noqa: E402
from sdf import Prim, Scene, bezier, chain, v3  # noqa: E402

NAME = 'Demon'
TAGLINE = ('Charred, starved, 10 studs to the horn tips. Goat legs on cloven hooves, ember cracks in the skin, '
           'a skull that is mostly teeth. Hunts often; recoils hard from the crucifix.')
GLOW_COLOR = (1.0, 0.40, 0.06)
GLOW_STRENGTH = 7.0
GLOW_NOTE = 'eyes + throat ember: Neon #FF6610; optional Emissive map for the skin cracks'
MOOD_POSE = ('Idle', 0.25)
MOOD_DIST = 10.5
ANIM_ZOOM = 1.1
BAKE = {'extrusion': 0.035, 'ray': 0.12, 'samples': 6}
SHEET_NOTES = [
    'Read in the dark: horned silhouette first; ember cracks, eye slits and the throat glow mark it at range.',
    'Stands 10 studs to the horn tips in rest pose; every locomotion clip stoops it under 8.2 studs. '
    'Collision: 3×8×3 box, not walkable.',
]
PREVIEW_CLOSEUPS = [('head', (0, -1, 0.1), (0, -0.55, 8.45), 2.6), ('head3q', (-1, -0.7, 0.15), (0, -0.55, 8.45), 2.6),
                    ('hand', (0.2, -1, 0.3), (3.8, -0.1, 4.7), 2.4), ('leg', (1, -0.3, 0.1), (0.5, 0, 2.0), 4.6)]

# ------------------------------------------------------------------ skeleton
J = dict(root=v3(0, 0, 0), hrp=v3(0, 0.05, 4.55), pelvis=v3(0, 0.08, 4.45), waist=v3(0, 0.06, 5.25),
         chest=v3(0, 0.0, 6.05), neck=v3(0, -0.05, 7.20), head=v3(0, -0.32, 7.85), headtop=v3(0, -0.40, 8.80),
         jaw=v3(0, -0.30, 7.95), chin=v3(0, -1.05, 7.70))
SIDE = dict(clav=v3(0.12, -0.05, 7.05), shoulder=v3(1.00, 0.05, 7.05), elbow=v3(2.25, 0.22, 6.10),
            wrist=v3(3.30, 0.0, 5.12),
            hip=v3(0.45, 0.08, 4.38), knee=v3(0.52, -0.62, 3.00), hock=v3(0.54, 0.48, 1.55),
            ball=v3(0.55, 0.02, 0.18), tip=v3(0.56, -0.26, 0.0))


def S(key, s=1):
    p = SIDE[key].copy()
    p[0] *= s
    return p


def hand_frame(s=1):
    a = S('wrist', s) - S('elbow', s)
    a /= np.linalg.norm(a)
    n = v3(-0.6 * s, 0, -0.8)
    n = n - a * np.dot(n, a)
    n /= np.linalg.norm(n)
    sp = np.cross(a, n) * s
    return a, n, sp


def finger_points(s, idx):
    a, n, sp = hand_frame(s)
    knuck = S('wrist', s) + a * 0.42 + sp * (-0.15 + 0.15 * idx) + n * 0.01
    lens = [0.50, 0.42, 0.26] if idx != 1 else [0.56, 0.46, 0.28]
    d = a + sp * (-0.12 + 0.12 * idx)
    d /= np.linalg.norm(d)
    pts, ang = [knuck], 0.0
    for L, cdeg in zip(lens, (14, 24, 30)):
        ang += math.radians(cdeg)
        pts.append(pts[-1] + (d * math.cos(ang) + n * math.sin(ang)) * L)
    return pts


def thumb_points(s):
    a, n, sp = hand_frame(s)
    base = S('wrist', s) + a * 0.14 - sp * 0.12 + n * 0.04
    d = a * 0.5 + v3(0, -1, 0) * 0.7 + n * 0.2
    d /= np.linalg.norm(d)
    d2 = d * 0.7 + n * 0.7
    d2 /= np.linalg.norm(d2)
    return [base, base + d * 0.36, base + d * 0.36 + d2 * 0.3]


def bones():
    b = [
        dict(name='Root', head=J['root'], tail=J['root'] + v3(0, 0, 0.6), deform=False),
        dict(name='HumanoidRootPart', head=J['hrp'], tail=J['hrp'] + v3(0, 0, 0.5), parent='Root', deform=False),
        dict(name='Hips', head=J['pelvis'], tail=J['waist'], parent='HumanoidRootPart'),
        dict(name='Spine', head=J['waist'], tail=J['chest'], parent='Hips'),
        dict(name='Chest', head=J['chest'], tail=J['neck'], parent='Spine'),
        dict(name='Neck', head=J['neck'], tail=J['head'], parent='Chest'),
        dict(name='Head', head=J['head'], tail=J['headtop'], parent='Neck'),
        dict(name='Jaw', head=J['jaw'], tail=J['chin'], parent='Head', roll_to=(0, 0, 1)),
    ]
    for s, t in ((1, 'L'), (-1, 'R')):
        a, n, sp = hand_frame(s)
        b += [
            dict(name=f'Clavicle_{t}', head=S('clav', s), tail=S('shoulder', s), parent='Chest'),
            dict(name=f'UpperArm_{t}', head=S('shoulder', s), tail=S('elbow', s), parent=f'Clavicle_{t}'),
            dict(name=f'LowerArm_{t}', head=S('elbow', s), tail=S('wrist', s), parent=f'UpperArm_{t}'),
            dict(name=f'Hand_{t}', head=S('wrist', s), tail=S('wrist', s) + a * 0.42, parent=f'LowerArm_{t}',
                 roll_to=tuple(n)),
        ]
        for i, f in enumerate('ABC'):
            pts = finger_points(s, i)
            b.append(dict(name=f'Finger{f}1_{t}', head=pts[0], tail=pts[1], parent=f'Hand_{t}', roll_to=tuple(n)))
            b.append(dict(name=f'Finger{f}2_{t}', head=pts[1], tail=pts[3], parent=f'Finger{f}1_{t}', roll_to=tuple(n)))
        tp = thumb_points(s)
        b.append(dict(name=f'Thumb_{t}', head=tp[0], tail=tp[2], parent=f'Hand_{t}', roll_to=tuple(n)))
        b += [
            dict(name=f'UpperLeg_{t}', head=S('hip', s), tail=S('knee', s), parent='Hips'),
            dict(name=f'LowerLeg_{t}', head=S('knee', s), tail=S('hock', s), parent=f'UpperLeg_{t}'),
            dict(name=f'Foot_{t}', head=S('hock', s), tail=S('ball', s), parent=f'LowerLeg_{t}'),
            dict(name=f'Hoof_{t}', head=S('ball', s), tail=S('tip', s), parent=f'Foot_{t}', roll_to=(0, 0, 1)),
        ]
    return b


# ---------------------------------------------------------------- the sculpt
def _rot_to(d, axis='x'):
    d = v3(d) / np.linalg.norm(d)
    if axis == 'x':
        x = d
        y = np.cross(v3(0, 0, 1), x)
        if np.linalg.norm(y) < 1e-3:
            y = v3(0, 1, 0)
        y /= np.linalg.norm(y)
        z = np.cross(x, y)
    else:
        z = d
        x = np.cross(v3(0, 1, 0), z)
        x /= np.linalg.norm(x)
        y = np.cross(z, x)
    return np.stack([x, y, z], axis=1)


def L(a, b, t):
    return a + (b - a) * t


MOUTH = dict(z=7.82)


def mouth_arc(th, inset=0.0):
    """The grin runs along both sides of a long snout (th in -90..90)."""
    t = math.radians(th)
    rx, ry = 0.30 - inset, 0.70 - inset
    z = MOUTH['z'] + 0.20 * (abs(th) / 90) ** 2.2 - 0.06 * math.cos(t)
    return v3(rx * math.sin(t), -0.40 - ry * math.cos(t), z)


def horn_points(s):
    return bezier((0.24 * s, -0.42, 8.55), (0.90 * s, -0.25, 8.80), (1.40 * s, 0.15, 9.55), (0.88 * s, 0.10, 10.15), 10)


def body_prims():
    P = []
    # --- skull: long goat-like snout, heavy brow, back of the head swept up
    P.append(Prim('ellip', 'Head', k=0.0, region='skin', c=(0, -0.30, 8.30), r=(0.40, 0.48, 0.40)))
    P.append(Prim('cone', 'Head', k=0.14, region='skin', squash=(1.0, 0.85), a=(0, -0.45, 8.10), b=(0, -1.05, 7.86),
                  r1=0.30, r2=0.17, up=(0, 0, 1)))  # snout
    P.append(Prim('ellip', 'Head', k=0.1, region='skin', c=(0, -0.62, 8.42), r=(0.34, 0.12, 0.09)))  # brow
    for s in (1, -1):
        P.append(Prim('ellip', 'Head', k=0.06, region='skin', c=(0.30 * s, -0.52, 8.10), r=(0.08, 0.20, 0.07)))  # zygoma
        P.append(Prim('ellip', None, op='sub', k=0.05, c=(0.19 * s, -0.70, 8.30), r=(0.10, 0.07, 0.045),
                      rot=(0, 0, 20 * s)))  # slit sockets
    P.append(Prim('cone', 'Jaw', k=0.12, region='skin', squash=(1.0, 0.8), a=(0, -0.35, 7.72), b=(0, -1.0, 7.66),
                  r1=0.26, r2=0.14, up=(0, 0, 1)))
    P.append(Prim('ellip', 'Jaw', k=0.10, region='skin', c=(0, -0.25, 7.74), r=(0.32, 0.30, 0.16)))
    for th in np.linspace(-88, 88, 33):
        P.append(Prim('ellip', None, op='sub', k=0.015, c=mouth_arc(th, -0.02), r=(0.06, 0.10, 0.06),
                      rot=(0, 0, th)))
    P.append(Prim('cone', None, op='sub', k=0.05, a=(0, -0.35, MOUTH['z'] + 0.02), b=(0, -0.92, MOUTH['z'] + 0.02),
                  r1=0.20, r2=0.10))
    # nose pits
    for s in (1, -1):
        P.append(Prim('ellip', None, op='sub', k=0.02, c=(0.06 * s, -1.11, 7.97), r=(0.03, 0.03, 0.045)))
    # spine of the neck + ropey neck
    P.append(Prim('cone', 'Neck', k=0.12, region='skin', a=J['neck'] + v3(0, 0.05, -0.15), b=J['head'] + v3(0, 0.05, 0.1),
                  r1=0.26, r2=0.22))
    for s in (1, -1):
        P.append(Prim('cone', 'Neck', k=0.05, region='crack', a=(0.22 * s, -0.25, 8.0), b=(0.08 * s, -0.25, 7.05),
                      r1=0.05, r2=0.06))
    # --- torso: broad bony shoulders over a waist you could close a hand around
    P.append(Prim('ellip', 'Chest', k=0.12, region='crack', c=(0, 0.0, 6.55), r=(0.70, 0.46, 0.76)))
    P.append(Prim('ellip', 'Chest', k=0.14, region='skin', c=(0, 0.06, 7.02), r=(0.98, 0.40, 0.30)))
    P.append(Prim('cone', 'Spine', k=0.18, squash=(1.0, 0.75), region='skin', a=(0, 0.08, 5.0), b=(0, 0.05, 5.95),
                  r1=0.28, r2=0.36))
    P.append(Prim('ellip', 'Hips', k=0.16, region='skin', c=(0, 0.10, 4.55), r=(0.56, 0.34, 0.34)))
    P.append(Prim('ellip', None, op='sub', k=0.16, c=(0, -0.38, 5.45), r=(0.28, 0.16, 0.36)))
    for s, t in ((1, 'L'), (-1, 'R')):
        for i in range(7):
            z = 7.02 - i * 0.15
            w = 0.58 - abs(i - 2.5) * 0.025
            pts = [v3(0.05 * s, -0.40, z - 0.03), v3(0.30 * s, -0.36, z + 0.02), v3(w * s, -0.10, z + 0.1),
                   v3((w - 0.06) * s, 0.20, z + 0.15)]
            P += chain([p * v3(0.97, 0.97, 1) for p in pts], [0.024, 0.03, 0.03, 0.022], 'Chest', k=0.06)
        P.append(Prim('ellip', 'Chest', k=0.06, rot=(0, 0, 14 * s), c=(0.34 * s, 0.33, 6.85), r=(0.2, 0.06, 0.25)))
        P.append(Prim('ellip', 'Hips', k=0.04, c=(0.42 * s, -0.04, 4.78), r=(0.12, 0.09, 0.07)))
        P.append(Prim('cone', f'Clavicle_{t}', k=0.05, a=(0.06 * s, -0.30, 7.02), b=(0.88 * s, -0.06, 7.08),
                      r1=0.05, r2=0.06))
    for i in range(14):  # spine ridge with little spikes
        z = 4.75 + i * 0.19
        bone = 'Hips' if z < 5.25 else ('Spine' if z < 6.05 else 'Chest')
        P.append(Prim('cone', bone, k=0.04, region='horn', a=(0, 0.26 + 0.04 * math.sin(i), z),
                      b=(0, 0.42 + 0.03 * (i % 3), z + 0.08), r1=0.055, r2=0.012))
    # --- arms
    for s, t in ((1, 'L'), (-1, 'R')):
        sh, el, wr = S('shoulder', s), S('elbow', s), S('wrist', s)
        P.append(Prim('cone', f'Clavicle_{t}', k=0.12, a=(0.15 * s, 0.05, 7.25), b=sh + v3(-0.1 * s, 0, 0.06),
                      r1=0.17, r2=0.15))
        P.append(Prim('sphere', f'UpperArm_{t}', k=0.12, c=sh + v3(0.02 * s, 0, 0.02), r=0.25))
        P.append(Prim('cone', f'UpperArm_{t}', k=0.08, a=sh, b=el, r1=0.19, r2=0.115))
        P.append(Prim('ellip', f'UpperArm_{t}', k=0.05, c=L(sh, el, 0.42) + v3(0, -0.05, 0.03), r=(0.38, 0.1, 0.09),
                      rot=_rot_to(el - sh)))
        P.append(Prim('cone', f'LowerArm_{t}', k=0.03, region='horn', a=el + v3(0, 0.05, 0), b=el + v3(0.05 * s, 0.30, -0.05),
                      r1=0.08, r2=0.015))  # elbow spur
        P.append(Prim('cone', f'LowerArm_{t}', k=0.07, a=el, b=wr, r1=0.12, r2=0.075))
        P.append(Prim('ellip', f'LowerArm_{t}', k=0.05, c=L(el, wr, 0.3) + v3(0, -0.03, 0.03), r=(0.34, 0.09, 0.08),
                      rot=_rot_to(wr - el)))
        # --- goat legs
        hp, kn, hk, ba, tp = S('hip', s), S('knee', s), S('hock', s), S('ball', s), S('tip', s)
        P.append(Prim('cone', f'UpperLeg_{t}', k=0.16, a=hp, b=kn, r1=0.34, r2=0.17))
        P.append(Prim('ellip', f'UpperLeg_{t}', k=0.08, c=L(hp, kn, 0.35) + v3(0, -0.06, 0), r=(0.20, 0.18, 0.55),
                      rot=_rot_to(kn - hp, 'z')))
        P.append(Prim('sphere', f'LowerLeg_{t}', k=0.06, c=kn, r=0.15))
        P.append(Prim('cone', f'LowerLeg_{t}', k=0.06, a=kn, b=hk, r1=0.14, r2=0.10))
        P.append(Prim('ellip', f'LowerLeg_{t}', k=0.06, c=L(kn, hk, 0.3) + v3(0, 0.05, 0), r=(0.13, 0.14, 0.38),
                      rot=_rot_to(hk - kn, 'z')))
        P.append(Prim('sphere', f'Foot_{t}', k=0.05, c=hk + v3(0, 0.03, 0), r=0.10))
        P.append(Prim('cone', f'Foot_{t}', k=0.05, a=hk, b=ba, r1=0.09, r2=0.08))
        P.append(Prim('cone', f'Hoof_{t}', k=0.03, region='nail', squash=(1.0, 0.75), a=ba + v3(0, 0.05, 0.05),
                      b=tp + v3(0, 0, 0.04), r1=0.11, r2=0.04))
        P.append(Prim('box', None, op='sub', k=0.0, c=tp + v3(0, 0.0, 0.1), h=(0.012, 0.25, 0.2),
                      rot=(0, 0, 0)))  # cloven split
    return P


def hand_prims():
    P = []
    for s, t in ((1, 'L'), (-1, 'R')):
        a, n, sp = hand_frame(s)
        el, wr = S('elbow', s), S('wrist', s)
        P.append(Prim('cone', f'LowerArm_{t}', k=0.04, a=L(el, wr, 0.8), b=wr, r1=0.085, r2=0.075))
        P.append(Prim('cone', f'Hand_{t}', k=0.06, squash=(1.4, 0.55), up=tuple(n), a=wr + a * 0.04, b=wr + a * 0.38,
                      r1=0.08, r2=0.095))
        for i, f in enumerate('ABC'):
            pts = finger_points(s, i)
            P.append(Prim('sphere', f'Finger{f}1_{t}', k=0.03, c=pts[0], r=0.06))
            P += chain(pts[:2], [0.055, 0.048], f'Finger{f}1_{t}', k=0.025)
            P += chain(pts[1:], [0.048, 0.042, 0.036], f'Finger{f}2_{t}', k=0.02)
            P.append(Prim('sphere', f'Finger{f}2_{t}', k=0.02, c=pts[1], r=0.052))
            P.append(Prim('sphere', f'Finger{f}2_{t}', k=0.02, c=pts[2], r=0.046))
            d = pts[3] - pts[2]
            d /= np.linalg.norm(d)
            claw = bezier(pts[3] - d * 0.06, pts[3] + d * 0.18, pts[3] + d * 0.30 + n * 0.12, pts[3] + d * 0.30 + n * 0.30, 5)
            P += chain(claw, [0.042, 0.038, 0.03, 0.022, 0.012, 0.004], f'Finger{f}2_{t}', k=0.012, region='nail')
        tp = thumb_points(s)
        P += chain(tp, [0.055, 0.046, 0.038], f'Thumb_{t}', k=0.03)
        d = tp[2] - tp[1]
        d /= np.linalg.norm(d)
        P += chain([tp[2] - d * 0.04, tp[2] + d * 0.14, tp[2] + d * 0.2 + n * 0.1], [0.035, 0.022, 0.005],
                   f'Thumb_{t}', k=0.01, region='nail')
    return P


def horn_prims():
    P = []
    for s in (1, -1):
        pts = horn_points(s)
        n = len(pts)
        rad = [0.17 * (1 - i / (n - 1)) ** 0.8 + 0.012 for i in range(n)]
        P += chain(pts, rad, 'Head', k=0.03, region='horn')
        # growth rings
        for i in range(1, n - 2):
            for j in range(3):
                u = (j + 0.5) / 3
                c = pts[i] + (pts[i + 1] - pts[i]) * u
                r = rad[i] + (rad[i + 1] - rad[i]) * u
                ax = pts[i + 1] - pts[i]
                ax /= np.linalg.norm(ax)
                P.append(Prim('cone', 'Head', k=0.02, region='horn', a=c - ax * 0.025, b=c + ax * 0.025, r1=r * 1.10,
                              r2=r * 1.10))
        # root boss blending into the skull
        P.append(Prim('sphere', 'Head', k=0.08, region='horn', c=pts[0] + v3(0, 0, -0.05), r=0.19))
    return P


def teeth_prims():
    P = []
    rng = np.random.default_rng(5)
    for row, bone in ((1, 'Head'), (-1, 'Jaw')):
        for th in np.linspace(-84, 84, 29):
            j = rng.normal(0, 1, 2)
            edge = abs(th) / 84
            sz = 1.0 - 0.3 * (1 - edge)  # bigger toward the back: a predator's mouth
            base = mouth_arc(th, 0.05) + v3(0, 0, 0.07 * row)
            tip = mouth_arc(th + j[0], 0.01) + v3(0, 0, (0.02 + 0.03 * abs(j[1])) * -row)
            rad = (math.sin(math.radians(th)), -math.cos(math.radians(th)), 0)
            P.append(Prim('cone', bone, k=0.003, region='teeth', a=base, b=tip, up=rad, r1=0.032 * sz, r2=0.006,
                          squash=(1.0, 0.7)))
        pts = [mouth_arc(th, 0.07) + v3(0, 0, 0.08 * row) for th in np.linspace(-88, 88, 11)]
        P += chain(pts, [0.035] * 11, bone, k=0.02, region='gum')
    # fangs at the front
    for s in (1, -1):
        b = mouth_arc(8 * s, 0.05) + v3(0, 0, 0.07)
        P.append(Prim('cone', 'Head', k=0.003, region='teeth', a=b, b=b + v3(0.0, -0.03, -0.17), r1=0.04, r2=0.006))
    return P


def glow_prims():
    P = [Prim('ellip', 'Head', k=0.0, region='glow', c=(0.19 * s, -0.66, 8.30), r=(0.055, 0.03, 0.018),
              rot=(0, 0, 20 * s)) for s in (1, -1)]
    P.append(Prim('ellip', 'Head', k=0.0, region='glow', c=(0, -0.30, MOUTH['z'] + 0.01), r=(0.13, 0.12, 0.05)))
    return P


def pieces():
    body = Scene(body_prims())
    return [
        bk.Piece('body', body, tris=6600, voxel=0.022, falloff=0.08, lo_voxel=0.035),
        bk.Piece('hands', Scene(hand_prims()), tris=2000, voxel=0.012, falloff=0.035, lo_voxel=0.016),
        bk.Piece('horns', Scene(horn_prims()), tris=1300, voxel=0.012, rigid='Head', mat='skin'),
        bk.Piece('teeth', Scene(teeth_prims()), tris=1300, voxel=0.0065, mat='teeth', falloff=0.02),
        bk.Piece('glow', Scene(glow_prims()), tris=160, voxel=0.008, rigid='Head', group='glow', mat='teeth'),
    ]


# ----------------------------------------------------------------- materials
def mat_skin(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n1 = nk.noise(co, 2.2, 6, 0.6).outputs['Fac']
    char = nk.ramp(n1, [(0.35, (0.018, 0.014, 0.013)), (0.55, (0.04, 0.03, 0.026)), (0.75, (0.085, 0.07, 0.06))])
    ash = nk.maprange(nk.noise(co, 7.0, 6, 0.65).outputs['Fac'], 0.58, 0.72)
    col = nk.mix(nk.math('MULTIPLY', ash, 0.7), char, (0.20, 0.19, 0.18))  # ash flakes
    under = nk.maprange(nk.noise(co, 1.0, 3, 0.5).outputs['Fac'], 0.5, 0.7)
    col = nk.mix(nk.math('MULTIPLY', under, 0.5), col, (0.10, 0.025, 0.018))  # raw red-brown undertone
    # crack network (voronoi edges), strongest on the chest / throat region
    vo = nk.voronoi(nk.vmath('ADD', co, nk.vmath('MULTIPLY', nk.noise(co, 4.0, 2).outputs['Color'], (0.15, 0.15, 0.15))),
                    3.5, 'DISTANCE_TO_EDGE')
    edge = nk.maprange(vo.outputs['Distance'], 0.0, 0.022, 1.0, 0.0)
    patch = nk.maprange(nk.noise(co, 1.3, 3, 0.5).outputs['Fac'], 0.52, 0.66)
    crack_rg = nk.math('ADD', nk.math('MULTIPLY', nk.attr('rg_crack'), 0.9), nk.math('MULTIPLY', patch, 0.8))
    keep = nk.math('MULTIPLY', nk.math('SUBTRACT', 1.0, nk.attr('rg_horn')), nk.math('SUBTRACT', 1.0, nk.attr('rg_nail')))
    cr = nk.math('MULTIPLY', nk.math('MULTIPLY', edge, nk.math('MINIMUM', crack_rg, 1.0)), keep)
    col = nk.mix(cr, col, (0.95, 0.30, 0.04))
    horn = nk.attr('rg_horn')
    hcol = nk.ramp(nk.noise(co, 12.0, 4, 0.5).outputs['Fac'], [(0.3, (0.035, 0.03, 0.026)), (0.7, (0.16, 0.13, 0.10))])
    z = nk.node('ShaderNodeSeparateXYZ')
    nk.set(z.inputs[0], co)
    hcol = nk.mix(nk.maprange(z.outputs['Z'], 9.3, 10.1), hcol, (0.30, 0.27, 0.22))  # pale horn tips
    col = nk.mix(horn, col, hcol)
    nail = nk.attr('rg_nail')
    col = nk.mix(nail, col, (0.012, 0.01, 0.01))
    rough = nk.mixf(ash, 0.55, 0.85)
    rough = nk.mixf(cr, rough, 0.35)
    rough = nk.mixf(horn, rough, 0.45)
    rough = nk.mixf(nail, rough, 0.22)
    # bump: scaly leather + cracks sunk in + horn ridges
    sc = nk.voronoi(co, 26.0).outputs['Distance']
    wr = nk.noise(co, 18.0, 8, 0.65).outputs['Fac']
    h = nk.math('ADD', nk.math('MULTIPLY', sc, 0.5), nk.math('MULTIPLY', wr, 0.5))
    h = nk.math('SUBTRACT', h, nk.math('MULTIPLY', edge, 0.6))
    rings = nk.wave(co, 9.0, 3.0, 2.0, 'RINGS').outputs['Fac']
    h = nk.mixf(horn, h, nk.math('ADD', nk.math('MULTIPLY', rings, 0.6), nk.math('MULTIPLY', wr, 0.3)))
    nk.finish(col, rough, 0.0, nk.bump(h, 0.35, 0.01), emit_mask=cr)
    return mat


def mat_teeth(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n = nk.noise(co, 30.0, 4, 0.5).outputs['Fac']
    gum = nk.attr('rg_gum')
    col = nk.ramp(n, [(0.35, (0.30, 0.25, 0.15)), (0.65, (0.50, 0.44, 0.30))])
    col = nk.mix(gum, col, (0.12, 0.02, 0.01))
    rough = nk.mixf(gum, nk.maprange(n, 0.3, 0.7, 0.25, 0.4), 0.3)
    nk.finish(col, rough, 0.0, nk.bump(nk.noise(co, 80.0, 3, 0.5).outputs['Fac'], 0.15, 0.004),
              emit_mask=nk.math('MULTIPLY', gum, 0.5))
    return mat


MATERIALS = {'skin': mat_skin, 'teeth': mat_teeth}


# ----------------------------------------------------------------- animation
SIDES = (('L', 1), ('R', -1))


def mx(p, sgn):
    return (p[0] * sgn, p[1], p[2])


def fingers(curl, spread=0.0, thumb=None):
    p = {}
    for i, f in enumerate('ABC'):
        p[f'Finger{f}1_L'] = (0, curl, (i - 1) * spread)
        p[f'Finger{f}2_L'] = (0, curl * 1.2, 0)
    p['Thumb_L'] = (0, (thumb if thumb is not None else curl) * 0.6, 0)
    return bk.sym(p)


def legs(an, pose, balls, lift=None):
    """Digitigrade: IK hip->knee->hock to sit the hock above/behind the hoof ball."""
    for t, sgn in SIDES:
        ball = mo.Vector(balls[t])
        pitch = (lift or {}).get(t, 0.0)
        r = math.radians(pitch)
        hock = ball + mo.Vector((0, 0.46 * math.cos(r) - 1.37 * math.sin(r) * 0.25, 1.37 * math.cos(r) + 0.3 * math.sin(r)))
        mo.ik2(an, pose, f'UpperLeg_{t}', f'LowerLeg_{t}', hock, (0.15 * sgn, -1, 0.2))
        an.aim(pose, f'Foot_{t}', ball - an.world_head(pose, f'Foot_{t}'))
        q = an.delta(pose, f'Foot_{t}')
        pose[f'Hoof_{t}'] = q.inverted() @ bk.Q((pitch * 0.6, 0, 0))
    return pose


def ball(t, x=0.0, y=0.0, z=0.0):
    b = SIDE['ball']
    return (b[0] * (1 if t == 'L' else -1) + x, b[1] + y, b[2] + z)


def arms_hang(an, pose, swing=0.0, out=0.35, fwd=0.0, curl=20):
    for t, sgn in SIDES:
        sw = swing if t == 'L' else -swing
        an.aim(pose, f'UpperArm_{t}', (out * sgn, -0.15 + fwd + sw, -1))
        an.aim(pose, f'LowerArm_{t}', (0.18 * sgn, -0.45 + fwd * 1.3 + sw * 1.2, -1))
        an.aim(pose, f'Hand_{t}', (0.05 * sgn, -0.5 + fwd + sw, -1))
    pose.update(fingers(curl))
    return pose


def arms_ik(an, pose, wrists, poles=None, hand_dir=None):
    for t, sgn in SIDES:
        mo.ik2(an, pose, f'UpperArm_{t}', f'LowerArm_{t}', mo.Vector(wrists[t]),
               poles[t] if poles else (sgn, 0.6, -0.4))
        if hand_dir:
            an.aim(pose, f'Hand_{t}', mx(hand_dir, sgn))
    return pose


def hunch(pose, bow, look=0.0, twist=0.0, roll=0.0):
    pose['Hips'] = (bow * 0.2, 0, twist * 0.3)
    pose['Spine'] = (bow * 0.4, roll * 0.3, twist * 0.4)
    pose['Chest'] = (bow * 0.5, roll * 0.4, twist * 0.5)
    pose['Neck'] = (bow * 0.2 - look * 0.4, 0, 0)
    pose['Head'] = (-bow * 0.9 - look * 0.6, roll, 0)
    return pose


def clips(an):
    out = []

    def stand(bow=24, drop=-0.35, look=0.0):
        p = {'@root': (0, 0, drop)}
        hunch(p, bow, look)
        p['Clavicle_L'] = (0, -8, 0)
        p['Clavicle_R'] = bk.mirror_q(bk.Q((0, -8, 0)))
        arms_hang(an, p, out=0.42, fwd=0.15)
        legs(an, p, {'L': ball('L', 0.06, 0.05), 'R': ball('R', -0.06, -0.05)})
        return p

    # ---- Idle: heavy breathing through the teeth, claws flexing, a jaw snap
    def idle(t):
        br = mo.s(2 * t)
        p = {'@root': (0.05 * mo.s(t), 0, -0.35 + 0.04 * br)}
        hunch(p, 24 + 3 * br, look=4 * mo.s(t + 0.3), twist=6 * mo.s(t), roll=10 * mo.s(t + 0.1))
        p['Clavicle_L'] = (0, -8 - 3 * br, 0)
        p['Clavicle_R'] = bk.mirror_q(bk.Q((0, -8 - 3 * br, 0)))
        arms_hang(an, p, swing=0.04 * mo.s(t), out=0.42, fwd=0.15)
        for i, f in enumerate('ABC'):
            c = 22 + 16 * mo.s(2 * t + i * 0.1)
            p[f'Finger{f}1_L'] = (0, c, 0)
            p[f'Finger{f}2_L'] = (0, c * 1.2, 0)
            c2 = 22 + 16 * mo.s(2 * t + 0.4 + i * 0.1)
            p[f'Finger{f}1_R'] = bk.mirror_q(bk.Q((0, c2, 0)))
            p[f'Finger{f}2_R'] = bk.mirror_q(bk.Q((0, c2 * 1.2, 0)))
        p['Jaw'] = (8 + 6 * br + 22 * mo.twitch(t, 0.7, 0.04), 0, 0)
        legs(an, p, {'L': ball('L', 0.06, 0.05), 'R': ball('R', -0.06, -0.05)})
        return p
    out.append(('Idle', 120, idle, True))

    # ---- Walk: predatory stalk, head level, shoulders rolling
    def walk(t):
        yL, zL, sL = mo.foot_cycle(t, 2.1, 0.5, 0.6)
        yR, zR, sR = mo.foot_cycle(t + 0.5, 2.1, 0.5, 0.6)
        p = {'@root': (0.08 * mo.s(t), 0, -0.50 + 0.10 * mo.c(2 * t))}
        hunch(p, 30, look=6, twist=12 * mo.c(t))
        p['Hips'] = (6, 3 * mo.s(t), -10 * mo.c(t))
        arms_hang(an, p, swing=0.35 * mo.c(t), out=0.45, fwd=0.25, curl=26)
        p['Jaw'] = (10 + 4 * mo.s(2 * t), 0, 0)
        legs(an, p, {'L': ball('L', 0, yL, zL), 'R': ball('R', 0, yR, zR)},
             {'L': -30 * math.sin(math.pi * sL) if zL > 0 else 0, 'R': -30 * math.sin(math.pi * sR) if zR > 0 else 0})
        return p
    out.append(('Walk', 42, walk, True))

    # ---- Run (hunt): bent low, claws forward, long bounding strides
    def run(t):
        yL, zL, sL = mo.foot_cycle(t, 3.6, 1.0, 0.42)
        yR, zR, sR = mo.foot_cycle(t + 0.5, 3.6, 1.0, 0.42)
        p = {'@root': (0.1 * mo.s(t), 0, -1.05 + 0.25 * mo.c(2 * t + 0.15))}
        hunch(p, 52, look=26, twist=14 * mo.c(t))
        p['Hips'] = (18, 3 * mo.s(t), -14 * mo.c(t))
        p['Jaw'] = (26 + 8 * mo.s(2 * t), 0, 0)
        for tt, sgn in SIDES:
            ph = mo.c(t) if tt == 'L' else -mo.c(t)
            an.aim(p, f'UpperArm_{tt}', (0.4 * sgn, -0.8 - 0.6 * ph, -0.55 + 0.3 * ph))
            an.aim(p, f'LowerArm_{tt}', (0.15 * sgn, -1.0 - 0.3 * ph, -0.5 + 0.4 * ph))
            an.aim(p, f'Hand_{tt}', (0.05 * sgn, -1.0, -0.4))
        p.update(fingers(-4, 12, 0))
        legs(an, p, {'L': ball('L', 0, 0.3 + yL, zL), 'R': ball('R', 0, 0.3 + yR, zR)},
             {'L': -45 * math.sin(math.pi * sL) if zL > 0 else 0, 'R': -45 * math.sin(math.pi * sR) if zR > 0 else 0})
        return p
    out.append(('Run', 21, run, True))

    st = stand()

    # ---- Attack: rear up, both claws slash down across the target
    def k_rear():
        p = {'@root': (0, 0.4, -0.15)}
        hunch(p, -8, look=-10)
        p['Jaw'] = (40, 0, 0)
        p.update(fingers(-10, 14, -8))
        arms_ik(an, p, {'L': (1.6, 0.6, 9.0), 'R': (-1.6, 0.6, 9.0)}, hand_dir=(0.2, 0.2, 1))
        legs(an, p, {'L': ball('L', 0.1, 0.5), 'R': ball('R', -0.1, -0.4)})
        return p

    def k_slash():
        p = {'@root': (0, -0.9, -1.2)}
        hunch(p, 48, look=20)
        p['Jaw'] = (30, 0, 0)
        p.update(fingers(10, 6, 0))
        arms_ik(an, p, {'L': (-0.4, -2.6, 3.0), 'R': (0.4, -2.6, 2.6)}, hand_dir=(0, -0.5, -1))
        legs(an, p, {'L': ball('L', 0.1, -1.2), 'R': ball('R', -0.1, 0.9)})
        return p
    out.append(('Attack', 39, bk.track([(0, st), (0.35, k_rear()), (0.48, k_slash(), 'snap'), (0.7, k_slash()),
                                        (1.0, st)]), False))

    # ---- Roar: rears back, arms thrown wide, jaw unhinged, head shaking
    def k_roar(shake=0.0):
        p = {'@root': (0, 0.35, -0.2)}
        hunch(p, -14, look=-26, roll=shake * 12)
        p['Head'] = bk.pose_mul({'Head': p['Head']}, {'Head': (0, 0, shake * 14)})['Head']
        p['Jaw'] = (55, 0, 0)
        p.update(fingers(-14, 18, -10))
        arms_ik(an, p, {'L': (3.1, 0.4, 7.4), 'R': (-3.1, 0.4, 7.4)}, hand_dir=(1, 0.2, 0.5))
        legs(an, p, {'L': ball('L', 0.2, 0.3), 'R': ball('R', -0.2, 0.0)})
        return p
    seq = [(0, st), (0.2, k_roar())]
    for i in range(8):
        seq.append((0.26 + i * 0.07, k_roar((1 if i % 2 else -1) * (1 - i / 9))))
    seq += [(0.86, k_roar()), (1.0, st)]
    out.append(('Roar', 60, bk.track(seq), False))

    # ---- RepelledCross: flinches from the crucifix, arm over its face, staggers back
    def k_flinch():
        p = {'@root': (0, 0.8, -0.6)}
        hunch(p, 30, look=-10, twist=-30, roll=-20)
        p['Jaw'] = (44, 0, 0)
        p.update(fingers(30, 10, 20))
        hd = an.world_head(p, 'Head')
        arms_ik(an, p, {'L': (hd[0] + 0.3, hd[1] - 0.9, hd[2] - 0.2), 'R': (-2.4, 1.0, 5.2)},
                poles={'L': (1, -0.2, -1), 'R': (-1, 0.5, -0.3)}, hand_dir=(-0.6, -0.3, 0.5))
        legs(an, p, {'L': ball('L', 0.1, 1.1), 'R': ball('R', -0.2, 0.6)})
        return p

    def k_cower():
        p = k_flinch()
        p['@root'] = (0, 1.4, -1.3)
        hunch(p, 46, look=-6, twist=-36, roll=-24)
        hd = an.world_head(p, 'Head')
        arms_ik(an, p, {'L': (hd[0] + 0.25, hd[1] - 0.8, hd[2] - 0.1), 'R': (-2.0, 1.6, 4.4)},
                poles={'L': (1, -0.2, -1), 'R': (-1, 0.5, -0.3)}, hand_dir=(-0.6, -0.3, 0.5))
        legs(an, p, {'L': ball('L', 0.1, 1.5), 'R': ball('R', -0.2, 1.1)})
        return p
    out.append(('RepelledCross', 45, bk.track([(0, st), (0.12, k_flinch(), 'snap'), (0.55, k_cower()),
                                               (0.8, k_cower()), (1.0, k_cower())]), False))

    # ---- Manifest: uncurls from a crouched knot, horns rising last
    def k_knot():
        p = {'@root': (0, 0.4, -3.2)}
        hunch(p, 80, look=-40)
        p['Head'] = (80, 0, 0)
        p.update(fingers(50, 0, 30))
        arms_ik(an, p, {'L': (0.9, -0.9, 1.0), 'R': (-0.9, -0.9, 1.0)}, hand_dir=(0, 0, -1))
        legs(an, p, {'L': ball('L', 0.3, 0.3), 'R': ball('R', -0.3, 0.3)})
        return p

    def k_half():
        p = {'@root': (0, 0.3, -1.8)}
        hunch(p, 60, look=0, roll=25)
        p.update(fingers(30))
        arms_ik(an, p, {'L': (1.4, -1.2, 1.4), 'R': (-1.6, -0.8, 1.6)}, hand_dir=(0, 0, -1))
        legs(an, p, {'L': ball('L', 0.2, 0.1), 'R': ball('R', -0.2, 0.3)})
        return p
    out.append(('Manifest', 60, bk.track([(0, k_knot()), (0.15, k_knot()), (0.45, k_half()), (0.55, k_half()),
                                          (0.85, st, 'snap'), (1.0, st)]), False))

    def k_sink():
        p = k_knot()
        p['@root'] = (0, 0.4, -4.4)
        return p
    out.append(('Vanish', 36, bk.track([(0, st), (0.3, k_half()), (1.0, k_sink(), 'in')]), False))
    return out


if __name__ == '__main__':
    import pipeline
    pipeline.build(sys.modules[__name__])
