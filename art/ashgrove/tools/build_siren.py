"""AH_Ent_Siren — the drowned singer, found far from the sea.

Folklore: the sirens of Greek myth sang sailors onto the rocks; later
European tradition gave them a fish's tail.  Ours is drowned and starved:
waterlogged blue-grey skin over bone, black lidless eyes, a lipless mouth of
needle teeth, spined fin-frills where the ears should be, and a long eel
tail.  A corroded bronze circlet is all that is left of who she was.

She swims through the air as if the house were underwater.

Run:  python3 build_siren.py   (--preview for a quick sculpt check)
"""
import math
import sys

import numpy as np

sys.path.insert(0, __file__.rsplit('/', 1)[0])
import blendkit as bk  # noqa: E402
import motion as mo  # noqa: E402
from sdf import Prim, Scene, bezier, chain, sweep, v3  # noqa: E402

NAME = 'Siren'
TAGLINE = ('Drowned siren that swims through the air: bony face, black eyes, needle teeth, fin-frill ears, '
           'a long eel tail. Sings to slow her prey; always answers in a woman\'s voice.')
GLOW_COLOR = (0.70, 0.88, 1.0)
GLOW_STRENGTH = 5.0
GLOW_NOTE = 'pupils: pinprick, Neon #B3E0FF; add a faint blue PointLight (range 6) on Head while singing'
MOOD_POSE = ('Idle', 0.2)
MOOD_DIST = 10.0
ANIM_ZOOM = 1.45
ANIM_TARGET = (0, 0.6, 3.6)
BAKE = {'extrusion': 0.03, 'ray': 0.1, 'samples': 6}
SHEET_NOTES = [
    'Read in the dark: pale floating torso over a long dark tail; the fin frills and the hair break the outline.',
    'Hovers: the tail tip skims ~0.3 studs above the floor. Collision: 3×7×6 box, not walkable.',
]
PREVIEW_CLOSEUPS = [('head', (0, -1, 0.05), (0, -0.05, 6.55), 1.7), ('head3q', (-0.8, -1, 0.1), (0, -0.05, 6.55), 1.7),
                    ('tail', (1, -0.2, 0.2), (0, 2.0, 1.8), 5.5), ('hand', (0.2, -1, 0.3), (2.6, -0.1, 4.1), 1.8)]

# ------------------------------------------------------------------ skeleton
J = dict(root=v3(0, 0, 0), hrp=v3(0, 0.05, 3.55), pelvis=v3(0, 0.05, 3.50), waist=v3(0, 0.04, 4.15),
         chest=v3(0, 0.0, 4.80), neck=v3(0, 0.02, 5.85), head=v3(0, -0.04, 6.25), headtop=v3(0, -0.05, 7.05),
         jaw=v3(0, -0.02, 6.48), chin=v3(0, -0.30, 6.12))
SIDE = dict(clav=v3(0.08, -0.04, 5.68), shoulder=v3(0.62, 0.02, 5.68), elbow=v3(1.45, 0.10, 4.95),
            wrist=v3(2.20, 0.0, 4.32))
TAIL = bezier((0, 0.05, 3.50), (0, 0.10, 1.70), (0, 1.20, 0.55), (0, 4.30, 0.65), 8)
TAIL_R = [0.34, 0.37, 0.35, 0.31, 0.26, 0.21, 0.16, 0.11, 0.07]
HAIR = {'L': [v3(0.22, 0.36, 6.30), v3(0.26, 0.44, 5.60), v3(0.28, 0.52, 4.80)],
        'R': [v3(-0.22, 0.36, 6.30), v3(-0.26, 0.44, 5.60), v3(-0.28, 0.52, 4.80)],
        'B': [v3(0.0, 0.40, 6.30), v3(0.0, 0.48, 5.60), v3(0.0, 0.55, 4.80)]}


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


def finger_pts(s, i, curl=(10, 16, 20)):
    a, n, sp = hand_frame(s)
    knuck = S('wrist', s) + a * 0.32 + sp * (-0.15 + 0.10 * i) + n * 0.01
    d = a + sp * (-0.22 + 0.15 * i)
    d /= np.linalg.norm(d)
    lens = (0.30, 0.25, 0.20)
    pts, ang = [knuck], 0.0
    for L, cd in zip(lens, curl):
        ang += math.radians(cd)
        pts.append(pts[-1] + (d * math.cos(ang) + n * math.sin(ang)) * L)
    return pts


def thumb_pts(s):
    a, n, sp = hand_frame(s)
    base = S('wrist', s) + a * 0.10 - sp * 0.10 + n * 0.03
    d = a * 0.5 + v3(0, -1, 0) * 0.7 + n * 0.2
    d /= np.linalg.norm(d)
    return [base, base + d * 0.25, base + d * 0.45 + n * 0.08]


