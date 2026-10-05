"""Animated previews of clips (GIF) plus a flashlight still, from a close front-3/4 camera.

    python3 preview_gif.py Dybbuk Walk Chase Idle:2 [--still Idle:0.05]

`Clip:N` renders every Nth frame.  Output: Entities/<Name>/Review/Preview/.
"""
import os
import sys

import bpy
from mathutils import Vector
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blendkit as bk  # noqa: E402
import review  # noqa: E402


VIEW = 'side' if '--side' in sys.argv else 'front'


def setup_camera(target=Vector((0, 0, 4.4))):
    cam = bk.make_camera('PreviewCam')
    cam.data.type = 'PERSP'
    cam.data.lens = 30
    off = Vector((-16.0, -5.5, -0.8)) if VIEW == 'side' else Vector((-4.6, -16.0, -0.8))
    cam.location = target + off
    bk.look_at(cam, target)
    return cam


def main():
    name = sys.argv[1]
    asset = f'AH_Ent_{name}'
    od = os.path.join(bk.ROOT, 'Entities', name)
    out = os.path.join(od, 'Review', 'Preview')
    os.makedirs(out, exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=os.path.join(od, 'Source', f'{asset}.blend'))
    arm = bpy.data.objects[f'{asset}_Rig']
    args = [a for a in sys.argv[2:] if a != '--side']
    still = None
    if '--still' in args:
        i = args.index('--still')
        still = args[i + 1]
        args = args[:i] + args[i + 2:]
    review._floor()
    for o in bpy.data.objects:
        if o.name.startswith('REV_'):
            o.hide_render = o.name != 'REV_Floor'
    setup_camera()
    review._studio(Vector((0, 0, 4.5)), 9.0)
    bk.set_world((0.30, 0.30, 0.32), 0.55)
    for spec in args:
        clip, step = (spec.split(':') + ['1'])[:2]
        act = bpy.data.actions[f'{asset}_Anim_{clip}']
        n = int(act['frames'])
        frames = []
        for f in range(1, n + 1, int(step)):
            review._set_pose(arm, act, f)
            p = os.path.join(out, f'_f{f}.png')
            bk.render(p, res=(400, 500), samples=10)
            frames.append(Image.open(p).convert('P', palette=Image.ADAPTIVE, colors=128))
            os.remove(p)
        gif = os.path.join(out, f'{asset}_{clip}{"_Side" if VIEW == "side" else ""}.gif')
        frames[0].save(gif, save_all=True, append_images=frames[1:], duration=int(1000 / 30 * int(step)), loop=0,
                       optimize=True)
        bk.log('  gif', gif, len(frames), 'frames')
    if still:
        clip, t = still.split(':')
        act = bpy.data.actions[f'{asset}_Anim_{clip}']
        review._set_pose(arm, act, 1 + int(float(t) * int(act['frames'])))
        bpy.data.objects['REV_Wall'].hide_render = False
        bk.clear_lights()
        bk.set_world((0.01, 0.012, 0.018), 0.12)
        cam = setup_camera(Vector((0, 0, 4.3)))
        bk.add_light('Flash', 'SPOT', cam.location + Vector((0.5, 0.3, -0.4)), Vector((0, 0.5, 4.2)), 3400,
                     spot=(40, 0.35), color=(1.0, 0.93, 0.8))
        bk.render(os.path.join(out, f'{asset}_{clip}_Flashlight.png'), res=(900, 1000), samples=64)
        bk.log('  still', clip)


if __name__ == '__main__':
    main()
