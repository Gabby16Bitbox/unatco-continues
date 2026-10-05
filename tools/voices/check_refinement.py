"""Verify installed-source PCM preservation and Battery Park BSP visibility offline.

The geometry check uses solid polygons from the actual Revision map. It cannot
replace an in-game check of animation, pawn AI, dynamic movers or camera framing.
"""
import io
import argparse
import json
import sys
import wave
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE.parent))
from ue1pkg import Pkg
from bspmap import read_model
from prepare_samples import sound_bytes


def pcm(data):
    with wave.open(io.BytesIO(data)) as reader:
        return (reader.getnchannels(), reader.getsampwidth(), reader.getframerate(),
                reader.readframes(reader.getnframes()))


def sounds(path):
    package = Pkg(str(path))
    return {e['name']: pcm(sound_bytes(package, e)) for e in package.exports
            if package.classname(e) == 'Sound'}


def audio_check(previous_path):
    plan = json.loads((HERE / 'delivery_natural_v4.json').read_text())
    changed = set(json.loads((HERE / 'natural_v4/refined_keys.json').read_text()))
    compiled = sounds(ROOT / 'dist/UnatcoVoices.u')
    previous = sounds(previous_path)
    for key in plan['lines']:
        source = pcm((ROOT / ('src/UnatcoVoices/Sounds/' + key + '.wav')).read_bytes())
        assert compiled[key] == source, 'Compiled audio differs from WAV: ' + key
        if key not in changed:
            assert compiled[key] == previous[key], 'Unrequested voice changed: ' + key
        else:
            assert compiled[key] != previous[key], 'Revised voice was not applied: ' + key
    return {'compiled_matches_source': len(plan['lines']),
            'unchanged_pcm_matches_previous_install': len(plan['lines']) - len(changed),
            'changed_lines': len(changed), 'previous_package': str(previous_path)}


class Geometry:
    def __init__(self, package):
        model = max((e['size'], i + 1) for i, e in enumerate(package.exports)
                    if package.classname(e) == 'Model')[1]
        points, nodes, flags, verts = read_model(package, model)
        triangles = []
        for plane, first, count, surface in nodes:
            if count < 3 or first + count > len(verts) or flags[surface] & 8:
                continue
            poly = [points[verts[first + i]] for i in range(count)]
            triangles.extend((poly[0], poly[i], poly[i + 1]) for i in range(1, count - 1))
        triangles = np.asarray(triangles, dtype=float)
        self.a = triangles[:, 0]
        self.e1 = triangles[:, 1] - self.a
        self.e2 = triangles[:, 2] - self.a

    def trace(self, start, end):
        direction = end - start
        cross = np.cross(direction, self.e2)
        determinant = np.sum(self.e1 * cross, axis=1)
        active = np.abs(determinant) > 1e-7
        inverse = np.zeros_like(determinant)
        inverse[active] = 1 / determinant[active]
        delta = start - self.a
        u = np.sum(delta * cross, axis=1) * inverse
        q = np.cross(delta, self.e1)
        v = np.sum(direction * q, axis=1) * inverse
        t = np.sum(self.e2 * q, axis=1) * inverse
        hit = active & (u >= -1e-7) & (v >= -1e-7) & (u + v <= 1 + 1e-7) & (t > 1e-5) & (t <= 1)
        indices = np.flatnonzero(hit)
        if not len(indices):
            return None
        index = indices[np.argmin(t[indices])]
        normal = np.cross(self.e1[index], self.e2[index])
        normal /= np.linalg.norm(normal)
        if np.dot(normal, direction) > 0:
            normal = -normal
        return start + direction * t[index], normal

    def clear(self, start, end):
        return self.trace(start, end) is None

    def lane(self, start, end):
        direction = end - start
        side = np.array([direction[1], -direction[0], 0.0])
        side /= np.linalg.norm(side)
        for height in (-25, 0, 25):
            for offset in (-22, 0, 22):
                shift = side * offset + np.array([0, 0, height])
                if not self.clear(start + shift, end + shift):
                    return False
        for fraction in np.linspace(0, 1, 12):
            point = start + direction * fraction
            hit = self.trace(point, point - np.array([0, 0, 120]))
            if hit is None or abs(point[2] - hit[0][2] - 42) > 32:
                return False
        return True


def geometry_check():
    map_path = Path(r'C:\Program Files (x86)\Steam\steamapps\common\Deus Ex\Revision\Maps\04_NYC_BatteryPark.dx')
    package = Pkg(str(map_path))
    geometry = Geometry(package)
    gunther = next(np.array(package.get(i, 'Location'), dtype=float)
                   for i, e in enumerate(package.exports, 1) if package.classname(e) == 'GuntherHermann')
    jc = gunther + np.array([-100.0, 0, 0])
    nodes = [(e['name'], np.array(package.get(i, 'Location'), dtype=float))
             for i, e in enumerate(package.exports, 1)
             if package.classname(e) in ('PathNode', 'PatrolPoint', 'PlayerStart', 'InventorySpot', 'AmbushPoint')
             and package.get(i, 'Location') is not None]
    viable = []
    for name, destination in nodes:
        delta = destination - gunther
        if not 350 <= np.linalg.norm(delta) <= 900 or abs(delta[2]) > 64:
            continue
        direction = delta.copy()
        direction[2] = 0
        direction /= np.linalg.norm(direction)
        side = np.cross(direction, [0, 0, 1])
        dest_jc, dest_g = destination + side * 42, destination - side * 42
        if not geometry.lane(jc, dest_jc) or not geometry.lane(gunther, dest_g):
            continue
        mid = (jc + gunther) * .5
        focus = mid + [0, 0, 20]
        candidates = [mid - direction * 240 + sign * side * 240 + [0, 0, 35] for sign in (1, -1)]
        candidates += [mid + sign * side * 320 + [0, 0, 35] for sign in (1, -1)]
        candidates += [mid + direction * 300 + sign * side * 180 + [0, 0, 35] for sign in (1, -1)]
        for camera in candidates:
            hit = geometry.trace(focus, camera)
            if hit is not None:
                camera = hit[0] + hit[1] * 16
            if np.linalg.norm(camera - focus) < 170:
                continue
            if geometry.clear(camera, jc + [0, 0, 22]) and geometry.clear(camera, gunther + [0, 0, 22]):
                viable.append({'node': name, 'destination': destination.tolist(), 'camera': camera.tolist(),
                               'camera_height_above_actors': float(camera[2] - mid[2])})
                break
    assert viable, 'No unobstructed walking corridor / low two-person camera near original Gunther'
    return {'map': str(map_path), 'gunther': gunther.tolist(), 'test_jc': jc.tolist(),
            'solid_triangles': len(geometry.a), 'viable_straight_lanes_and_visible_low_shots': viable,
            'limitation': 'Offline BSP only: approximate cylinder clearance; does not exercise native pawn AI, dynamic movers, input or rendering.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--previous-package', type=Path, default=Path(r'C:\Program Files (x86)\Steam\steamapps\common\Deus Ex\Revision\System\UnatcoVoices.u'))
    args = parser.parse_args()
    result = {'audio': audio_check(args.previous_package), 'geometry': geometry_check()}
    (HERE / 'natural_v4/refinement-checks.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(result['audio'])
    print('Battery Park:', len(result['geometry']['viable_straight_lanes_and_visible_low_shots']), 'clear corridors with visible low shots')
