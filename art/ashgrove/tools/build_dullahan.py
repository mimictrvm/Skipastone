"""AH_Ent_Dullahan — the headless rider, on foot in the portrait gallery.

Folklore (Ireland): the Dullahan rides at night carrying its own head, which
grins from ear to ear and has small eyes that dart about; it uses a human
spine as a whip.  Ours has lost its horse: a tall figure in a soaked,
caped coachman's greatcoat, the hood standing up stiff around nothing.

The carried head is its own mesh (AH_Ent_Dullahan_Head + _HeadGlow) so the
camera code can hide it: the Dullahan "appears headless in photos".

Run:  python3 build_dullahan.py   (--preview for a quick sculpt check)
"""
import math
import sys

import numpy as np

sys.path.insert(0, __file__.rsplit('/', 1)[0])
import blendkit as bk  # noqa: E402
import motion as mo  # noqa: E402
from sdf import Prim, Scene, bezier, chain, drape, fbm, v3  # noqa: E402

NAME = 'Dullahan'
TAGLINE = ('Headless rider on foot: caped coachman\'s greatcoat, empty hood over a neck stump, '
           'carries its grinning head by the hair and a whip made from a human spine.')
GLOW_COLOR = (1.0, 0.32, 0.12)
GLOW_STRENGTH = 5.0
GLOW_NOTE = 'eyes of the carried head: ember red, Neon #FF5220 (part of the Head set)'
MOOD_POSE = ('Idle', 0.3)
MOOD_DIST = 9.0
ANIM_ZOOM = 1.15
BAKE = {'extrusion': 0.035, 'ray': 0.12, 'samples': 6}
SHEET_NOTES = [
    'Photo mechanic: hide AH_Ent_Dullahan_Head and AH_Ent_Dullahan_HeadGlow (Transparency = 1) in the photo render.',
    'Read in the dark: tall caped silhouette with an empty hood; the two ember eyes swing at hip height. '
    'Collision: 3×8×2 box, not walkable.',
]
PREVIEW_CLOSEUPS = [('head', (0, -1, 0.05), (2.82, -0.05, 3.3), 1.9), ('head3q', (-0.7, -1, 0.1), (2.82, -0.05, 3.3), 1.9),
                    ('hood', (-0.5, -1, 0.5), (0, 0, 6.6), 2.2), ('whip', (0.3, -1, 0.2), (-2.82, 0, 2.3), 4.6)]

# ------------------------------------------------------------------ skeleton
J = dict(root=v3(0, 0, 0), hrp=v3(0, 0.02, 3.70), pelvis=v3(0, 0.02, 3.62), waist=v3(0, 0.02, 4.32),
         chest=v3(0, 0.0, 5.10), neck=v3(0, 0.02, 6.30), necktop=v3(0, 0.0, 6.80))
SIDE = dict(clav=v3(0.12, -0.02, 6.12), shoulder=v3(1.0, 0.04, 6.18), elbow=v3(1.85, 0.12, 5.30),
            wrist=v3(2.58, 0.0, 4.50), fist=v3(2.80, -0.05, 4.29),
            hip=v3(0.38, 0.02, 3.55), knee=v3(0.42, -0.10, 1.90), ankle=v3(0.44, 0.10, 0.40),
            ball=v3(0.45, -0.36, 0.11), toe=v3(0.46, -0.62, 0.07))
HEAD_C = v3(2.80, -0.05, 3.25)       # carried head centre (left hand)
WHIP_TOP = v3(-2.80, -0.05, 4.29)    # right fist
WHIP_N = 8
WHIP_LEN = 4.05
COAT_SECTORS = {'Back': 180, 'L': 100, 'R': -100, 'FL': 38, 'FR': -38}
SKIRT = dict(z_top=4.25, z_bot=0.32, r_top=(0.64, 0.52), r_bot=(1.30, 1.08), centre=(0.0, 0.06))


def S(key, s=1):
    p = SIDE[key].copy()
    p[0] *= s
    return p


def arm_frame(s):
    a = S('wrist', s) - S('elbow', s)
    a /= np.linalg.norm(a)
    n = v3(-0.57 * s, 0, -0.82)
    n = n - a * np.dot(n, a)
    n /= np.linalg.norm(n)
    sp = np.cross(a, n) * s
    return a, n, sp


def skirt_point(theta_deg, z, inset=0.92):
    sk = SKIRT
    u = np.clip((sk['z_top'] - z) / (sk['z_top'] - sk['z_bot']), 0, 1)
    us = u * u * (3 - 2 * u)
    rx = sk['r_top'][0] + (sk['r_bot'][0] - sk['r_top'][0]) * us
    ry = sk['r_top'][1] + (sk['r_bot'][1] - sk['r_top'][1]) * us
    th = math.radians(theta_deg)
    return v3(sk['centre'][0] + rx * inset * math.sin(th), sk['centre'][1] - ry * inset * math.cos(th), z)


def whip_joint(k):
    return WHIP_TOP + v3(0, 0, -WHIP_LEN * k / WHIP_N)


def bones():
    b = [
        dict(name='Root', head=J['root'], tail=J['root'] + v3(0, 0, 0.6), deform=False),
        dict(name='HumanoidRootNode', head=J['hrp'], tail=J['hrp'] + v3(0, 0, 0.5), parent='Root', deform=False),
        dict(name='Hips', head=J['pelvis'], tail=J['waist'], parent='HumanoidRootNode'),
        dict(name='Spine', head=J['waist'], tail=J['chest'], parent='Hips'),
        dict(name='Chest', head=J['chest'], tail=J['neck'], parent='Spine'),
        dict(name='Neck', head=J['neck'], tail=J['necktop'], parent='Chest'),
        dict(name='Hood', head=v3(0, 0.16, 6.45), tail=v3(0, 0.16, 7.55), parent='Chest'),
        dict(name='CapeBack', head=v3(0, 0.45, 6.2), tail=v3(0, 0.8, 5.25), parent='Chest'),
        dict(name='CapeL', head=v3(0.9, 0.0, 6.3), tail=v3(1.45, 0.0, 5.45), parent='Clavicle_L'),
        dict(name='CapeR', head=v3(-0.9, 0.0, 6.3), tail=v3(-1.45, 0.0, 5.45), parent='Clavicle_R'),
    ]
    for s, t in ((1, 'L'), (-1, 'R')):
        a, n, sp = arm_frame(s)
        b += [
            dict(name=f'Clavicle_{t}', head=S('clav', s), tail=S('shoulder', s), parent='Chest'),
            dict(name=f'UpperArm_{t}', head=S('shoulder', s), tail=S('elbow', s), parent=f'Clavicle_{t}'),
            dict(name=f'LowerArm_{t}', head=S('elbow', s), tail=S('wrist', s), parent=f'UpperArm_{t}'),
            dict(name=f'Hand_{t}', head=S('wrist', s), tail=S('fist', s), parent=f'LowerArm_{t}', roll_to=tuple(n)),
            dict(name=f'UpperLeg_{t}', head=S('hip', s), tail=S('knee', s), parent='Hips'),
            dict(name=f'LowerLeg_{t}', head=S('knee', s), tail=S('ankle', s), parent=f'UpperLeg_{t}'),
            dict(name=f'Foot_{t}', head=S('ankle', s), tail=S('ball', s), parent=f'LowerLeg_{t}', roll_to=(0, 0, 1)),
            dict(name=f'Toe_{t}', head=S('ball', s), tail=S('toe', s), parent=f'Foot_{t}', roll_to=(0, 0, 1)),
        ]
    # bones must be created parent-first: move the capes after the clavicles
    order = [x for x in b if not x['name'].startswith('Cape')] + [x for x in b if x['name'].startswith('Cape')]
    b = order
    for name, ang in COAT_SECTORS.items():
        p0, p1, p2 = skirt_point(ang, 4.05, 0.9), skirt_point(ang, 2.25, 0.9), skirt_point(ang, 0.45, 0.9)
        b.append(dict(name=f'Coat{name}1', head=p0, tail=p1, parent='Hips'))
        b.append(dict(name=f'Coat{name}2', head=p1, tail=p2, parent=f'Coat{name}1'))
    b.append(dict(name='HeadProp', head=S('fist', 1), tail=HEAD_C, parent='Hand_L'))
    b.append(dict(name='HeadJaw', head=HEAD_C + v3(0, 0.02, -0.12), tail=HEAD_C + v3(0, -0.30, -0.42),
                  parent='HeadProp', roll_to=(0, 0, 1)))
    for k in range(WHIP_N):
        b.append(dict(name=f'Whip{k + 1}', head=whip_joint(k), tail=whip_joint(k + 1),
                      parent='Hand_R' if k == 0 else f'Whip{k}'))
    return b


