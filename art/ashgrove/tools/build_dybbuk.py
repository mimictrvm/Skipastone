"""AH_Ent_Dybbuk — the thing that came out of the box in the cellar vault.

Folklore: in Ashkenazi Jewish folklore a dybbuk is a dislocated, malicious
soul that cannot move on and clings to the living (possession).  Our take:
a starved, too-tall grey figure on stilt legs that end in points, with a
soot-black head that is nothing but a grin.  No religious symbols anywhere.

Run:  python3 build_dybbuk.py   (add --preview for a quick sculpt check)
"""
import math
import sys

import numpy as np

sys.path.insert(0, __file__.rsplit('/', 1)[0])
import blendkit as bk  # noqa: E402
import motion as mo  # noqa: E402
from sdf import Prim, Scene, bezier, chain, v3  # noqa: E402

NAME = 'Dybbuk'
TAGLINE = ('Starved stilt-legged figure, 9 studs tall. Soot-black head that is only a grin. '
           'Throws corpses; stunned the first time a music box plays.')
GLOW_COLOR = (1.0, 0.82, 0.55)
GLOW_STRENGTH = 4.0
GLOW_NOTE = 'eyes: pinpricks, Neon #FFD18C, add a 2-stud dim PointLight on Head'
MOOD_POSE = ('Idle', 0.35)
MOOD_DIST = 10.0
ANIM_ZOOM = 1.0
BAKE = {'extrusion': 0.035, 'ray': 0.12, 'samples': 6}
PREVIEW_CLOSEUPS = [('head', (0, -1, 0.05), (0, -0.2, 8.45), 1.5), ('head3q', (-0.8, -1, 0.1), (0, -0.2, 8.45), 1.5),
                    ('hand', (0.2, -1, 0.3), (3.95, -0.1, 4.95), 2.2), ('cloth', (-0.5, -1, 0.1), (0, 0, 4.8), 2.0)]
SHEET_NOTES = [
    'Read in the dark: pale ash body vs. black head; the grin and the two pinprick eyes are the only things lit at range.',
    'Legs end in spikes (no feet) — footstep audio should be a sharp tap. Collision: 2×9×2 box, not walkable.',
]

# ------------------------------------------------------------------ skeleton
J = dict(
    root=v3(0, 0, 0),
    hrp=v3(0, 0.02, 5.05),
    pelvis=v3(0, 0.03, 4.98),
    waist=v3(0, 0.03, 5.62),
    chest=v3(0, 0.0, 6.40),
    neck=v3(0, 0.02, 7.38),
    head=v3(0, -0.06, 7.92),
    headtop=v3(0, -0.08, 9.02),
    jaw=v3(0, -0.04, 8.26),
    chin=v3(0, -0.40, 8.02),
)
SIDE = dict(
    clav=v3(0.10, -0.06, 7.28),
    shoulder=v3(0.78, 0.02, 7.30),
    elbow=v3(2.20, 0.10, 6.38),
    wrist=v3(3.48, -0.02, 5.50),
    hip=v3(0.36, 0.03, 4.95),
    knee=v3(0.46, -0.16, 2.75),
    ankle=v3(0.50, 0.04, 1.05),
    tip=v3(0.52, 0.10, 0.0),
)


def S(key, s=1):
    p = SIDE[key].copy()
    p[0] *= s
    return p


def hand_frame(s=1):
    a = S('wrist', s) - S('elbow', s)
    a /= np.linalg.norm(a)
    n = v3(-0.57 * s, 0, -0.82)  # palm normal (down / in)
    n = n - a * np.dot(n, a)
    n /= np.linalg.norm(n)
    sp = np.cross(a, n) * s  # spread axis, points to the creature's back (+Y) on both sides
    return a, n, sp


def finger_points(s, idx):
    """Knuckle-to-tip points of finger idx (0 front .. 2 back) on side s."""
    a, n, sp = hand_frame(s)
    wrist = S('wrist', s)
    knuck = wrist + a * 0.40 + sp * (-0.13 + 0.13 * idx) + n * 0.01
    lens = [0.52, 0.46, 0.30] if idx != 1 else [0.58, 0.50, 0.32]
    curl = [12, 22, 30]
    pts = [knuck]
    d = a + sp * (-0.10 + 0.10 * idx)
    d /= np.linalg.norm(d)
    ang = 0
    for L, cdeg in zip(lens, curl):
        ang += math.radians(cdeg)
        di = d * math.cos(ang) + n * math.sin(ang)
        pts.append(pts[-1] + di * L)
    return pts


def thumb_points(s):
    a, n, sp = hand_frame(s)
    wrist = S('wrist', s)
    base = wrist + a * 0.12 - sp * 0.10 + n * 0.03
    d = a * 0.55 + v3(0, -1, 0) * 0.65 + n * 0.25
    d /= np.linalg.norm(d)
    d2 = d * 0.8 + n * 0.6
    d2 /= np.linalg.norm(d2)
    return [base, base + d * 0.34, base + d * 0.34 + d2 * 0.30]


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
        b += [
            dict(name=f'Clavicle_{t}', head=S('clav', s), tail=S('shoulder', s), parent='Chest'),
            dict(name=f'UpperArm_{t}', head=S('shoulder', s), tail=S('elbow', s), parent=f'Clavicle_{t}'),
            dict(name=f'LowerArm_{t}', head=S('elbow', s), tail=S('wrist', s), parent=f'UpperArm_{t}'),
        ]
        a, n, sp = hand_frame(s)
        b.append(dict(name=f'Hand_{t}', head=S('wrist', s), tail=S('wrist', s) + a * 0.40,
                      parent=f'LowerArm_{t}', roll_to=tuple(n)))
        for i, f in enumerate('ABC'):
            pts = finger_points(s, i)
            b.append(dict(name=f'Finger{f}1_{t}', head=pts[0], tail=pts[1], parent=f'Hand_{t}', roll_to=tuple(n)))
            b.append(dict(name=f'Finger{f}2_{t}', head=pts[1], tail=pts[3], parent=f'Finger{f}1_{t}',
                          roll_to=tuple(n)))
        tp = thumb_points(s)
        b.append(dict(name=f'Thumb_{t}', head=tp[0], tail=tp[2], parent=f'Hand_{t}', roll_to=tuple(n)))
        b += [
            dict(name=f'UpperLeg_{t}', head=S('hip', s), tail=S('knee', s), parent='Hips'),
            dict(name=f'LowerLeg_{t}', head=S('knee', s), tail=S('ankle', s), parent=f'UpperLeg_{t}'),
            dict(name=f'Spike_{t}', head=S('ankle', s), tail=S('tip', s), parent=f'LowerLeg_{t}'),
        ]
    return b


