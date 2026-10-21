#!/usr/bin/env python3
"""Measure paired body outlines/ground anchors; preserves the original PNG bytes."""
import hashlib
import json
import math
import argparse
from collections import deque
from pathlib import Path
from measure_expansion_atlases import rgba

def outline(pixels, w):
    mask, edges = set(pixels), {}
    def edge(a, b):
        edges.setdefault(a, []).append(b)
    for p in pixels:
        x, y = p % w, p // w
        if p - w not in mask: edge((x,y), (x+1,y))
        if p + 1 not in mask: edge((x+1,y), (x+1,y+1))
        if p + w not in mask: edge((x+1,y+1), (x,y+1))
        if p - 1 not in mask: edge((x,y+1), (x,y))
    directions = {(1,0):0, (0,1):1, (-1,0):2, (0,-1):3}
    rank = {1:0, 0:1, 3:2, 2:3}
    loops = []
    while edges:
        start = next(iter(edges))
        current, incoming, loop = start, 0, [start]
        while current in edges:
            candidates = edges[current]
            nxt = min(candidates, key=lambda q: rank[(directions[(q[0]-current[0],q[1]-current[1])]-incoming)%4])
            candidates.remove(nxt)
            if not candidates: del edges[current]
            incoming = directions[(nxt[0]-current[0],nxt[1]-current[1])]
            current = nxt
            loop.append(current)
            if current == start: break
        if len(loop) > 10: loops.append(loop)
    def area(ps):
        return abs(sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(ps,ps[1:])))
    points = max(loops, key=area)
    def rdp(ps):
        if len(ps) < 3: return ps
        ax,ay=ps[0]; bx,by=ps[-1]; dx,dy=bx-ax,by-ay
        den=math.hypot(dx,dy)
        ds=[math.hypot(x-ax,y-ay) if den==0 else abs(dx*(ay-y)-(ax-x)*dy)/den for x,y in ps]
        at=max(range(len(ds)),key=ds.__getitem__)
        return rdp(ps[:at+1])[:-1]+rdp(ps[at:]) if ds[at]>1.0 else [ps[0],ps[-1]]
    mid=len(points)//2
    return rdp(points[:mid+1])[:-1]+rdp(points[mid:])[:-1]


ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('image', nargs='?', default='game/assets/grapples/mavrin-polina-hold.png')
parser.add_argument('--columns', type=int, default=4)
parser.add_argument('--rows', type=int, default=3)
parser.add_argument('--solo', action='store_true')
args = parser.parse_args()
image = ROOT / args.image
w, h, alpha = rgba(image)
mask = bytearray(a > 128 for a in alpha)
groups = [[] for _ in range(args.columns * args.rows)]
for start in range(w * h):
    if not mask[start]:
        continue
    queue, pixels = deque([start]), []
    mask[start] = 0
    while queue:
        p = queue.popleft()
        pixels.append(p)
        x, y = p % w, p // w
        for q in (p - w if y else -1, p + w if y + 1 < h else -1, p - 1 if x else -1, p + 1 if x + 1 < w else -1):
            if q >= 0 and mask[q]:
                mask[q] = 0
                queue.append(q)
    if len(pixels) > 1000:
        cx = sum(p % w for p in pixels) / len(pixels)
        cy = sum(p // w for p in pixels) / len(pixels)
        groups[min(args.rows-1, int(cy / (h / args.rows))) * args.columns + min(args.columns-1, int(cx / (w / args.columns)))].append(pixels)

frames = []
for index, components in enumerate(groups):
    assert components, ('missing paired pose', index)
    pixels = [p for body in components for p in body]
    xs, ys = [p % w for p in pixels], [p // w for p in pixels]
    x0, x1, y0, y1 = min(xs), max(xs) + 1, min(ys), max(ys) + 1
    # The left figure is Mavrin. His feet remain the ground anchor even when
    # Polina is standing in the opening/release poses.
    feet = [p % w for p in pixels if p // w >= y1 - 8 and (args.solo or p % w < x0 + (x1 - x0) * .57)]
    assert feet, ('no Mavrin ground anchor', index)
    anchor = [(min(feet) + max(feet)) / 2, y1]
    frames.append({'rect': [x0, y0, x1 - x0, y1 - y0], 'anchor': anchor, 'polygons': [outline(body, w) for body in components]})
    print('Paired pose', index, 'components', len(components), 'size', x1 - x0, y1 - y0)

base = frames[0]
result = {'size': [w, h], 'height': base['rect'][3], 'sha256': hashlib.sha256(image.read_bytes()).hexdigest(), 'frames': frames}
image.with_suffix('.json').write_text(json.dumps(result, separators=(',', ':')) + '\n')
