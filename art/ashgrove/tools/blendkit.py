"""Blender helpers for the Ashgrove House entity pipeline.

Each creature script describes Pieces (SDF scenes + bone ownership), a
skeleton, a procedural material and its animation clips; this module turns
that into: a high-poly sculpt, a game-res mesh with UVs, baked PBR maps, a
skinned rig, FBX files and review renders.
"""
import math
import os
import time

import bpy  # noqa: F401  (must load before bmesh)
import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Quaternion, Vector

from sdf import limit_weights

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))


def log(*a):
    print(f'[{time.strftime("%H:%M:%S")}]', *a, flush=True)


# ---------------------------------------------------------------- scene setup
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.fps = 30
    s.unit_settings.system = 'NONE'  # 1 Blender unit == 1 Roblox stud
    s.render.engine = 'CYCLES'
    s.cycles.device = 'CPU'
    return s


def link(obj):
    bpy.context.scene.collection.objects.link(obj)
    return obj


def activate(obj, select_only=True):
    if select_only:
        for o in bpy.context.scene.objects:
            o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def mesh_from_arrays(name, verts, faces):
    me = bpy.data.meshes.new(name)
    me.vertices.add(len(verts))
    me.vertices.foreach_set('co', np.asarray(verts, np.float32).ravel())
    n = len(faces)
    me.loops.add(n * 3)
    me.loops.foreach_set('vertex_index', np.asarray(faces, np.int32).ravel())
    me.polygons.add(n)
    me.polygons.foreach_set('loop_start', np.arange(0, n * 3, 3, dtype=np.int32))
    me.update(calc_edges=True)
    me.validate()
    obj = bpy.data.objects.new(name, me)
    return link(obj)


def verts_np(obj):
    me = obj.data
    a = np.zeros(len(me.vertices) * 3, np.float32)
    me.vertices.foreach_get('co', a)
    return a.reshape(-1, 3).astype(np.float64)