# ---------------------------------------------------------------- the sculpt
MOUTH_Z = 8.17


def mouth_arc(theta_deg, inset=0.0):
    th = math.radians(theta_deg)
    rx, ry = 0.30 - inset, 0.37 - inset
    z = MOUTH_Z + 0.24 * (abs(theta_deg) / 86.0) ** 2.4
    return v3(rx * math.sin(th), -0.06 - ry * math.cos(th), z)


def body_prims():
    P = []
    # --- head: long, narrow, gaunt; the grin takes the lower half
    P.append(Prim('ellip', 'Head', k=0.0, region='head', c=(0, -0.02, 8.58), r=(0.35, 0.42, 0.58)))
    P.append(Prim('ellip', 'Head', k=0.12, region='head', c=(0, -0.13, 8.36), r=(0.31, 0.32, 0.42)))
    P.append(Prim('ellip', 'Jaw', k=0.10, region='head', c=(0, -0.17, 8.02), r=(0.24, 0.24, 0.15)))
    P.append(Prim('ellip', 'Jaw', k=0.08, region='head', c=(0, -0.30, 7.93), r=(0.10, 0.09, 0.06)))  # chin
    for s in (1, -1):
        P.append(Prim('ellip', 'Head', k=0.09, region='head', c=(0.22 * s, -0.36, 8.48), r=(0.07, 0.05, 0.05)))
        P.append(Prim('ellip', None, op='sub', k=0.08, c=(0.31 * s, -0.33, 8.30), r=(0.06, 0.06, 0.12)))
    # deep, narrow, slightly uneven eye sockets
    for s, dz in ((1, 0.012), (-1, -0.006)):
        P.append(Prim('ellip', None, op='sub', k=0.05, c=(0.14 * s, -0.47, 8.62 + dz), r=(0.07, 0.10, 0.045),
                      rot=(0, 0, -8 * s)))
    # grin: slit along the arc + a cavity behind it
    for th in np.linspace(-86, 86, 35):
        P.append(Prim('ellip', None, op='sub', k=0.015, c=mouth_arc(th, -0.02), r=(0.055, 0.11, 0.062),
                      rot=(0, 0, th)))
    P.append(Prim('ellip', None, op='sub', k=0.04, c=(0, -0.14, MOUTH_Z + 0.04), r=(0.24, 0.24, 0.09)))
    # --- neck + tendons
    P += chain([J['neck'] + v3(0, 0, -0.1), J['head'] + v3(0, -0.02, 0.15)], [0.15, 0.125], 'Neck', k=0.08)
    for s in (1, -1):
        P.append(Prim('cone', 'Neck', k=0.05, a=(0.19 * s, -0.02, 8.12), b=(0.05 * s, -0.20, 7.30), r1=0.04, r2=0.035))
    # --- torso: starved
    P.append(Prim('ellip', 'Chest', k=0.12, c=(0, -0.01, 6.62), r=(0.50, 0.34, 0.66)))
    P.append(Prim('ellip', 'Chest', k=0.10, c=(0, 0.03, 7.12), r=(0.62, 0.30, 0.22)))  # shoulder girdle
    P.append(Prim('cone', 'Spine', k=0.14, squash=(1.0, 0.72), a=(0, 0.04, 5.30), b=(0, 0.02, 6.10), r1=0.27, r2=0.31))
    P.append(Prim('ellip', 'Hips', k=0.12, c=(0, 0.04, 5.08), r=(0.42, 0.26, 0.27)))
    P.append(Prim('ellip', None, op='sub', k=0.16, c=(0, -0.43, 5.70), r=(0.30, 0.17, 0.32)))  # sunken belly
    for s in (1, -1):
        P.append(Prim('ellip', 'Hips', k=0.04, c=(0.35 * s, -0.08, 5.27), r=(0.11, 0.08, 0.06)))  # iliac crest
        P.append(Prim('ellip', 'Hips', k=0.10, c=(0.22 * s, 0.13, 4.93), r=(0.20, 0.16, 0.21)))   # glutes
        P.append(Prim('ellip', 'Chest', k=0.06, rot=(0, 0, 12 * s), c=(0.28 * s, 0.30, 6.95),
                      r=(0.17, 0.05, 0.21)))  # shoulder blades
        # clavicles
        P.append(Prim('cone', f'Clavicle_{"L" if s > 0 else "R"}', k=0.05,
                      a=(0.05 * s, -0.26, 7.24), b=(0.70 * s, -0.04, 7.34), r1=0.045, r2=0.05))
        # ribs: slope down toward the sternum
        for i in range(7):
            z = 6.98 - i * 0.135
            w = 0.47 - abs(i - 2.5) * 0.02
            pts = [v3(0.04 * s, -0.33 + i * 0.006, z - 0.02), v3(0.26 * s, -0.29, z + 0.03),
                   v3(w * s, -0.08, z + 0.10), v3((w - 0.05) * s, 0.16, z + 0.15)]
            pts = [p * v3(0.97, 0.97, 1) for p in pts]
            P += chain(pts, [0.022, 0.027, 0.027, 0.02], 'Chest', k=0.06)
    for i in range(12):  # spine knobs
        z = 5.25 + i * 0.17
        P.append(Prim('sphere', 'Spine' if z < 6.4 else 'Chest', k=0.05, c=(0, 0.29 - 0.03 * abs(i - 6) / 6, z),
                      r=0.045))
    # --- arms
    for s, t in ((1, 'L'), (-1, 'R')):
        sh, el, wr = S('shoulder', s), S('elbow', s), S('wrist', s)
        P.append(Prim('cone', f'Clavicle_{t}', k=0.10, a=(0.12 * s, 0.02, 7.40), b=sh + v3(-0.1 * s, 0, 0.05),
                      r1=0.13, r2=0.12))  # trapezius
        P.append(Prim('sphere', f'UpperArm_{t}', k=0.08, c=sh + v3(0.02 * s, 0, 0), r=0.16))
        P.append(Prim('cone', f'UpperArm_{t}', k=0.07, a=sh, b=el, r1=0.14, r2=0.095))
        P.append(Prim('ellip', f'UpperArm_{t}', k=0.05, c=bk_l(sh, el, 0.45) + v3(0, -0.04, 0.02),
                      r=(0.32, 0.09, 0.08), rot=_rot_to(el - sh)))  # stringy bicep
        P.append(Prim('sphere', f'LowerArm_{t}', k=0.05, c=el + v3(0, 0.05, 0.02), r=0.10))  # elbow knob
        P.append(Prim('cone', f'LowerArm_{t}', k=0.06, a=el, b=wr, r1=0.105, r2=0.065))
        P.append(Prim('ellip', f'LowerArm_{t}', k=0.05, c=bk_l(el, wr, 0.3) + v3(0, -0.03, 0.02),
                      r=(0.30, 0.075, 0.07), rot=_rot_to(wr - el)))
        # --- legs
        hp, kn, an, tp = S('hip', s), S('knee', s), S('ankle', s), S('tip', s)
        P.append(Prim('cone', f'UpperLeg_{t}', k=0.10, a=hp, b=kn, r1=0.21, r2=0.12))
        P.append(Prim('ellip', f'UpperLeg_{t}', k=0.06, c=bk_l(hp, kn, 0.35) + v3(0, -0.05, 0),
                      r=(0.13, 0.11, 0.55), rot=_rot_to(kn - hp, 'z')))
        P.append(Prim('sphere', f'LowerLeg_{t}', k=0.06, c=kn + v3(0, -0.04, 0), r=0.125))  # knee
        P.append(Prim('cone', f'LowerLeg_{t}', k=0.05, a=kn, b=an, r1=0.115, r2=0.075))
        P.append(Prim('cone', f'Spike_{t}', k=0.05, a=an, b=tp, r1=0.078, r2=0.012, region='nail'))
    return P


