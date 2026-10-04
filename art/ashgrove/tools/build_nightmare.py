"""AH_Ent_Nightmare — the mare that rides the sleeper's chest.

Folklore: the Germanic / Scandinavian *mara* (Slavic *mora*) is a spirit that
sits on sleepers' chests and gives them bad dreams; the word survives in
"nightmare".  Usually harmless; this one has taken form.  A floating cage of
bone plates around a core of black tar that drips away beneath it, a long
neck, a cracked porcelain-pale skull mask with a grin of far too many teeth,
and a crescent of bone over the brow (the moon it comes with).

Run:  python3 build_nightmare.py   (--preview for a quick sculpt check)
"""
import math
import sys

import numpy as np

sys.path.insert(0, __file__.rsplit('/', 1)[0])
import blendkit as bk  # noqa: E402
import motion as mo  # noqa: E402
from sdf import Prim, Scene, bezier, chain, fbm, sweep, v3  # noqa: E402

NAME = 'Nightmare'
TAGLINE = ('Floating cage of bone plates around dripping black tar; a long neck and a cracked porcelain skull '
           'with a crescent of bone. Causes hallucinations; hunts more in the dark.')
GLOW_COLOR = (0.85, 0.80, 1.0)
GLOW_STRENGTH = 5.0
GLOW_NOTE = 'eyes: pinprick, Neon #D9CCFF'
MOOD_POSE = ('Idle', 0.3)
MOOD_DIST = 9.5
ANIM_ZOOM = 1.15
BAKE = {'extrusion': 0.03, 'ray': 0.1, 'samples': 6}
SHEET_NOTES = [
    'Read in the dark: the pale mask and grin float above an almost invisible body; the bone plates catch the beam.',
    'Hovers: drips end ~0.3 studs above the floor. Collision: 3×8×3 box, not walkable.',
]
PREVIEW_CLOSEUPS = [('head', (0, -1, 0.05), (0, -0.3, 6.95), 1.9), ('head3q', (-0.8, -1, 0.1), (0, -0.3, 6.95), 1.9),
                    ('cage', (-0.6, -1, 0.1), (0, 0, 3.9), 4.4), ('hand', (0.2, -1, 0.3), (2.6, -0.1, 3.9), 2.0)]

# ------------------------------------------------------------------ skeleton
J = dict(root=v3(0, 0, 0), hrp=v3(0, 0.05, 3.8), pelvis=v3(0, 0.05, 2.0), waist=v3(0, 0.05, 3.5),
         chest=v3(0, 0.04, 4.6), neck1=v3(0, 0.10, 5.65), neck2=v3(0, -0.05, 6.10), head=v3(0, -0.22, 6.42),
         headtop=v3(0, -0.25, 7.45), jaw=v3(0, -0.15, 6.78), chin=v3(0, -0.52, 6.40))
SIDE = dict(clav=v3(0.10, 0.02, 5.48), shoulder=v3(0.72, 0.08, 5.50), elbow=v3(1.55, 0.18, 4.65),
            wrist=v3(2.30, 0.0, 3.95))
DRIPS = [(-100, 0.7), (-40, 1.35), (15, 0.6), (70, 1.1), (130, 1.5), (175, 0.9), (-155, 1.25), (-125, 0.55)]


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


def finger_pts(s, i):
    """Four very long fingers; i 0..3 front to back."""
    a, n, sp = hand_frame(s)
    knuck = S('wrist', s) + a * 0.30 + sp * (-0.13 + 0.087 * i)
    d = a + sp * (-0.12 + 0.08 * i)
    d /= np.linalg.norm(d)
    pts, ang = [knuck], 0.0
    for L, cd in zip((0.42, 0.36, 0.30), (8, 14, 18)):
        ang += math.radians(cd)
        pts.append(pts[-1] + (d * math.cos(ang) + n * math.sin(ang)) * L)
    return pts


