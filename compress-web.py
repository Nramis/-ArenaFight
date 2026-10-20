"""Run after Godot Web export. Serve a gzip WASM within static-host file limits."""
from pathlib import Path
import gzip, shutil, subprocess
p=Path(__file__).parent/'public/play'
f=p/'game.wasm'
with f.open('rb') as src, gzip.open(p/'game.wasm.gz','wb',compresslevel=9) as dst:shutil.copyfileobj(src,dst)
# Archive uncompressed intermediate outside the static output.
f.replace(Path(__file__).parent/'game.wasm.intermediate')
html=p/'game.html'
s=html.read_text()
shim='''<script>
const originalFetch = window.fetch.bind(window);
window.fetch = async function(input, options) {
 const url = typeof input === 'string' ? input : (input instanceof URL ? input.href : input.url);
 if (url && /game\\.pck(?:\\?.*)?$/.test(url)) {
  const {fetchGamePack} = await import('./pack-loader.mjs?v=1');
  return fetchGamePack(url, options, originalFetch);
 }
 if (url && /game\\.wasm(?:\\?.*)?$/.test(url)) {
  const response = await originalFetch(url.replace('game.wasm','game.wasm.gz'), options);
  if (!response.ok) throw new Error('Не удалось загрузить игру: '+response.status);
  const bytes = await response.arrayBuffer();
  const isGzip = new Uint8Array(bytes, 0, Math.min(2, bytes.byteLength));
  if (isGzip[0] === 31 && isGzip[1] === 139) {
   const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
   return new Response(stream, {headers:{'Content-Type':'application/wasm'}});
  }
  return new Response(bytes,{headers:{'Content-Type':'application/wasm'}});
 }
 return originalFetch(input,options);
};
</script>'''
s=s.replace('</head>',shim+'\n</head>')
html.write_text(s)
print('Compressed WASM:',(p/'game.wasm.gz').stat().st_size)
subprocess.run(['node', str(Path(__file__).parent/'scripts/package-game.mjs')], check=True)
(p/'game.pck').replace(Path(__file__).parent/'game.pck.intermediate')
