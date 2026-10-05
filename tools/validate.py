"""Rebuild print files and check meshes, rail fit and positive retention.

Run: python3 validate.py [--openscad /path/to/OpenSCAD]
Only the Python standard library is required. No physical force/life claims.
"""
import argparse
from collections import defaultdict, deque
import json
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent if SCRIPT_DIR.name == 'tools' else SCRIPT_DIR
EXPORTS = ROOT / 'exports' if (ROOT / 'exports').exists() else ROOT
CHECKS = 'tools/checks.scad' if (ROOT / 'tools/checks.scad').exists() else 'checks.scad'
parser = argparse.ArgumentParser()
parser.add_argument('--openscad', default=shutil.which('openscad') or
                    '/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD')
args = parser.parse_args()
temporary = tempfile.TemporaryDirectory(prefix='openreed-box-checks-')
OUT = Path(temporary.name)


def compile_model(source, target, definitions):
    command = [args.openscad, '--hardwarnings', '--backend', 'Manifold',
               '--export-format', 'binstl', '-o', str(target)]
    for key, value in definitions.items():
        command += ['-D', f'{key}={json.dumps(value)}']
    command.append(str(ROOT / source))
    result = subprocess.run(command, text=True, capture_output=True)
    if result.returncode:
        if 'Current top level object is empty' in result.stderr and 'ERROR:' not in result.stderr:
            return False
        raise RuntimeError(f'{target.name}: {result.stderr or result.stdout}')
    return target.exists() and target.stat().st_size > 84


def inspect_stl(path):
    raw = path.read_bytes()
    count = struct.unpack_from('<I', raw, 80)[0]
    assert len(raw) == 84 + 50*count, f'Invalid binary STL: {path.name}'
    edges = defaultdict(list)
    vertices = set()
    volume = 0
    triangles = []
    for i in range(count):
        values = struct.unpack_from('<12fH', raw, 84+50*i)
        triangle = [tuple(values[3+j*3:6+j*3]) for j in range(3)]
        a,b,c = triangle
        assert len(set(triangle)) == 3, f'Degenerate triangle: {path.name}'
        vertices.update(triangle)
        triangles.append(triangle)
        volume += (a[0]*(b[1]*c[2]-b[2]*c[1]) +
                   a[1]*(b[2]*c[0]-b[0]*c[2]) +
                   a[2]*(b[0]*c[1]-b[1]*c[0]))/6
        for v,w in [(a,b),(b,c),(c,a)]:
            edges[tuple(sorted([v,w]))].append((i, 1 if v < w else -1))
    assert all(len(faces)==2 for faces in edges.values()), f'Open/nonmanifold edges: {path.name}'
    assert all(sum(direction for _,direction in faces)==0 for faces in edges.values()), f'Inconsistent winding: {path.name}'
    neighbours = defaultdict(set)
    for faces in edges.values():
        f,g = faces[0][0], faces[1][0]
        neighbours[f].add(g)
        neighbours[g].add(f)
    visited = set()
    components = 0
    for start in range(count):
        if start in visited:
            continue
        components += 1
        queue = deque([start])
        visited.add(start)
        while queue:
            for neighbour in neighbours[queue.popleft()]:
                if neighbour not in visited:
                    visited.add(neighbour)
                    queue.append(neighbour)
    assert components == 1 and volume > 0, f'Disconnected/inside-out print part: {path.name}'
    low = [min(v[i] for v in vertices) for i in range(3)]
    high = [max(v[i] for v in vertices) for i in range(3)]
    return {'triangles':count, 'connected_solids':components,
            'watertight':True, 'consistent_winding':True,
            'volume_mm3':round(volume,3),
            'size_mm':[round(b-a,3) for a,b in zip(low,high)],
            'min_z_mm':round(low[2],6)}


report = {'mesh_checks':{}, 'collision_checks':[], 'parameter_checks':[]}
for part in ['body','lid','fit_test_body','fit_test_lid']:
    target = EXPORTS / f'{part}.stl'
    assert compile_model('box.scad',target,{'part':part})
    report['mesh_checks'][part] = inspect_stl(target)
    assert report['mesh_checks'][part]['min_z_mm'] == 0, 'Part must sit on bed'

cases = [('closed',0,False),('coupon',0,False),('locked_x',0,True),
         ('locked_z',0,True),('rear_stop',0,True),('coupon_stop',0,True),
         ('coupon_lock',0,True)]
cases += [('released',offset,False) for offset in [0,0.3,0.6,1,2,3,4,5,7,9,40,100,135]]
for check,offset,expected_solid in cases:
    target = OUT / f'{check}-{offset}.stl'
    target.unlink(missing_ok=True)
    solid = compile_model(CHECKS,target,
                          {'render_model':False,'check':check,'offset':offset})
    assert solid == expected_solid, f'Unexpected collision result: {check}, offset={offset}'
    report['collision_checks'].append({'check':check,'offset_mm':offset,
                                      'expected_intersection':expected_solid,'passed':True})

for name,parameters in [
    ('small',{'inner_length':80,'inner_width':30,'inner_height':20,
              'inner_corner_radius':6,'outer_corner_radius':4}),
    ('large',{'inner_length':170,'inner_width':70,'inner_height':60}),
    ('looser_fit',{'slide_clearance':0.4,'vertical_clearance':0.35})
]:
    for part in ['body','lid']:
        target = OUT / f'{name}-{part}.stl'
        assert compile_model('box.scad',target,dict(parameters,part=part))
        inspect_stl(target)
    target = OUT / f'{name}-closed.stl'
    target.unlink(missing_ok=True)
    assert not compile_model(CHECKS,target,
                             dict(parameters,render_model=False,check='closed'))
    report['parameter_checks'].append({'preset':name,'parameters':parameters,'passed':True})

report['scope'] = ('CAD geometry only. Released motion uses a rigid inward arm envelope; '
                   'not a deformation or load simulation. No physical prototype has been tested.')
(EXPORTS / 'validation-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
temporary.cleanup()
print(f'PASS: 4 watertight, single-solid print parts; {len(cases)} collision/retention checks; '
      f'{len(report["parameter_checks"])} alternate parameter presets.')