# ---------------------------------------------------------------- the sculpt
def surface_y(prims, x, z, y0=-2.0, y1=1.0, n=600):
    sc = Scene(prims)
    ys = np.linspace(y0, y1, n)
    P = np.stack([np.full(n, x), ys, np.full(n, z)], 1)
    d = sc.eval(P)
    i = np.argmax(d < 0)
    return float(ys[max(i - 1, 0)])


def body_prims():
    P = []
    # torso in the coat
    P.append(Prim('ellip', 'Chest', k=0.0, region='coat', c=(0, 0.02, 5.40), r=(0.80, 0.52, 0.88)))
    P.append(Prim('cone', 'Spine', k=0.18, squash=(1.0, 0.80), region='coat', a=(0, 0.03, 3.95), b=(0, 0.02, 4.85),
                  r1=0.60, r2=0.66))
    P.append(Prim('ellip', 'Hips', k=0.15, region='coat', c=(0, 0.05, 3.70), r=(0.64, 0.48, 0.42)))
    for s, t in ((1, 'L'), (-1, 'R')):
        P.append(Prim('ellip', f'Clavicle_{t}', k=0.18, region='coat', c=(0.78 * s, 0.03, 6.02), r=(0.36, 0.32, 0.26)))
    # high standing collar + the stump
    P.append(Prim('cone', 'Chest', k=0.08, region='coat', a=(0, 0.04, 6.05), b=(0, 0.05, 6.55), r1=0.40, r2=0.37,
                  squash=(1.0, 0.92)))
    P.append(Prim('cone', None, op='sub', k=0.03, a=(0, 0.04, 6.30), b=(0, 0.05, 6.70), r1=0.27, r2=0.29))
    P.append(Prim('cone', 'Neck', k=0.05, region='skin', a=(0, 0.03, 6.20), b=(0, 0.02, 6.74), r1=0.22, r2=0.19))
    P.append(Prim('box', None, op='sub', k=0.01, c=(0, 0, 7.02), h=(0.5, 0.5, 0.25), disp=(0.025, 18.0, 4)))
    P.append(Prim('ellip', 'Neck', k=0.03, region='gore', c=(0, 0.02, 6.755), r=(0.175, 0.165, 0.03),
                  disp=(0.012, 22.0, 6)))
    P.append(Prim('cone', 'Neck', k=0.02, region='bone', a=(0, 0.08, 6.68), b=(0, 0.085, 6.87), r1=0.065, r2=0.05))
    P.append(Prim('ellip', 'Neck', k=0.015, region='bone', c=(0, 0.14, 6.84), r=(0.03, 0.06, 0.025)))
    # sleeves
    for s, t in ((1, 'L'), (-1, 'R')):
        sh, el, wr = S('shoulder', s), S('elbow', s), S('wrist', s)
        a, n, sp = arm_frame(s)
        P.append(Prim('sphere', f'UpperArm_{t}', k=0.12, region='coat', c=sh + v3(0.02 * s, 0, -0.02), r=0.30))
        P.append(Prim('cone', f'UpperArm_{t}', k=0.08, region='coat', a=sh, b=el, r1=0.28, r2=0.22))
        P.append(Prim('sphere', f'LowerArm_{t}', k=0.08, region='coat', c=el + v3(0, 0.03, 0), r=0.22))
        P.append(Prim('cone', f'LowerArm_{t}', k=0.06, region='coat', a=el, b=wr - a * 0.08, r1=0.215, r2=0.20))
        # turned-back cuff
        P.append(Prim('cone', f'LowerArm_{t}', k=0.02, region='cuff', a=wr - a * 0.50, b=wr - a * 0.04,
                      r1=0.25, r2=0.28))
        P.append(Prim('cone', None, op='sub', k=0.02, a=wr - a * 0.10, b=wr + a * 0.2, r1=0.16, r2=0.16))
    # legs: trousers + tall riding boots
    for s, t in ((1, 'L'), (-1, 'R')):
        hp, kn, an, ba, to = S('hip', s), S('knee', s), S('ankle', s), S('ball', s), S('toe', s)
        P.append(Prim('cone', f'UpperLeg_{t}', k=0.12, region='wool', a=hp, b=kn, r1=0.31, r2=0.21))
        P.append(Prim('sphere', f'LowerLeg_{t}', k=0.06, region='wool', c=kn + v3(0, -0.02, 0.05), r=0.21))
        P.append(Prim('cone', f'LowerLeg_{t}', k=0.05, region='leather', a=kn + v3(0, -0.04, 0.32),
                      b=kn + v3(0, -0.02, -0.06), r1=0.26, r2=0.235))  # boot top
        P.append(Prim('cone', f'LowerLeg_{t}', k=0.06, region='leather', a=kn, b=an, r1=0.22, r2=0.16))
        P.append(Prim('ellip', f'LowerLeg_{t}', k=0.06, region='leather', c=kn + (an - kn) * 0.3 + v3(0, 0.06, 0),
                      r=(0.18, 0.18, 0.42)))  # calf
        P.append(Prim('cone', f'Foot_{t}', k=0.07, region='leather', squash=(1.0, 0.72), a=an, b=ba, r1=0.16, r2=0.14))
        P.append(Prim('ellip', f'Foot_{t}', k=0.05, region='leather', c=an + v3(0, 0.09, -0.24), r=(0.14, 0.15, 0.12)))
        P.append(Prim('cone', f'Toe_{t}', k=0.05, region='leather', squash=(1.0, 0.62), a=ba, b=to, r1=0.14,
                      r2=0.085))
        P.append(Prim('box', f'Foot_{t}', k=0.03, region='sole', c=(0.45 * s, -0.18, 0.03), h=(0.15, 0.48, 0.03),
                      round=0.02))
        P.append(Prim('box', f'Foot_{t}', k=0.02, region='sole', c=(0.44 * s, 0.17, 0.07), h=(0.13, 0.12, 0.07),
                      round=0.02))  # heel
    # belt, buckle, buttons, lapel edges
    P.append(Prim('cone', 'Spine', k=0.02, region='leather', squash=(1.0, 0.82), a=(0, 0.03, 3.98), b=(0, 0.03, 4.16),
                  r1=0.665, r2=0.665))
    base = list(P)
    yb = surface_y(base, 0.0, 4.07)
    P.append(Prim('box', 'Spine', k=0.01, region='brass', c=(0, yb - 0.02, 4.07), h=(0.12, 0.03, 0.09), round=0.015))
    P.append(Prim('box', None, op='sub', k=0.005, c=(0, yb - 0.05, 4.07), h=(0.07, 0.03, 0.045)))
    for row, x in enumerate((0.20, -0.20, 0.0)):
        if x == 0.0:
            continue
        for i in range(6):
            z = 4.40 + i * 0.26
            y = surface_y(base, x, z)
            P.append(Prim('sphere', 'Spine' if z < 5.0 else 'Chest', k=0.008, region='brass', c=(x, y + 0.005, z),
                          r=0.042))
    for s in (1, -1):
        pts = []
        for z in np.linspace(6.1, 4.3, 7):
            x = s * (0.07 + 0.12 * (6.1 - z) / 1.8 + 0.12 * max(0, z - 5.5))
            pts.append(v3(x, surface_y(base, x, z) + 0.01, z))
        P += chain(pts, [0.03] * len(pts), ['Chest' if p[2] > 5.0 else 'Spine' for p in pts], k=0.03, region='coat')
    return P


