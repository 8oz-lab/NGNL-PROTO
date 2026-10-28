# Wandelt "matrix"-Transformationen in einer GLB-Datei in translation/rotation/scale um.
# Godot übernimmt bei Knochen mit "matrix" keine Ruhepose, das Skelett fällt sonst in einen Punkt zusammen.
# Aufruf: python3 tools/fix_gltf_matrix.py eingabe.glb ausgabe.glb
import json, struct, sys, math
import numpy as np
src, dst = sys.argv[1], sys.argv[2]
d = open(src, 'rb').read()
l = struct.unpack('<I', d[12:16])[0]
j = json.loads(d[20:20 + l])
rest = d[20 + l:]
def quat(R):
    t = np.trace(R)
    if t > 0:
        s = math.sqrt(t + 1) * 2; w = s / 4; x = (R[2,1]-R[1,2])/s; y = (R[0,2]-R[2,0])/s; z = (R[1,0]-R[0,1])/s
    elif R[0,0] > R[1,1] and R[0,0] > R[2,2]:
        s = math.sqrt(1+R[0,0]-R[1,1]-R[2,2])*2; w=(R[2,1]-R[1,2])/s; x=s/4; y=(R[0,1]+R[1,0])/s; z=(R[0,2]+R[2,0])/s
    elif R[1,1] > R[2,2]:
        s = math.sqrt(1+R[1,1]-R[0,0]-R[2,2])*2; w=(R[0,2]-R[2,0])/s; x=(R[0,1]+R[1,0])/s; y=s/4; z=(R[1,2]+R[2,1])/s
    else:
        s = math.sqrt(1+R[2,2]-R[0,0]-R[1,1])*2; w=(R[1,0]-R[0,1])/s; x=(R[0,2]+R[2,0])/s; y=(R[1,2]+R[2,1])/s; z=s/4
    q = np.array([x, y, z, w]); return (q / np.linalg.norm(q)).tolist()
n = 0
for node in j['nodes']:
    if 'matrix' not in node: continue
    M = np.array(node.pop('matrix')).reshape(4, 4).T
    t = M[:3, 3]; B = M[:3, :3]
    sc = np.linalg.norm(B, axis=0)
    if np.linalg.det(B) < 0: sc[0] = -sc[0]
    node['translation'] = t.tolist(); node['rotation'] = quat(B / sc); node['scale'] = sc.tolist()
    n += 1
js = json.dumps(j, separators=(',', ':')).encode()
js += b' ' * ((4 - len(js) % 4) % 4)
out = struct.pack('<III', 0x46546C67, 2, 12 + 8 + len(js) + len(rest)) + struct.pack('<II', len(js), 0x4E4F534A) + js + rest
open(dst, 'wb').write(out)
print('converted', n, 'nodes')