def drip_pts(i):
    ang, ln = DRIPS[i]
    a = math.radians(ang)
    top = v3(0.30 * math.sin(a), 0.08 - 0.26 * math.cos(a), 2.0 + 0.25 * ((i * 0.37) % 1))
    mid = top + v3(0.10 * math.sin(a), 0.06, -ln * 0.5)
    end = top + v3(0.16 * math.sin(a), 0.10, -ln)
    return top, mid, end


def bones():
    b = [
        dict(name='Root', head=J['root'], tail=J['root'] + v3(0, 0, 0.6), deform=False),
        dict(name='HumanoidRootNode', head=J['hrp'], tail=J['hrp'] + v3(0, 0, 0.5), parent='Root', deform=False),
        dict(name='Hips', head=J['pelvis'], tail=J['waist'], parent='HumanoidRootNode'),
        dict(name='Spine', head=J['waist'], tail=J['chest'], parent='Hips'),
        dict(name='Chest', head=J['chest'], tail=J['neck1'], parent='Spine'),
        dict(name='Neck1', head=J['neck1'], tail=J['neck2'], parent='Chest'),
        dict(name='Neck2', head=J['neck2'], tail=J['head'], parent='Neck1'),
        dict(name='Head', head=J['head'], tail=J['headtop'], parent='Neck2'),
        dict(name='Jaw', head=J['jaw'], tail=J['chin'], parent='Head', roll_to=(0, 0, 1)),
    ]
    for s, t in ((1, 'L'), (-1, 'R')):
        a, n, sp = hand_frame(s)
        b += [
            dict(name=f'Clavicle_{t}', head=S('clav', s), tail=S('shoulder', s), parent='Chest'),
            dict(name=f'UpperArm_{t}', head=S('shoulder', s), tail=S('elbow', s), parent=f'Clavicle_{t}'),
            dict(name=f'LowerArm_{t}', head=S('elbow', s), tail=S('wrist', s), parent=f'UpperArm_{t}'),
            dict(name=f'Hand_{t}', head=S('wrist', s), tail=S('wrist', s) + a * 0.30, parent=f'LowerArm_{t}',
                 roll_to=tuple(n)),
        ]
        for g, (i0, i1) in (('A', (0, 1)), ('B', (2, 3))):
            p0, p1 = finger_pts(s, i0), finger_pts(s, i1)
            m = [(x + y) / 2 for x, y in zip(p0, p1)]
            b.append(dict(name=f'Fingers{g}1_{t}', head=m[0], tail=m[1], parent=f'Hand_{t}', roll_to=tuple(n)))
            b.append(dict(name=f'Fingers{g}2_{t}', head=m[1], tail=m[3], parent=f'Fingers{g}1_{t}', roll_to=tuple(n)))
    for i in range(len(DRIPS)):
        top, mid, end = drip_pts(i)
        b.append(dict(name=f'Drip{i + 1}_1', head=top, tail=mid, parent='Hips', roll_to=(1, 0, 0)))
        b.append(dict(name=f'Drip{i + 1}_2', head=mid, tail=end, parent=f'Drip{i + 1}_1', roll_to=(1, 0, 0)))
    return b


# ---------------------------------------------------------------- the sculpt
def L(a, b, t):
    return a + (b - a) * t


def plate_ring(z, r, s, tilt=0.12):
    """Arc of one bone plate on side s: from the spine (back) round to near the front."""
    pts = []
    for th in np.linspace(174, 20, 10):
        a = math.radians(th) * s
        dz = tilt * (1 - th / 172)  # plates dip toward the front like ribs
        pts.append(v3(r * 1.05 * math.sin(a), 0.06 - r * math.cos(a), z - dz))
    return pts