def tri_count(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def shade_smooth(obj):
    obj.data.polygons.foreach_set('use_smooth', [True] * len(obj.data.polygons))


def apply_mods(obj):
    activate(obj)
    for m in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


def smooth_mesh(obj, iters=2, factor=0.5):
    m = obj.modifiers.new('sm', 'SMOOTH')
    m.iterations, m.factor = iters, factor
    apply_mods(obj)


def decimate_to(obj, target_tris):
    n = tri_count(obj)
    if n > target_tris:
        m = obj.modifiers.new('dec', 'DECIMATE')
        m.decimate_type = 'COLLAPSE'
        m.ratio = target_tris / n
        m.use_collapse_triangulate = True
        apply_mods(obj)
    return tri_count(obj)


# ----------------------------------------------------------------- the pieces
class Piece:
    """One watertight component of a creature.

    scene  : sdf.Scene
    tris   : triangle budget for the game mesh
    voxel  : marching-cubes voxel size for the high-poly sculpt
    rigid  : bone name -> the whole piece follows one bone (teeth, eyes)
    group  : which exported mesh it ends up in ('body', 'glow', 'head', ...)
    mat    : material builder name (see materials in the creature script)
    falloff: skin weight blend distance
    """

    def __init__(self, name, scene, tris, voxel, rigid=None, group='body', mat='skin',
                 falloff=0.08, smooth=1, lo_voxel=None, weight_scene=None):
        self.name, self.scene, self.tris, self.voxel = name, scene, tris, voxel
        self.weight_scene = weight_scene
        self.rigid, self.group, self.mat, self.falloff = rigid, group, mat, falloff
        self.smooth, self.lo_voxel = smooth, lo_voxel

    def build(self):
        log(f'piece {self.name}')
        v, f = self.scene.mesh(self.voxel)
        hi = mesh_from_arrays(self.name + '_hi', v, f)
        if self.smooth:
            smooth_mesh(hi, self.smooth, 0.4)
        shade_smooth(hi)
        if self.lo_voxel:
            v2, f2 = self.scene.mesh(self.lo_voxel, verbose=False)
            lo = mesh_from_arrays(self.name + '_lo', v2, f2)
            if self.smooth:
                smooth_mesh(lo, self.smooth, 0.4)
        else:
            lo = hi.copy()
            lo.data = hi.data.copy()
            lo.name = self.name + '_lo'
            link(lo)
        decimate_to(lo, self.tris)
        shade_smooth(lo)
        self.hi, self.lo = hi, lo
        # region masks on the sculpt drive the procedural material
        P = verts_np(hi)
        regions, R = self.scene.region_weights(P)
        for i, rg in enumerate(regions):
            at = hi.data.attributes.new('rg_' + rg, 'FLOAT', 'POINT')
            at.data.foreach_set('value', R[:, i].astype(np.float32))
        log(f'  hi {tri_count(hi)} tris, lo {tri_count(lo)} tris, regions {regions}')
        return self

    def skin(self, arm_bones):
        lo = self.lo
        P = verts_np(lo)
        if self.rigid:
            bones, W = [self.rigid], np.ones((len(P), 1))
        else:
            bones, W = (self.weight_scene or self.scene).bone_weights(P, self.falloff)
            W = smooth_weights(lo, W, iters=3)
            W = limit_weights(W, 4)
        for i, b in enumerate(bones):
            assert b in arm_bones, f'{self.name}: unknown bone {b}'
            vg = lo.vertex_groups.get(b) or lo.vertex_groups.new(name=b)
            idx = np.nonzero(W[:, i] > 1e-4)[0]
            for vi in idx:
                vg.add([int(vi)], float(W[vi, i]), 'REPLACE')


def smooth_weights(obj, W, iters=3, alpha=0.5):
    me = obj.data
    e = np.zeros(len(me.edges) * 2, np.int64)
    me.edges.foreach_get('vertices', e)
    e = e.reshape(-1, 2)
    n = len(me.vertices)
    for _ in range(iters):
        acc = np.zeros_like(W)
        cnt = np.zeros(n)
        np.add.at(acc, e[:, 0], W[e[:, 1]])
        np.add.at(acc, e[:, 1], W[e[:, 0]])
        np.add.at(cnt, e[:, 0], 1)
        np.add.at(cnt, e[:, 1], 1)
        avg = acc / np.maximum(cnt, 1)[:, None]
        W = W * (1 - alpha) + avg * alpha
    return W


def join(objs, name):
    objs = [o for o in objs]
    activate(objs[0])
    for o in objs[1:]:
        o.select_set(True)
    bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = name
    o.data.name = name
    return o


# ------------------------------------------------------------------------- UV
def unwrap(obj, margin=0.004, angle=60):
    activate(obj)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(angle), island_margin=margin,
                             area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.pack_islands(rotate=True, margin=margin)
    bpy.ops.object.mode_set(mode='OBJECT')


# ------------------------------------------------------------------ materials
class NodeKit:
    """Tiny helper for writing node trees in Python."""

    def __init__(self, mat):
        mat.use_nodes = True
        self.mat, self.nt = mat, mat.node_tree
        self.nt.nodes.clear()
        self.x = 0

    def node(self, kind, **inputs):
        n = self.nt.nodes.new(kind)
        n.location = (self.x, 0)
        self.x += 40
        for k, v in inputs.items():
            if k.startswith('_'):
                setattr(n, k[1:], v)
            else:
                self.set(n.inputs[k], v)
        return n

    def set(self, sock, v):
        if hasattr(v, 'is_output') or isinstance(v, bpy.types.NodeSocket):
            self.nt.links.new(v, sock)
        elif isinstance(v, bpy.types.Node):
            self.nt.links.new(v.outputs[0], sock)
        else:
            if isinstance(v, (tuple, list)) and len(v) == 3 and sock.type == 'RGBA':
                v = (*v, 1.0)
            sock.default_value = v

    def out(self, n, i=0):
        return n.outputs[i] if not isinstance(n, bpy.types.NodeSocket) else n

    # convenience -------------------------------------------------------
    def attr(self, name):
        return self.node('ShaderNodeAttribute', _attribute_name=name).outputs['Fac']

    def coord(self, kind='Object'):
        return self.node('ShaderNodeTexCoord').outputs[kind]

    def math(self, op, a, b=0.0, clamp=False):
        n = self.node('ShaderNodeMath', _operation=op, _use_clamp=clamp)
        self.set(n.inputs[0], a)
        self.set(n.inputs[1], b)
        return n.outputs[0]

    def vmath(self, op, a, b=(0, 0, 0)):
        n = self.node('ShaderNodeVectorMath', _operation=op)
        self.set(n.inputs[0], a)
        self.set(n.inputs[1], b)
        return n.outputs[0]

    def mix(self, fac, a, b, blend='MIX'):
        n = self.node('ShaderNodeMix', _data_type='RGBA', _blend_type=blend)
        self.set(n.inputs['Factor'], fac)
        self.set(n.inputs[6], a)
        self.set(n.inputs[7], b)
        return n.outputs[2]

    def mixf(self, fac, a, b):
        n = self.node('ShaderNodeMix', _data_type='FLOAT')
        self.set(n.inputs['Factor'], fac)
        self.set(n.inputs[2], a)
        self.set(n.inputs[3], b)
        return n.outputs[0]

    def noise(self, vec=None, scale=5.0, detail=4.0, rough=0.5, dist=0.0, dims='3D', w=0.0):
        n = self.node('ShaderNodeTexNoise', _noise_dimensions=dims)
        if vec is not None:
            self.set(n.inputs['Vector'], vec)
        self.set(n.inputs['Scale'], scale)
        self.set(n.inputs['Detail'], detail)
        self.set(n.inputs['Roughness'], rough)
        self.set(n.inputs['Distortion'], dist)
        if dims == '4D':
            self.set(n.inputs['W'], w)
        return n

    def voronoi(self, vec=None, scale=5.0, feature='F1', metric='EUCLIDEAN', rnd=1.0):
        n = self.node('ShaderNodeTexVoronoi', _feature=feature, _distance=metric)
        if vec is not None:
            self.set(n.inputs['Vector'], vec)
        self.set(n.inputs['Scale'], scale)
        self.set(n.inputs['Randomness'], rnd)
        return n

    def wave(self, vec=None, scale=5.0, distortion=2.0, detail=2.0, kind='BANDS', axis='Z', profile='SIN'):
        n = self.node('ShaderNodeTexWave', _wave_type=kind, _bands_direction=axis, _wave_profile=profile)
        if vec is not None:
            self.set(n.inputs['Vector'], vec)
        self.set(n.inputs['Scale'], scale)
        self.set(n.inputs['Distortion'], distortion)
        self.set(n.inputs['Detail'], detail)
        return n

    def ramp(self, fac, stops, interp='LINEAR'):
        n = self.node('ShaderNodeValToRGB')
        cr = n.color_ramp
        cr.interpolation = interp
        while len(cr.elements) > 1:
            cr.elements.remove(cr.elements[-1])
        for i, (pos, col) in enumerate(stops):
            e = cr.elements[0] if i == 0 else cr.elements.new(pos)
            e.position = pos
            e.color = (*col, 1.0) if len(col) == 3 else col
        self.set(n.inputs['Fac'], fac)
        return n.outputs['Color']

    def maprange(self, v, a, b, c=0.0, d=1.0, clamp=True):
        n = self.node('ShaderNodeMapRange', _clamp=clamp)
        self.set(n.inputs['Value'], v)
        n.inputs['From Min'].default_value = a
        n.inputs['From Max'].default_value = b
        n.inputs['To Min'].default_value = c
        n.inputs['To Max'].default_value = d
        return n.outputs['Result']

    def bump(self, height, strength=0.3, distance=0.02, normal=None):
        n = self.node('ShaderNodeBump', _invert=False)
        self.set(n.inputs['Height'], height)
        n.inputs['Strength'].default_value = strength
        n.inputs['Distance'].default_value = distance
        if normal is not None:
            self.set(n.inputs['Normal'], normal)
        return n.outputs['Normal']

    def finish(self, albedo, rough, metal=0.0, normal=None, emission=None, emit_strength=0.0, sss=0.0,
               emit_mask=None):
        """Principled output + a spare emission node used for baking."""
        bsdf = self.node('ShaderNodeBsdfPrincipled')
        bsdf.name = 'BSDF'
        self.set(bsdf.inputs['Base Color'], albedo)
        self.set(bsdf.inputs['Roughness'], rough)
        self.set(bsdf.inputs['Metallic'], metal)
        if normal is not None:
            self.set(bsdf.inputs['Normal'], normal)
        if emission is not None:
            self.set(bsdf.inputs['Emission Color'], emission)
            bsdf.inputs['Emission Strength'].default_value = emit_strength
        if sss:
            bsdf.inputs['Subsurface Weight'].default_value = sss
            bsdf.inputs['Subsurface Radius'].default_value = (0.3, 0.12, 0.08)
            bsdf.inputs['Subsurface Scale'].default_value = 0.05
        em = self.node('ShaderNodeEmission')
        em.name = 'BAKE_EMIT'
        out = self.node('ShaderNodeOutputMaterial')
        out.name = 'OUT'
        self.nt.links.new(bsdf.outputs[0], out.inputs['Surface'])
        # remember sockets for bake passes
        self.mat['bake_albedo'] = self._sock_path(albedo)
        self.mat['bake_rough'] = self._sock_path(rough)
        self.mat['bake_metal'] = self._sock_path(metal)
        self.mat['bake_emit'] = self._sock_path(emit_mask if emit_mask is not None else 0.0)
        if emit_mask is not None:
            self.mat['has_emit'] = True
            self.set(bsdf.inputs['Emission Color'], (1.0, 0.35, 0.06))
            self.set(bsdf.inputs['Emission Strength'], self.math('MULTIPLY', emit_mask, 3.0))
        return bsdf

    def _sock_path(self, s):
        if isinstance(s, bpy.types.NodeSocket):
            return f'{s.node.name}|{s.identifier}'
        return repr(s)


def bake_source(mat, key):
    v = mat[key]
    if '|' in v:
        node, ident = v.split('|')
        n = mat.node_tree.nodes[node]
        for o in n.outputs:
            if o.identifier == ident:
                return o
    return eval(v)


def set_bake_pass(mats, which):
    for m in mats:
        nt = m.node_tree
        out, em, bsdf = nt.nodes['OUT'], nt.nodes['BAKE_EMIT'], nt.nodes['BSDF']
        for l in list(out.inputs['Surface'].links):
            nt.links.remove(l)
        if which == 'normal':
            nt.links.new(bsdf.outputs[0], out.inputs['Surface'])
            continue
        src = bake_source(m, {'albedo': 'bake_albedo', 'rough': 'bake_rough', 'metal': 'bake_metal',
                              'emit': 'bake_emit'}[which])
        for l in list(em.inputs['Color'].links):
            nt.links.remove(l)
        if isinstance(src, bpy.types.NodeSocket):
            nt.links.new(src, em.inputs['Color'])
        else:
            c = src if isinstance(src, (tuple, list)) else (src, src, src)
            em.inputs['Color'].default_value = (*c[:3], 1.0)
        em.inputs['Strength'].default_value = 1.0
        nt.links.new(em.outputs[0], out.inputs['Surface'])


# ----------------------------------------------------------------------- bake
def bake_maps(low, highs, out_dir, prefix, size=1024, extrusion=0.03, ray=0.12, samples=8):
    """Bake Color / Normal / Roughness / Metalness from the sculpts to `low`."""
    s = bpy.context.scene
    s.render.engine = 'CYCLES'
    s.cycles.samples = samples
    s.cycles.use_denoising = False
    s.render.bake.use_selected_to_active = True
    s.render.bake.cage_extrusion = extrusion
    s.render.bake.max_ray_distance = ray
    s.render.bake.margin = 12
    s.render.bake.margin_type = 'EXTEND'
    os.makedirs(out_dir, exist_ok=True)
    # target material on the low mesh
    mat = bpy.data.materials.new(prefix + '_BakeTarget')
    mat.use_nodes = True
    low.data.materials.clear()
    low.data.materials.append(mat)
    tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
    mats = list({m for h in highs for m in h.data.materials if m})
    results = {}
    passes = [('albedo', 'EMIT', 'sRGB'), ('rough', 'EMIT', 'Non-Color'),
              ('metal', 'EMIT', 'Non-Color'), ('normal', 'NORMAL', 'Non-Color')]
    if any(m.get('has_emit') for m in mats):
        passes.append(('emit', 'EMIT', 'Non-Color'))
    for which, btype, cs in passes:
        name = {'albedo': 'Color', 'rough': 'Roughness', 'metal': 'Metalness', 'normal': 'Normal',
                'emit': 'Emissive'}[which]
        img = bpy.data.images.new(f'{prefix}_{name}', size, size, alpha=False, float_buffer=(which == 'normal'))
        img.colorspace_settings.name = cs
        tex.image = img
        mat.node_tree.nodes.active = tex
        set_bake_pass(mats, which)
        activate(low)
        for h in highs:
            h.select_set(True)
        low.select_set(True)
        bpy.context.view_layer.objects.active = low
        t = time.time()
        if btype == 'NORMAL':
            s.render.bake.normal_space = 'TANGENT'
            bpy.ops.object.bake(type='NORMAL')
        else:
            bpy.ops.object.bake(type='EMIT')
        path = os.path.join(out_dir, f'{prefix}_{name}.png')
        img.filepath_raw = path
        img.file_format = 'PNG'
        s.render.image_settings.color_depth = '8'
        img.save()
        results[which] = path
        log(f'  baked {name} in {time.time()-t:.0f}s')
    set_bake_pass(mats, 'normal')
    bpy.data.materials.remove(mat)
    return results


def game_material(name, maps, glow=None):
    """Material on the game mesh that uses the baked maps (render + .blend)."""
    mat = bpy.data.materials.new(name)
    nk = NodeKit(mat)
    def img(path, cs):
        n = nk.node('ShaderNodeTexImage')
        n.image = bpy.data.images.load(path, check_existing=True)
        n.image.colorspace_settings.name = cs
        return n
    col = img(maps['albedo'], 'sRGB')
    rgh = img(maps['rough'], 'Non-Color')
    met = img(maps['metal'], 'Non-Color')
    nrm = img(maps['normal'], 'Non-Color')
    nm = nk.node('ShaderNodeNormalMap')
    nk.set(nm.inputs['Color'], nrm.outputs['Color'])
    bsdf = nk.node('ShaderNodeBsdfPrincipled')
    nk.set(bsdf.inputs['Base Color'], col.outputs['Color'])
    nk.set(bsdf.inputs['Roughness'], rgh.outputs['Color'])
    nk.set(bsdf.inputs['Metallic'], met.outputs['Color'])
    nk.set(bsdf.inputs['Normal'], nm.outputs['Normal'])
    if maps.get('emit'):
        em = img(maps['emit'], 'Non-Color')
        nk.set(bsdf.inputs['Emission Color'], (1.0, 0.35, 0.06))
        nk.set(bsdf.inputs['Emission Strength'], nk.math('MULTIPLY', em.outputs['Color'], 3.0))
    out = nk.node('ShaderNodeOutputMaterial')
    nk.nt.links.new(bsdf.outputs[0], out.inputs['Surface'])
    return mat


def glow_material(name, color, strength=6.0):
    mat = bpy.data.materials.new(name)
    nk = NodeKit(mat)
    em = nk.node('ShaderNodeEmission', Color=color, Strength=strength)
    out = nk.node('ShaderNodeOutputMaterial')
    nk.nt.links.new(em.outputs[0], out.inputs['Surface'])
    mat['roblox_neon'] = True
    return mat


# ------------------------------------------------------------------- armature
def build_armature(name, bones):
    """bones: list of dicts {name, head, tail, parent, deform, roll_to}.

    roll_to: a world vector the bone's local Z axis should point toward
    (defaults to -Y, the creature's front), so every bone has a predictable
    local frame.
    """
    arm = bpy.data.armatures.new(name)
    obj = link(bpy.data.objects.new(name, arm))
    activate(obj)
    bpy.ops.object.mode_set(mode='EDIT')
    eb = {}
    for b in bones:
        e = arm.edit_bones.new(b['name'])
        e.head, e.tail = Vector(b['head']), Vector(b['tail'])
        e.align_roll(Vector(b.get('roll_to', (0, -1, 0))))
        e.use_deform = b.get('deform', True)
        if b.get('parent'):
            e.parent = eb[b['parent']]
            e.use_connect = False
        eb[b['name']] = e
    bpy.ops.object.mode_set(mode='OBJECT')
    obj.data.display_type = 'STICK'
    return obj


def bind(mesh, arm):
    mesh.parent = arm
    m = mesh.modifiers.new('Armature', 'ARMATURE')
    m.object = arm
    return m


# ------------------------------------------------------------------ animation
def Q(r):
    """Pose value -> Quaternion. Accepts Quaternion, (rx, ry, rz) degrees, None."""
    if r is None:
        return Quaternion()
    if isinstance(r, Quaternion):
        return r.copy()
    return Euler([math.radians(x) for x in r], 'XYZ').to_quaternion()


def mirror_name(n):
    if n.endswith('_L'):
        return n[:-2] + '_R'
    if n.endswith('_R'):
        return n[:-2] + '_L'
    return n


def mirror_q(q):
    return Quaternion((q.w, q.x, -q.y, -q.z))


def sym(pose, also=None):
    """Copy every *_L entry to *_R mirrored across the X=0 plane."""
    out = dict(pose)
    for k, v in pose.items():
        if k.endswith('_L'):
            out[mirror_name(k)] = mirror_q(Q(v))
    if also:
        out.update(also)
    return out


def pose_mul(*poses):
    """Compose poses: bone rotations multiply (later applied first), root adds."""
    out = {}
    for p in poses:
        for b, r in p.items():
            if b == '@root':
                o = out.get(b, Vector())
                out[b] = Vector(o) + Vector(r)
            else:
                out[b] = Q(out.get(b)) @ Q(r)
    return out


def pose_blend(a, b, u):
    out = {}
    for k in set(a) | set(b):
        if k == '@root':
            va, vb = Vector(a.get(k, (0, 0, 0))), Vector(b.get(k, (0, 0, 0)))
            out[k] = va.lerp(vb, u)
        else:
            qa, qb = Q(a.get(k)), Q(b.get(k))
            if qa.dot(qb) < 0:
                qb.negate()
            out[k] = qa.slerp(qb, u)
    return out


def ease(x, kind='smooth'):
    x = min(max(x, 0.0), 1.0)
    if kind == 'smooth':
        return x * x * (3 - 2 * x)
    if kind == 'in':
        return x * x
    if kind == 'out':
        return 1 - (1 - x) * (1 - x)
    if kind == 'snap':
        return 1 - (1 - x) ** 4
    return x


def track(keys, kind='smooth'):
    """keys: [(t, pose[, ease]), ...] with t in [0,1]. Returns fn(t) -> pose."""
    def fn(t):
        if t <= keys[0][0]:
            return dict(keys[0][1])
        for k0, k1 in zip(keys, keys[1:]):
            t0, p0 = k0[0], k0[1]
            t1, p1 = k1[0], k1[1]
            if t0 <= t <= t1:
                e = k1[2] if len(k1) > 2 else kind
                return pose_blend(p0, p1, ease((t - t0) / max(t1 - t0, 1e-6), e))
        return dict(keys[-1][1])
    return fn


class Animator:
    """Authoring helper.

    Pose values are rotations expressed about the *rest pose's* armature axes
    (X = creature's left, -Y = its front, Z = up), applied hierarchically:
    a child's rotation is carried along by its parents.  '@root' offsets
    HumanoidRootNode in studs (in place: no travel).
    """

    def __init__(self, arm):
        self.arm = arm
        self.bones = [b.name for b in arm.data.bones]
        self.rest = {b.name: b.matrix_local.to_quaternion() for b in arm.data.bones}
        self.dir = {b.name: (b.tail_local - b.head_local).normalized() for b in arm.data.bones}
        self.head = {b.name: b.head_local.copy() for b in arm.data.bones}
        self.parent = {b.name: (b.parent.name if b.parent else None) for b in arm.data.bones}
        self.root_bone = 'HumanoidRootNode'

    def chain(self, bone):
        out = []
        while bone:
            out.append(bone)
            bone = self.parent[bone]
        return out[::-1]

    def delta(self, pose, bone):
        q = Quaternion()
        for b in self.chain(bone):
            q = q @ Q(pose.get(b))
        return q

    def aim(self, pose, bone, direction, amount=1.0, twist=0.0):
        """Rotate `bone` so it points along `direction` (armature space)."""
        par = self.parent[bone]
        qp = self.delta(pose, par) if par else Quaternion()
        local = qp.inverted() @ Vector(direction).normalized()
        q = self.dir[bone].rotation_difference(local)
        if twist:
            q = q @ Quaternion(self.dir[bone], math.radians(twist))
        if amount < 1.0:
            q = Quaternion().slerp(q, amount)
        pose[bone] = q
        return pose

    def world_head(self, pose, bone):
        """Posed head position of a bone (armature space)."""
        ch = self.chain(bone)
        pos = self.head[ch[0]].copy()
        q = Quaternion()
        root = pose.get('@root')
        for i, b in enumerate(ch):
            if i > 0:
                prev = ch[i - 1]
                pos = pos + q @ (self.head[b] - self.head[prev])
            q = q @ Q(pose.get(b))
            if b == self.root_bone and root is not None:
                pos = pos + Vector(root)
        return pos

    def new_action(self, name, frames, loop=True):
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        act['loop'] = loop
        act['frames'] = frames
        ad = self.arm.animation_data or self.arm.animation_data_create()
        ad.action = act
        for pb in self.arm.pose.bones:
            pb.rotation_mode = 'QUATERNION'
        return act

    def apply_pose(self, pose):
        for pb in self.arm.pose.bones:
            rq = self.rest[pb.name]
            pb.rotation_quaternion = rq.inverted() @ Q(pose.get(pb.name)) @ rq
            pb.location = (0, 0, 0)
        off = pose.get('@root')
        if off is not None:
            pb = self.arm.pose.bones[self.root_bone]
            pb.location = self.rest[self.root_bone].inverted() @ Vector(off)

    def bake_fn(self, name, frames, fn, loop=True):
        """fn(t in [0,1]) -> pose. Keys every frame (frames+1 keys when looping
        so the last key equals the first)."""
        act = self.new_action(name, frames, loop)
        prev = {}
        for f in range(0, frames + 1):
            t = f / frames
            pose = fn(0.0 if (loop and f == frames) else t)
            self.apply_pose(pose)
            for pb in self.arm.pose.bones:
                q = pb.rotation_quaternion.copy()
                if pb.name in prev and prev[pb.name].dot(q) < 0:
                    q.negate()
                    pb.rotation_quaternion = q
                prev[pb.name] = q
                pb.keyframe_insert('rotation_quaternion', frame=f + 1)
            self.arm.pose.bones[self.root_bone].keyframe_insert('location', frame=f + 1)
        for fc in act_fcurves(act):
            for kp in fc.keyframe_points:
                kp.interpolation = 'LINEAR'
        log(f'  anim {name}: {frames} frames ({frames/30:.2f}s){" loop" if loop else ""}')
        return act


def act_fcurves(act):
    try:
        return list(act.fcurves)
    except AttributeError:  # Blender 5 layered actions
        out = []
        for layer in act.layers:
            for strip in layer.strips:
                for cb in strip.channelbags:
                    out += list(cb.fcurves)
        return out


# --------------------------------------------------------------------- export
# FBX axis conversion for Forward -Z, Up Y: Blender +Z (up) -> +Y, Blender +Y -> -Z.
AXIS_TO_FBX = Matrix(((1, 0, 0, 0), (0, 0, 1, 0), (0, -1, 0, 0), (0, 0, 0, 1)))  # exact -90 deg about X
_FBX_PATCHED = False


def _patch_fbx_exporter():
    """Keep skinned meshes as children of the armature node in the FBX.

    Blender's exporter deliberately writes meshes bound to an armature with no
    parent (scene root).  Roblox then builds a joint from the body mesh to
    itself.  Our armature and meshes are both identity in the file, so making
    the armature the FBX parent changes no transform.
    """
    global _FBX_PATCHED
    if _FBX_PATCHED:
        return
    import inspect
    from io_scene_fbx import export_fbx_bin as efb
    src = inspect.getsource(efb.fbx_data_from_scene)
    old = 'and (par_obj, ob_obj) not in arm_parents:'
    assert old in src, 'FBX exporter changed: update _patch_fbx_exporter'
    src = src.replace(old, 'and (KEEP_ARMATURE_CHILDREN or (par_obj, ob_obj) not in arm_parents):')
    efb.KEEP_ARMATURE_CHILDREN = True
    exec(compile(src, efb.__file__, 'exec'), efb.__dict__)
    _FBX_PATCHED = True


class RobloxSpace:
    """Context manager: bakes the FBX axis conversion into the mesh and bone data.

    Inside the block the rig's data is rotated by AXIS_TO_FBX and the armature
    object carries the inverse, so the scene looks unchanged in Blender but the
    exporter (Forward -Z, Up Y) writes the armature, the Root bone and the mesh
    nodes with identity transforms.  Pose-bone animation is bone-local, so the
    clips are unaffected.  Everything is restored on exit.
    """

    def __init__(self, arm, meshes):
        self.arm, self.meshes = arm, meshes

    def _apply(self, m):
        for me in self.meshes:
            me.data.transform(m)
            me.data.update()
        self.arm.data.transform(m)

    def __enter__(self):
        for o in [self.arm] + self.meshes:
            assert o.matrix_world.is_identity if hasattr(o.matrix_world, 'is_identity') else \
                o.matrix_world == Matrix.Identity(4), f'{o.name} must have identity transforms before export'
        self._apply(AXIS_TO_FBX)
        self.arm.matrix_world = AXIS_TO_FBX.inverted()
        bpy.context.view_layer.update()
        return self

    def __exit__(self, *exc):
        self.arm.matrix_world = Matrix.Identity(4)
        self._apply(AXIS_TO_FBX.inverted())
        bpy.context.view_layer.update()
        return False


def export_fbx(path, objs, action=None, anim=False):
    """Roblox export contract: Forward -Z, Up Y, Apply Unit, FBX Units Scale
    (1 Blender unit = 1 stud, no x100), no leaf bones, armature as a Null.
    Call inside `RobloxSpace` so the armature node is identity."""
    _patch_fbx_exporter()
    activate(objs[0])
    for o in objs:
        o.select_set(True)
    arm = next((o for o in objs if o.type == 'ARMATURE'), None)
    if arm is not None:
        if arm.animation_data is None:
            arm.animation_data_create()
        arm.animation_data.action = action
        if action is None:
            for pb in arm.pose.bones:
                pb.rotation_quaternion = Quaternion()
                pb.location = (0, 0, 0)
    s = bpy.context.scene
    s.unit_settings.system = 'METRIC'
    s.unit_settings.scale_length = 1.0
    if action is not None:
        s.frame_start, s.frame_end = 1, int(action['frames']) + (1 if action['loop'] else 0)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.fbx(
        filepath=path, use_selection=True, object_types={'ARMATURE', 'MESH'},
        apply_unit_scale=True, global_scale=1.0, apply_scale_options='FBX_SCALE_UNITS',
        axis_forward='-Z', axis_up='Y', bake_space_transform=False,
        use_mesh_modifiers=False, mesh_smooth_type='FACE',
        add_leaf_bones=False, primary_bone_axis='Y', secondary_bone_axis='X',
        armature_nodetype='NULL', use_armature_deform_only=False,
        bake_anim=anim, bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False,
        bake_anim_force_startend_keying=True, bake_anim_simplify_factor=0.0,
        path_mode='STRIP', embed_textures=False)
    s.unit_settings.system = 'NONE'
    log(f'  wrote {os.path.relpath(path, ROOT)}')


def export_roblox(asset_dir, asset, arm, meshes, clips):
    """Model + one FBX per clip, all in Roblox space."""
    with RobloxSpace(arm, meshes):
        export_fbx(os.path.join(asset_dir, f'{asset}.fbx'), [arm] + meshes, action=None)
        for cname, act in clips:
            export_fbx(os.path.join(asset_dir, 'Animations', f'{asset}_Anim_{cname}.fbx'), [arm], action=act,
                       anim=True)
    arm.animation_data.action = None


# --------------------------------------------------------------------- render
def bbox_world(objs):
    pts = []
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        if o.type != 'MESH':
            continue
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        a = np.zeros(len(me.vertices) * 3, np.float32)
        me.vertices.foreach_get('co', a)
        a = a.reshape(-1, 3)
        M = np.array(o.matrix_world)
        pts.append(a @ M[:3, :3].T + M[:3, 3])
        ev.to_mesh_clear()
    p = np.concatenate(pts)
    return p.min(0), p.max(0)


def make_camera(name='Cam'):
    cam = bpy.data.objects.get(name)
    if cam is None:
        cam = link(bpy.data.objects.new(name, bpy.data.cameras.new(name)))
    bpy.context.scene.camera = cam
    return cam


def look_at(obj, target):
    d = Vector(target) - obj.location
    obj.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()


def add_light(name, kind, loc, target, energy, size=1.0, color=(1, 1, 1), spot=None):
    ld = bpy.data.lights.new(name, kind)
    ld.energy = energy
    ld.color = color
    if kind == 'AREA':
        ld.size = size
    if kind == 'SPOT' and spot:
        ld.spot_size = math.radians(spot[0])
        ld.spot_blend = spot[1]
        ld.shadow_soft_size = 0.05
    o = link(bpy.data.objects.new(name, ld))
    o.location = loc
    look_at(o, target)
    return o


def clear_lights():
    for o in list(bpy.data.objects):
        if o.type in ('LIGHT',):
            bpy.data.objects.remove(o)


def set_world(color, strength=1.0):
    w = bpy.data.worlds.get('W') or bpy.data.worlds.new('W')
    bpy.context.scene.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes.get('Background')
    bg.inputs['Color'].default_value = (*color, 1)
    bg.inputs['Strength'].default_value = strength


def render(path, res=(768, 1024), samples=48, transparent=False):
    s = bpy.context.scene
    s.render.engine = 'CYCLES'
    s.cycles.samples = samples
    s.cycles.use_denoising = True
    s.render.resolution_x, s.render.resolution_y = res
    s.render.resolution_percentage = 100
    s.render.film_transparent = transparent
    s.render.image_settings.file_format = 'PNG'
    s.render.image_settings.color_mode = 'RGBA' if transparent else 'RGB'
    s.view_settings.view_transform = 'AgX'
    s.view_settings.look = 'None'
    s.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path