def _rot_to(d, axis='x'):
    """Rotation matrix whose local `axis` points along d."""
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


def bk_l(a, b, t):
    return a + (b - a) * t


def hand_prims():
    P = []
    for s, t in ((1, 'L'), (-1, 'R')):
        a, n, sp = hand_frame(s)
        el, wr = S('elbow', s), S('wrist', s)
        P.append(Prim('cone', f'LowerArm_{t}', k=0.04, a=bk_l(el, wr, 0.82), b=wr, r1=0.075, r2=0.066))
        P.append(Prim('cone', f'Hand_{t}', k=0.06, squash=(1.35, 0.55), up=tuple(n),
                      a=wr + a * 0.04, b=wr + a * 0.36, r1=0.075, r2=0.085))
        for i, f in enumerate('ABC'):
            pts = finger_points(s, i)
            P.append(Prim('sphere', f'Finger{f}1_{t}', k=0.03, c=pts[0], r=0.052))
            P += chain(pts[:2], [0.048, 0.042], f'Finger{f}1_{t}', k=0.025)
            P += chain(pts[1:], [0.042, 0.037, 0.033], f'Finger{f}2_{t}', k=0.02)
            P.append(Prim('sphere', f'Finger{f}2_{t}', k=0.02, c=pts[1], r=0.045))
            P.append(Prim('sphere', f'Finger{f}2_{t}', k=0.02, c=pts[2], r=0.04))
            # long hooked nail continues the curl
            d = pts[3] - pts[2]
            d /= np.linalg.norm(d)
            claw = bezier(pts[3] - d * 0.06, pts[3] + d * 0.14, pts[3] + d * 0.24 + n * 0.10,
                          pts[3] + d * 0.26 + n * 0.22, 4)
            P += chain(claw, [0.034, 0.03, 0.022, 0.012, 0.004], f'Finger{f}2_{t}', k=0.012, region='nail')
        tp = thumb_points(s)
        P += chain(tp, [0.05, 0.042, 0.034], f'Thumb_{t}', k=0.03)
        d = tp[2] - tp[1]
        d /= np.linalg.norm(d)
        P += chain([tp[2] - d * 0.04, tp[2] + d * 0.12, tp[2] + d * 0.16 + n * 0.08], [0.03, 0.02, 0.005],
                   f'Thumb_{t}', k=0.01, region='nail')
    return P


