"""Derive render-only UV outlines; never change the original sprite PNGs.

Development dependencies: Pillow, numpy, scipy, scikit-image.
Run after replacing the three 8x6 atlases, before the Godot Web export.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image
from scipy import ndimage
from skimage.measure import find_contours, approximate_polygon

ROOT = Path(__file__).resolve().parents[1]
TIERS = ('prosperous', 'struggling', 'bankrupt')


def build():
    result = {}
    for tier in TIERS:
        path = ROOT / 'game/assets/ruslan' / (tier + '.png')
        image = Image.open(path).convert('RGBA')
        alpha = np.asarray(image)[:, :, 3]
        width, height = image.size
        assert width % 8 == 0 and height % 6 == 0
        cw, ch = width // 8, height // 6
        frames = []
        for pose in range(48):
            ox, oy = pose % 8 * cw, pose // 8 * ch
            solid = alpha[oy:oy+ch, ox:ox+cw] > 24
            labels, count = ndimage.label(solid)
            assert count > 0, (tier, pose)
            areas = np.bincount(labels.ravel())
            selected = int(np.argmax(areas[1:])) + 1
            body = labels == selected
            yy, xx = np.where(body)
            # A two-pixel transparent allowance keeps antialiased body edges.
            # Separate neighbouring shoes cannot enter the retained contour.
            padded = np.pad(ndimage.binary_dilation(body, iterations=2), 1)
            contours = find_contours(padded, 0.5)
            contour = max(contours, key=len)
            contour = approximate_polygon(contour, tolerance=0.65)
            outline = [[round(float(np.clip(p[1] - 1, 0.5, cw - 0.5)), 2), round(float(np.clip(p[0] - 1, 0.5, ch - 0.5)), 2)] for p in contour[:-1]]
            assert len(outline) >= 3
            frames.append({'outline': outline, 'bounds': [int(xx.min()), int(yy.min()), int(xx.max()+1), int(yy.max()+1)]})
        idle = [frame['bounds'] for frame in frames[:8]]
        anchor_x = sum((r[0]+r[2])/2 for r in idle)/8
        baseline = sum(r[3] for r in idle)/8
        idle_height = sum(r[3]-r[1] for r in idle)/8
        result[tier] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'cell': [cw, ch], 'anchor': [round(anchor_x, 2), round(baseline, 2)], 'scale': round(110.0/idle_height, 6), 'frames': frames}
    out = ROOT / 'game/fighter/ruslan_atlas.gd'
    out.write_text('class_name RuslanAtlas\nextends RefCounted\n\n# Generated render-only outlines. Original PNGs are unchanged.\nconst DATA = ' + json.dumps(result, ensure_ascii=False, separators=(',', ':')) + '\n')
    print('Wrote 144 isolated pose outlines:', out)


if __name__ == '__main__':
    build()