def bones():
    b = [
        dict(name='Root', head=J['root'], tail=J['root'] + v3(0, 0, 0.6), deform=False),
        dict(name='HumanoidRootNode', head=J['hrp'], tail=J['hrp'] + v3(0, 0, 0.5), parent='Root', deform=False),
        dict(name='Hips', head=J['pelvis'], tail=J['waist'], parent='HumanoidRootNode'),
        dict(name='Spine', head=J['waist'], tail=J['chest'], parent='Hips'),
        dict(name='Chest', head=J['chest'], tail=J['neck'], parent='Spine'),
        dict(name='Neck', head=J['neck'], tail=J['head'], parent='Chest'),
        dict(name='Head', head=J['head'], tail=J['headtop'], parent='Neck'),
        dict(name='Jaw', head=J['jaw'], tail=J['chin'], parent='Head', roll_to=(0, 0, 1)),
        dict(name='Frill_L', head=v3(0.30, 0.02, 6.55), tail=v3(0.72, 0.30, 6.95), parent='Head', roll_to=(0, 0, 1)),
        dict(name='Frill_R', head=v3(-0.30, 0.02, 6.55), tail=v3(-0.72, 0.30, 6.95), parent='Head', roll_to=(0, 0, 1)),
    ]
    for k, side in enumerate(('L', 'R', 'B')):
        h = HAIR[side]
        b.append(dict(name=f'Hair{side}1', head=h[0], tail=h[1], parent='Head'))
        b.append(dict(name=f'Hair{side}2', head=h[1], tail=h[2], parent=f'Hair{side}1'))
    for s, t in ((1, 'L'), (-1, 'R')):
        a, n, sp = hand_frame(s)
        b += [
            dict(name=f'Clavicle_{t}', head=S('clav', s), tail=S('shoulder', s), parent='Chest'),
            dict(name=f'UpperArm_{t}', head=S('shoulder', s), tail=S('elbow', s), parent=f'Clavicle_{t}'),
            dict(name=f'LowerArm_{t}', head=S('elbow', s), tail=S('wrist', s), parent=f'UpperArm_{t}'),
            dict(name=f'Hand_{t}', head=S('wrist', s), tail=S('wrist', s) + a * 0.32, parent=f'LowerArm_{t}',
                 roll_to=tuple(n)),
        ]
        f1, f3 = finger_pts(s, 1), finger_pts(s, 2)
        mid = [(p + q) / 2 for p, q in zip(f1, f3)]
        b.append(dict(name=f'Fingers1_{t}', head=mid[0], tail=mid[1], parent=f'Hand_{t}', roll_to=tuple(n)))
        b.append(dict(name=f'Fingers2_{t}', head=mid[1], tail=mid[3], parent=f'Fingers1_{t}', roll_to=tuple(n)))
        tp = thumb_pts(s)
        b.append(dict(name=f'Thumb_{t}', head=tp[0], tail=tp[2], parent=f'Hand_{t}', roll_to=tuple(n)))
    for k in range(len(TAIL) - 1):
        b.append(dict(name=f'Tail{k + 1}', head=TAIL[k], tail=TAIL[k + 1], parent='Hips' if k == 0 else f'Tail{k}',
                      roll_to=(1, 0, 0)))
    return b


# ---------------------------------------------------------------- the sculpt
def L(a, b, t):
    return a + (b - a) * t


def _rot_to(d):
    x = v3(d) / np.linalg.norm(d)
    y = np.cross(v3(0, 0, 1), x)
    if np.linalg.norm(y) < 1e-3:
        y = v3(0, 1, 0)
    y /= np.linalg.norm(y)
    return np.stack([x, y, np.cross(x, y)], axis=1)


MOUTH_Z = 6.30


def mouth_arc(th, inset=0.0):
    t = math.radians(th)
    rx, ry = 0.24 - inset, 0.30 - inset
    z = MOUTH_Z + 0.07 * (abs(th) / 80) ** 2
    return v3(rx * math.sin(t), -0.04 - ry * math.cos(t), z)