def teeth_prims():
    P = []
    rng = np.random.default_rng(7)
    n = 25
    for row, bone in ((1, 'Head'), (-1, 'Jaw')):
        for i, th in enumerate(np.linspace(-80, 80, n)):
            if row < 0 and i in (5, 18):
                continue  # a couple missing
            edge = abs(th) / 80
            size = 1.0 - 0.45 * edge
            jit = rng.normal(0, 1, 3)
            base = mouth_arc(th, 0.04) + v3(0, 0, 0.088 * row)
            tip = mouth_arc(th + jit[0] * 1.2, 0.006 + 0.012 * edge) + \
                v3(0, 0, (0.004 + 0.012 * abs(jit[1])) * -row)
            rad = (math.sin(math.radians(th)), -math.cos(math.radians(th)), 0)
            P.append(Prim('cone', bone, k=0.003, region='teeth', a=base, b=tip, up=rad,
                          r1=0.029 * size * (1 + 0.15 * jit[2]), r2=0.010 * size, squash=(1.0, 0.62)))
        pts = [mouth_arc(th, 0.065) + v3(0, 0, 0.085 * row) for th in np.linspace(-84, 84, 11)]
        P += chain(pts, [0.03] * 11, bone, k=0.02, region='gum')
    return P


def cloth_prims():
    """Torn grave-linen wrapped around the hips, strips hanging."""
    P = []
    P.append(Prim('cone', 'Hips', k=0.0, shell=0.02, squash=(1.0, 0.78), region='cloth',
                  a=(0, 0.04, 5.48), b=(0, 0.04, 4.92), r1=0.40, r2=0.47))
    # open the top and bottom (ragged), before the strips are added
    P.append(Prim('box', None, op='sub', k=0.01, c=(0, 0, 5.62), h=(1.2, 1.2, 0.14), disp=(0.05, 7.0, 11)))
    P.append(Prim('box', None, op='sub', k=0.01, c=(0, 0, 4.30), h=(1.2, 1.2, 0.58), disp=(0.05, 6.0, 12)))
    rng = np.random.default_rng(3)
    for ang, ln, w in ((-90, 1.05, 0.10), (-62, 0.75, 0.08), (-118, 0.65, 0.07), (90, 0.95, 0.10),
                       (58, 0.6, 0.07), (128, 0.8, 0.08), (-150, 0.55, 0.07), (155, 0.7, 0.08),
                       (-30, 0.45, 0.06), (20, 0.5, 0.06), (180, 0.4, 0.06), (0, 0.35, 0.05)):
        a = math.radians(ang + rng.normal(0, 4))
        rad = v3(math.cos(a), math.sin(a), 0)
        pts, wid = [], []
        for k in range(5):
            u = k / 4
            r = 1.0 + 0.10 * u + 0.03 * math.sin(u * 5 + ang)
            pts.append(v3(0.47 * r * math.cos(a), 0.37 * r * math.sin(a) + 0.04, 5.08 - ln * u)
                       + v3(-math.sin(a), math.cos(a), 0) * 0.04 * math.sin(u * 3 + ang))
            wid.append(w * (1 - 0.55 * u ** 1.5))
        for k in range(4):
            P.append(Prim('cone', 'Hips', k=0.015, region='cloth', a=pts[k], b=pts[k + 1], r1=wid[k], r2=wid[k + 1],
                          up=tuple(rad), squash=(1.0, 0.013 / w), disp=(0.008, 10.0, 5)))
    for i in range(10):
        a = i * 2.39996
        P.append(Prim('sphere', None, op='sub', k=0.02,
                      c=(0.47 * math.cos(a), 0.37 * math.sin(a), 4.95 + 0.45 * ((i * 0.37) % 1)),
                      r=0.04 + 0.03 * ((i * 0.61) % 1), disp=(0.02, 14.0, i)))
    return P


def eye_prims():
    return [Prim('sphere', 'Head', k=0.0, region='glow', c=(0.14 * s, -0.415, 8.62 + (0.012 if s > 0 else -0.006)), r=0.013) for s in (1, -1)]


def pieces():
    body = Scene(body_prims())
    return [
        bk.Piece('body', body, tris=7400, voxel=0.022, falloff=0.07, lo_voxel=0.035),
        bk.Piece('hands', Scene(hand_prims()), tris=2100, voxel=0.011, falloff=0.035, lo_voxel=0.016),
        bk.Piece('teeth', Scene(teeth_prims()), tris=1100, voxel=0.0065, mat='teeth', falloff=0.02),
        bk.Piece('cloth', Scene(cloth_prims()), tris=900, voxel=0.011, mat='cloth', falloff=0.14,
                 weight_scene=body, smooth=0),
        bk.Piece('eyes', Scene(eye_prims()), tris=80, voxel=0.006, rigid='Head', group='glow', mat='teeth'),
    ]