def cage_prims():
    P = []
    nplates = 9
    rng = np.random.default_rng(4)
    for i in range(nplates):
        u = i / (nplates - 1)
        z = 5.30 - u * 3.05 + rng.normal(0, 0.03)
        r = 0.80 - 0.46 * u ** 0.9
        h = 0.15 - 0.05 * u
        bone = 'Chest' if z > 4.6 else ('Spine' if z > 3.5 else 'Hips')
        for s in (1, -1):
            pts = plate_ring(z + rng.normal(0, 0.03), r * (1 + rng.normal(0, 0.03)), s, tilt=0.10 + 0.08 * rng.random())
            pts = pts[:len(pts) - int(rng.integers(0, 3))]
            for k in range(len(pts) - 1):
                rad = (pts[k] + pts[k + 1]) / 2 - v3(0, 0.06, pts[k][2])
                rad[2] = 0
                rad /= np.linalg.norm(rad) + 1e-9
                taper = 1.0 - 0.25 * (k / (len(pts) - 2)) ** 3
                P.append(Prim('cone', bone, k=0.03, region='bone', squash=(1.0, 0.42), up=tuple(rad),
                              a=pts[k], b=pts[k + 1], r1=h * taper, r2=h * (1.0 - 0.25 * ((k + 1) / (len(pts) - 2)) ** 3)))
    # spine column at the back holding the plates
    for i in range(20):
        z = 2.0 + i * 0.19
        bone = 'Chest' if z > 4.6 else ('Spine' if z > 3.5 else 'Hips')
        P.append(Prim('ellip', bone, k=0.04, region='bone', c=(0, 0.66 - 0.2 * max(0, (3.0 - z) / 1.0), z),
                      r=(0.10, 0.08, 0.07)))
        P.append(Prim('cone', bone, k=0.03, region='bone', a=(0, 0.70, z), b=(0, 0.86, z - 0.08), r1=0.045, r2=0.01))
    # collar plate the arms hang from
    for s, t in ((1, 'L'), (-1, 'R')):
        P.append(Prim('cone', f'Clavicle_{t}', k=0.06, region='bone', squash=(1.0, 0.45), up=(0, 0, 1),
                      a=(0.05 * s, -0.05, 5.55), b=S('shoulder', s) + v3(-0.05 * s, 0, 0.02), r1=0.10, r2=0.13))
    return P


def core_prims():
    """Tar core inside the cage, sagging into drips."""
    spine = [v3(0, 0.08, z) for z in np.linspace(5.45, 1.85, 12)]
    rad = [0.36, 0.48, 0.52, 0.52, 0.50, 0.46, 0.42, 0.38, 0.36, 0.36, 0.34, 0.24]

    def core(X):
        d = sweep(X, spine, rad)
        return d + 0.05 * fbm(X, 3.0, 3, 7)
    P = [Prim('func', 'Spine', k=0.0, region='tar', lo=(-0.6, -0.55, 1.5), hi=(0.6, 0.7, 5.7), fn=core)]
    for i in range(len(DRIPS)):
        top, mid, end = drip_pts(i)
        pts = bezier(top + v3(0, 0, 0.25), mid + v3(0, 0, 0.1), L(mid, end, 0.6), end, 6)
        r0 = 0.10 + 0.03 * (i % 3) / 2
        rads = [r0, r0 * 0.8, r0 * 0.62, r0 * 0.5, r0 * 0.4, r0 * 0.34, r0 * 0.3]
        for k in range(6):
            P.append(Prim('cone', f'Drip{i + 1}_1' if k < 3 else f'Drip{i + 1}_2', k=0.08, region='tar',
                          a=pts[k], b=pts[k + 1], r1=rads[k], r2=rads[k + 1]))
        P.append(Prim('sphere', f'Drip{i + 1}_2', k=0.05, region='tar', c=end + v3(0, 0, -0.02), r=r0 * 0.5))
    return P


def core_weight_scene():
    P = [Prim('cone', 'Hips', a=(0, 0.08, 1.7), b=(0, 0.08, 3.5), r1=0.3, r2=0.4),
         Prim('cone', 'Spine', a=(0, 0.08, 3.5), b=(0, 0.08, 4.6), r1=0.4, r2=0.45),
         Prim('cone', 'Chest', a=(0, 0.08, 4.6), b=(0, 0.08, 5.5), r1=0.45, r2=0.3)]
    for i in range(len(DRIPS)):
        top, mid, end = drip_pts(i)
        P.append(Prim('cone', f'Drip{i + 1}_1', a=top, b=mid, r1=0.1, r2=0.1))
        P.append(Prim('cone', f'Drip{i + 1}_2', a=mid, b=end, r1=0.1, r2=0.1))
    return Scene(P)


