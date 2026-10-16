# Sound sources

Base combat effects below are CC0 and nonverbal. The separately attributed Toasty cameo excerpt is listed at the end.

| Source | Author | Files used | License |
| --- | --- | --- | --- |
| https://kenney.nl/assets/impact-sounds | Kenney | Concrete footsteps, medium/heavy punches, soft landings, plate blocks, glass and bell impacts | CC0 |
| https://kenney.nl/assets/rpg-audio | Kenney | Cloth, belt handling, metal clicks, latch and coins | CC0 |
| https://kenney.nl/assets/sci-fi-sounds | Kenney | Short arcade laser shots and force field effect | CC0 |
| https://opengameart.org/content/swishes-sound-pack | artisticdude | swish-1, swish-2, swish-3, swish-5, swish-8 WAV files | CC0 |

CC0: https://creativecommons.org/publicdomain/zero/1.0/
Original Kenney license notices are preserved in this directory. Sample file names are retained. The event mapping and relative playback levels are defined in `../../fx/sfx.gd`; effects share a bounded ten-voice pool on the ArenaSFX audio bus. No voice synthesis is used.

## Arena update

`arena_*.wav`: six original synthesized nonverbal effects created for this game: combo, finisher, counter, body fall, heavy swing and round chime. No external recordings or voices. The reproducible generator is `tools/create_arena_sounds.py`.

## User-requested Toasty cameo

`toasty-mk.mp3`: short original “Toasty!” voice excerpt from Mortal Kombat (Dan Forden / Midway), requested by the user, sourced from https://www.myinstants.com/en/instant/mortal-kombat-toasty-67477/ (file /media/sounds/mk3-04245.mp3). This excerpt is not CC0 and is not part of the CC0 sound packs above.
