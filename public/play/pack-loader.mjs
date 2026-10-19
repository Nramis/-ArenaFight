const hex = bytes => Array.from(new Uint8Array(bytes), value => value.toString(16).padStart(2, '0')).join('');

export async function fetchGamePack(url, options, fetchFile) {
    const base = new URL(url, globalThis.location?.href || 'http://localhost/play/');
    const response = await fetchFile(new URL('pack.json', base), { ...options, cache: 'no-store' });
    if (!response.ok) throw new Error('Не удалось загрузить описание игры: ' + response.status);
    const manifest = await response.json();
    if (!Number.isSafeInteger(manifest.size) || manifest.size < 1 || manifest.size > 100 * 1024 * 1024 || !Array.isArray(manifest.parts) || manifest.parts.length < 1 || manifest.parts.length > 64) {
        throw new Error('Неверное описание игрового пакета');
    }
    let total = 0;
    for (const part of manifest.parts) {
        if (!/^game-data-[a-f0-9]{12}-\d{2}\.bin$/.test(part.name) || !Number.isSafeInteger(part.size) || part.size < 1 || part.size > 2 * 1024 * 1024 || !/^[a-f0-9]{64}$/.test(part.sha256)) {
            throw new Error('Неверная часть игрового пакета');
        }
        total += part.size;
    }
    if (total !== manifest.size) throw new Error('Не совпадает размер игрового пакета');
    const buffers = new Array(manifest.parts.length);
    let next = 0;
    await Promise.all(Array.from({ length: Math.min(4, buffers.length) }, async () => {
        while (next < buffers.length) {
            const index = next++;
            const part = manifest.parts[index];
            const response = await fetchFile(new URL(part.name, base), options);
            if (!response.ok) throw new Error('Не удалось загрузить часть игры: ' + response.status);
            const bytes = await response.arrayBuffer();
            if (bytes.byteLength !== part.size) throw new Error('Неполная часть игрового пакета');
            if (globalThis.crypto?.subtle && hex(await crypto.subtle.digest('SHA-256', bytes)) !== part.sha256) {
                throw new Error('Повреждена часть игрового пакета. Обновите страницу.');
            }
            buffers[index] = bytes;
        }
    }));
    return new Response(new Blob(buffers).stream(), {
        headers: { 'Content-Type': 'application/octet-stream', 'Content-Length': String(manifest.size) },
    });
}