def body_prims():
    P = []
    # --- skull-like face: narrow, hollow cheeks, huge sockets, lipless mouth
    P.append(Prim('ellip', 'Head', k=0.0, region='skin', c=(0, 0.04, 6.66), r=(0.31, 0.38, 0.40)))
    P.append(Prim('ellip', 'Head', k=0.10, region='skin', c=(0, -0.12, 6.45), r=(0.24, 0.24, 0.33)))
    P.append(Prim('ellip', 'Jaw', k=0.08, region='skin', c=(0, -0.13, 6.18), r=(0.19, 0.20, 0.12)))
    for s in (1, -1):
        P.append(Prim('ellip', 'Head', k=0.06, region='skin', c=(0.20 * s, -0.22, 6.50), r=(0.07, 0.07, 0.05)))
        P.append(Prim('ellip', None, op='sub', k=0.07, c=(0.25 * s, -0.20, 6.32), r=(0.06, 0.06, 0.09)))
        P.append(Prim('ellip', None, op='sub', k=0.05, c=(0.115 * s, -0.34, 6.62), r=(0.10, 0.11, 0.10)))
    P.append(Prim('ellip', None, op='sub', k=0.02, c=(0, -0.37, 6.47), r=(0.035, 0.04, 0.05)))  # nose hole
    for th in np.linspace(-80, 80, 29):
        P.append(Prim('ellip', None, op='sub', k=0.012, c=mouth_arc(th, -0.02), r=(0.045, 0.09, 0.045),
                      rot=(0, 0, th)))
    P.append(Prim('ellip', None, op='sub', k=0.03, c=(0, -0.10, MOUTH_Z + 0.02), r=(0.18, 0.18, 0.06)))
    # --- neck, emaciated torso
    P += chain([J['neck'] + v3(0, 0, -0.1), J['head'] + v3(0, 0, 0.12)], [0.12, 0.11], 'Neck', k=0.08)
    for s in (1, -1):
        P.append(Prim('cone', 'Neck', k=0.04, a=(0.14 * s, -0.02, 6.35), b=(0.04 * s, -0.16, 5.70), r1=0.03, r2=0.03))
        # gill slits on the neck
        for i in range(3):
            P.append(Prim('ellip', None, op='sub', k=0.01, c=(0.115 * s, -0.02 + 0.03 * i, 6.02 - 0.06 * i),
                          r=(0.02, 0.06, 0.012), rot=(0, 0, 60 * s)))
    P.append(Prim('ellip', 'Chest', k=0.10, c=(0, -0.01, 5.05), r=(0.40, 0.27, 0.55)))
    P.append(Prim('ellip', 'Chest', k=0.08, c=(0, 0.02, 5.48), r=(0.50, 0.24, 0.17)))
    P.append(Prim('cone', 'Spine', k=0.12, squash=(1.0, 0.75), a=(0, 0.04, 3.95), b=(0, 0.02, 4.70), r1=0.25, r2=0.27))
    P.append(Prim('ellip', None, op='sub', k=0.12, c=(0, -0.33, 4.30), r=(0.22, 0.12, 0.25)))
    for s, t in ((1, 'L'), (-1, 'R')):
        for i in range(6):
            z = 5.38 - i * 0.12
            pts = [v3(0.03 * s, -0.27, z - 0.02), v3(0.2 * s, -0.24, z + 0.02), v3(0.36 * s, -0.06, z + 0.07),
                   v3(0.31 * s, 0.14, z + 0.1)]
            P += chain(pts, [0.018, 0.022, 0.022, 0.016], 'Chest', k=0.05)
        P.append(Prim('cone', f'Clavicle_{t}', k=0.04, a=(0.04 * s, -0.2, 5.62), b=(0.55 * s, -0.02, 5.70), r1=0.03,
                      r2=0.035))
        P.append(Prim('cone', f'Clavicle_{t}', k=0.10, a=(0.1 * s, 0.03, 5.78), b=S('shoulder', s) + v3(-0.08 * s, 0, 0.04),
                      r1=0.10, r2=0.09))
        sh, el, wr = S('shoulder', s), S('elbow', s), S('wrist', s)
        P.append(Prim('sphere', f'UpperArm_{t}', k=0.07, c=sh, r=0.12))
        P.append(Prim('cone', f'UpperArm_{t}', k=0.06, a=sh, b=el, r1=0.10, r2=0.07))
        P.append(Prim('sphere', f'LowerArm_{t}', k=0.04, c=el + v3(0, 0.04, 0), r=0.07))
        P.append(Prim('cone', f'LowerArm_{t}', k=0.05, a=el, b=wr, r1=0.075, r2=0.05))
        # forearm fin
        a = wr - el
        P.append(Prim('cone', f'LowerArm_{t}', k=0.02, region='fin', squash=(0.12, 1.0), up=(0, 1, 0),
                      a=L(el, wr, 0.15) + v3(0, 0.06, 0), b=L(el, wr, 0.8) + v3(0, 0.05, 0), r1=0.16, r2=0.04))
    for i in range(12):  # vertebrae down the back
        z = 4.0 + i * 0.15
        P.append(Prim('sphere', 'Spine' if z < 4.8 else 'Chest', k=0.04, c=(0, 0.25, z), r=0.035))
    # --- the tail: pelvis blends into an eel body (one smooth swept tube)
    dense = bezier((0, 0.05, 3.50), (0, 0.10, 1.70), (0, 1.20, 0.55), (0, 4.30, 0.65), 40)
    rad = np.interp(np.linspace(0, 1, 41), np.linspace(0, 1, len(TAIL_R)), TAIL_R)
    sq = [(1.0, 1.0 + 0.15 * u) for u in np.linspace(0, 1, 41)]
    lo = np.min(dense, 0) - 0.5
    hi = np.max(dense, 0) + 0.5
    P.append(Prim('func', 'Tail1', k=0.20, region='tail', lo=lo, hi=hi,
                  fn=lambda X: sweep(X, dense, rad, sq)))
    P.append(Prim('ellip', 'Hips', k=0.18, region='skin', c=(0, 0.05, 3.72), r=(0.34, 0.26, 0.30)))
    return P


def tail_weight_prims():
    return [Prim('cone', f'Tail{k + 1}', k=0.0, a=TAIL[k], b=TAIL[k + 1], r1=TAIL_R[k], r2=TAIL_R[k + 1])
            for k in range(len(TAIL) - 1)]


def fin_membrane(base, tip, bone_fn, n_spines, region='fin', thick=0.018, rspine=0.026, inner=0.92):
    """Spined membrane between a base polyline and a tip polyline (lists of points)."""
    P = []
    for i in range(n_spines):
        u = i / (n_spines - 1)
        bi = _interp(base, u)
        ti = _interp(tip, u)
        P.append(Prim('cone', bone_fn(u), k=0.01, region='spine', a=bi, b=ti, r1=rspine, r2=rspine * 0.15))
        if i < n_spines - 1:
            u2 = (i + 0.5) / (n_spines - 1)
            b2, t2 = _interp(base, u2), _interp(tip, u2)
            nb = _interp(base, (i + 1) / (n_spines - 1))
            nt = _interp(tip, (i + 1) / (n_spines - 1))
            # membrane: flattened cones filling the gap (normal ~ across the fan)
            normal = np.cross(ti - bi, nb - bi)
            normal /= np.linalg.norm(normal) + 1e-9
            w = 0.5 * (np.linalg.norm(nb - bi) + np.linalg.norm(nt - ti)) * 0.5 + 0.01
            wb, wt = np.linalg.norm(nb - bi) * 0.55, np.linalg.norm(nt - ti) * 0.55
            tip_in = b2 + (t2 - b2) * inner
            P.append(Prim('cone', bone_fn(u2), k=0.012, region=region, squash=(1.0, thick / max(wb, 0.01)),
                          up=tuple(normal), a=b2, b=tip_in, r1=wb, r2=max(wt, 0.01)))
    return P


def _interp(pts, u):
    pts = [v3(p) for p in pts]
    if len(pts) == 1:
        return pts[0]
    x = u * (len(pts) - 1)
    i = min(int(x), len(pts) - 2)
    return pts[i] + (pts[i + 1] - pts[i]) * (x - i)