# ----------------------------------------------------------------- materials
def mat_skin(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n1 = nk.noise(co, 1.4, 6, 0.6).outputs['Fac']
    base = nk.ramp(n1, [(0.30, (0.15, 0.148, 0.145)), (0.5, (0.235, 0.228, 0.215)), (0.72, (0.31, 0.295, 0.27))])
    # grave mottling / bruising
    st = nk.maprange(nk.noise(co, 0.8, 5, 0.55).outputs['Fac'], 0.52, 0.72)
    col = nk.mix(nk.math('MULTIPLY', st, 0.65), base, (0.17, 0.14, 0.15))
    # veins (ridges of a distorted noise)
    vn = nk.noise(co, 3.2, 3, 0.45, dist=0.9).outputs['Fac']
    ridge = nk.maprange(nk.math('ABSOLUTE', nk.math('SUBTRACT', vn, 0.5)), 0.0, 0.022, 1.0, 0.0)
    col = nk.mix(nk.math('MULTIPLY', ridge, 0.5), col, (0.13, 0.15, 0.2))
    # soot: the head, creeping down the neck and up from the hands/spikes in a ragged edge
    sootn = nk.noise(co, 6.0, 4, 0.6).outputs['Fac']
    head = nk.attr('rg_head')
    soot = nk.maprange(nk.math('SUBTRACT', nk.math('MULTIPLY', head, 1.5), nk.math('MULTIPLY', sootn, 0.6)), 0.15, 0.45)
    z = nk.node('ShaderNodeSeparateXYZ')
    nk.set(z.inputs[0], co)
    feet = nk.maprange(nk.math('ADD', z.outputs['Z'], nk.math('MULTIPLY', sootn, 0.9)), 0.4, 1.9, 1.0, 0.0)
    col = nk.mix(nk.math('MULTIPLY', feet, 0.75), col, (0.06, 0.05, 0.045))
    col = nk.mix(soot, col, (0.022, 0.02, 0.022))
    nail = nk.attr('rg_nail')
    nailc = nk.mix(nk.math('MULTIPLY', sootn, 0.5), (0.10, 0.075, 0.05), (0.03, 0.025, 0.02))
    col = nk.mix(nail, col, nailc)
    rough = nk.mixf(soot, nk.maprange(n1, 0.2, 0.8, 0.58, 0.74), 0.46)
    rough = nk.mixf(nail, rough, 0.32)
    # bump: wrinkles + pores + veins raised
    wr = nk.noise(co, 22.0, 8, 0.62, dist=0.3).outputs['Fac']
    po = nk.voronoi(co, 90.0).outputs['Distance']
    h = nk.math('ADD', nk.math('MULTIPLY', wr, 0.6), nk.math('MULTIPLY', po, 0.15))
    h = nk.math('ADD', h, nk.math('MULTIPLY', ridge, 0.35))
    nrm = nk.bump(h, 0.32, 0.01)
    nk.finish(col, rough, 0.0, nrm)
    return mat


def mat_teeth(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n = nk.noise(co, 30.0, 4, 0.5).outputs['Fac']
    gum = nk.attr('rg_gum')
    col = nk.ramp(n, [(0.35, (0.36, 0.31, 0.21)), (0.65, (0.58, 0.53, 0.40))])
    col = nk.mix(gum, col, (0.09, 0.03, 0.03))
    rough = nk.mixf(gum, nk.maprange(n, 0.3, 0.7, 0.28, 0.42), 0.35)
    nrm = nk.bump(nk.noise(co, 80.0, 3, 0.5).outputs['Fac'], 0.15, 0.004)
    nk.finish(col, rough, 0.0, nrm)
    return mat


def mat_cloth(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n1 = nk.noise(co, 2.5, 6, 0.6).outputs['Fac']
    col = nk.ramp(n1, [(0.3, (0.13, 0.115, 0.09)), (0.55, (0.24, 0.215, 0.17)), (0.75, (0.30, 0.27, 0.21))])
    stain = nk.maprange(nk.noise(co, 4.0, 4, 0.6).outputs['Fac'], 0.55, 0.68)
    col = nk.mix(nk.math('MULTIPLY', stain, 0.8), col, (0.09, 0.06, 0.04))
    z = nk.node('ShaderNodeSeparateXYZ')
    nk.set(z.inputs[0], co)
    hem = nk.maprange(z.outputs['Z'], 4.1, 4.9, 1.0, 0.0)
    col = nk.mix(nk.math('MULTIPLY', hem, 0.7), col, (0.06, 0.05, 0.04))
    w1 = nk.wave(co, 70.0, 1.0, 1.0, 'BANDS', 'X').outputs['Fac']
    w2 = nk.wave(co, 70.0, 1.0, 1.0, 'BANDS', 'Z').outputs['Fac']
    h = nk.math('ADD', nk.math('MULTIPLY', w1, 0.5), nk.math('MULTIPLY', w2, 0.5))
    h = nk.math('ADD', h, nk.math('MULTIPLY', n1, 2.0))
    nk.finish(col, 0.93, 0.0, nk.bump(h, 0.25, 0.006))
    return mat


MATERIALS = {'skin': mat_skin, 'teeth': mat_teeth, 'cloth': mat_cloth}


# ----------------------------------------------------------------- animation
SIDES = (('L', 1), ('R', -1))


def mx(p, sgn):
    return (p[0] * sgn, p[1], p[2])


def legs(an, pose, feet):
    """feet: {'L': (x, y, z) tip target, 'R': ...} -> two-bone IK, knees forward."""
    for t, sgn in SIDES:
        mo.ik2(an, pose, f'UpperLeg_{t}', f'LowerLeg_{t}', feet[t], (0.15 * sgn, -1, 0.1), end=f'Spike_{t}')
    return pose


def arms(an, pose, wrists, elbow_out=1.0, hand_dir=None, pole=None):
    for t, sgn in SIDES:
        pl = pole[t] if pole else (sgn * elbow_out, 0.4, -0.5)
        mo.ik2(an, pose, f'UpperArm_{t}', f'LowerArm_{t}', wrists[t], pl)
        if hand_dir is not None:
            an.aim(pose, f'Hand_{t}', mx(hand_dir[t] if isinstance(hand_dir, dict) else hand_dir, sgn))
    return pose


def fingers(curl, spread=0.0, thumb=None):
    """Left-hand finger pose; sym() mirrors it."""
    p = {}
    for i, f in enumerate('ABC'):
        sp = (i - 1) * spread
        p[f'Finger{f}1_L'] = (0, curl, sp)
        p[f'Finger{f}2_L'] = (0, curl * 1.2, 0)
    p['Thumb_L'] = (0, (thumb if thumb is not None else curl) * 0.6, 0)
    return p


def hang_arms(an, pose, swing=0.0, out=0.28, fwd=0.0, lag=0.0, curl=18):
    for t, sgn in SIDES:
        sw = swing if t == 'L' else -swing
        an.aim(pose, f'UpperArm_{t}', (out * sgn, -0.05 + fwd + sw, -1))
        an.aim(pose, f'LowerArm_{t}', (0.12 * sgn, -0.30 + fwd * 1.3 + sw * 1.2 + lag * (1 if t == 'L' else -1), -1))
        an.aim(pose, f'Hand_{t}', (0.05 * sgn, -0.40 + fwd * 1.3 + sw * 1.4, -1))
    return pose


def stand(an, t=0.0, bow=1.0, drop=-0.18, feet_w=0.50):
    pose = {'@root': (0, 0, drop)}
    pose['Spine'] = (6 * bow, 0, 0)
    pose['Chest'] = (10 * bow, 0, 0)
    pose['Neck'] = (20 * bow, 0, 0)
    pose['Head'] = (-24 * bow, 6, 0)
    pose['Clavicle_L'] = (0, 6, 0)
    pose['Clavicle_R'] = bk.mirror_q(bk.Q((0, 6, 0)))
    pose.update(bk.sym(fingers(16)))
    hang_arms(an, pose)
    legs(an, pose, {'L': (feet_w, 0.06, 0.0), 'R': (-feet_w, 0.06, 0.0)})
    return pose


def clips(an):
    out = []

    # ---- Idle: breathing, slow sway, two sharp head twitches, finger flex
    def idle(t):
        pose = {'@root': (0.05 * mo.s(t), 0.02 * mo.c(t), -0.18 + 0.025 * mo.s(2 * t))}
        br = mo.s(2 * t)
        tw = mo.twitch(t, 0.22, 0.05, 1) - mo.twitch(t, 0.62, 0.04, 1)
        pose['Hips'] = (0, 1.5 * mo.s(t), 0)
        pose['Spine'] = (6 + 1.0 * br, 0, 0)
        pose['Chest'] = (10 + 2.0 * br, -1.5 * mo.s(t), 0)
        pose['Neck'] = (20 + 1.5 * mo.s(t + 0.3), 0, 4 * mo.s(t))
        pose['Head'] = (-24 + 3 * mo.s(t + 0.1) + 10 * mo.twitch(t, 0.80, 0.03),
                        6 + 6 * mo.s(t * 1 + 0.2) + 18 * mo.twitch(t, 0.62, 0.05),
                        8 * mo.s(t) + 28 * tw)
        pose['Jaw'] = (4 * mo.twitch(t, 0.80, 0.02) + 2 * (mo.twitch(t, 0.83, 0.02)), 0, 0)
        pose['Clavicle_L'] = (0, 6 + 1.5 * br, 0)
        pose['Clavicle_R'] = bk.mirror_q(bk.Q((0, 6 + 1.5 * br, 0)))
        fl = {}
        for i, f in enumerate('ABC'):
            c = 16 + 10 * mo.s(t * 2 + i * 0.12)
            fl[f'Finger{f}1_L'] = (0, c, 0)
            fl[f'Finger{f}2_L'] = (0, c * 1.3, 0)
            c2 = 16 + 10 * mo.s(t * 2 + 0.5 + i * 0.15)
            fl[f'Finger{f}1_R'] = bk.mirror_q(bk.Q((0, c2, 0)))
            fl[f'Finger{f}2_R'] = bk.mirror_q(bk.Q((0, c2 * 1.3, 0)))
        pose.update(fl)
        hang_arms(an, pose, swing=0.04 * mo.s(t), lag=0.03 * mo.s(t + 0.2))
        legs(an, pose, {'L': (0.50, 0.06, 0.0), 'R': (-0.50, 0.06, 0.0)})
        return pose
    out.append(('Idle', 120, idle, True))

    # ---- Walk: slow stilt gait, stiff knees, dangling arms, head bob + twitch
    def walk(t):
        uL, uR = t, t + 0.5
        yL, zL, _ = mo.foot_cycle(uL, 2.2, 0.55, 0.62)
        yR, zR, _ = mo.foot_cycle(uR, 2.2, 0.55, 0.62)
        pose = {'@root': (0.10 * mo.s(t), 0, -0.30 + 0.10 * mo.c(2 * t))}
        pose['Hips'] = (0, 3 * mo.s(t), -9 * mo.c(t))
        pose['Spine'] = (12, 0, 4 * mo.c(t))
        pose['Chest'] = (16 + 2 * mo.c(2 * t), -2 * mo.s(t), 6 * mo.c(t))
        pose['Neck'] = (24, 0, -3 * mo.c(t))
        pose['Head'] = (-30 + 4 * mo.c(2 * t + 0.1), 8 + 22 * mo.twitch(t, 0.35, 0.04), -4 * mo.c(t) + 20 * mo.twitch(t, 0.8, 0.04))
        pose.update(bk.sym(fingers(20 + 6 * mo.s(2 * t))))
        hang_arms(an, pose, swing=0.30 * mo.c(t - 0.08), fwd=0.05, lag=0.05 * mo.s(t))
        legs(an, pose, {'L': (0.48, 0.06 + yL, zL), 'R': (-0.48, 0.06 + yR, zR)})
        return pose
    out.append(('Walk', 48, walk, True))

    # ---- Run (hunt): bent almost double, long lurching strides, arms reaching
    def run(t):
        yL, zL, _ = mo.foot_cycle(t, 3.4, 1.0, 0.45)
        yR, zR, _ = mo.foot_cycle(t + 0.5, 3.4, 1.0, 0.45)
        pose = {'@root': (0.12 * mo.s(t), 0, -0.75 + 0.22 * mo.c(2 * t + 0.1))}
        pose['Hips'] = (8, 3 * mo.s(t), -14 * mo.c(t))
        pose['Spine'] = (20, 0, 6 * mo.c(t))
        pose['Chest'] = (24 + 4 * mo.c(2 * t), 0, 10 * mo.c(t))
        pose['Neck'] = (8, 0, -6 * mo.c(t))
        pose['Head'] = (-48 + 6 * mo.c(2 * t), 10 * mo.s(t), 0)
        pose['Jaw'] = (14 + 6 * mo.s(2 * t), 0, 0)
        pose.update(bk.sym(fingers(-6, 10, 0)))
        for tt, sgn in SIDES:
            ph = mo.c(t) if tt == 'L' else -mo.c(t)
            an.aim(pose, f'UpperArm_{tt}', (0.35 * sgn, -0.7 - 0.55 * ph, -0.55 + 0.2 * ph))
            an.aim(pose, f'LowerArm_{tt}', (0.15 * sgn, -1.0 - 0.3 * ph, -0.35 + 0.35 * ph))
            an.aim(pose, f'Hand_{tt}', (0.05 * sgn, -1.0, -0.6 + 0.2 * ph))
        legs(an, pose, {'L': (0.50, 0.25 + yL, zL), 'R': (-0.50, 0.25 + yR, zR)})
        return pose
    out.append(('Run', 24, run, True))

    # ---- Attack: wind up, lunge, grab, drag the victim to its chest
    st = stand(an)

    def k_wind():
        p = {'@root': (0, 0.3, -0.45), 'Spine': (-4, 0, 0), 'Chest': (-6, 0, 0), 'Neck': (10, 0, 0),
             'Head': (-40, 0, 0), 'Jaw': (16, 0, 0)}
        p.update(bk.sym(fingers(-10, 12, -5)))
        arms(an, p, {'L': (1.6, 0.9, 7.4), 'R': (-1.6, 0.9, 7.4)})
        legs(an, p, {'L': (0.55, 0.5, 0), 'R': (-0.55, -0.4, 0)})
        return p

    def k_lunge():
        p = {'@root': (0, -1.0, -1.0), 'Hips': (12, 0, 0), 'Spine': (18, 0, 0), 'Chest': (22, 0, 0), 'Neck': (6, 0, 0),
             'Head': (-36, 0, 0), 'Jaw': (34, 0, 0)}
        p.update(bk.sym(fingers(-12, 14, -10)))
        arms(an, p, {'L': (0.55, -3.6, 5.6), 'R': (-0.55, -3.6, 5.6)}, hand_dir=(0.0, -1, -0.2))
        legs(an, p, {'L': (0.55, -1.4, 0), 'R': (-0.55, 0.9, 0)})
        return p

    def k_grab():
        p = k_lunge()
        p.update(bk.sym(fingers(62, 0, 40)))
        p['Jaw'] = (22, 0, 0)
        return p

    def k_pull():
        p = {'@root': (0, -0.4, -0.6), 'Hips': (6, 0, 0), 'Spine': (10, 0, 0), 'Chest': (14, 0, 0), 'Neck': (22, 0, 0),
             'Head': (-20, 14, 0), 'Jaw': (8, 0, 0)}
        p.update(bk.sym(fingers(62, 0, 40)))
        arms(an, p, {'L': (0.55, -1.4, 6.3), 'R': (-0.55, -1.4, 6.3)}, hand_dir=(-0.3, -0.6, 0.2))
        legs(an, p, {'L': (0.55, -0.9, 0), 'R': (-0.55, 0.5, 0)})
        return p
    out.append(('Attack', 45, bk.track([(0, st), (0.28, k_wind()), (0.42, k_lunge(), 'snap'), (0.52, k_grab(), 'snap'),
                                        (0.82, k_pull()), (1.0, k_pull())]), False))

    # ---- ThrowCorpse: stoop, grip the body, hoist overhead, hurl (release at 72%)
    def k_stoop():
        p = {'@root': (0, 0.2, -1.6), 'Hips': (20, 0, 0), 'Spine': (28, 0, 0), 'Chest': (30, 0, 0), 'Neck': (6, 0, 0),
             'Head': (-20, 0, 0)}
        p.update(bk.sym(fingers(-8, 10, -6)))
        arms(an, p, {'L': (0.75, -1.9, 0.9), 'R': (-0.75, -1.9, 0.9)}, hand_dir=(0, -0.3, -1))
        legs(an, p, {'L': (0.65, 0.2, 0), 'R': (-0.65, 0.4, 0)})
        return p

    def k_grip():
        p = k_stoop()
        p.update(bk.sym(fingers(58, 0, 45)))
        return p

    def k_hoist():
        p = {'@root': (0, 0.4, -0.25), 'Hips': (-6, 0, 0), 'Spine': (-10, 0, 0), 'Chest': (-12, 0, 0),
             'Neck': (6, 0, 0), 'Head': (-24, 0, 0), 'Jaw': (20, 0, 0)}
        p.update(bk.sym(fingers(58, 0, 45)))
        arms(an, p, {'L': (0.65, 0.5, 9.6), 'R': (-0.65, 0.5, 9.6)}, hand_dir=(0, 0.3, 1),
             pole={'L': (1, 0.5, 0.2), 'R': (-1, 0.5, 0.2)})
        legs(an, p, {'L': (0.55, -0.3, 0), 'R': (-0.55, 0.9, 0)})
        return p

    def k_hurl():
        p = {'@root': (0, -0.8, -0.8), 'Hips': (16, 0, 0), 'Spine': (24, 0, 0), 'Chest': (30, 0, 0), 'Neck': (8, 0, 0),
             'Head': (-30, 0, 0), 'Jaw': (30, 0, 0)}
        p.update(bk.sym(fingers(-10, 16, -8)))
        arms(an, p, {'L': (0.75, -3.2, 4.8), 'R': (-0.75, -3.2, 4.8)}, hand_dir=(0, -1, -0.6))
        legs(an, p, {'L': (0.55, -1.4, 0), 'R': (-0.55, 0.9, 0)})
        return p
    out.append(('ThrowCorpse', 75, bk.track([(0, st), (0.22, k_stoop()), (0.32, k_grip(), 'snap'),
                                             (0.58, k_hoist()), (0.72, k_hurl(), 'snap'), (0.80, k_hurl()),
                                             (1.0, st)]), False))

    # ---- Stunned (music box): recoil, clutch head, shake, freeze. Then StunnedLoop.
    def k_recoil():
        p = {'@root': (0, 0.6, -0.3), 'Hips': (-6, 0, 0), 'Spine': (-12, 0, 0), 'Chest': (-16, 0, 0),
             'Neck': (-10, 0, 0), 'Head': (-40, -12, 0), 'Jaw': (42, 0, 0)}
        p.update(bk.sym(fingers(-14, 18, -10)))
        arms(an, p, {'L': (2.3, 0.6, 7.8), 'R': (-2.3, 0.6, 7.6)}, hand_dir=(1, 0.2, 0.6))
        legs(an, p, {'L': (0.6, 0.6, 0), 'R': (-0.6, 0.2, 0)})
        return p

    def k_clutch(shake=0.0):
        p = {'@root': (0, 0.2, -1.1), 'Hips': (14, 0, 0), 'Spine': (20, 0, 0), 'Chest': (24, 0, 0),
             'Neck': (24, 0, 0), 'Head': (6, 10 * shake, 16 * shake), 'Jaw': (36, 0, 0)}
        p.update(bk.sym(fingers(40, 8, 30)))
        hp = an.world_head(p, 'Head')
        arms(an, p, {'L': (hp[0] + 0.50, hp[1] - 0.25, hp[2] + 0.20), 'R': (hp[0] - 0.50, hp[1] - 0.25, hp[2] + 0.20)},
             hand_dir={'L': (-0.4, -0.3, 1), 'R': (-0.4, -0.3, 1)},
             pole={'L': (1, -0.6, -0.2), 'R': (-1, -0.6, -0.2)})
        legs(an, p, {'L': (0.70, 0.1, 0), 'R': (-0.70, 0.3, 0)})
        return p

    rec = k_recoil()
    seq = [(0, st), (0.08, rec, 'snap'), (0.2, rec)]
    for i in range(9):
        seq.append((0.26 + i * 0.065, k_clutch((1 if i % 2 else -1) * (1 - i / 10))))
    seq += [(0.9, k_clutch(0.0)), (1.0, k_clutch(0.0))]
    out.append(('Stunned', 75, bk.track(seq), False))

    def stun_loop(t):
        sh = 0.25 * mo.s(6 * t) + 0.15 * mo.s(11 * t + 0.3)
        p = k_clutch(sh)
        p['@root'] = (0.02 * mo.s(9 * t), 0.2, -1.1 + 0.02 * mo.s(5 * t))
        return p
    out.append(('StunnedLoop', 30, stun_loop, True))

    # ---- Manifest: unfolds from a heap on the floor in jerky stages
    def k_heap():
        p = {'@root': (0, 0.6, -3.5), 'Hips': (62, 0, 10), 'Spine': (36, 0, 0), 'Chest': (36, 10, 0),
             'Neck': (40, 0, 0), 'Head': (30, 50, 0)}
        p.update(bk.sym(fingers(40, 0, 30)))
        arms(an, p, {'L': (1.8, -1.7, 0.45), 'R': (-2.0, -0.9, 0.45)}, hand_dir=(0.3, -0.6, -0.2))
        legs(an, p, {'L': (1.0, -1.0, 0.0), 'R': (-1.2, -0.6, 0.0)})
        return p

    def k_kneel():
        p = {'@root': (0, 0.4, -2.5), 'Hips': (40, 0, 0), 'Spine': (30, 0, 0), 'Chest': (30, -10, 0),
             'Neck': (10, 0, 0), 'Head': (-50, -30, 0), 'Jaw': (20, 0, 0)}
        p.update(bk.sym(fingers(20, 0, 10)))
        arms(an, p, {'L': (1.2, -1.4, 0.4), 'R': (-1.2, -1.4, 0.4)}, hand_dir=(0, -0.3, -1))
        legs(an, p, {'L': (0.8, -0.2, 0.0), 'R': (-0.8, 0.2, 0.0)})
        return p

    def k_rise():
        p = {'@root': (0, 0.2, -0.9), 'Hips': (10, 0, 0), 'Spine': (24, 0, 0), 'Chest': (30, 0, 0),
             'Neck': (30, 0, 0), 'Head': (-10, 40, 0)}
        p.update(bk.sym(fingers(30)))
        hang_arms(an, p, fwd=0.2)
        legs(an, p, {'L': (0.55, 0.1, 0.0), 'R': (-0.55, 0.1, 0.0)})
        return p
    head_snap = dict(st)
    head_snap['Head'] = (-30, -20, 30)
    out.append(('Manifest', 60, bk.track([(0, k_heap()), (0.12, k_heap()), (0.3, k_kneel(), 'snap'), (0.42, k_kneel()),
                                          (0.62, k_rise(), 'snap'), (0.74, k_rise()), (0.86, head_snap, 'snap'),
                                          (1.0, st)]), False))

    # ---- Vanish: head snaps back, body arches, collapses down through the floor line
    def k_arch():
        p = {'@root': (0, 0.3, -0.1), 'Spine': (-14, 0, 0), 'Chest': (-20, 0, 0), 'Neck': (-24, 0, 0),
             'Head': (-40, 0, 0), 'Jaw': (40, 0, 0)}
        p.update(bk.sym(fingers(-14, 18, -10)))
        arms(an, p, {'L': (2.4, 0.8, 6.0), 'R': (-2.4, 0.8, 6.0)})
        legs(an, p, {'L': (0.5, 0.1, 0), 'R': (-0.5, 0.1, 0)})
        return p

    def k_drop():
        p = k_heap()
        p['@root'] = (0, 0.6, -4.6)
        return p
    out.append(('Vanish', 36, bk.track([(0, st), (0.3, k_arch(), 'snap'), (0.45, k_arch()), (1.0, k_drop(), 'in')]),
                False))
    return out


if __name__ == '__main__':
    import pipeline
    pipeline.build(sys.modules[__name__])
