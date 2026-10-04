"""Reads an FBX file the way an importer sees it (no Blender scene involved).

    python3 inspect_fbx.py file.fbx [more.fbx ...]

Prints: unit scale and axes, every Model node with its parent and local
transform, vertex extents per mesh, and the rotation keys of the Root and
HumanoidRootNode bones.  Used to check the Roblox export contract.
"""
import sys

import bpy  # noqa: F401  (puts the bundled add-ons on sys.path)
import numpy as np
from io_scene_fbx import parse_fbx


def props70(elem):
    out = {}
    for c in elem.elems:
        if c.id == b'Properties70':
            for p in c.elems:
                name = p.props[0].decode()
                out[name] = p.props[4:]
    return out


def child(elem, name):
    for c in elem.elems:
        if c.id == name:
            return c
    return None


def inspect(path):
    root, ver = parse_fbx.parse(path)
    info = {'version': ver}
    gs = child(root, b'GlobalSettings')
    g = props70(gs)
    info['UnitScaleFactor'] = g.get('UnitScaleFactor', [None])[0]
    info['axes'] = {k: g[k][0] for k in ('UpAxis', 'UpAxisSign', 'FrontAxis', 'FrontAxisSign', 'CoordAxis',
                                         'CoordAxisSign') if k in g}
    objs = child(root, b'Objects')
    conns = child(root, b'Connections')
    by_id, models, geoms, curvenodes, curves = {}, {}, {}, {}, {}
    for o in objs.elems:
        uid = o.props[0]
        by_id[uid] = o
        if o.id == b'Model':
            name = o.props[1].split(b'\x00')[0].decode()
            kind = o.props[2].decode()
            p = props70(o)
            models[uid] = dict(name=name, kind=kind, t=p.get('Lcl Translation', [0, 0, 0]),
                               r=p.get('Lcl Rotation', [0, 0, 0]), s=p.get('Lcl Scaling', [1, 1, 1]),
                               pre=p.get('PreRotation', [0, 0, 0]))
        elif o.id == b'Geometry':
            v = child(o, b'Vertices')
            if v is not None:
                geoms[uid] = np.asarray(v.props[0]).reshape(-1, 3)
        elif o.id == b'AnimationCurveNode':
            curvenodes[uid] = o.props[1].split(b'\x00')[0].decode()
        elif o.id == b'AnimationCurve':
            kv = child(o, b'KeyValueFloat')
            curves[uid] = np.asarray(kv.props[0]) if kv is not None else np.zeros(0)
    parent, geo_of, cn_target, curve_of = {}, {}, {}, {}
    for c in conns.elems:
        kind, a, b = c.props[0], c.props[1], c.props[2]
        prop = c.props[3].decode() if len(c.props) > 3 else ''
        if a in models and (b in models or b == 0):
            parent[a] = b
        if a in geoms and b in models:
            geo_of[b] = a
        if a in curvenodes and b in models:
            cn_target[a] = (b, prop)
        if a in curves and b in curvenodes:
            curve_of.setdefault(b, {})[prop] = a
    info['models'] = []
    for uid, m in models.items():
        par = parent.get(uid)
        m['parent'] = 'scene' if par == 0 else (models[par]['name'] if par in models else '?')
        if uid in geo_of:
            v = geoms[geo_of[uid]]
            m['verts'] = len(v)
            m['extent'] = (v.min(0).round(3).tolist(), v.max(0).round(3).tolist())
        info['models'].append(m)
    info['anim'] = {}
    for cn, (tgt, prop) in cn_target.items():
        name = models[tgt]['name']
        if name in ('Root', 'HumanoidRootNode', 'HumanoidRootPart') and prop == 'Lcl Rotation':
            ch = curve_of.get(cn, {})
            vals = {k: curves[v] for k, v in ch.items()}
            info['anim'][name] = {k: (float(x.min()), float(x.max()), len(x)) for k, x in vals.items()}
    return info


def fmt(v):
    return '(' + ', '.join(f'{x:.3g}' for x in v) + ')'


if __name__ == '__main__':
    for path in [a for a in sys.argv[1:] if a.endswith('.fbx')]:
        i = inspect(path)
        print(f'== {path.rsplit("/", 1)[-1]}  FBX {i["version"]}  UnitScaleFactor={i["UnitScaleFactor"]}  {i["axes"]}')
        for m in i['models']:
            if m['kind'] in ('Mesh', 'Null') or m['name'] in ('Root', 'HumanoidRootNode', 'HumanoidRootPart', 'Hips'):
                extra = f'  verts={m["verts"]} extent={m["extent"]}' if 'verts' in m else ''
                print(f'  {m["kind"]:9s} {m["name"]:28s} parent={m["parent"]:24s} T={fmt(m["t"])} R={fmt(m["r"])} '
                      f'S={fmt(m["s"])}{extra}')
        for name, ch in i['anim'].items():
            print(f'  anim {name} Lcl Rotation keys: ' + ', '.join(f'{k}[{a:.1f}..{b:.1f}]x{n}' for k, (a, b, n) in ch.items()))