MOUTH_Z = 6.66


def mouth_arc(th, inset=0.0):
    t = math.radians(th)
    rx, ry = 0.34 - inset, 0.36 - inset
    z = MOUTH_Z + 0.20 * (abs(th) / 92) ** 2.0
    return v3(rx * math.sin(t), -0.20 - ry * math.cos(t), z)


def head_prims():
    P = []
    C = v3(0, -0.20, 6.95)
    P.append(Prim('ellip', 'Head', k=0.0, region='mask', c=C + v3(0, 0.04, 0.10), r=(0.38, 0.42, 0.52)))
    P.append(Prim('ellip', 'Jaw', k=0.10, region='mask', c=C + v3(0, -0.03, -0.38), r=(0.34, 0.33, 0.20)))
    for s in (1, -1):
        P.append(Prim('ellip', None, op='sub', k=0.04, c=C + v3(0.16 * s, -0.40, 0.19), r=(0.10, 0.09, 0.045),
                      rot=(0, 18 * s, -10 * s)))
    for th in np.linspace(-94, 94, 39):
        P.append(Prim('ellip', None, op='sub', k=0.012, c=mouth_arc(th, -0.02), r=(0.05, 0.10, 0.09),
                      rot=(0, 0, th)))
    P.append(Prim('ellip', None, op='sub', k=0.04, c=(0, -0.22, MOUTH_Z + 0.05), r=(0.27, 0.25, 0.10)))
    # bone crescent over the brow: two blades from the temples curving up and in
    for s in (1, -1):
        pts = bezier(C + v3(0.32 * s, -0.04, 0.28), C + v3(0.75 * s, -0.06, 0.62), C + v3(0.62 * s, -0.04, 1.12),
                     C + v3(0.10 * s, 0.0, 1.22), 10)
        rads = [0.12 * (1 - k / 10) ** 0.8 + 0.02 for k in range(11)]
        for k in range(10):
            P.append(Prim('cone', 'Head', k=0.05 if k == 0 else 0.015, region='bone', squash=(1.0, 0.28),
                          up=(0, 1, 0), a=pts[k], b=pts[k + 1], r1=rads[k], r2=rads[k + 1]))
    # vertebral neck
    neck = bezier(J['neck1'] + v3(0, 0, -0.2), J['neck1'] + v3(0, 0.05, 0.3), J['neck2'] + v3(0, -0.05, 0.1),
                  J['head'] + v3(0, 0.02, 0.15), 9)
    for k, p in enumerate(neck):
        bone = 'Neck1' if p[2] < 5.95 else 'Neck2'
        P.append(Prim('ellip', bone, k=0.05, region='bone', c=p, r=(0.10, 0.09, 0.06)))
    P += chain(neck, [0.06] * len(neck), ['Neck1' if p[2] < 5.95 else 'Neck2' for p in neck[:-1]], k=0.05,
               region='tar')
    return P


def teeth_prims():
    P = []
    rng = np.random.default_rng(13)
    for row, bone in ((1, 'Head'), (-1, 'Jaw')):
        for rank in range(2):  # two crowded ranks of teeth
            for th in np.linspace(-90, 90, 34 - rank * 6):
                j = rng.normal(0, 1, 3)
                sz = 1.0 - 0.35 * abs(th) / 90
                inset = 0.035 + rank * 0.05
                base = mouth_arc(th + rank * 2.5, inset) + v3(0, 0, 0.105 * row)
                tip = mouth_arc(th + j[0] * 1.5 + rank * 2.5, inset - 0.03) + \
                    v3(0, 0, (0.004 + 0.012 * abs(j[1])) * -row)
                rad = (math.sin(math.radians(th)), -math.cos(math.radians(th)), 0)
                P.append(Prim('cone', bone, k=0.002, region='teeth', a=base, b=tip, up=rad,
                              r1=0.024 * sz * (1 + 0.15 * j[2]), r2=0.008 * sz, squash=(1.0, 0.7)))
        pts = [mouth_arc(th, 0.10) + v3(0, 0, 0.10 * row) for th in np.linspace(-94, 94, 11)]
        P += chain(pts, [0.04] * 11, bone, k=0.02, region='gum')
    return P


