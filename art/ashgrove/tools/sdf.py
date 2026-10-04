"""Signed-distance-field modelling for the Ashgrove House entities.

Creatures are described as lists of primitives (round cones, ellipsoids,
boxes) combined with smooth unions / subtractions.  Each primitive carries the
bone it belongs to and a material region tag, so the same description drives
the mesh, the skin weights and the texture masks.

Units are Roblox studs, Z up, creature faces -Y (Blender front view).
"""
import math
import numpy as np
from skimage import measure

F = np.float32


# ---------------------------------------------------------------- maths utils
def v3(*a):
    if len(a) == 1:
        a = a[0]
    return np.asarray(a, dtype=np.float64)


def rot_matrix(rx=0.0, ry=0.0, rz=0.0):
    """World-from-local rotation, XYZ euler in degrees (Blender order)."""
    rx, ry, rz = (math.radians(x) for x in (rx, ry, rz))
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return Rz @ Ry @ Rx


def frame_from_axis(axis, up_hint=(0, 0, 1)):
    """Orthonormal frame whose third column is `axis`."""
    z = v3(axis)
    z = z / np.linalg.norm(z)
    up = v3(up_hint)
    if abs(np.dot(up, z)) > 0.95:
        up = v3(0, -1, 0) if abs(z[1]) < 0.95 else v3(1, 0, 0)
    x = np.cross(up, z)
    x /= np.linalg.norm(x)
    y = np.cross(z, x)
    return np.stack([x, y, z], axis=1)


# ---------------------------------------------------------------------- noise
def _hash3(ix, iy, iz, seed):
    h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791) ^ (seed * 2654435761)
    h &= 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h ^= h >> 16
    return (h & 0xFFFF).astype(F) / F(65535.0)


def value_noise(P, scale=1.0, seed=0):
    """Smooth 3D value noise in [-1, 1]."""
    q = P.astype(np.float64) * scale
    i = np.floor(q).astype(np.int64)
    f = (q - i).astype(F)
    u = f * f * f * (f * (f * 6 - 15) + 10)
    out = np.zeros(len(P), F)
    for dx in (0, 1):
        wx = u[:, 0] if dx else 1 - u[:, 0]
        for dy in (0, 1):
            wy = u[:, 1] if dy else 1 - u[:, 1]
            for dz in (0, 1):
                wz = u[:, 2] if dz else 1 - u[:, 2]
                out += wx * wy * wz * _hash3(i[:, 0] + dx, i[:, 1] + dy, i[:, 2] + dz, seed)
    return out * 2 - 1


def fbm(P, scale=1.0, octaves=4, seed=0, gain=0.5):
    amp, tot, norm = 1.0, np.zeros(len(P), F), 0.0
    for o in range(octaves):
        tot += F(amp) * value_noise(P, scale * (2 ** o), seed + o * 17)
        norm += amp
        amp *= gain
    return tot / F(norm)


