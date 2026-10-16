# Intermediate animation frames

Seven transparent 1536 × 1024 PNG atlases, generated using the built-in image generator from the corresponding `../motion/<character>.png` identity and style reference.

Files: `rafael.png`, `nikita.png`, `vladislav.png`, `mavrin.png`, `ramis.png`, `ilgiz.png`, `bigboss.png`.

Shared generation brief: Preserve the supplied adult character's identity, outfit, colors, proportions and cel shaded outlined style. Create eight additional frames in a strict four-column, two-row transparent grid: walking passing pose A, opposite passing pose B, punch windup with fist chambered at shoulder, punch retraction towards guard, kick chamber with knee raised, kick retraction with lower leg folding back, curled ground knockdown facing right, kneeling get-up. Keep the full body inside each cell, consistent camera scale and aligned ground baselines. No props, weapons, text, floor, voices or gore.

These eight frames are interleaved with the original eight poses by `../../fighter/animation_timeline.gd`. Ground baselines and isolation bounds are in `../../fighter/transition_atlas.gd`. Tracked import settings use 85% WebP color compression with alpha preserved, reducing the browser download while the source PNGs remain intact.
