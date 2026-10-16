# Crouch and aerial animation frames

Seven transparent 1536 × 1024 atlases, generated with the built-in image generator using each matching motion atlas as a character reference: rafael, nikita, vladislav, mavrin, ramis, ilgiz, bigboss.

Shared brief: preserve the adult character identity, outfit, proportions and outlined cel shaded style. Strict four-column, two-row transparent grid, full body inside each cell: half squat transition, crouching jab, low kick, sweeping kick, airborne windup, airborne punch, airborne kick, landing crouch. Consistent scale, no text, background or gore.

The renderer uses per-frame baselines from `../../fighter/posture_atlas.gd`. Source PNGs remain intact; native texture import uses 85% WebP color compression with alpha.