# ----------------------------------------------------------------- primitives
class Prim:
    """One SDF primitive.

    kind: 'cone' (round cone a->b, r1->r2), 'ellip' (centre, radii, rot),
          'box' (centre, half-size, rot, rounding), 'sphere'.
    op:   'add' (smooth union), 'sub' (smooth subtraction), 'int' (intersect)
    squash: optional per-local-axis scale for cones (x, y) to make
            elliptical cross sections, local frame z = along the cone.
    shell: if > 0 the primitive becomes a hollow shell of that thickness.
    """

    def __init__(self, kind, bone=None, k=0.05, op='add', region='skin', squash=None,
                 shell=0.0, disp=None, **p):
        self.kind, self.bone, self.k, self.op, self.region = kind, bone, k, op, region
        self.squash, self.shell, self.disp = squash, shell, disp
        self.p = {key: (v3(v) if isinstance(v, (tuple, list, np.ndarray)) else v) for key, v in p.items()}
        if kind == 'func':
            self.fn = p['fn']
            self.p = {'lo': v3(p['lo']), 'hi': v3(p['hi'])}
            self.R = np.eye(3)
            return
        if kind == 'cone':
            a, b = self.p['a'], self.p['b']
            ax = b - a
            if np.linalg.norm(ax) < 1e-6:
                ax = v3(0, 0, 1e-3)
                self.p['b'] = a + ax
            self.frame = frame_from_axis(ax, self.p.get('up', (0, 0, 1)) if 'up' in self.p else (0, 0, 1))
            if 'up' in self.p:
                del self.p['up']
        if 'rot' in self.p:
            r = self.p['rot']
            self.R = rot_matrix(*r) if np.shape(r) == (3,) else np.asarray(r)
        else:
            self.R = np.eye(3)

    # bounding box (min, max) of the primitive, generous
    def bounds(self):
        p = self.p
        pad = self.k + self.shell + (self.disp[0] if self.disp else 0) + 0.02
        if self.kind == 'func':
            return p['lo'] - pad, p['hi'] + pad
        if self.kind == 'cone':
            r = max(p['r1'], p['r2'])
            if self.squash is not None:
                r *= max(1.0, max(self.squash))
            lo = np.minimum(p['a'], p['b']) - r
            hi = np.maximum(p['a'], p['b']) + r
        elif self.kind in ('ellip', 'box'):
            ext = p['r'] if self.kind == 'ellip' else p['h'] + p.get('round', 0)
            e = np.abs(self.R) @ ext
            lo, hi = p['c'] - e, p['c'] + e
        else:
            lo, hi = p['c'] - p['r'], p['c'] + p['r']
        return lo - pad, hi + pad

    def eval(self, P):
        p = self.p
        if self.kind == 'func':
            d = self.fn(P).astype(np.float64)
        elif self.kind == 'cone':
            a, b = p['a'], p['b']
            if self.squash is not None:
                q = (P - a) @ self.frame
                sx, sy = self.squash
                q[:, 0] /= sx
                q[:, 1] /= sy
                d = sd_round_cone_local(q, np.linalg.norm(b - a), p['r1'], p['r2'])
                d = d * min(sx, sy)
            else:
                d = sd_round_cone(P, a, b, p['r1'], p['r2'])
        elif self.kind == 'ellip':
            q = (P - p['c']) @ self.R
            r = p['r']
            k0 = np.linalg.norm(q / r, axis=1)
            k1 = np.linalg.norm(q / (r * r), axis=1)
            d = k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)
        elif self.kind == 'box':
            q = np.abs((P - p['c']) @ self.R) - p['h']
            rnd = p.get('round', 0.0)
            d = np.linalg.norm(np.maximum(q, 0), axis=1) + np.minimum(np.max(q, axis=1), 0) - rnd
        else:
            d = np.linalg.norm(P - p['c'], axis=1) - p['r']
        if self.shell > 0:
            d = np.abs(d) - self.shell
        if self.disp is not None:
            amp, scale, seed = self.disp
            d = d + amp * fbm(P, scale, 3, seed)
        return d.astype(F)


def sd_round_cone(P, a, b, r1, r2):
    ba = b - a
    l2 = float(ba @ ba)
    rr = r1 - r2
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    pa = P - a
    y = pa @ ba
    z = y - l2
    x = pa * l2 - np.outer(y, ba)
    x2 = np.einsum('ij,ij->i', x, x)
    y2 = y * y * l2
    z2 = z * z * l2
    k = np.sign(rr) * rr * rr * x2
    d3 = (np.sqrt(np.maximum(x2 * a2 * il2, 0)) + y * rr) * il2 - r1
    d2 = np.sqrt(x2 + y2) * il2 - r1
    d1 = np.sqrt(x2 + z2) * il2 - r2
    return np.where(np.sign(z) * a2 * z2 > k, d1, np.where(np.sign(y) * a2 * y2 < k, d2, d3))


def sd_round_cone_local(q, L, r1, r2):
    """Round cone from origin along +z of length L (q already in local frame)."""
    return sd_round_cone(q, np.zeros(3), np.array([0, 0, L]), r1, r2)


