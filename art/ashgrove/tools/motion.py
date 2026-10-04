"""Procedural motion helpers: two-bone IK, foot cycles, noise for life."""
import math

from mathutils import Quaternion, Vector

import blendkit as bk


def rest_tail(an, bone):
    b = an.arm.data.bones[bone]
    return b.tail_local.copy()


def world_tail(an, pose, bone):
    head = an.world_head(pose, bone)
    q = an.delta(pose, bone)
    b = an.arm.data.bones[bone]
    return head + q @ (b.tail_local - b.head_local)


def aim_vec(an, pose, bone, rest_vec, direction):
    """Rotate `bone` so that rest-space vector `rest_vec` points along direction."""
    par = an.parent[bone]
    qp = an.delta(pose, par) if par else Quaternion()
    local = qp.inverted() @ Vector(direction).normalized()
    pose[bone] = Vector(rest_vec).normalized().rotation_difference(local)
    return pose


def ik2(an, pose, upper, lower, target, pole, end=None, twist=0.0):
    """Analytic two-bone IK. `end` (optional) is a child bone of `lower` whose
    tail is the effector; it keeps its rest relation to `lower`."""
    hip = an.world_head(pose, upper)
    knee_rest = an.head[lower]
    eff_rest = rest_tail(an, end or lower)
    L1 = (knee_rest - an.head[upper]).length
    L2 = (eff_rest - knee_rest).length
    d = Vector(target) - hip
    dist = min(max(d.length, abs(L1 - L2) + 1e-4), (L1 + L2) * 0.9995)
    dn = d.normalized()
    p = Vector(pole) - dn * Vector(pole).dot(dn)
    if p.length < 1e-6:
        p = Vector((0, -1, 0)) - dn * dn.y * -1
    p.normalize()
    cos_a = (L1 * L1 + dist * dist - L2 * L2) / (2 * L1 * dist)
    a = math.acos(max(-1, min(1, cos_a)))
    knee = hip + L1 * (math.cos(a) * dn + math.sin(a) * p)
    aim_vec(an, pose, upper, knee_rest - an.head[upper], knee - hip)
    if twist:
        pose[upper] = Quaternion(dn, math.radians(twist)) @ pose[upper]
    eff = hip + dn * dist
    aim_vec(an, pose, lower, eff_rest - knee_rest, eff - an.world_head(pose, lower))
    if end:
        pose.setdefault(end, Quaternion())
    return pose


def foot_cycle(u, stride, lift, stance=0.6, front=-1.0):
    """Foot offset (dy, dz) for an in-place cycle; u in [0,1).
    Stance: foot slides from front to back on the ground. Swing: lifts and
    returns.  front=-1 means the creature faces -Y."""
    u %= 1.0
    if u < stance:
        s = u / stance
        y = front * stride * (0.5 - s)
        return y, 0.0, 0.0
    s = (u - stance) / (1 - stance)
    e = s * s * (3 - 2 * s)
    y = front * stride * (-0.5 + e)
    z = lift * math.sin(math.pi * s) ** 0.8
    return y, z, s


def wobble(t, freq, seed=0.0, amp=1.0):
    """Cheap smooth pseudo-noise (sum of incommensurate sines), loops if freq ints."""
    return amp * (math.sin(2 * math.pi * (freq * t) + seed * 1.7) * 0.6 +
                  math.sin(2 * math.pi * (freq * 2 * t) + seed * 3.1) * 0.3 +
                  math.sin(2 * math.pi * (freq * 3 * t) + seed * 5.3) * 0.1)


def twitch(t, at, dur=0.06, amp=1.0):
    """Sharp spike centred at time `at` (fraction of clip)."""
    x = (t - at) / dur
    if abs(x) > 1:
        return 0.0
    return amp * (1 - abs(x)) ** 2


def s(t):
    return math.sin(2 * math.pi * t)


def c(t):
    return math.cos(2 * math.pi * t)
