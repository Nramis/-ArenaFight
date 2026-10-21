# Sound sources

Base combat effects below are CC0 and nonverbal. The separately attributed Toasty cameo excerpt is listed at the end.

| Source | Author | Files used | License |
| --- | --- | --- | --- |
| https://kenney.nl/assets/impact-sounds | Kenney | Concrete footsteps, medium/heavy punches, soft landings, plate blocks, glass and bell impacts | CC0 |
| https://kenney.nl/assets/rpg-audio | Kenney | Cloth, belt handling, metal clicks, latch and coins | CC0 |
| https://kenney.nl/assets/sci-fi-sounds | Kenney | Short arcade laser shots and force field effect | CC0 |
| https://opengameart.org/content/swishes-sound-pack | artisticdude | swish-1, swish-2, swish-3, swish-5, swish-8 WAV files | CC0 |

CC0: https://creativecommons.org/publicdomain/zero/1.0/
Original Kenney license notices are preserved in this directory. Sample file names are retained. The event mapping and relative playback levels are defined in `../../fx/sfx.gd`; effects share a bounded ten-voice pool on the ArenaSFX audio bus.

## Arena update

`arena_*.wav`: six original synthesized nonverbal effects created for this game: combo, finisher, counter, body fall, heavy swing and round chime. No external recordings or voices. The reproducible generator is `tools/create_arena_sounds.py`.

## Юсуп

`yusupStory.wav` («Там, короче…») и `yusupForget.wav` («А забей!») синтезированы установленным голосом Microsoft Pavel через Windows SAPI. Это обычная синтезированная речь, без клонирования голоса человека с фотографии. Генератор: `tools/generateYusupVoice.ps1`. Обе записи используют общие настройки громкости и отключения звука игры.

## User-requested Toasty cameo

`toasty-mk.mp3`: short original “Toasty!” voice excerpt from Mortal Kombat (Dan Forden / Midway), requested by the user, sourced from https://www.myinstants.com/en/instant/mortal-kombat-toasty-67477/ (file /media/sounds/mk3-04245.mp3). This excerpt is not CC0 and is not part of the CC0 sound packs above.

## Rinat

`rinatChain.wav`, `rinatChant0.wav`–`rinatChant2.wav` are synthetic eSpeak NG voices (Russian and Tatar), processed with FFmpeg. The short chants are original lines, not an excerpt of an existing song. No impersonation of the reference person's voice. `rinatVape.wav` is seeded procedural filtered noise. Reproduce with `python tools/create_rinat_audio.py --espeak-bin espeak-ng`. Shirt tearing reuses the credited Kenney cloth recordings.

## Kudesnik update
`mavrinKet.wav`, `mavrinPolina.wav`, `polinaReply.wav`: synthetic Russian eSpeak voices (ru/ru+f3), generated from original user-requested dialogue; not recordings or voice clones. `waterSeal.wav` and `waterJet.wav`: original procedural effects. Reproduce with `python tools/create_expansion_audio.py` and eSpeak installed.