def _rot_z(d):
    z = v3(d) / np.linalg.norm(d)
    x = np.cross(v3(0, 1, 0), z)
    x /= np.linalg.norm(x)
    return np.stack([x, np.cross(z, x), z], axis=1)


def hand_prims():
    P = []
    for s, t in ((1, 'L'), (-1, 'R')):
        a, n, sp = hand_frame(s)
        sh, el, wr = S('shoulder', s), S('elbow', s), S('wrist', s)
        P.append(Prim('sphere', f'UpperArm_{t}', k=0.05, region='bone', c=sh, r=0.12))
        P.append(Prim('cone', f'UpperArm_{t}', k=0.05, region='skin', a=sh, b=el, r1=0.085, r2=0.06))
        P.append(Prim('ellip', f'UpperArm_{t}', k=0.05, region='skin', c=L(sh, el, 0.4), r=(0.11, 0.09, 0.3),
                      rot=_rot_z(el - sh)))
        P.append(Prim('sphere', f'LowerArm_{t}', k=0.04, region='bone', c=el, r=0.075))
        P.append(Prim('cone', f'LowerArm_{t}', k=0.04, region='skin', a=el, b=wr, r1=0.06, r2=0.045))
        P.append(Prim('cone', f'Hand_{t}', k=0.04, region='skin', squash=(1.5, 0.5), up=tuple(n), a=wr, b=wr + a * 0.28,
                      r1=0.05, r2=0.06))
        for i in range(4):
            pts = finger_pts(s, i)
            g = 'A' if i < 2 else 'B'
            P += chain(pts[:2], [0.03, 0.027], f'Fingers{g}1_{t}', k=0.015, region='skin')
            P += chain(pts[1:], [0.027, 0.024, 0.02], f'Fingers{g}2_{t}', k=0.012, region='skin')
            for q in pts[1:3]:
                P.append(Prim('sphere', f'Fingers{g}2_{t}', k=0.012, region='bone', c=q, r=0.032))
            d = pts[3] - pts[2]
            d /= np.linalg.norm(d)
            P += chain([pts[3] - d * 0.03, pts[3] + d * 0.12], [0.02, 0.004], f'Fingers{g}2_{t}', k=0.006,
                       region='tar')
    return P


def eye_prims():
    C = v3(0, -0.20, 6.95)
    return [Prim('sphere', 'Head', k=0.0, region='glow', c=C + v3(0.15 * s, -0.33, 0.19), r=0.012) for s in (1, -1)]


def pieces():
    return [
        bk.Piece('cage', Scene(cage_prims()), tris=3600, voxel=0.014, falloff=0.10, lo_voxel=0.022),
        bk.Piece('core', Scene(core_prims()), tris=2000, voxel=0.02, falloff=0.25, weight_scene=core_weight_scene(),
                 mat='tar'),
        bk.Piece('head', Scene(head_prims()), tris=2300, voxel=0.011, falloff=0.05),
        bk.Piece('teeth', Scene(teeth_prims()), tris=1600, voxel=0.0055, mat='teeth', falloff=0.02),
        bk.Piece('arms', Scene(hand_prims()), tris=1900, voxel=0.008, falloff=0.04, lo_voxel=0.012),
        bk.Piece('eyes', Scene(eye_prims()), tris=60, voxel=0.004, rigid='Head', group='glow', mat='teeth'),
    ]


