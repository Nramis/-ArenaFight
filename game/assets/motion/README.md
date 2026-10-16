# Motion sprites

Created with the built-in image generator using the existing character atlases as identity and outfit references. Original ability atlases remain in use for transformations and special poses.

Files in this directory: `rafael.png`, `nikita.png`, `vladislav.png`, `mavrin.png`, `ramis.png`, `ilgiz.png`, `bigboss.png`.

Each sheet is a transparent 1536 × 1024 PNG, four columns and two rows. Pose order: guard, forward step, alternate step, straight punch, front kick, tucked jump, hit recoil, crouching guard. Alpha-derived ground baselines and isolated kick polygons are defined in `../../fighter/motion_atlas.gd` and `../../fighter/combat_art.gd`.

## Generation prompt set

Shared brief: Create a new production 2D fighting animation sprite atlas from the supplied reference. Preserve the specified character's face, outfit and colors. Crisp illustrated cel shading, clean dark outlines, readable silhouettes and consistent proportions. Exactly four columns and two rows, eight isolated full-body sprites on a transparent background, facing right, with blank margins and aligned feet. Pose order: boxing guard, left step, right step, extended punch, waist-height front kick, tucked jump, backwards hit recoil, low blocking guard. No text, floor, props, other people or background shadows.

Character-specific reference subjects:

- Rafael: top row of `../fighters.png`; dark wavy hair, white polo with dark trim, dark trousers, white sneakers.
- Nikita: bottom row of `../fighters.png`; short light brown hair, white ribbed polo, dark trousers, black sneakers.
- Vladislav: `../vladislav.png`; dark bangs, pale blue hoodie, black trousers and sneakers, normal body.
- Mavrin: `../mavrin.png`; balding mature man with prominent nose, yellow T-shirt, visible small belly, dark trousers and shoes.
- Ramis: `../ramis.png`; receding short dark hair, black rectangular glasses, blue polo, dark jeans, normal upright form.
- Ilgiz: top row of `../newcomers.png`; swept light brown hair, gray jacket, brown turtleneck, black trousers and dark shoes.
- Rafael Big Boss: bottom row of `../newcomers.png`; compact adult body, receding light brown hair, trimmed beard, open red and black plaid shirt over black tee, black jeans and shoes; no weapons in normal combat poses. His special weapon and camera-smile poses remain in the original atlas.
