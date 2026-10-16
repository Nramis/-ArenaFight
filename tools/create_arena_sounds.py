# Original synthesized effects; deterministic local generation, no sampled audio.
import math, random, wave, struct
from pathlib import Path
out=Path(__file__).resolve().parents[1]/'game/assets/sfx'
rng=random.Random(713); sr=22050
for name,dur in [('arena_combo',.16),('arena_finish',.4),('arena_counter',.24),('arena_bodyfall',.32),('arena_heavy_air',.22),('arena_round',.6)]:
 samples=[]; low=0
 for n in range(int(sr*dur)):
  t=n/sr; u=t/dur; noise=rng.uniform(-1,1); low=.84*low+.16*noise
  if name=='arena_combo': v=.45*math.sin(2*math.pi*(620*t+1000*t*t))*math.exp(-22*t)+.12*noise*math.exp(-65*t)
  elif name=='arena_finish': v=(.4*math.sin(2*math.pi*164.8*t)+.27*math.sin(2*math.pi*247*t)+.18*math.sin(2*math.pi*329.6*t))*math.exp(-9*t)+.2*low*math.exp(-30*t)
  elif name=='arena_counter': v=(.5*math.sin(2*math.pi*(1700*t-1700*t*t))+.2*noise)*math.exp(-26*t)
  elif name=='arena_bodyfall': v=(.6*math.sin(2*math.pi*(95*t-100*t*t))+.8*low)*math.exp(-17*t)
  elif name=='arena_heavy_air': v=(noise-low)*math.sin(math.pi*u)**1.5*.32+low*.4*math.sin(math.pi*u)
  else:
   freq=[329.63,415.3,493.88][min(2,int(t/.16))];v=.38*math.sin(2*math.pi*freq*t)*math.sin(math.pi*u)**.5
  fade=min(1,n/60,(sr*dur-n)/100);samples.append(max(-.95,min(.95,v*fade)))
 with wave.open(str(out/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(sr);f.writeframes(b''.join(struct.pack('<h',int(v*32767)) for v in samples))
