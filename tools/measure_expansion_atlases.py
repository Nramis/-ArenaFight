#!/usr/bin/env python3
"""Measure alpha components in original ImageGen sheets without modifying pixels.

Stdlib-only PNG RGBA decoder: no imaging dependencies or raster editing.
"""
import json
import math
import struct
import zlib
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def rgba(path):
    raw = path.read_bytes()
    pos, compressed = 8, bytearray()
    while pos < len(raw):
        size = struct.unpack('>I', raw[pos:pos + 4])[0]
        kind, data = raw[pos + 4:pos + 8], raw[pos + 8:pos + 8 + size]
        if kind == b'IHDR':
            w, h, bits, color, _, _, interlace = struct.unpack('>IIBBBBB', data)
            assert (bits, color, interlace) == (8, 6, 0), (path, bits, color, interlace)
        if kind == b'IDAT':
            compressed.extend(data)
        pos += size + 12
    data = zlib.decompress(compressed)
    stride = w * 4
    previous = bytearray(stride)
    alpha = bytearray(w * h)
    for y in range(h):
        offset = y * (stride + 1)
        mode = data[offset]
        row = bytearray(data[offset + 1:offset + 1 + stride])
        for i in range(stride):
            a, b, c = row[i - 4] if i >= 4 else 0, previous[i], previous[i - 4] if i >= 4 else 0
            if mode == 1:
                row[i] = (row[i] + a) & 255
            elif mode == 2:
                row[i] = (row[i] + b) & 255
            elif mode == 3:
                row[i] = (row[i] + (a + b) // 2) & 255
            elif mode == 4:
                p = a + b - c
                ds = (abs(p - a), abs(p - b), abs(p - c))
                row[i] = (row[i] + (a if ds[0] <= ds[1] and ds[0] <= ds[2] else b if ds[1] <= ds[2] else c)) & 255
            else:
                assert mode == 0
        alpha[y * w:(y + 1) * w] = row[3::4]
        previous = row
    return w, h, alpha


def outline(pixels, w):
    mask = set(pixels)
    edges = {}
    for p in pixels:
        x, y = p % w, p // w
        if p - w not in mask:
            edges[(x, y)] = (x + 1, y)
        if p + 1 not in mask:
            edges[(x + 1, y)] = (x + 1, y + 1)
        if p + w not in mask:
            edges[(x + 1, y + 1)] = (x, y + 1)
        if p - 1 not in mask:
            edges[(x, y + 1)] = (x, y)
    loops = []
    while edges:
        start = next(iter(edges))
        current, loop = start, [start]
        while current in edges:
            current = edges.pop(current)
            loop.append(current)
            if current == start:
                break
        if len(loop) > 10:
            loops.append(loop)
    points = max(loops, key=len)
    def rdp(ps):
        if len(ps) < 3:
            return ps
        ax, ay = ps[0]
        bx, by = ps[-1]
        dx, dy = bx - ax, by - ay
        den = math.hypot(dx, dy)
        ds = [math.hypot(x - ax, y - ay) if den == 0 else abs(dx * (ay - y) - (ax - x) * dy) / den for x, y in ps]
        at = max(range(len(ds)), key=ds.__getitem__)
        return rdp(ps[:at + 1])[:-1] + rdp(ps[at:]) if ds[at] > 1.1 else [ps[0], ps[-1]]
    mid = len(points) // 2
    return rdp(points[:mid + 1])[:-1] + rdp(points[mid:])[:-1]


def measure(path):
    w, h, alpha = rgba(path)
    mask = bytearray(1 if a > 128 else 0 for a in alpha)
    components = []
    for start in range(w * h):
        if mask[start] != 1:
            continue
        queue, pixels = deque([start]), []
        mask[start] = 0
        while queue:
            p = queue.popleft()
            pixels.append(p)
            x, y = p % w, p // w
            for n in (p - 1 if x else -1, p + 1 if x + 1 < w else -1, p - w if y else -1, p + w if y + 1 < h else -1):
                if n >= 0 and mask[n] == 1:
                    mask[n] = 0
                    queue.append(n)
        if len(pixels) >= 1000:
            components.append(pixels)
    # Some generated shoes/hands touch at a single cell boundary. Split only
    # oversized joined bodies at the sparsest vertical seam; source pixels stay intact.
    expected = 31 if path.name == "bigboss-cheese.png" else 32
    while len(components) < expected:
        joined = max(components, key=len)
        typical = sorted(len(p) for p in components)[len(components) // 2]
        assert len(joined) > typical * 1.45, (path, len(components))
        x0, x1 = min(i % w for i in joined), max(i % w for i in joined)
        counts = [0] * w
        for i in joined:
            counts[i % w] += 1
        cut = min(range(int(x0 + (x1 - x0) * .32), int(x0 + (x1 - x0) * .68)), key=lambda x: counts[x] + abs(x - (x0 + x1) / 2) * .08)
        components.remove(joined)
        components.extend([[i for i in joined if i % w < cut], [i for i in joined if i % w >= cut]])
    print(path.name, 'body components:', len(components), flush=True)
    assert len(components) == expected, (path, len(components), sorted(len(p) for p in components))
    components.sort(key=lambda p: sum(i // w for i in p) / len(p))
    ordered = []
    if expected == 31:
        # One generated slot contains the flying snack, not a body. Hold the
        # preceding full-body followthrough there; no sprite is fabricated.
        for row in range(4):
            bodies = [p for p in components if int(sum(i // w for i in p) / len(p) / (h / 4)) == row]
            bodies.sort(key=lambda p: sum(i % w for i in p) / len(p))
            assert len(bodies) == (7 if row == 1 else 8), (path, row, len(bodies))
            if row == 1:
                bodies.insert(5, bodies[4])
            ordered.extend(bodies)
    else:
        for row in range(4):
            ordered.extend(sorted(components[row * 8:row * 8 + 8], key=lambda p: sum(i % w for i in p) / len(p)))
    frames = []
    for pixels in ordered:
        xs, ys = [i % w for i in pixels], [i // w for i in pixels]
        x0, x1, y0, y1 = min(xs), max(xs) + 1, min(ys), max(ys) + 1
        feet = [i % w for i in pixels if i // w >= y1 - 7]
        frames.append({'rect': [max(0, x0 - 1), max(0, y0 - 1), min(w, x1 + 1) - max(0, x0 - 1), min(h, y1 + 1) - max(0, y0 - 1)], 'anchor': [(min(feet) + max(feet)) / 2, y1], 'polygon': outline(pixels, w)})
    return {'size': [w, h], 'height': frames[0]['rect'][3], 'frames': frames}


if __name__ == '__main__':
    bank = ROOT / 'game/assets/nikita-v2'
    results = {p.name: measure(p) for p in sorted(bank.glob('*.png'))}
    target = ROOT / 'game/assets/cheese/bigboss-cheese.png'
    if target.exists():
        results[target.name] = measure(target)
    (bank / 'regions.json').write_text(json.dumps(results, separators=(',', ':')) + '\n')