def tail_bone(u):
    k = min(int(u * (len(TAIL) - 1)), len(TAIL) - 2)
    return 'Hips' if k == 0 else f'Tail{k}'


def fin_prims():
    P = []
    # dorsal fin along the back of the tail (on +Y/up side of the curve)
    base, tip = [], []
    for k in range(1, len(TAIL) - 1):
        p = TAIL[k]
        d = TAIL[k + 1] - TAIL[k - 1]
        d /= np.linalg.norm(d)
        back = np.cross(d, v3(1, 0, 0))  # perpendicular in the YZ plane
        if back[1] < 0 and back[2] < 0:
            back = -back
        if np.dot(back, v3(0, 1, 0.3)) < 0:
            back = -back
        h = 0.22 + 0.25 * math.sin(math.pi * (k - 1) / (len(TAIL) - 3))
        base.append(p + back * TAIL_R[k] * 0.85)
        tip.append(p + back * (TAIL_R[k] + h) - d * 0.08)
    P += fin_membrane(base, tip, lambda u: f'Tail{2 + min(int(u * 6), 5)}', 15, inner=0.8)
    # horizontal fluke at the tip
    end = TAIL[-1]
    d = TAIL[-1] - TAIL[-2]
    d /= np.linalg.norm(d)
    for s in (1, -1):
        base = [end - d * 0.55 + v3(0.05 * s, 0, 0), end - d * 0.10 + v3(0.04 * s, 0, 0)]
        tip = [end + d * 0.25 + v3(1.55 * s, 0, 0.08), end + d * 1.35 + v3(0.75 * s, 0, 0.02)]
        P += fin_membrane(base, tip, lambda u: 'Tail8', 10, thick=0.016, rspine=0.024, inner=0.85)
    # ragged edges of the fluke
    for i in range(6):
        c = end + d * (0.5 + 0.1 * i) + v3((0.4 + 0.15 * i) * (1 if i % 2 else -1), 0, 0)
        P.append(Prim('sphere', None, op='sub', k=0.01, c=c, r=0.10 + 0.04 * (i % 3), disp=(0.03, 10.0, i)))
    # fin-frill "ears"
    for s, t in ((1, 'L'), (-1, 'R')):
        base = [v3(0.27 * s, -0.08, 6.48), v3(0.30 * s, 0.10, 6.62), v3(0.26 * s, 0.24, 6.78)]
        tip = [v3(0.55 * s, 0.10, 6.42), v3(0.78 * s, 0.38, 6.82), v3(0.50 * s, 0.50, 7.10)]
        P += fin_membrane(base, tip, lambda u, t=t: f'Frill_{t}', 6, thick=0.014, rspine=0.022, inner=0.72)
    return P


def hand_prims():
    P = []
    for s, t in ((1, 'L'), (-1, 'R')):
        a, n, sp = hand_frame(s)
        el, wr = S('elbow', s), S('wrist', s)
        P.append(Prim('cone', f'LowerArm_{t}', k=0.03, a=L(el, wr, 0.8), b=wr, r1=0.055, r2=0.05))
        P.append(Prim('cone', f'Hand_{t}', k=0.04, squash=(1.5, 0.5), up=tuple(n), a=wr + a * 0.03, b=wr + a * 0.30,
                      r1=0.06, r2=0.07))
        fingers = [finger_pts(s, i) for i in range(4)]
        for i, pts in enumerate(fingers):
            P += chain(pts[:2], [0.034, 0.03], f'Fingers1_{t}', k=0.02)
            P += chain(pts[1:], [0.03, 0.026, 0.022], f'Fingers2_{t}', k=0.015)
            d = pts[3] - pts[2]
            d /= np.linalg.norm(d)
            P += chain([pts[3] - d * 0.03, pts[3] + d * 0.12, pts[3] + d * 0.16 + n * 0.07], [0.022, 0.014, 0.003],
                       f'Fingers2_{t}', k=0.008, region='nail')
        for i in range(3):  # webbing between fingers
            base = [fingers[i][0], fingers[i + 1][0]]
            tip = [fingers[i][2], fingers[i + 1][2]]
            mid_b = (base[0] + base[1]) / 2
            mid_t = (tip[0] + tip[1]) / 2 * 0.9 + mid_b * 0.1
            w = np.linalg.norm(base[1] - base[0]) * 0.55
            normal = np.cross(tip[0] - base[0], base[1] - base[0])
            normal /= np.linalg.norm(normal)
            P.append(Prim('cone', f'Fingers1_{t}', k=0.01, region='fin', squash=(1.0, 0.012 / w), up=tuple(normal),
                          a=mid_b, b=mid_t, r1=w, r2=w * 0.8))
        tp = thumb_pts(s)
        P += chain(tp, [0.035, 0.03, 0.025], f'Thumb_{t}', k=0.02)
    return P


def teeth_prims():
    P = []
    rng = np.random.default_rng(2)
    for row, bone in ((1, 'Head'), (-1, 'Jaw')):
        for th in np.linspace(-76, 76, 31):
            j = rng.normal(0, 1, 2)
            base = mouth_arc(th, 0.03) + v3(0, 0, 0.06 * row)
            tip = mouth_arc(th + j[0], 0.0) + v3(0, 0, (0.012 * abs(j[1])) * -row)
            P.append(Prim('cone', bone, k=0.002, region='teeth', a=base, b=tip, r1=0.012, r2=0.003))
        pts = [mouth_arc(th, 0.05) + v3(0, 0, 0.065 * row) for th in np.linspace(-80, 80, 9)]
        P += chain(pts, [0.022] * 9, bone, k=0.015, region='gum')
    return P


