#!/usr/bin/env python3
"""Original procedural water sounds and openly synthetic Russian eSpeak dialogue."""
import math
import os
import random
import struct
import subprocess
import wave
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'game/assets/sfx'
espeak = os.environ.get('ARENA_ESPEAK_BIN', 'espeak')
path = os.environ.get('ARENA_ESPEAK_DATA')
for name, text, voice, pitch, rate in [
    ('mavrinKet', 'КЭТ!', 'ru', '38', '135'),
    ('mavrinPolina', 'Эххх, Полинаа!', 'ru', '42', '145'),
    ('polinaReply', 'Идите в жопу со своими упражнениями, Игорь Анатольевич!', 'ru+f3', '65', '165'),
]:
    subprocess.run([espeak, *(['--path=' + path] if path else []), '-v', voice, '-p', pitch, '-s', rate, '-w', str(OUT / (name + '.wav')), text], check=True)

rng = random.Random(2319)
rate = 22050
for name, duration in [('waterSeal', .55), ('waterJet', .65)]:
    values = []
    for i in range(int(duration * rate)):
        t = i / rate
        envelope = min(1, t / .035) * min(1, (duration - t) / .12)
        value = (math.sin(2 * math.pi * (300 * t + 700 * t * t)) * .2 + math.sin(2 * math.pi * 1100 * t) * .08) if name == 'waterSeal' else (rng.uniform(-1, 1) * .34 + math.sin(2 * math.pi * 2300 * t) * .08)
        values.append(int(max(-1, min(1, value * envelope)) * 32767))
    with wave.open(str(OUT / (name + '.wav')), 'wb') as wav:
        wav.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        wav.writeframes(struct.pack('<' + 'h' * len(values), *values))