def fist_prims():
    P = []
    for s, t in ((1, 'L'), (-1, 'R')):
        a, n, sp = arm_frame(s)
        wr, fi = S('wrist', s), S('fist', s)
        R = np.stack([a, sp, n], 1)
        P.append(Prim('cone', f'LowerArm_{t}', k=0.04, region='leather', a=wr - a * 0.40, b=wr - a * 0.02,
                      r1=0.17, r2=0.205))  # gauntlet cuff
        P.append(Prim('cone', f'Hand_{t}', k=0.06, region='leather', a=wr - a * 0.05, b=fi - a * 0.05, r1=0.13, r2=0.13,
                      squash=(1.1, 0.8), up=tuple(n)))
        P.append(Prim('box', f'Hand_{t}', k=0.05, region='leather', c=fi + a * 0.02 + n * 0.03, h=(0.11, 0.15, 0.10),
                      rot=R, round=0.05))
        for i in range(4):  # knuckles
            P.append(Prim('sphere', f'Hand_{t}', k=0.03, region='leather',
                          c=fi + a * 0.13 + sp * (-0.12 + 0.08 * i) - n * 0.02, r=0.055))
        P.append(Prim('cone', f'Hand_{t}', k=0.03, region='leather', a=fi - a * 0.06 - sp * 0.15 + n * 0.05,
                      b=fi + a * 0.10 - sp * 0.10 + n * 0.12, r1=0.06, r2=0.05))  # thumb
    return P


def whip_prims():
    P = []
    top = WHIP_TOP
    # leather-wrapped grip through the fist + brass pommel
    P.append(Prim('cone', 'Whip1', k=0.01, region='leather', a=top + v3(0, 0, 0.30), b=top + v3(0, 0, -0.38),
                  r1=0.055, r2=0.06))
    P.append(Prim('sphere', 'Whip1', k=0.01, region='brass', c=top + v3(0, 0, 0.33), r=0.07))
    nv = 22
    z0, z1 = top[2] - 0.40, 0.75
    seg = WHIP_LEN / WHIP_N
    for i in range(nv):
        u = i / (nv - 1)
        z = z0 + (z1 - z0) * u
        sc = 1.0 - 0.6 * u
        k = min(int((top[2] - z) / seg), WHIP_N - 1)
        bone = f'Whip{k + 1}'
        c = v3(top[0], top[1], z)
        P.append(Prim('ellip', bone, k=0.012, region='bone', c=c, r=(0.075 * sc, 0.065 * sc, 0.045 * sc)))
        P.append(Prim('cone', bone, k=0.012, region='bone', a=c + v3(0, 0.03, 0) * sc, b=c + v3(0, 0.15, -0.05) * sc,
                      r1=0.03 * sc, r2=0.012 * sc))  # spinous process
        for sx in (1, -1):
            P.append(Prim('cone', bone, k=0.01, region='bone', a=c + v3(0.03 * sx, 0.02, 0) * sc,
                          b=c + v3(0.12 * sx, 0.04, 0.02) * sc, r1=0.022 * sc, r2=0.012 * sc))
        if i < nv - 1:
            P.append(Prim('cone', bone, k=0.01, region='sinew', a=c, b=c + v3(0, 0, (z1 - z0) / (nv - 1)),
                          r1=0.028 * sc, r2=0.026 * sc))
    # sinew lash + knot
    P.append(Prim('cone', f'Whip{WHIP_N}', k=0.01, region='sinew', a=v3(top[0], top[1], z1), b=v3(top[0], top[1], 0.30),
                  r1=0.022, r2=0.012))
    P.append(Prim('sphere', f'Whip{WHIP_N}', k=0.01, region='sinew', c=v3(top[0], top[1], 0.28), r=0.03))
    return P


MOUTH = dict(z=-0.20, rx=0.30, ry=0.33)


def head_arc(th, inset=0.0):
    t = math.radians(th)
    rx, ry = MOUTH['rx'] - inset, MOUTH['ry'] - inset
    z = MOUTH['z'] + 0.17 * (abs(th) / 95.0) ** 2.2
    return HEAD_C + v3(rx * math.sin(t), -0.04 - ry * math.cos(t), z)