def eye_prims():
    """Huge black eyeballs (textured part); the pupils are the glow part."""
    return [Prim('sphere', 'Head', k=0.0, region='eye', c=(0.115 * s, -0.205, 6.62), r=0.08) for s in (1, -1)]


def pupil_prims():
    return [Prim('sphere', 'Head', k=0.0, region='glow', c=(0.11 * s, -0.283, 6.615), r=0.010) for s in (1, -1)]


def hair_prims():
    P = []
    rng = np.random.default_rng(8)
    C = v3(0, 0.04, 6.66)
    R = v3(0.335, 0.405, 0.415)
    for i in range(46):
        # root on the scalp (top / back / sides, never the face)
        az = rng.uniform(-math.pi * 0.62, math.pi * 0.62) + math.pi  # around the back
        el = math.radians(rng.uniform(5, 80))
        root = C + R * v3(math.cos(el) * math.sin(az), -math.cos(el) * math.cos(az), math.sin(el))
        side = 'L' if root[0] > 0.12 else ('R' if root[0] < -0.12 else 'B')
        sx = root[0]
        # hug the skull down to the nape, then fall down the back
        nape = v3(sx * 1.05, 0.32 + 0.1 * rng.random(), 6.25)
        end = v3(sx * 1.1 + rng.normal(0, 0.06), 0.42 + 0.12 * rng.random(), 4.75 + rng.uniform(-0.3, 0.5))
        out = (root - C) / np.linalg.norm(root - C)
        path = bezier(root, root + out * 0.10 + v3(0, 0.12, -0.12), nape + v3(0, 0.06, 0.2), nape, 3)
        path += bezier(nape, nape + v3(0, 0.05, -0.4), end + v3(0, 0, 0.5), end, 4)[1:]
        r0 = 0.028 + 0.016 * rng.random()
        n = len(path)
        for k in range(n - 1):
            u = k / (n - 1)
            bone = 'Head' if path[k][2] > 6.3 else (f'Hair{side}1' if path[k][2] > 5.6 else f'Hair{side}2')
            P.append(Prim('cone', bone, k=0.035, region='hair', a=path[k], b=path[k + 1],
                          r1=r0 * (1 - 0.55 * u), r2=r0 * (1 - 0.55 * (k + 1) / (n - 1)) + 0.004))
    return P


def circlet_prims():
    P = [Prim('func', 'Head', k=0.0, region='bronze', lo=(-0.4, -0.45, 6.75), hi=(0.4, 0.45, 7.0),
              fn=lambda X: _torus(X, (0, 0.04, 6.86), 0.345, 0.40, 0.022))]
    for s in (1, 0, -1):  # three small leaf pendants at the brow
        c = v3(0.12 * s, -0.36 + 0.04 * abs(s), 6.83)
        P.append(Prim('ellip', 'Head', k=0.01, region='bronze', c=c, r=(0.035, 0.012, 0.06), rot=(0, 0, 20 * s)))
    return P


def _torus(X, c, rx, ry, r):
    q = X - v3(c)
    e = np.sqrt((q[:, 0] / rx) ** 2 + (q[:, 1] / ry) ** 2)
    rho = (e - 1.0) * 0.5 * (rx + ry)
    return np.sqrt(rho ** 2 + q[:, 2] ** 2) - r


def pieces():
    body = Scene(body_prims())
    wsc = Scene([p for p in body.prims if p.kind != 'func'] + tail_weight_prims())
    return [
        bk.Piece('body', body, tris=5200, voxel=0.018, falloff=0.08, lo_voxel=0.03, weight_scene=wsc),
        bk.Piece('fins', Scene(fin_prims()), tris=1500, voxel=0.009, falloff=0.06, mat='fin', smooth=0,
                 weight_scene=None),
        bk.Piece('hands', Scene(hand_prims()), tris=1300, voxel=0.008, falloff=0.03),
        bk.Piece('hair', Scene(hair_prims()), tris=1700, voxel=0.012, falloff=0.08, mat='hair'),
        bk.Piece('teeth', Scene(teeth_prims()), tris=700, voxel=0.0045, mat='teeth', falloff=0.02),
        bk.Piece('eyes', Scene(eye_prims()), tris=200, voxel=0.008, rigid='Head', mat='teeth'),
        bk.Piece('circlet', Scene(circlet_prims()), tris=400, voxel=0.007, rigid='Head', mat='hair'),
        bk.Piece('pupils', Scene(pupil_prims()), tris=60, voxel=0.004, rigid='Head', group='glow', mat='teeth'),
    ]


