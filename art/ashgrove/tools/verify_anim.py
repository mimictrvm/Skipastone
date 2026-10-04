"""Round-trip check: the exported clip FBX, re-imported, must pose every bone
where the source .blend does (world space, every 6th frame).

    python3 verify_anim.py Dybbuk [Walk ...]
"""
import os
import sys

import bpy
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blendkit as bk  # noqa: E402

name = sys.argv[1]
asset = f'AH_Ent_{name}'
od = os.path.join(bk.ROOT, 'Entities', name)
clips = sys.argv[2:] or sorted(f[len(asset) + 6:-4] for f in os.listdir(os.path.join(od, 'Animations')))


def bone_world(arm):
    return {pb.name: (arm.matrix_world @ pb.head, arm.matrix_world @ pb.tail) for pb in arm.pose.bones}


worst = 0.0
for clip in clips:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(od, 'Source', f'{asset}.blend'))
    arm = bpy.data.objects[f'{asset}_Rig']
    act = bpy.data.actions[f'{asset}_Anim_{clip}']
    arm.animation_data.action = act
    frames = list(range(1, int(act['frames']) + 1, 6))
    ref = {}
    for f in frames:
        bpy.context.scene.frame_set(f)
        ref[f] = bone_world(arm)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(od, 'Animations', f'{asset}_Anim_{clip}.fbx'))
    imp = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    start = int(imp.animation_data.action.frame_range[0])
    errs = []
    for f in frames:
        bpy.context.scene.frame_set(start + f - 1)
        got = bone_world(imp)
        for b, (h, t) in ref[f].items():
            gh, gt = got[b]
            errs.append((gh - h).length)  # FBX stores joints, not tails
    e = max(errs)
    worst = max(worst, e)
    print(f'{asset} {clip:14s} max bone error {e:.5f} studs over {len(frames)} frames x {len(ref[frames[0]])} bones')
print(f'WORST {worst:.5f}')