def head_prims():
    H = HEAD_C
    P = []
    P.append(Prim('ellip', 'HeadProp', k=0.0, region='flesh', c=H + v3(0, 0.07, 0.17), r=(0.36, 0.43, 0.41)))
    P.append(Prim('ellip', 'HeadProp', k=0.12, region='flesh', c=H + v3(0, -0.10, -0.04), r=(0.31, 0.30, 0.40)))
    P.append(Prim('ellip', 'HeadJaw', k=0.10, region='flesh', c=H + v3(0, -0.12, -0.36), r=(0.26, 0.25, 0.16)))
    P.append(Prim('ellip', 'HeadJaw', k=0.07, region='flesh', c=H + v3(0, -0.28, -0.44), r=(0.10, 0.08, 0.07)))
    for s in (1, -1):
        P.append(Prim('ellip', 'HeadProp', k=0.07, region='flesh', c=H + v3(0.23 * s, -0.27, 0.0), r=(0.10, 0.07, 0.06)))
        P.append(Prim('ellip', 'HeadProp', k=0.04, region='flesh', c=H + v3(0.355 * s, 0.02, -0.02), r=(0.04, 0.10, 0.14)))
        P.append(Prim('ellip', None, op='sub', k=0.06, c=H + v3(0.29 * s, -0.24, -0.18), r=(0.06, 0.06, 0.10)))
    P.append(Prim('ellip', 'HeadProp', k=0.07, region='flesh', c=H + v3(0, -0.34, 0.17), r=(0.27, 0.07, 0.06)))  # brow
    for s in (1, -1):
        P.append(Prim('ellip', None, op='sub', k=0.04, c=H + v3(0.13 * s, -0.38, 0.07), r=(0.075, 0.07, 0.05)))
    P.append(Prim('cone', 'HeadProp', k=0.04, region='flesh', a=H + v3(0, -0.40, 0.12), b=H + v3(0, -0.47, -0.06),
                  r1=0.04, r2=0.065))  # nose
    P.append(Prim('ellip', None, op='sub', k=0.02, c=H + v3(0.0, -0.50, -0.09), r=(0.06, 0.04, 0.025)))
    for th in np.linspace(-96, 96, 37):
        P.append(Prim('ellip', None, op='sub', k=0.012, c=head_arc(th, -0.02), r=(0.05, 0.10, 0.05), rot=(0, 0, th)))
    P.append(Prim('ellip', None, op='sub', k=0.04, c=H + v3(0, -0.10, MOUTH['z'] + 0.03), r=(0.24, 0.22, 0.075)))
    # neck end, torn
    P.append(Prim('cone', 'HeadProp', k=0.08, region='flesh', a=H + v3(0, 0.05, -0.35), b=H + v3(0, 0.08, -0.74),
                  r1=0.18, r2=0.165))
    P.append(Prim('box', None, op='sub', k=0.01, c=H + v3(0, 0.08, -1.0), h=(0.4, 0.4, 0.25), disp=(0.03, 16.0, 8)))
    P.append(Prim('ellip', 'HeadProp', k=0.02, region='gore', c=H + v3(0, 0.08, -0.745), r=(0.155, 0.15, 0.03),
                  disp=(0.012, 22.0, 9)))
    P.append(Prim('cone', 'HeadProp', k=0.02, region='bone', a=H + v3(0, 0.13, -0.70), b=H + v3(0, 0.13, -0.80),
                  r1=0.05, r2=0.04))
    # teeth
    rng = np.random.default_rng(11)
    for row, bone in ((1, 'HeadProp'), (-1, 'HeadJaw')):
        for th in np.linspace(-88, 88, 27):
            j = rng.normal(0, 1, 2)
            sz = 1.0 - 0.4 * abs(th) / 88
            base = head_arc(th, 0.035) + v3(0, 0, 0.075 * row)
            tip = head_arc(th + j[0], 0.008) + v3(0, 0, (0.004 + 0.01 * abs(j[1])) * -row)
            rad = (math.sin(math.radians(th)), -math.cos(math.radians(th)), 0)
            P.append(Prim('cone', bone, k=0.003, region='teeth', a=base, b=tip, up=rad, r1=0.026 * sz,
                          r2=0.011 * sz, squash=(1.0, 0.65)))
        pts = [head_arc(th, 0.06) + v3(0, 0, 0.085 * row) for th in np.linspace(-92, 92, 11)]
        P += chain(pts, [0.028] * 11, bone, k=0.02, region='gum')
    # lank hair gathered up into the fist
    fist = S('fist', 1)
    for i in range(26):
        az = 2 * math.pi * i / 26 + 0.3 * rng.normal()
        el = math.radians(35 + 40 * rng.random())
        root = H + v3(0, 0.07, 0.17) + v3(0.33 * math.cos(el) * math.sin(az), 0.40 * math.cos(el) * -math.cos(az),
                                          0.38 * math.sin(el))
        if math.cos(az) > 0.6 and el < math.radians(55):
            continue  # keep the face clear
        tgt = fist + v3(rng.normal(0, 0.04), rng.normal(0, 0.04), -0.08)
        mid = (root + tgt) / 2 + (root - H) * 0.25
        pts = bezier(root - (root - H) * 0.06, mid, (mid + tgt) / 2, tgt, 5)
        P += chain(pts, [0.045, 0.04, 0.035, 0.03, 0.028, 0.025], 'HeadProp', k=0.03, region='hair')
    for i in range(7):  # loose strands hanging past the face
        az = math.radians(rng.uniform(-150, 150) + 180)
        root = H + v3(0.30 * math.sin(az), 0.07 - 0.36 * math.cos(az), 0.25)
        pts = bezier(root, root + v3(0, 0, -0.25) + (root - H) * 0.15, root + v3(0, 0, -0.55) + (root - H) * 0.2,
                     root + v3(rng.normal(0, 0.05), 0, -0.85 - 0.2 * rng.random()) + (root - H) * 0.2, 5)
        P += chain(pts, [0.035, 0.032, 0.028, 0.024, 0.02, 0.012], 'HeadProp', k=0.02, region='hair')
    return P


def head_eyes():
    return [Prim('sphere', 'HeadProp', k=0.0, region='glow', c=HEAD_C + v3(0.13 * s, -0.355, 0.07), r=0.016)
            for s in (1, -1)]


def skirt_prims():
    sk = SKIRT
    P = [Prim('func', 'Hips', k=0.0, region='coat', lo=(-1.5, -1.3, 0.1), hi=(1.5, 1.4, 4.35),
              fn=lambda X: drape(X, sk['z_top'], sk['z_bot'], sk['r_top'], sk['r_bot'], sk['centre'], folds=9,
                                 amp_top=0.0, amp_bot=0.075, thick=0.03, open_front=21, open_back=9, seed=1,
                                 hem_noise=0.13))]
    for i in range(8):  # rips in the hem
        a = math.radians(30 + i * 41)
        c = skirt_point(math.degrees(a), 0.45 + 0.35 * ((i * 0.37) % 1), 1.0)
        P.append(Prim('ellip', None, op='sub', k=0.02, c=c, r=(0.08, 0.08, 0.25 + 0.1 * ((i * 0.6) % 1)),
                      disp=(0.03, 9.0, i)))
    return P


def coat_weight_scene(body):
    """Bone ownership for the coat skirt: capsules along each panel + the hips."""
    P = [Prim('ellip', 'Hips', k=0.0, c=(0, 0.05, 4.05), r=(0.75, 0.62, 0.32))]
    for name, ang in COAT_SECTORS.items():
        p0, p1, p2 = skirt_point(ang, 4.0, 1.0), skirt_point(ang, 2.25, 1.0), skirt_point(ang, 0.3, 1.0)
        P.append(Prim('cone', f'Coat{name}1', k=0.0, a=p0, b=p1, r1=0.02, r2=0.02))
        P.append(Prim('cone', f'Coat{name}2', k=0.0, a=p1, b=p2, r1=0.02, r2=0.02))
    return Scene(P)


def cape_prims(body_scene):
    """Coachman's shoulder cape: a flared bell with slits where the arms come out."""
    arms = [p for p in body_scene.prims if p.bone in ('UpperArm_L', 'UpperArm_R') and p.op == 'add']
    arm_sc = Scene(arms)

    def fn(X):
        d = drape(X, 6.52, 5.05, (0.50, 0.42), (1.62, 1.02), (0.0, 0.04), folds=13, amp_top=0.0, amp_bot=0.05,
                  thick=0.03, open_front=0, seed=4, hem_noise=0.08, flare=0.28)
        slit = arm_sc.eval(X) - 0.07
        return np.maximum(d, -slit)
    return [Prim('func', 'Chest', k=0.0, region='coat', lo=(-1.8, -1.2, 4.9), hi=(1.8, 1.2, 6.65), fn=fn)]


def cape_weight_scene(body_scene):
    P = [p for p in body_scene.prims if p.bone in ('Chest', 'Clavicle_L', 'Clavicle_R', 'UpperArm_L', 'UpperArm_R',
                                                    'Spine') and p.op == 'add']
    P = list(P)
    P.append(Prim('cone', 'CapeBack', k=0.0, a=(0, 0.62, 6.05), b=(0, 0.75, 5.35), r1=0.05, r2=0.05))
    for s, t in ((1, 'L'), (-1, 'R')):
        P.append(Prim('cone', f'Cape{t}', k=0.0, a=(1.05 * s, 0.05, 6.1), b=(1.5 * s, 0.05, 5.45), r1=0.04, r2=0.04))
    return Scene(P)


