import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fetchGamePack } from '../../public/play/pack-loader.mjs';

const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const base = new URL('../../public/play/', import.meta.url);

test('shipped pack parts reconstruct the exact exported Godot package', async () => {
    const manifest = JSON.parse(await readFile(new URL('pack.json', base), 'utf8'));
    let inFlight = 0;
    let peak = 0;
    const fetchFile = async url => {
        inFlight++;
        peak = Math.max(peak, inFlight);
        try {
            return new Response(await readFile(new URL(url.pathname.split('/').pop(), base)));
        } finally { inFlight--; }
    };
    const response = await fetchGamePack('https://arena.example/play/game.pck', {}, fetchFile);
    const bytes = Buffer.from(await response.arrayBuffer());
    assert.equal(bytes.length, manifest.size);
    assert.equal(digest(bytes), manifest.sha256);
    assert.equal(response.headers.get('Content-Length'), String(bytes.length));
    assert(peak <= 4);
    assert.equal(bytes.subarray(0, 4).toString(), 'GDPC');
});

function fixture(change = {}) {
    const bytes = new Uint8Array([1, 2, 3, 4]);
    const part = { name: 'game-data-123456789abc-00.bin', size: bytes.length, sha256: digest(bytes) };
    const manifest = { size: bytes.length, parts: [part], ...change };
    const fetchFile = async url => url.pathname.endsWith('pack.json') ? Response.json(manifest) : new Response(bytes);
    return { bytes, part, manifest, fetchFile };
}

test('corrupted parts are rejected before reaching the game engine', async () => {
    const f = fixture();
    f.part.sha256 = '0'.repeat(64);
    await assert.rejects(fetchGamePack('https://arena.example/play/game.pck', {}, f.fetchFile), /Повреждена/);
});

test('incomplete parts and failed downloads surface a loading error', async () => {
    const f = fixture();
    f.part.size = 5;
    f.manifest.size = 5;
    await assert.rejects(fetchGamePack('https://arena.example/play/game.pck', {}, f.fetchFile), /Неполная/);
    const missing = async url => url.pathname.endsWith('pack.json') ? Response.json(f.manifest) : new Response('', { status: 404 });
    await assert.rejects(fetchGamePack('https://arena.example/play/game.pck', {}, missing), /404/);
});

test('invalid manifests cannot fetch paths outside the game directory', async () => {
    const f = fixture();
    f.part.name = '../private.bin';
    await assert.rejects(fetchGamePack('https://arena.example/play/game.pck', {}, f.fetchFile), /Неверная часть/);
    f.part.name = 'game-data-123456789abc-00.bin';
    f.manifest.size = 9;
    await assert.rejects(fetchGamePack('https://arena.example/play/game.pck', {}, f.fetchFile), /Не совпадает/);
});
