"""Re-exports finished entities from their Source .blend under the current
Roblox export contract (see blendkit.export_fbx) without rebuilding anything.

    python3 reexport.py Dybbuk Dullahan ...   (no names = all five)
"""
import json
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blendkit as bk  # noqa: E402

NAMES = [a for a in sys.argv[1:] if not a.startswith('-')] or ['Dybbuk', 'Dullahan', 'Demon', 'Siren', 'Nightmare']


def act_paths(act):
    return [fc.data_path for fc in bk.act_fcurves(act)]


def main():
    for name in NAMES:
        asset = f'AH_Ent_{name}'
        od = os.path.join(bk.ROOT, 'Entities', name)
        blend = os.path.join(od, 'Source', f'{asset}.blend')
        bpy.ops.wm.open_mainfile(filepath=blend)
        arm = bpy.data.objects[f'{asset}_Rig']
        meshes = [o for o in bpy.data.objects if o.type == 'MESH' and o.parent == arm]
        stats = json.load(open(os.path.join(od, 'Source', 'stats.json')))
        # rename the hips root so it can't collide with Roblox's HumanoidRootPart part
        bone = arm.data.bones.get('HumanoidRootPart')
        if bone is not None:
            bone.name = 'HumanoidRootNode'
        clips = []
        for cname in stats['clips']:
            act = bpy.data.actions[f'{asset}_Anim_{cname}']
            stale = [p for p in act_paths(act) if 'HumanoidRootPart' in p]
            for fc in bk.act_fcurves(act):
                if 'HumanoidRootPart' in fc.data_path:
                    fc.data_path = fc.data_path.replace('HumanoidRootPart', 'HumanoidRootNode')
            assert not [p for p in act_paths(act) if 'HumanoidRootPart' in p], cname
            if stale:
                bk.log(f'  {cname}: fixed {len(stale)} curve paths')
            clips.append((cname, act))
        bk.log(f'{asset}: {len(meshes)} meshes, {len(clips)} clips')
        bk.export_roblox(od, asset, arm, meshes, clips)
        bpy.ops.wm.save_as_mainfile(filepath=blend, compress=True)


if __name__ == '__main__':
    main()