def hood_prims():
    P = [Prim('ellip', 'Hood', k=0.0, region='coat', shell=0.04, c=(0, 0.14, 6.98), r=(0.47, 0.52, 0.64),
              disp=(0.015, 4.0, 3))]
    P.append(Prim('ellip', 'Hood', k=0.10, region='coat', shell=0.035, c=(0, 0.30, 7.22), r=(0.30, 0.34, 0.42)))  # peak
    P.append(Prim('ellip', None, op='sub', k=0.04, c=(0, -0.48, 6.95), r=(0.38, 0.50, 0.56)))  # face opening
    P.append(Prim('box', None, op='sub', k=0.02, c=(0, 0.0, 6.12), h=(1.0, 1.0, 0.36), disp=(0.03, 6.0, 2)))
    return P


def pieces():
    body = Scene(body_prims())
    return [
        bk.Piece('body', body, tris=4300, voxel=0.022, falloff=0.09, lo_voxel=0.035),
        bk.Piece('fists', Scene(fist_prims()), tris=700, voxel=0.014, falloff=0.06),
        bk.Piece('skirt', Scene(skirt_prims()), tris=1700, voxel=0.016, falloff=0.45, smooth=0,
                 weight_scene=coat_weight_scene(body)),
        bk.Piece('cape', Scene(cape_prims(body)), tris=1100, voxel=0.016, falloff=0.25, smooth=0,
                 weight_scene=cape_weight_scene(body)),
        bk.Piece('hood', Scene(hood_prims()), tris=600, voxel=0.016, rigid='Hood', smooth=0),
        bk.Piece('whip', Scene(whip_prims()), tris=1300, voxel=0.009, mat='whip', falloff=0.05),
        bk.Piece('head', Scene(head_prims()), tris=2100, voxel=0.009, group='head', mat='head', falloff=0.03),
        bk.Piece('eyes', Scene(head_eyes()), tris=80, voxel=0.006, rigid='HeadProp', group='head_glow', mat='head'),
    ]


# ----------------------------------------------------------------- materials
def _sep(nk, co):
    n = nk.node('ShaderNodeSeparateXYZ')
    nk.set(n.inputs[0], co)
    return n


def mat_body(mat):
    """Coat wool, leather, brass, the stump."""
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    xyz = _sep(nk, co)
    n1 = nk.noise(co, 2.0, 6, 0.6).outputs['Fac']
    # soaked black-green wool, lighter where it is dry and dusty
    wet = nk.maprange(nk.noise(co, 0.9, 4, 0.55).outputs['Fac'], 0.42, 0.62)
    rain = nk.maprange(nk.noise(nk.vmath('MULTIPLY', co, (6.0, 6.0, 0.6)), 3.0, 3, 0.5).outputs['Fac'], 0.5, 0.7)
    wool = nk.ramp(n1, [(0.3, (0.018, 0.02, 0.019)), (0.6, (0.035, 0.038, 0.034)), (0.8, (0.06, 0.06, 0.052))])
    dust = nk.maprange(nk.math('ADD', xyz.outputs['Z'], nk.math('MULTIPLY', n1, 1.5)), 0.4, 1.6, 1.0, 0.0)
    wool = nk.mix(nk.math('MULTIPLY', dust, 0.6), wool, (0.11, 0.10, 0.085))
    wool_r = nk.mixf(nk.math('MAXIMUM', wet, rain), 0.88, 0.45)
    cuff = nk.attr('rg_cuff')
    wool = nk.mix(cuff, wool, nk.mix(n1, (0.05, 0.012, 0.012), (0.09, 0.02, 0.018)))  # oxblood cuffs
    trous = nk.attr('rg_wool')
    wool = nk.mix(trous, wool, nk.mix(n1, (0.03, 0.028, 0.03), (0.055, 0.05, 0.05)))
    # leather (boots, belt, gloves)
    lth = nk.attr('rg_leather')
    sole = nk.attr('rg_sole')
    scuff = nk.maprange(nk.noise(co, 9.0, 6, 0.6).outputs['Fac'], 0.55, 0.75)
    lcol = nk.mix(scuff, (0.028, 0.018, 0.012), (0.11, 0.075, 0.05))
    lcol = nk.mix(sole, lcol, (0.015, 0.012, 0.01))
    lrough = nk.mixf(scuff, 0.32, 0.6)
    # tarnished brass with verdigris
    brass = nk.attr('rg_brass')
    verd = nk.maprange(nk.noise(co, 14.0, 4, 0.6).outputs['Fac'], 0.5, 0.65)
    bcol = nk.mix(verd, (0.42, 0.31, 0.14), (0.16, 0.30, 0.24))
    bmet = nk.mixf(verd, 1.0, 0.0)
    brough = nk.mixf(verd, 0.38, 0.8)
    # the stump: grey corpse skin, wet gore, bone
    skin = nk.attr('rg_skin')
    gore = nk.attr('rg_gore')
    bone = nk.attr('rg_bone')
    sk = nk.mix(nk.noise(co, 12.0, 5, 0.6).outputs['Fac'], (0.12, 0.10, 0.10), (0.22, 0.18, 0.17))
    gc = nk.mix(nk.noise(co, 30.0, 4, 0.6).outputs['Fac'], (0.10, 0.008, 0.008), (0.25, 0.03, 0.025))
    col = wool
    col = nk.mix(lth, col, lcol)
    col = nk.mix(sole, col, lcol)
    col = nk.mix(brass, col, bcol)
    col = nk.mix(skin, col, sk)
    col = nk.mix(gore, col, gc)
    col = nk.mix(bone, col, (0.55, 0.50, 0.40))
    rough = wool_r
    rough = nk.mixf(nk.math('ADD', lth, sole, True), rough, lrough)
    rough = nk.mixf(brass, rough, brough)
    rough = nk.mixf(skin, rough, 0.6)
    rough = nk.mixf(gore, rough, 0.18)
    rough = nk.mixf(bone, rough, 0.45)
    metal = nk.mixf(brass, 0.0, bmet)
    # bump: wool twill + leather grain + creases
    tw = nk.wave(nk.vmath('ADD', co, nk.vmath('MULTIPLY', co, (1, 1, 1))), 55.0, 2.0, 1.0, 'BANDS', 'Z').outputs['Fac']
    grain = nk.voronoi(co, 70.0).outputs['Distance']
    crease = nk.noise(co, 6.0, 6, 0.65, dist=0.4).outputs['Fac']
    h = nk.math('ADD', nk.math('MULTIPLY', tw, 0.25), nk.math('MULTIPLY', crease, 0.9))
    h = nk.mixf(lth, h, nk.math('ADD', nk.math('MULTIPLY', grain, 0.4), nk.math('MULTIPLY', crease, 0.7)))
    h = nk.mixf(gore, h, nk.noise(co, 40.0, 4, 0.7).outputs['Fac'])
    nk.finish(col, rough, metal, nk.bump(h, 0.3, 0.01))
    return mat