def smin(a, b, k):
    if k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return b * (1 - h) + a * h - k * h * (1 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


# --------------------------------------------------------------------- scenes
class Scene:
    """Ordered primitive list -> one watertight surface."""

    def __init__(self, prims, disp=None):
        self.prims = list(prims)
        self.disp = disp  # optional callable(P, d) -> d

    def bounds(self):
        los, his = zip(*(p.bounds() for p in self.prims if p.op == 'add'))
        return np.min(los, axis=0), np.max(his, axis=0)

    def eval(self, P, prims=None):
        prims = self.prims if prims is None else prims
        d = np.full(len(P), 1e3, F)
        for pr in prims:
            di = pr.eval(P)
            if pr.op == 'add':
                d = smin(d, di, pr.k)
            elif pr.op == 'sub':
                d = smax(d, -di, pr.k)
            elif pr.op == 'int':
                d = smax(d, di, pr.k)
        if self.disp is not None:
            d = self.disp(P, d)
        return d

    def mesh(self, voxel, pad=0.08, block=40, verbose=True):
        lo, hi = self.bounds()
        lo, hi = lo - pad, hi + pad
        n = np.ceil((hi - lo) / voxel).astype(int) + 1
        if verbose:
            print(f'  sdf grid {n.tolist()} = {np.prod(n)/1e6:.1f}M samples, {len(self.prims)} prims')
        vol = np.full(n, 1e3, F)
        pb = [p.bounds() for p in self.prims]
        xs = [lo[i] + np.arange(n[i]) * voxel for i in range(3)]
        for i0 in range(0, n[0], block):
            for j0 in range(0, n[1], block):
                for k0 in range(0, n[2], block):
                    i1, j1, k1 = min(i0 + block, n[0]), min(j0 + block, n[1]), min(k0 + block, n[2])
                    blo = v3(xs[0][i0], xs[1][j0], xs[2][k0])
                    bhi = v3(xs[0][i1 - 1], xs[1][j1 - 1], xs[2][k1 - 1])
                    sel = [pr for pr, (a, b) in zip(self.prims, pb)
                           if np.all(a <= bhi) and np.all(b >= blo)]
                    if not any(pr.op == 'add' for pr in sel):
                        continue
                    g = np.stack(np.meshgrid(xs[0][i0:i1], xs[1][j0:j1], xs[2][k0:k1], indexing='ij'), -1)
                    P = g.reshape(-1, 3)
                    vol[i0:i1, j0:j1, k0:k1] = self.eval(P, sel).reshape(g.shape[:3])
        if vol.min() >= 0:
            raise RuntimeError('SDF scene has no interior')
        verts, faces, _, _ = measure.marching_cubes(vol, 0.0, spacing=(voxel,) * 3,
                                                     gradient_direction='ascent')
        verts = verts + lo
        faces = faces[:, ::-1]  # skimage winds inward for an SDF; flip to outward normals
        if verbose:
            print(f'  marching cubes -> {len(verts)} verts, {len(faces)} tris')
        return verts.astype(np.float64), faces.astype(np.int64)

    # ---- per-vertex information from the primitives
    def prim_distances(self, P):
        return np.stack([pr.eval(P) for pr in self.prims], axis=1)

    def bone_weights(self, P, falloff=0.08, max_inf=4):
        """Soft skin weights {bone: array} from distances to bone-tagged prims."""
        D = self.prim_distances(P)
        bones = sorted({pr.bone for pr in self.prims if pr.bone and pr.op == 'add'})
        W = np.zeros((len(P), len(bones)), np.float64)
        for j, pr in enumerate(self.prims):
            if pr.op != 'add' or not pr.bone:
                continue
            d = np.maximum(D[:, j], 0)
            # nearest primitive dominates, neighbours within the falloff blend in
            W[:, bones.index(pr.bone)] = np.maximum(W[:, bones.index(pr.bone)], np.exp(-d / falloff))
        return bones, W

    def region_weights(self, P, falloff=0.03):
        D = self.prim_distances(P)
        regions = sorted({pr.region for pr in self.prims if pr.op == 'add'})
        R = np.zeros((len(P), len(regions)), np.float64)
        for j, pr in enumerate(self.prims):
            if pr.op != 'add':
                continue
            d = np.maximum(D[:, j], 0)
            R[:, regions.index(pr.region)] = np.maximum(R[:, regions.index(pr.region)], np.exp(-d / falloff))
        R /= R.sum(1, keepdims=True) + 1e-12
        return regions, R


def limit_weights(W, max_inf=4, min_w=0.01):
    W = W.copy()
    if W.shape[1] > max_inf:
        idx = np.argsort(-W, axis=1)[:, max_inf:]
        np.put_along_axis(W, idx, 0, axis=1)
    W[W < min_w * W.max(1, keepdims=True)] = 0
    W /= W.sum(1, keepdims=True) + 1e-12
    return W


# ------------------------------------------------------------ shape helpers
def chain(points, radii, bones, k=0.05, region='skin', squash=None, op='add'):
    """Round cones along a polyline; bones[i] owns segment i."""
    out = []
    for i in range(len(points) - 1):
        b = bones[i] if isinstance(bones, (list, tuple)) else bones
        sq = squash[i] if isinstance(squash, list) else squash
        rg = region[i] if isinstance(region, list) else region
        out.append(Prim('cone', b, k=k, region=rg, squash=sq, op=op,
                        a=points[i], b=points[i + 1], r1=radii[i], r2=radii[i + 1]))
    return out


def bezier(p0, p1, p2, p3, n):
    p0, p1, p2, p3 = map(v3, (p0, p1, p2, p3))
    out = []
    for i in range(n + 1):
        t = i / n
        out.append((1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t * t * p2 + t ** 3 * p3)
    return out


def lerp(a, b, t):
    return a + (b - a) * t


def mirror(prims_fn):
    """Call prims_fn(side) for side in (+1 'L' -> +X, -1 'R' -> -X)."""
    out = []
    for s, tag in ((1, 'L'), (-1, 'R')):
        out += prims_fn(s, tag)
    return out


def drape(P, z_top, z_bot, r_top, r_bot, centre=(0.0, 0.0), folds=7, amp_top=0.0, amp_bot=0.08,
          thick=0.03, open_front=0.0, open_back=0.0, seed=0, hem_noise=0.08, top_noise=0.0,
          sag=0.0, shell=True, flare=None):
    """Hanging cloth around the Z axis: an elliptical tube whose radius goes from
    r_top=(rx, ry) at z_top to r_bot at z_bot, with vertical folds that grow
    toward the hem, an optional opening at the front (-Y) / back (+Y) given as a
    half-angle in degrees, and a ragged hem.  Returns a distance field."""
    x = P[:, 0] - centre[0]
    y = P[:, 1] - centre[1]
    z = P[:, 2]
    u = np.clip((z_top - z) / (z_top - z_bot), 0, 1)
    us = u * u * (3 - 2 * u) if flare is None else u ** flare
    rx = r_top[0] + (r_bot[0] - r_top[0]) * us
    ry = r_top[1] + (r_bot[1] - r_top[1]) * us
    th = np.arctan2(x, -y)  # 0 = front, +pi/2 = creature's left
    e = np.sqrt((x / rx) ** 2 + (y / ry) ** 2)
    amp = amp_top + (amp_bot - amp_top) * u
    wob = value_noise(np.stack([th * 2.0, z * 0.6, np.zeros_like(z)], 1), 1.0, seed) * 0.6
    target = 1.0 + amp * np.sin(folds * th + wob * 2.0 + seed)
    rm = 0.5 * (rx + ry)
    d = (e - target) * rm
    if shell:
        d = np.abs(d) - thick
    hem = z_bot + hem_noise * value_noise(np.stack([th * 3.0, z * 0, x * 0], 1), 1.0, seed + 5)
    top = z_top + top_noise * value_noise(np.stack([th * 3.0, z * 0, x * 0], 1), 1.0, seed + 9)
    d = np.maximum(d, np.maximum(hem - z, z - top))
    rho = np.sqrt(x * x + y * y)
    if open_front > 0:
        w = np.radians(open_front) * (0.35 + 0.65 * us)
        d = np.maximum(d, (w - np.abs(th)) * rho)
    if open_back > 0:
        w = np.radians(open_back) * us ** 2
        d = np.maximum(d, (w - (np.pi - np.abs(th))) * rho)
    return d


def sweep(P, pts, radii, squash=None):
    """Smooth tube along a polyline with linearly varying radius (no joint bulges).
    squash: optional per-point (sx, sy) scale of the cross-section in a frame
    whose x axis is world X (good for tails that bend in the YZ plane)."""
    pts = np.asarray(pts, np.float64)
    radii = np.asarray(radii, np.float64)
    best = np.full(len(P), 1e9)
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        ab = b - a
        L2 = float(ab @ ab)
        t = np.clip(((P - a) @ ab) / L2, 0, 1)
        q = P - (a + np.outer(t, ab))
        r = radii[i] + (radii[i + 1] - radii[i]) * t
        if squash is not None:
            sq = np.asarray(squash[i]) + (np.asarray(squash[i + 1]) - np.asarray(squash[i])) * t[:, None]
            # cross-section frame: x = world X, y = perpendicular in the YZ plane
            d = ab / np.sqrt(L2)
            yax = np.cross(d, np.array([1.0, 0, 0]))
            yax /= np.linalg.norm(yax) + 1e-9
            qx = q[:, 0] / sq[:, 0]
            qy = (q @ yax) / sq[:, 1]
            qz = q @ d
            dist = (np.sqrt(qx * qx + qy * qy + qz * qz) - r) * np.minimum(sq[:, 0], sq[:, 1])
        else:
            dist = np.linalg.norm(q, axis=1) - r
        best = np.minimum(best, dist)
    return best
