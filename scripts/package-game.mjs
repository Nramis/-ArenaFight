import { readFileSync, writeFileSync, readdirSync, unlinkSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const directory = fileURLToPath(new URL('../public/play/', import.meta.url));
const pack = readFileSync(path.join(directory, 'game.pck'));
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const sha256 = digest(pack);
const parts = [];
const chunkSize = 2 * 1024 * 1024;
for (let offset = 0; offset < pack.length; offset += chunkSize) {
    const bytes = pack.subarray(offset, offset + chunkSize);
    const name = `game-data-${sha256.slice(0, 12)}-${String(parts.length).padStart(2, '0')}.bin`;
    writeFileSync(path.join(directory, name), bytes);
    parts.push({ name, size: bytes.length, sha256: digest(bytes) });
}
const keep = new Set(parts.map(part => part.name));
for (const name of readdirSync(directory)) {
    if (/^game-data-[a-f0-9]+-\d+\.bin$/.test(name) && !keep.has(name)) unlinkSync(path.join(directory, name));
}
writeFileSync(path.join(directory, 'pack.json'), JSON.stringify({ size: pack.length, sha256, parts }, null, 2) + '\n');
const htmlPath = path.join(directory, 'game.html');
writeFileSync(htmlPath, readFileSync(htmlPath, 'utf8').replace(/"game.pck":\d+/, '"game.pck":' + pack.length));
console.log(`Packaged ${pack.length} bytes into ${parts.length} verified parts (${sha256.slice(0, 12)}).`);