# ----------------------------------------------------------------- materials
def mat_bone(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n1 = nk.noise(co, 3.0, 6, 0.6).outputs['Fac']
    bone = nk.ramp(n1, [(0.3, (0.30, 0.27, 0.21)), (0.55, (0.46, 0.42, 0.33)), (0.78, (0.56, 0.52, 0.42))])
    dirt = nk.maprange(nk.noise(co, 1.5, 4, 0.5).outputs['Fac'], 0.5, 0.7)
    bone = nk.mix(nk.math('MULTIPLY', dirt, 0.6), bone, (0.12, 0.10, 0.08))
    mask = nk.attr('rg_mask')
    porc = nk.ramp(n1, [(0.3, (0.58, 0.57, 0.53)), (0.7, (0.74, 0.73, 0.68))])
    vo = nk.voronoi(co, 5.0, 'DISTANCE_TO_EDGE')
    crack = nk.maprange(vo.outputs['Distance'], 0.0, 0.012, 1.0, 0.0)
    crack = nk.math('MULTIPLY', crack, nk.maprange(nk.noise(co, 2.0, 3, 0.5).outputs['Fac'], 0.45, 0.6))
    porc = nk.mix(crack, porc, (0.05, 0.04, 0.04))
    col = nk.mix(mask, bone, porc)
    tar = nk.attr('rg_tar')
    skin = nk.attr('rg_skin')
    col = nk.mix(skin, col, nk.mix(n1, (0.012, 0.011, 0.014), (0.035, 0.03, 0.04)))
    col = nk.mix(tar, col, (0.006, 0.005, 0.007))
    rough = nk.mixf(mask, nk.maprange(n1, 0.2, 0.8, 0.45, 0.7), 0.28)
    rough = nk.mixf(tar, rough, 0.12)
    rough = nk.mixf(skin, rough, 0.55)
    grooves = nk.wave(co, 14.0, 4.0, 3.0, 'BANDS', 'Z').outputs['Fac']
    h = nk.math('ADD', nk.math('MULTIPLY', nk.noise(co, 25.0, 8, 0.6).outputs['Fac'], 0.6),
                nk.math('MULTIPLY', grooves, 0.25))
    h = nk.mixf(mask, h, nk.math('SUBTRACT', nk.math('MULTIPLY', nk.noise(co, 40.0, 3, 0.4).outputs['Fac'], 0.2),
                                 nk.math('MULTIPLY', crack, 0.5)))
    nk.finish(col, rough, 0.0, nk.bump(h, 0.3, 0.008))
    return mat


def mat_tar(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n = nk.noise(co, 4.0, 5, 0.6).outputs['Fac']
    col = nk.mix(n, (0.004, 0.003, 0.006), (0.02, 0.012, 0.03))
    rough = nk.maprange(nk.noise(co, 2.0, 3, 0.5).outputs['Fac'], 0.4, 0.6, 0.06, 0.25)
    nk.finish(col, rough, 0.0, nk.bump(nk.noise(co, 9.0, 4, 0.6).outputs['Fac'], 0.25, 0.01))
    return mat


def mat_teeth(mat):
    nk = bk.NodeKit(mat)
    co = nk.coord('Object')
    n = nk.noise(co, 30.0, 4, 0.5).outputs['Fac']
    gum = nk.attr('rg_gum')
    col = nk.ramp(n, [(0.35, (0.38, 0.33, 0.22)), (0.65, (0.60, 0.55, 0.40))])
    col = nk.mix(gum, col, (0.02, 0.01, 0.015))
    rough = nk.mixf(gum, 0.3, 0.2)
    nk.finish(col, rough, 0.0, nk.bump(n, 0.1, 0.003))
    return mat


MATERIALS = {'skin': mat_bone, 'tar': mat_tar, 'teeth': mat_teeth}


# ----------------------------------------------------------------- animation
SIDES = (('L', 1), ('R', -1))


def fingers(curl, spread=0.0):
    return bk.sym({'FingersA1_L': (0, curl, -spread), 'FingersA2_L': (0, curl * 1.3, 0),
                   'FingersB1_L': (0, curl, spread), 'FingersB2_L': (0, curl * 1.3, 0)})


def drips(p, t, amp=8.0, trail=0.0, freq=1.0):
    for i in range(len(DRIPS)):
        ph = i * 0.17
        p[f'Drip{i + 1}_1'] = (trail * 0.6 + amp * mo.s(freq * t + ph), amp * 0.5 * mo.s(freq * t + ph + 0.3), 0)
        p[f'Drip{i + 1}_2'] = (trail * 0.8 + amp * 1.4 * mo.s(freq * t + ph - 0.15), amp * 0.6 * mo.s(freq * t + ph), 0)
    return p


def body(p, bow=0.0, look=0.0, tilt=0.0, twist=0.0):
    p['Hips'] = (bow * 0.2, 0, twist * 0.2)
    p['Spine'] = (bow * 0.3, tilt * 0.2, twist * 0.3)
    p['Chest'] = (bow * 0.4, tilt * 0.3, twist * 0.4)
    p['Neck1'] = (bow * 0.3 + 10, 0, 0)
    p['Neck2'] = (-look * 0.5 - 6, tilt * 0.3, 0)
    p['Head'] = (-bow * 0.8 - look * 0.5 - 4, tilt, 0)
    return p


def arms_hang(an, p, t, out=0.35, fwd=0.2, wave=0.05, curl=14):
    for tt, sgn in SIDES:
        ph = 0 if tt == 'L' else 0.37
        an.aim(p, f'UpperArm_{tt}', (out * sgn, -0.10 + fwd + wave * mo.s(t + ph), -1))
        an.aim(p, f'LowerArm_{tt}', (out * 0.4 * sgn, -0.35 + fwd * 1.3 + wave * 1.5 * mo.s(t + ph - 0.1), -1))
        an.aim(p, f'Hand_{tt}', (0.05 * sgn, -0.45 + fwd + wave * 2 * mo.s(t + ph - 0.2), -1))
    p.update(fingers(curl))
    return p


def clips(an):
    out = []

    def idle(t):
        p = {'@root': (0.04 * mo.s(t), 0.03 * mo.c(t), 0.25 + 0.15 * mo.s(t))}
        body(p, bow=6 + 2 * mo.s(t), look=4 * mo.s(t + 0.3), tilt=14 * mo.s(t + 0.1) + 30 * mo.twitch(t, 0.45, 0.03),
             twist=6 * mo.s(t))
        arms_hang(an, p, t)
        p['Jaw'] = (6 + 4 * mo.s(2 * t), 0, 0)
        drips(p, t, amp=7)
        return p
    out.append(('Idle', 120, idle, True))

    def drift(t, fast=False):
        k = 1.7 if fast else 1.0
        p = {'@root': (0.04 * mo.s(t), 0, 0.15 + 0.10 * mo.s(2 * t))}
        body(p, bow=14 * k, look=16 * k, tilt=6 * mo.s(t), twist=5 * mo.s(t))
        if fast:
            for tt, sgn in SIDES:
                ph = mo.s(t) if tt == 'L' else -mo.s(t)
                an.aim(p, f'UpperArm_{tt}', (0.35 * sgn, -1.0 - 0.2 * ph, -0.35))
                an.aim(p, f'LowerArm_{tt}', (0.15 * sgn, -1.0, -0.25 + 0.2 * ph))
                an.aim(p, f'Hand_{tt}', (0.05 * sgn, -1.0, -0.3))
            p.update(fingers(-6, 10))
            p['Jaw'] = (30 + 8 * mo.s(2 * t), 0, 0)
            p['Head'] = bk.pose_mul({'Head': p['Head']}, {'Head': (0, 0, 14 * mo.twitch(t, 0.3, 0.05) -
                                                                        14 * mo.twitch(t, 0.75, 0.05))})['Head']
        else:
            arms_hang(an, p, t, fwd=0.45, wave=0.12)
            p['Jaw'] = (8, 0, 0)
        drips(p, t, amp=6 * k, trail=28 * k)
        return p
    out.append(('Drift', 60, lambda t: drift(t), True))
    out.append(('Hunt', 30, lambda t: drift(t, True), True))

    base0 = idle(0)

    # ---- Attack ("rides" the victim): rears up, drops forward, pins with both hands
    def k_rise():
        p = {'@root': (0, 0.4, 1.4)}
        body(p, bow=-14, look=-10)
        for tt, sgn in SIDES:
            an.aim(p, f'UpperArm_{tt}', (0.8 * sgn, -0.2, 0.6))
            an.aim(p, f'LowerArm_{tt}', (0.5 * sgn, -0.7, 0.5))
            an.aim(p, f'Hand_{tt}', (0.2 * sgn, -1.0, 0.0))
        p.update(fingers(-10, 12))
        p['Jaw'] = (40, 0, 0)
        drips(p, 0, amp=0, trail=-25)
        return p

    def k_pin():
        p = {'@root': (0, -1.8, -1.1)}
        body(p, bow=48, look=34)
        for tt, sgn in SIDES:
            mo.ik2(an, p, f'UpperArm_{tt}', f'LowerArm_{tt}', mo.Vector((0.55 * sgn, -3.3, 1.6)), (sgn, 0.4, 0.2))
            an.aim(p, f'Hand_{tt}', (0, -0.6, -1))
        p.update(fingers(30, 8))
        p['Jaw'] = (48, 0, 0)
        drips(p, 0, amp=0, trail=40)
        return p
    pin2 = k_pin()
    pin2['Head'] = bk.pose_mul({'Head': pin2['Head']}, {'Head': (0, 22, 0)})['Head']
    out.append(('Attack', 54, bk.track([(0, base0), (0.25, k_rise()), (0.42, k_pin(), 'snap'), (0.7, pin2),
                                        (0.85, pin2), (1.0, base0)]), False))

    # ---- Hallucinate: the head snaps through impossible angles, body stutters (loop it for the effect)
    def halluc(t):
        p = idle(t)
        steps = [(0.0, (0, 0, 0)), (0.12, (0, 0, 92)), (0.26, (0, 0, 92)), (0.3, (-30, 40, -60)),
                 (0.5, (-30, 40, -60)), (0.53, (0, 180, 0)), (0.72, (0, 180, 0)), (0.76, (20, 0, 150)),
                 (0.9, (20, 0, 150)), (1.0, (0, 0, 0))]
        rot = (0, 0, 0)
        for (t0, r0), (t1, r1) in zip(steps, steps[1:]):
            if t0 <= t <= t1:
                u = bk.ease((t - t0) / (t1 - t0), 'snap')
                rot = tuple(a + (b - a) * u for a, b in zip(r0, r1))
        p['Head'] = bk.pose_mul({'Head': p['Head']}, {'Head': rot})['Head']
        jitter = 0.06 * mo.s(23 * t) * (1 if (t * 9) % 1 > 0.5 else 0)
        p['@root'] = mo.Vector(p['@root']) + mo.Vector((jitter, 0, jitter * 0.5))
        p['Jaw'] = (14 + 30 * (mo.twitch(t, 0.3, 0.06) + mo.twitch(t, 0.76, 0.06)), 0, 0)
        p.update(fingers(-10 + 50 * mo.twitch(t, 0.53, 0.1), 10))
        return p
    out.append(('Hallucinate', 60, halluc, True))

    # ---- Manifest: pours up out of the floor; Vanish: melts back down
    def k_puddle():
        p = {'@root': (0, 0.0, -4.6)}
        body(p, bow=50, look=-60)
        arms_hang(an, p, 0, out=1.2, fwd=-0.4)
        drips(p, 0, amp=0, trail=-60)
        return p
    out.append(('Manifest', 60, bk.track([(0, k_puddle()), (0.2, k_puddle()), (0.75, base0, 'out'), (1.0, base0)]),
                False))
    out.append(('Vanish', 36, bk.track([(0, base0), (0.2, k_rise()), (1.0, k_puddle(), 'in')]), False))
    return out


if __name__ == '__main__':
    import pipeline
    pipeline.build(sys.modules[__name__])