# ----------------------------------------------------------------- materials
def mat_skin(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n1 = nk.noise(co, 2.0, 6, 0.6).outputs['Fac']
    skin = nk.ramp(n1, [(0.3, (0.20, 0.24, 0.25)), (0.55, (0.30, 0.34, 0.34)), (0.78, (0.38, 0.40, 0.38))])
    blot = nk.maprange(nk.noise(co, 1.1, 4, 0.55).outputs['Fac'], 0.52, 0.7)
    skin = nk.mix(nk.math('MULTIPLY', blot, 0.6), skin, (0.12, 0.16, 0.17))  # drowned blue-green blotches
    vn = nk.noise(co, 4.0, 3, 0.45, dist=0.8).outputs['Fac']
    vein = nk.maprange(nk.math('ABSOLUTE', nk.math('SUBTRACT', vn, 0.5)), 0.0, 0.02, 1.0, 0.0)
    skin = nk.mix(nk.math('MULTIPLY', vein, 0.55), skin, (0.08, 0.12, 0.20))
    # tail: dark eel scales fading in from the hips, paler belly
    tail = nk.attr('rg_tail')
    sc = nk.voronoi(nk.vmath('MULTIPLY', co, (1.0, 1.0, 1.0)), 18.0)
    scale_edge = nk.maprange(sc.outputs['Distance'], 0.0, 0.25)
    xyz = nk.node('ShaderNodeSeparateXYZ')
    nk.set(xyz.inputs[0], co)
    belly = nk.maprange(xyz.outputs['Y'], -0.2, 0.6, 1.0, 0.0)
    tcol = nk.mix(nk.noise(co, 3.0, 4, 0.5).outputs['Fac'], (0.03, 0.05, 0.055), (0.07, 0.10, 0.10))
    tcol = nk.mix(nk.math('MULTIPLY', belly, 0.4), tcol, (0.18, 0.20, 0.19))
    tcol = nk.mix(nk.math('MULTIPLY', nk.math('SUBTRACT', 1, scale_edge), 0.6), tcol, (0.02, 0.025, 0.03))
    col = nk.mix(tail, skin, tcol)
    eye = nk.attr('rg_eye')
    nail = nk.attr('rg_nail')
    fin = nk.attr('rg_fin')
    col = nk.mix(eye, col, (0.004, 0.004, 0.005))
    col = nk.mix(nail, col, (0.06, 0.06, 0.05))
    col = nk.mix(fin, col, (0.26, 0.30, 0.30))
    wet = nk.maprange(nk.noise(co, 3.0, 4, 0.5).outputs['Fac'], 0.4, 0.6, 0.25, 0.5)
    rough = nk.mixf(tail, wet, 0.3)
    rough = nk.mixf(eye, rough, 0.55)
    h = nk.math('ADD', nk.math('MULTIPLY', nk.noise(co, 22.0, 8, 0.6).outputs['Fac'], 0.6),
                nk.math('MULTIPLY', vein, 0.3))
    h = nk.mixf(tail, h, nk.math('ADD', scale_edge, nk.math('MULTIPLY', nk.noise(co, 40.0, 3, 0.5).outputs['Fac'], 0.2)))
    nk.finish(col, rough, 0.0, nk.bump(h, 0.3, 0.008), sss=0.15)
    return mat


def mat_fin(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n = nk.noise(co, 6.0, 5, 0.6).outputs['Fac']
    spine = nk.attr('rg_spine')
    mem = nk.ramp(n, [(0.3, (0.16, 0.20, 0.21)), (0.7, (0.32, 0.36, 0.35))])
    tear = nk.maprange(nk.noise(co, 14.0, 4, 0.6).outputs['Fac'], 0.6, 0.7)
    mem = nk.mix(nk.math('MULTIPLY', tear, 0.7), mem, (0.06, 0.07, 0.08))
    col = nk.mix(spine, mem, (0.05, 0.06, 0.065))
    rough = nk.mixf(spine, 0.28, 0.4)
    h = nk.wave(co, 30.0, 3.0, 2.0, 'BANDS', 'Y').outputs['Fac']
    nk.finish(col, rough, 0.0, nk.bump(h, 0.2, 0.004), sss=0.3)
    return mat


def mat_hair(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n = nk.noise(co, 5.0, 5, 0.6).outputs['Fac']
    hair = nk.mix(n, (0.01, 0.014, 0.012), (0.035, 0.045, 0.038))
    weed = nk.maprange(nk.noise(co, 2.5, 4, 0.5).outputs['Fac'], 0.58, 0.7)
    hair = nk.mix(nk.math('MULTIPLY', weed, 0.6), hair, (0.04, 0.07, 0.03))  # strands of weed
    bronze = nk.attr('rg_bronze')
    verd = nk.maprange(nk.noise(co, 18.0, 4, 0.6).outputs['Fac'], 0.45, 0.6)
    bcol = nk.mix(verd, (0.38, 0.24, 0.10), (0.15, 0.32, 0.26))
    col = nk.mix(bronze, hair, bcol)
    rough = nk.mixf(bronze, 0.32, nk.mixf(verd, 0.35, 0.75))
    metal = nk.mixf(bronze, 0.0, nk.mixf(verd, 1.0, 0.0))
    h = nk.wave(co, 60.0, 4.0, 2.0, 'BANDS', 'Z').outputs['Fac']
    h = nk.mixf(bronze, h, nk.noise(co, 50.0, 4, 0.6).outputs['Fac'])
    nk.finish(col, rough, metal, nk.bump(h, 0.25, 0.005))
    return mat


def mat_teeth(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n = nk.noise(co, 30.0, 4, 0.5).outputs['Fac']
    gum = nk.attr('rg_gum')
    eye = nk.attr('rg_eye')
    col = nk.ramp(n, [(0.35, (0.42, 0.42, 0.38)), (0.65, (0.62, 0.62, 0.56))])
    col = nk.mix(gum, col, (0.05, 0.02, 0.03))
    col = nk.mix(eye, col, (0.004, 0.004, 0.005))
    rough = nk.mixf(eye, nk.mixf(gum, 0.25, 0.3), 0.55)
    nk.finish(col, rough, 0.0, nk.bump(n, 0.1, 0.003))
    return mat


MATERIALS = {'skin': mat_skin, 'fin': mat_fin, 'hair': mat_hair, 'teeth': mat_teeth}


# ----------------------------------------------------------------- animation
SIDES = (('L', 1), ('R', -1))
NT = len(TAIL) - 1


def tail_wave(p, t, amp=14.0, speed=1.0, waves=1.0, yaw=4.0, base=None):
    """Dolphin-style vertical undulation travelling down the tail."""
    for k in range(NT):
        ph = speed * t - waves * k / NT
        a = amp * (0.35 + 0.65 * k / NT) * mo.s(ph)
        y = yaw * mo.s(ph * 0.5 + 0.2) * (k / NT)
        b = base[k] if base else 0.0
        if k == 0:
            p['Hips'] = bk.pose_mul({'Hips': p.get('Hips', (0, 0, 0))}, {'Hips': (a * 0.25, 0, 0)})['Hips']
        p[f'Tail{k + 1}'] = (a + b, 0, y)
    return p


def hair_drift(p, t, amp=8.0, lift=0.0, freq=1.0):
    for side, ph in (('L', 0.0), ('R', 0.33), ('B', 0.66)):
        sx = 1 if side == 'L' else (-1 if side == 'R' else 0)
        p[f'Hair{side}1'] = (lift * 0.5 + amp * mo.s(freq * t + ph) * 0.6, amp * 0.3 * mo.s(freq * t + ph + 0.2), 0)
        p[f'Hair{side}2'] = (lift * 0.6 + amp * mo.s(freq * t + ph - 0.15), sx * amp * 0.3, 0)
    return p


def fingers(curl, thumb=None):
    return bk.sym({'Fingers1_L': (0, curl, 0), 'Fingers2_L': (0, curl * 1.3, 0),
                   'Thumb_L': (0, (thumb if thumb is not None else curl) * 0.6, 0)})


def arms_drift(an, p, t, out=0.45, fwd=0.15, wave=0.06, curl=14):
    for tt, sgn in SIDES:
        ph = 0 if tt == 'L' else 0.5
        an.aim(p, f'UpperArm_{tt}', (out * sgn, -0.10 + fwd + wave * mo.s(t + ph), -1 + 0.1 * mo.s(t + ph + 0.2)))
        an.aim(p, f'LowerArm_{tt}', (out * 0.5 * sgn, -0.40 + fwd + wave * 1.5 * mo.s(t + ph - 0.1), -1))
        an.aim(p, f'Hand_{tt}', (0.1 * sgn, -0.5 + wave * 2 * mo.s(t + ph - 0.2), -1))
    p.update(fingers(curl))
    return p


def frills(p, flare):
    p['Frill_L'] = (0, -flare, flare * 0.6)
    p['Frill_R'] = bk.mirror_q(bk.Q((0, -flare, flare * 0.6)))
    return p


def body(p, bow=0.0, look=0.0, roll=0.0, twist=0.0):
    p['Spine'] = (bow * 0.4, roll * 0.3, twist * 0.4)
    p['Chest'] = (bow * 0.6, roll * 0.3, twist * 0.6)
    p['Neck'] = (bow * 0.1 - look * 0.4, roll * 0.3, 0)
    p['Head'] = (-bow * 0.6 - look * 0.6, roll, 0)
    return p


def clips(an):
    out = []

    def idle(t):
        p = {'@root': (0.06 * mo.s(t), 0.05 * mo.c(t), 0.35 + 0.12 * mo.s(t))}
        body(p, bow=6 + 3 * mo.s(t), look=4 * mo.s(t + 0.25), roll=10 * mo.s(t + 0.1), twist=6 * mo.s(t))
        tail_wave(p, t, amp=9, speed=1, waves=0.8)
        hair_drift(p, t, amp=10, lift=10)
        arms_drift(an, p, t)
        frills(p, 6 * mo.s(2 * t))
        p['Jaw'] = (5 + 3 * mo.s(2 * t), 0, 0)
        return p
    out.append(('Idle', 120, idle, True))

    def swim(t, fast=False):
        k = 1.0 if not fast else 1.6
        p = {'@root': (0, 0, 0.25 + 0.10 * mo.s(t) * k)}
        p['Hips'] = (8 * k, 0, 0)
        body(p, bow=18 * k, look=22 * k, roll=6 * mo.s(t), twist=5 * mo.s(t))
        tail_wave(p, t, amp=16 * k, speed=1, waves=1.0, yaw=3)
        hair_drift(p, t, amp=8 * k, lift=30 * k)
        if fast:
            for tt, sgn in SIDES:
                an.aim(p, f'UpperArm_{tt}', (0.45 * sgn, -1.0, -0.25))
                an.aim(p, f'LowerArm_{tt}', (0.2 * sgn, -1.0, -0.15))
                an.aim(p, f'Hand_{tt}', (0.1 * sgn, -1.0, -0.2))
            p.update(fingers(-6))
            p['Jaw'] = (24 + 6 * mo.s(2 * t), 0, 0)
        else:
            for tt, sgn in SIDES:
                ph = 0 if tt == 'L' else 0.0
                stroke = mo.s(t + ph)
                an.aim(p, f'UpperArm_{tt}', (0.7 * sgn, 0.1 + 0.5 * stroke, -0.5 - 0.3 * stroke))
                an.aim(p, f'LowerArm_{tt}', (0.4 * sgn, 0.2 + 0.6 * stroke, -0.7))
                an.aim(p, f'Hand_{tt}', (0.2 * sgn, 0.4 + 0.5 * stroke, -0.8))
            p.update(fingers(10))
            p['Jaw'] = (6, 0, 0)
        frills(p, -12 * k)
        return p
    out.append(('Swim', 48, lambda t: swim(t), True))
    out.append(('SwimFast', 24, lambda t: swim(t, True), True))

    # ---- Sing: head lifts, mouth opens, arms open, frills spread (loop while slowing players)
    def sing(t):
        p = {'@root': (0.03 * mo.s(t), 0, 0.45 + 0.06 * mo.s(2 * t))}
        body(p, bow=-6, look=-14 + 4 * mo.s(t), roll=14 * mo.s(t), twist=4 * mo.s(t + 0.3))
        tail_wave(p, t, amp=7, speed=1, waves=0.8)
        hair_drift(p, t, amp=12, lift=20)
        for tt, sgn in SIDES:
            ph = 0 if tt == 'L' else 0.5
            an.aim(p, f'UpperArm_{tt}', (1.0 * sgn, -0.5, -0.35 + 0.15 * mo.s(t + ph)))
            an.aim(p, f'LowerArm_{tt}', (0.8 * sgn, -0.9, -0.1 + 0.2 * mo.s(t + ph + 0.1)))
            an.aim(p, f'Hand_{tt}', (0.4 * sgn, -1.0, 0.2 * mo.s(t + ph + 0.2)))
        p.update(fingers(-8))
        frills(p, 22 + 6 * mo.s(2 * t))
        p['Jaw'] = (16 + 6 * mo.s(3 * t), 0, 0)
        return p
    out.append(('Sing', 90, sing, True))

    base0 = idle(0)

    # ---- Attack: coils back, lunges, both hands clamp, jaw unhinges
    def k_coil():
        p = {'@root': (0, 0.8, 0.6)}
        p['Hips'] = (-14, 0, 0)
        body(p, bow=-18, look=-10)
        tail_wave(p, 0.25, amp=24, speed=1, waves=0.6)
        hair_drift(p, 0, amp=0, lift=-10)
        for tt, sgn in SIDES:
            an.aim(p, f'UpperArm_{tt}', (1.0 * sgn, 0.4, 0.2))
            an.aim(p, f'LowerArm_{tt}', (0.6 * sgn, -0.6, 0.6))
            an.aim(p, f'Hand_{tt}', (0.2 * sgn, -1.0, 0.4))
        p.update(fingers(-10))
        frills(p, 30)
        p['Jaw'] = (30, 0, 0)
        return p

    def k_lunge(close=False):
        p = {'@root': (0, -1.6, -0.2)}
        p['Hips'] = (22, 0, 0)
        body(p, bow=34, look=36)
        tail_wave(p, 0.75, amp=20, speed=1, waves=0.6)
        hair_drift(p, 0, amp=0, lift=45)
        for tt, sgn in SIDES:
            mo.ik2(an, p, f'UpperArm_{tt}', f'LowerArm_{tt}', mo.Vector((0.35 * sgn, -3.4, 4.2)), (sgn, 0.3, -0.5))
            an.aim(p, f'Hand_{tt}', (-0.1 * sgn, -1.0, -0.1))
        p.update(fingers(60 if close else -10, 40 if close else -6))
        frills(p, 34)
        p['Jaw'] = (50 if not close else 34, 0, 0)
        return p
    out.append(('Attack', 42, bk.track([(0, base0), (0.3, k_coil()), (0.45, k_lunge(), 'snap'),
                                        (0.55, k_lunge(True), 'snap'), (0.8, k_lunge(True)), (1.0, base0)]), False))

    # ---- Scream: jaw unhinges impossibly wide, frills snap open, arms thrown back
    def k_scream(sh=0.0):
        p = {'@root': (0, 0.3, 0.55)}
        body(p, bow=-14, look=-8, roll=sh * 8)
        p['Head'] = bk.pose_mul({'Head': p['Head']}, {'Head': (0, 0, sh * 10)})['Head']
        tail_wave(p, 0.1, amp=12, speed=1, waves=0.6)
        hair_drift(p, 0, amp=0, lift=40)
        for tt, sgn in SIDES:
            an.aim(p, f'UpperArm_{tt}', (1.0 * sgn, 0.6, -0.2))
            an.aim(p, f'LowerArm_{tt}', (0.8 * sgn, 0.6, 0.2))
            an.aim(p, f'Hand_{tt}', (0.6 * sgn, 0.4, 0.4))
        p.update(fingers(-14))
        frills(p, 40)
        p['Jaw'] = (62, 0, 0)
        return p
    seq = [(0, base0), (0.15, k_scream(), 'snap')]
    for i in range(8):
        seq.append((0.2 + i * 0.07, k_scream((1 if i % 2 else -1) * 0.6)))
    seq += [(0.85, k_scream()), (1.0, base0)]
    out.append(('Scream', 45, bk.track(seq), False))

    # ---- Manifest: rises out of the floor as if surfacing; Vanish: dives back down
    def k_under():
        p = {'@root': (0, -0.6, -5.0)}
        p['Hips'] = (-40, 0, 0)
        body(p, bow=-20, look=-30)
        tail_wave(p, 0.5, amp=6, speed=1, waves=0.5)
        hair_drift(p, 0, amp=0, lift=-30)
        arms_drift(an, p, 0, out=0.2, fwd=0.6)
        frills(p, -15)
        return p

    def k_surface():
        p = idle(0.0)
        p['@root'] = (0, 0, 0.9)
        p = body(p, bow=-10, look=-20)
        hair_drift(p, 0, amp=0, lift=-20)
        return p
    out.append(('Manifest', 60, bk.track([(0, k_under()), (0.6, k_surface(), 'out'), (1.0, base0)]), False))

    def k_dive():
        p = {'@root': (0, -0.8, -5.5)}
        p['Hips'] = (60, 0, 0)
        body(p, bow=40, look=10)
        tail_wave(p, 0.2, amp=14, speed=1, waves=0.6)
        hair_drift(p, 0, amp=0, lift=50)
        for tt, sgn in SIDES:
            an.aim(p, f'UpperArm_{tt}', (0.3 * sgn, -0.6, -1))
            an.aim(p, f'LowerArm_{tt}', (0.1 * sgn, -0.3, -1))
            an.aim(p, f'Hand_{tt}', (0.0, -0.2, -1))
        frills(p, -15)
        return p
    out.append(('Vanish', 36, bk.track([(0, base0), (0.25, k_coil()), (1.0, k_dive(), 'in')]), False))
    return out


if __name__ == '__main__':
    import pipeline
    pipeline.build(sys.modules[__name__])
