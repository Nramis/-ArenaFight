"""Reproduce Rinat's original synthetic voices (eSpeak NG ru/tt) and vape effect.

Usage: python tools/create_rinat_audio.py --espeak-bin espeak-ng
Optional --data-path and --library-path support a locally extracted eSpeak build.
No recorded person's voice or existing song recording is used.
"""
import argparse
import math
import os
from pathlib import Path
import random
import subprocess
import tempfile
import wave
import struct

ROOT = Path(__file__).resolve().parents[1]
LINES = [
    ("rinatChain", "ru", "Ты Орлов? Иди сюда!", 170, 36),
    ("rinatChant0", "tt", "Малайлар! Әйдә, бля! Биергә!", 160, 48),
    ("rinatChant1", "tt", "Әй, малайлар! Кайда сез, бля?", 150, 58),
    ("rinatChant2", "tt", "Малайлар! Җырлыйбыз, бля! Әйдә!", 165, 42),
]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--espeak-bin', default='espeak-ng')
    parser.add_argument('--data-path')
    parser.add_argument('--library-path')
    args = parser.parse_args()
    env = os.environ.copy()
    if args.library_path:
        env['LD_LIBRARY_PATH'] = args.library_path
    output = ROOT / 'game/assets/sfx'
    with tempfile.TemporaryDirectory() as temp:
        for name, voice, text, speed, pitch in LINES:
            raw = Path(temp) / (name + '.wav')
            command = [args.espeak_bin, '-v', voice, '-s', str(speed), '-p', str(pitch), '-a', '180', '-w', str(raw)]
            if args.data_path:
                command.append('--path=' + args.data_path)
            subprocess.run(command + [text], env=env, check=True, capture_output=True)
            effects = 'asetrate=22050*0.94,aresample=44100,acompressor=threshold=0.25:ratio=3:attack=5:release=100,aecho=0.6:0.4:42:0.18,alimiter=limit=0.88'
            if 'Chant' in name:
                effects += ',vibrato=f=4.5:d=0.22,tremolo=f=3:d=0.15'
            subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(raw),'-af',effects,'-ac','1',str(output/(name+'.wav'))],check=True)
    rng = random.Random(1624)
    rate = 44100
    samples = []
    low = 0.0
    for i in range(int(rate*1.1)):
        t = i/rate
        low = low*0.83 + rng.uniform(-1,1)*0.17
        envelope = min(1,t/0.08)*min(1,(1.1-t)/0.22)
        samples.append(int(14000*low*envelope*(0.7+0.3*math.sin(t*9))))
    with wave.open(str(output/'rinatVape.wav'),'wb') as audio:
        audio.setparams((1,2,rate,0,'NONE','not compressed'))
        audio.writeframes(struct.pack('<'+'h'*len(samples),*samples))
    print('Generated four synthetic voice lines and the original vape effect.')

if __name__ == '__main__':
    main()
