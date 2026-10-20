#!/usr/bin/env python3
"""Measure generated atlases into pose regions; never modifies raster source images.
Requires Pillow, numpy, scipy, matplotlib. Run from any working directory.
"""
import json
from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage as ndi
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
FILES = list((ROOT / 'game/assets/rinat').glob('*.png')) + [ROOT / 'game/assets/skins/vlad-paquito.png']
ROWS = {'rinat-base.png': [305, 579, 825], 'rinat-master.png': [303, 582, 833], 'rinat-scorpion.png': [290, 566, 836], 'rinat-scorpion-master.png': [290, 563, 825], 'vlad-paquito.png': [286, 555, 834]}

def simplify(points, epsilon=1.5):
    if len(points) < 3: return points
    p=np.asarray(points); v=p[-1]-p[0]; d=np.linalg.norm(v)
    distance=np.linalg.norm(p-p[0],axis=1) if d<.001 else np.abs(v[0]*(p[:,1]-p[0,1])-v[1]*(p[:,0]-p[0,0]))/d
    i=int(np.argmax(distance))
    if distance[i]>epsilon:
        return simplify(p[:i+1],epsilon)[:-1]+simplify(p[i:],epsilon)
    return [p[0].tolist(),p[-1].tolist()]

def main():
    result={}
    for file in sorted(FILES):
        alpha=np.array(Image.open(file).getchannel('A')); mask=alpha>128
        labels,n=ndi.label(mask); counts=np.bincount(labels.ravel()); components=[]
        for k in np.flatnonzero(counts>1500):
            if k==0: continue
            component=labels==k
            yy,xx=np.where(component)
            # Two Paquito attack pairs touch. Split by geodesic distance from body cores.
            if file.name=='vlad-paquito.png' and len(xx)>25000:
                distance=ndi.distance_transform_edt(component)
                core_labels,core_n=ndi.label(distance>12)
                core_counts=np.bincount(core_labels.ravel())
                cores=[k for k in range(1,core_n+1) if core_counts[k]>500]
                assert len(cores)==2,(file.name,cores)
                markers=np.zeros(mask.shape,dtype=np.int32)
                for j,k in enumerate(cores,1): markers[core_labels==k]=j
                # Constrained geodesic flood: sources are entire eroded bodies,
                # keeping the split at the narrow contact between neighboring poses.
                divided=markers.copy()
                queue=deque(zip(*np.where(markers>0)))
                height,width=component.shape
                while queue:
                    y,x=queue.popleft()
                    for dy,dx in ((-1,0),(1,0),(0,-1),(0,1)):
                        ny,nx=y+dy,x+dx
                        if 0<=ny<height and 0<=nx<width and component[ny,nx] and not divided[ny,nx]:
                            divided[ny,nx]=divided[y,x]; queue.append((ny,nx))
                components.extend((divided==j)&component for j in range(1,len(cores)+1))
            else: components.append(component)
        rows=[[] for _ in range(4)]
        for component in components:
            yy,xx=np.where(component)
            row=sum(int(yy.max()+1)>edge for edge in ROWS[file.name])
            rows[row].append((float(np.mean(xx)),component))
        assert [len(row) for row in rows]==[8]*4,(file.name,[len(row) for row in rows])
        frames=[]
        for row in rows:
            for _,component in sorted(row,key=lambda item:item[0]):
                yy,xx=np.where(component); x0,x1,y0,y1=int(xx.min()),int(xx.max()+1),int(yy.min()),int(yy.max()+1)
                bottom=xx[yy>=y1-10]; anchorx=(int(bottom.min())+int(bottom.max()))/2
                # Dilate only analysis mask by one pixel to include antialiased edge in texture polygon.
                expanded=ndi.binary_dilation(component,iterations=1)
                fig,ax=plt.subplots(); contours=ax.contour(expanded.astype(float),levels=[.5]).allsegs[0]; plt.close(fig)
                outline=max(contours,key=len)
                # Split a closed contour into halves before RDP, avoiding coincident first/last endpoints.
                mid=len(outline)//2
                polygon=simplify(outline[:mid+1])+simplify(outline[mid:])[1:]
                polygon=[[round(float(x),2),round(float(y),2)] for x,y in polygon]
                frames.append({'rect':[max(0,x0-1),max(0,y0-1),min(alpha.shape[1],x1+1)-max(0,x0-1),min(alpha.shape[0],y1+1)-max(0,y0-1)],'anchor':[anchorx,y1],'polygon':polygon})
        result[file.name]={'height':frames[0]['rect'][3],'size':[alpha.shape[1],alpha.shape[0]],'frames':frames}
        print(file.name, len(frames),'height',result[file.name]['height'])
    out=ROOT/'game/assets/rinat/regions.json'
    out.write_text(json.dumps(result,separators=(',',':'))+'\n')
    print('Saved',out)

if __name__=='__main__':main()