def mat_whip(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n = nk.noise(co, 25.0, 5, 0.6).outputs['Fac']
    bone = nk.attr('rg_bone')
    brass = nk.attr('rg_brass')
    lth = nk.attr('rg_leather')
    sin = nk.attr('rg_sinew')
    bcol = nk.ramp(n, [(0.3, (0.30, 0.25, 0.17)), (0.7, (0.56, 0.50, 0.38))])
    grime = nk.maprange(nk.noise(co, 6.0, 4, 0.5).outputs['Fac'], 0.5, 0.7)
    bcol = nk.mix(nk.math('MULTIPLY', grime, 0.7), bcol, (0.18, 0.06, 0.04))  # old blood
    col = nk.mix(sin, bcol, nk.mix(n, (0.14, 0.05, 0.035), (0.24, 0.12, 0.07)))
    col = nk.mix(lth, col, (0.05, 0.03, 0.02))
    col = nk.mix(brass, col, (0.40, 0.30, 0.13))
    rough = nk.mixf(sin, nk.mixf(n, 0.42, 0.62), 0.35)
    rough = nk.mixf(lth, rough, 0.5)
    rough = nk.mixf(brass, rough, 0.4)
    metal = nk.mixf(brass, 0.0, 1.0)
    nk.finish(col, rough, metal, nk.bump(nk.noise(co, 60.0, 4, 0.6).outputs['Fac'], 0.25, 0.005))
    return mat


def mat_head(mat):
    """Rotting head: the folklore says 'the colour and texture of mouldy cheese'."""
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n1 = nk.noise(co, 5.0, 6, 0.6).outputs['Fac']
    base = nk.ramp(n1, [(0.3, (0.36, 0.34, 0.25)), (0.55, (0.50, 0.47, 0.34)), (0.75, (0.58, 0.55, 0.40))])
    mould = nk.maprange(nk.noise(co, 9.0, 6, 0.65).outputs['Fac'], 0.55, 0.68)
    spots = nk.maprange(nk.voronoi(co, 28.0).outputs['Distance'], 0.0, 0.18, 1.0, 0.0)
    col = nk.mix(mould, base, nk.mix(n1, (0.30, 0.33, 0.16), (0.42, 0.44, 0.22)))
    col = nk.mix(nk.math('MULTIPLY', spots, 0.55), col, (0.12, 0.13, 0.06))
    rot = nk.maprange(nk.noise(co, 3.0, 4, 0.5).outputs['Fac'], 0.55, 0.72)
    col = nk.mix(nk.math('MULTIPLY', rot, 0.8), col, (0.10, 0.07, 0.05))
    hair = nk.attr('rg_hair')
    gore = nk.attr('rg_gore')
    teeth = nk.attr('rg_teeth')
    gum = nk.attr('rg_gum')
    bone = nk.attr('rg_bone')
    col = nk.mix(hair, col, nk.mix(n1, (0.012, 0.01, 0.009), (0.04, 0.032, 0.025)))
    col = nk.mix(gore, col, nk.mix(n1, (0.10, 0.01, 0.01), (0.22, 0.03, 0.025)))
    col = nk.mix(teeth, col, nk.mix(n1, (0.34, 0.29, 0.17), (0.55, 0.48, 0.32)))
    col = nk.mix(gum, col, (0.08, 0.02, 0.02))
    col = nk.mix(bone, col, (0.5, 0.45, 0.35))
    rough = nk.mixf(mould, 0.42, 0.78)
    rough = nk.mixf(hair, rough, 0.55)
    rough = nk.mixf(gore, rough, 0.2)
    rough = nk.mixf(teeth, rough, 0.35)
    h = nk.math('ADD', nk.noise(co, 30.0, 8, 0.65).outputs['Fac'], nk.math('MULTIPLY', spots, 0.4))
    hw = nk.wave(co, 40.0, 3.0, 2.0, 'BANDS', 'Z').outputs['Fac']
    h = nk.mixf(hair, h, hw)
    nk.finish(col, rough, 0.0, nk.bump(h, 0.35, 0.008))
    return mat


MATERIALS = {'skin': mat_body, 'whip': mat_whip, 'head': mat_head}


# ----------------------------------------------------------------- animation
SIDES = (('L', 1), ('R', -1))


def legs(an, pose, feet, pitch=None):
    """feet: {'L': (x,y,z) ankle-ish target}. Feet stay flat unless pitch given."""
    for t, sgn in SIDES:
        tgt = mo.Vector(feet[t])
        mo.ik2(an, pose, f'UpperLeg_{t}', f'LowerLeg_{t}', tgt, (0.1 * sgn, -1, 0.1))
        q = an.delta(pose, f'LowerLeg_{t}')
        pr = (pitch or {}).get(t, 0.0)
        pose[f'Foot_{t}'] = q.inverted() @ bk.Q((pr, 0, 0))
        pose[f'Toe_{t}'] = bk.Q((-pr * 0.6 if pr < 0 else 0, 0, 0))
    return pose


def ankle(t, x, y, z):
    a = SIDE['ankle']
    return (a[0] * (1 if t == 'L' else -1) + x, a[1] + y, a[2] + z)


class Secondary:
    """Whip follow-the-leader, swinging head, coat panels."""

    def __init__(self, an, base, seconds, loop, speed=0.0):
        self.an, self.base, self.T, self.loop, self.v = an, base, seconds, loop, speed

    def at(self, t):
        if self.loop:
            return t % 1.0
        return min(max(t, 0.0), 1.0)

    def fist(self, t, side='R'):
        return mo.world_tail(self.an, self.base(self.at(t)), f'Hand_{side}')

    def whip(self, pose, t, lag=0.045, sag=0.55, lie=0.35, override=None, analytic=None, blend=0.0):
        """Follow-the-leader chain; `analytic(k)` -> direction can be blended in."""
        an = self.an
        p = mo.world_tail(an, pose, 'Hand_R')
        seg = WHIP_LEN / WHIP_N
        for k in range(WHIP_N):
            dt = (k + 1) * lag / self.T
            hist = self.fist(t - dt)
            tgt = hist + mo.Vector((0, self.v * (k + 1) * lag + lie * (k + 1) * seg * 0.35, -sag * (k + 1)))
            if override is not None:
                tgt = override(k, p, tgt)
            d = tgt - p
            if d.length < 1e-4:
                d = mo.Vector((0, 0, -1))
            d.normalize()
            nxt = p + d * seg
            if nxt.z < 0.06:
                nxt.z = 0.06
                d = (nxt - p)
                if d.length < 1e-4:
                    d = mo.Vector((0, 1, 0))
                d.normalize()
                nxt = p + d * seg
                if nxt.z < 0.06:
                    flat = mo.Vector((d.x, d.y, 0))
                    if flat.length < 1e-4:
                        flat = mo.Vector((0, 1, 0))
                    flat.normalize()
                    d = (flat * math.sqrt(max(seg * seg - (0.06 - p.z) ** 2, 0)) +
                         mo.Vector((0, 0, 0.06 - p.z))).normalized()
                    nxt = p + d * seg
            if analytic is not None and blend > 0:
                d = d.lerp(analytic(k), blend).normalized()
                nxt = p + d * seg
            an.aim(pose, f'Whip{k + 1}', d)
            p = nxt
        return pose

    def head(self, pose, t, lag=0.12, gain=1.0, extra=None):
        an = self.an
        f0 = mo.world_tail(an, pose, 'Hand_L')
        f1 = self.fist(t - lag / self.T, 'L')
        vel = (f0 - f1) / lag
        d = mo.Vector((0, self.v * 0.25, -1.0)) - vel * 0.25 * gain
        an.aim(pose, 'HeadProp', d.normalized())
        if extra:
            pose['HeadProp'] = pose['HeadProp'] @ bk.Q(extra)
        return pose

    def coat(self, pose, t, flare=0.0, flutter=0.0):
        an = self.an
        for t2, sgn in SIDES:
            q = an.delta(pose, f'UpperLeg_{t2}')
            fwd = (q @ mo.Vector((0, 0, -1)))
            swing = math.degrees(math.atan2(-fwd.y, -fwd.z))  # + = leg forward
            sec = 'FL' if t2 == 'L' else 'FR'
            pose[f'Coat{sec}1'] = (-swing * 0.75, 0, 0)
            pose[f'Coat{sec}2'] = (-swing * 0.25 + 4 * mo.s(t * 2 + 0.2) * flutter, 0, 0)
            side = 'L' if t2 == 'L' else 'R'
            pose[f'Coat{side}1'] = (-swing * 0.3 + flare * 0.4, 0, 0)
            pose[f'Coat{side}2'] = (flare * 0.3 + 6 * flutter * mo.s(t * 2 + 0.4), 0, 0)
        pose['CoatBack1'] = (flare, 0, 0)
        pose['CoatBack2'] = (flare * 0.6 + 8 * flutter * mo.s(t * 2 + 0.3), 0, 0)
        pose['CapeBack'] = (flare * 0.4 + 3 * flutter * mo.s(t * 2), 0, 0)
        return pose


def torso(pose, bow=0.0, twist=0.0, lean=0.0):
    pose['Spine'] = (2 + bow * 0.4, lean * 0.5, twist * 0.5)
    pose['Chest'] = (3 + bow * 0.6, lean * 0.5, twist * 0.5)
    pose['Neck'] = (0, 0, 0)
    pose['Hood'] = (bow * -0.3, 0, 0)
    return pose


def hold_arms(an, pose, lswing=0.0, rswing=0.0, lout=0.32, rout=0.30, lfwd=0.0, rfwd=0.0):
    """Left arm hangs carrying the head, right arm holds the whip slightly out."""
    an.aim(pose, 'Clavicle_L', (1, 0.0, -0.08))
    an.aim(pose, 'Clavicle_R', (-1, 0.0, -0.08))
    an.aim(pose, 'UpperArm_L', (lout, -0.05 + lswing + lfwd, -1))
    an.aim(pose, 'LowerArm_L', (lout * 0.6, -0.25 + lswing * 1.3 + lfwd * 1.5, -1))
    an.aim(pose, 'Hand_L', (0.15, -0.30 + lswing, -1))
    an.aim(pose, 'UpperArm_R', (-rout, -0.05 + rswing + rfwd, -1))
    an.aim(pose, 'LowerArm_R', (-rout * 0.8, -0.35 + rswing * 1.3 + rfwd * 1.5, -1))
    an.aim(pose, 'Hand_R', (-0.15, -0.45 + rswing, -1))
    return pose


def clips(an):
    out = []

    def stand_base(t=0.0):
        p = {'@root': (0, 0, -0.06)}
        torso(p, bow=2)
        hold_arms(an, p)
        legs(an, p, {'L': ankle('L', 0.04, 0.0, 0), 'R': ankle('R', -0.04, 0.0, 0)})
        return p

    # ---- Idle: still and heavy; the head turns slowly in its hand, coat stirs
    def idle_base(t):
        p = {'@root': (0.03 * mo.s(t), 0, -0.06 + 0.02 * mo.s(2 * t))}
        torso(p, bow=2 + 1.5 * mo.s(2 * t), twist=4 * mo.s(t))
        hold_arms(an, p, lswing=0.03 * mo.s(t + 0.1), rswing=0.02 * mo.s(t + 0.3))
        legs(an, p, {'L': ankle('L', 0.04, 0.0, 0), 'R': ankle('R', -0.04, 0.0, 0)})
        return p
    sec_i = Secondary(an, idle_base, 4.0, True)

    def idle(t):
        p = idle_base(t)
        sec_i.head(p, t, extra=(6 * mo.s(t + 0.2), 0, 25 * mo.s(t) + 30 * mo.twitch(t, 0.55, 0.05)))
        p['HeadJaw'] = (6 + 10 * mo.twitch(t, 0.58, 0.04) + 4 * mo.s(2 * t), 0, 0)
        sec_i.whip(p, t, sag=0.6, lie=0.5)
        sec_i.coat(p, t, flare=2 * mo.s(t), flutter=0.5)
        return p
    out.append(('Idle', 120, idle, True))

    # ---- locomotion family: Walk -> Stride -> Run (it speeds up the longer it sees you)
    def make_loco(name, frames, stride, lift, stance, bow, drop, bounce, armsw, speed, flare, flutter, jaw):
        T = frames / 30.0

        def base(t):
            yL, zL, _ = mo.foot_cycle(t, stride, lift, stance)
            yR, zR, _ = mo.foot_cycle(t + 0.5, stride, lift, stance)
            p = {'@root': (0.06 * mo.s(t), 0, drop + bounce * mo.c(2 * t))}
            p['Hips'] = (0, 2 * mo.s(t), -7 * mo.c(t))
            torso(p, bow=bow, twist=9 * mo.c(t))
            hold_arms(an, p, lswing=-armsw * mo.c(t) * 0.5, rswing=armsw * mo.c(t), lfwd=0.05 * bow / 10,
                      rfwd=0.05 * bow / 10)
            pitchL = -25 * math.sin(math.pi * max(0, (t % 1 - stance) / (1 - stance))) if t % 1 > stance else 0
            u2 = (t + 0.5) % 1
            pitchR = -25 * math.sin(math.pi * max(0, (u2 - stance) / (1 - stance))) if u2 > stance else 0
            legs(an, p, {'L': ankle('L', 0.0, yL, zL), 'R': ankle('R', 0.0, yR, zR)}, {'L': pitchL, 'R': pitchR})
            return p
        sec = Secondary(an, base, T, True, speed)

        def fn(t):
            p = base(t)
            sec.head(p, t, gain=1.0)
            p['HeadJaw'] = (jaw + 4 * mo.s(2 * t), 0, 0)
            sec.whip(p, t, lag=0.05, sag=0.5, lie=0.2)
            sec.coat(p, t, flare=flare, flutter=flutter)
            return p
        return (name, frames, fn, True)

    out.append(make_loco('Walk', 42, 1.9, 0.40, 0.62, 4, -0.16, 0.05, 0.10, 3.0, 4, 0.6, 6))
    out.append(make_loco('Stride', 30, 2.7, 0.55, 0.58, 9, -0.25, 0.08, 0.20, 6.5, 12, 1.0, 10))
    out.append(make_loco('Run', 22, 3.5, 0.85, 0.42, 18, -0.42, 0.14, 0.35, 11.0, 28, 1.6, 18))

    # ---- AttackWhip: raise the spine whip overhead and crack it forward (crack at 46%)
    def whip_base(t):
        def kp_wind():
            p = {'@root': (0, 0.25, -0.15)}
            torso(p, bow=-6, twist=-28)
            an.aim(p, 'Clavicle_L', (1, 0.0, -0.05))
            an.aim(p, 'Clavicle_R', (-1, 0.1, 0.2))
            an.aim(p, 'UpperArm_L', (0.35, -0.05, -1))
            an.aim(p, 'LowerArm_L', (0.2, -0.3, -1))
            an.aim(p, 'Hand_L', (0.1, -0.3, -1))
            an.aim(p, 'UpperArm_R', (-0.5, 0.45, 0.9))
            an.aim(p, 'LowerArm_R', (-0.2, 0.9, 0.6))
            an.aim(p, 'Hand_R', (0, 1, 0.2))
            legs(an, p, {'L': ankle('L', 0.05, -0.55, 0), 'R': ankle('R', -0.05, 0.55, 0)})
            return p

        def kp_strike():
            p = {'@root': (0, -0.45, -0.38)}
            torso(p, bow=18, twist=26)
            an.aim(p, 'Clavicle_L', (1, 0.0, -0.1))
            an.aim(p, 'Clavicle_R', (-1, -0.3, -0.05))
            an.aim(p, 'UpperArm_L', (0.35, 0.1, -1))
            an.aim(p, 'LowerArm_L', (0.2, -0.2, -1))
            an.aim(p, 'Hand_L', (0.1, -0.3, -1))
            an.aim(p, 'UpperArm_R', (-0.35, -1, -0.15))
            an.aim(p, 'LowerArm_R', (-0.1, -1, -0.35))
            an.aim(p, 'Hand_R', (0, -1, -0.5))
            legs(an, p, {'L': ankle('L', 0.05, -0.75, 0), 'R': ankle('R', -0.05, 0.75, 0)})
            return p
        st = stand_base()
        return bk.track([(0, st), (0.30, kp_wind()), (0.40, kp_wind()), (0.50, kp_strike(), 'snap'),
                         (0.72, kp_strike()), (1.0, st)])(t)
    sec_w = Secondary(an, whip_base, 1.6, False, 0.0)

    def attack_whip(t):
        p = whip_base(t)
        sec_w.head(p, t, gain=1.4)
        p['HeadJaw'] = (8 + 18 * mo.twitch(t, 0.5, 0.12), 0, 0)
        def wave(k):
            # each segment flips from up-and-back to straight forward a little after the
            # one before it (the travelling loop), then droops under its own weight
            tk = 0.40 + k * 0.011
            a = 150 + (-8 - 150) * bk.ease((t - tk) / 0.07, 'snap')
            a += (-70 + 8) * bk.ease((t - (0.60 + k * 0.012)) / 0.30, 'smooth')
            a -= 6 * k * bk.ease((t - 0.62) / 0.3)
            r = math.radians(a)
            return mo.Vector((0.0, -math.cos(r), math.sin(r)))
        w = bk.ease((t - 0.30) / 0.08) * (1 - bk.ease((t - 0.82) / 0.16))
        sec_w.whip(p, t, lag=0.03, sag=0.45, lie=0.1, analytic=wave, blend=w)
        sec_w.coat(p, t, flare=10 * mo.twitch(t, 0.5, 0.2), flutter=1.0)
        return p
    out.append(('AttackWhip', 48, attack_whip, False))

    # ---- Reveal (kill/jumpscare): lifts its head up to your face; the jaw drops in a laugh
    def reveal_base(t):
        st = stand_base()

        def kp_lift(h=1.0):
            p = {'@root': (0, -0.45, -0.30)}
            torso(p, bow=14, twist=-16)
            an.aim(p, 'Clavicle_L', (1, -0.2, 0.15))
            an.aim(p, 'Clavicle_R', (-1, 0.0, -0.08))
            mo.ik2(an, p, 'UpperArm_L', 'LowerArm_L', mo.Vector((0.15, -2.5, 6.0 * h + 4.6 * (1 - h))),
                   (1, 0.3, -0.6))
            an.aim(p, 'Hand_L', (-0.2, -1, 0.35))
            an.aim(p, 'UpperArm_R', (-0.45, 0.25, -1))
            an.aim(p, 'LowerArm_R', (-0.3, 0.1, -1))
            an.aim(p, 'Hand_R', (-0.1, 0.0, -1))
            legs(an, p, {'L': ankle('L', 0.05, -0.45, 0), 'R': ankle('R', -0.05, 0.4, 0)})
            return p
        return bk.track([(0, st), (0.25, kp_lift(0.6)), (0.42, kp_lift(1.0), 'snap'), (0.85, kp_lift(1.0)),
                         (1.0, kp_lift(1.0))])(t)
    sec_r = Secondary(an, reveal_base, 2.0, False)

    def reveal(t):
        p = reveal_base(t)
        u = bk.ease((t - 0.3) / 0.15, 'snap')
        if t < 0.3:
            sec_r.head(p, t)
        else:
            # hold the head upright, face toward the player (-Y), slight tilt
            q = an.delta(p, 'Hand_L')
            want = bk.Q((0, 14 * u + 4 * mo.s(3 * t), 0))
            p['HeadProp'] = q.inverted() @ want
        laugh = 0.5 + 0.5 * mo.s(6 * t)
        p['HeadJaw'] = (6 + 30 * u * (0.6 + 0.4 * laugh), 0, 0)
        sec_r.whip(p, t, sag=0.6, lie=0.4)
        sec_r.coat(p, t, flare=3, flutter=0.5)
        return p
    out.append(('Reveal', 60, reveal, False))

    # ---- Manifest: rises from one knee, coat settling, head lifted last
    def man_base(t):
        def kneel():
            p = {'@root': (0, 0.2, -1.55)}
            torso(p, bow=34, twist=6)
            hold_arms(an, p, lfwd=0.2, rfwd=0.1, lout=0.5, rout=0.5)
            legs(an, p, {'L': ankle('L', 0.1, -0.9, 0), 'R': ankle('R', -0.1, 0.9, 0.05)}, {'R': -40})
            return p
        st = stand_base()
        return bk.track([(0, kneel()), (0.2, kneel()), (0.75, st), (1.0, st)])(t)
    sec_m = Secondary(an, man_base, 2.0, False)

    def manifest(t):
        p = man_base(t)
        sec_m.head(p, t)
        sec_m.whip(p, t, sag=0.6, lie=0.5)
        sec_m.coat(p, t, flare=6 * (1 - t), flutter=0.8)
        return p
    out.append(('Manifest', 60, manifest, False))

    # ---- Vanish: turns its shoulder, coat swirls, sinks
    def van_base(t):
        def turn():
            p = {'@root': (0, 0.1, -0.3)}
            p['HumanoidRootNode'] = (0, 0, 70)
            torso(p, bow=10, twist=20)
            hold_arms(an, p, lout=0.5, rout=0.5)
            legs(an, p, {'L': ankle('L', 0.0, 0.0, 0), 'R': ankle('R', 0.0, 0.0, 0)})
            return p

        def sunk():
            p = turn()
            p['@root'] = (0, 0.1, -3.4)
            p['HumanoidRootNode'] = (0, 0, 140)
            return p
        st = stand_base()
        return bk.track([(0, st), (0.35, turn()), (1.0, sunk(), 'in')])(t)
    sec_v = Secondary(an, van_base, 1.2, False)

    def vanish(t):
        p = van_base(t)
        sec_v.head(p, t)
        sec_v.whip(p, t, sag=0.6, lie=0.3)
        sec_v.coat(p, t, flare=25 * t, flutter=1.5)
        return p
    out.append(('Vanish', 36, vanish, False))
    return out


if __name__ == '__main__':
    import pipeline
    pipeline.build(sys.modules[__name__])
