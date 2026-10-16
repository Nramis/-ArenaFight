import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync } from 'node:fs';
import { X509Certificate } from 'node:crypto';
import { networkInterfaces } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const directory = path.join(root, '.sites-runtime', 'https');
const key = path.join(directory, 'key.pem');
const cert = path.join(directory, 'cert.pem');
const addresses = [...new Set(['127.0.0.1', ...Object.values(networkInterfaces())
    .flatMap(entries => entries ?? [])
    .filter(entry => entry.family === 'IPv4')
    .map(entry => entry.address)])];

function certificateValid() {
    try {
        const certificate = new X509Certificate(readFileSync(cert));
        return existsSync(key)
            && Date.parse(certificate.validTo) > Date.now() + 86_400_000
            && certificate.checkHost('localhost') !== undefined
            && addresses.every(address => certificate.checkIP(address) !== undefined);
    } catch {
        return false;
    }
}

if (!certificateValid()) {
    mkdirSync(directory, { recursive: true });
    const gitOpenSSL = path.join(process.env.ProgramFiles ?? 'C:\\Program Files', 'Git', 'usr', 'bin', 'openssl.exe');
    const executable = process.platform === 'win32' && existsSync(gitOpenSSL) ? gitOpenSSL : 'openssl';
    const result = spawnSync(executable, [
        'req', '-x509', '-newkey', 'rsa:2048', '-sha256', '-nodes', '-days', '30',
        '-keyout', key, '-out', cert, '-subj', '/CN=Arena local',
        '-addext', `subjectAltName=DNS:localhost,${addresses.map(address => `IP:${address}`).join(',')}`,
    ], { encoding: 'utf8', windowsHide: true });
    if (result.error || result.status !== 0) {
        throw new Error('Не удалось создать HTTPS-сертификат. Установите OpenSSL (в Windows входит в Git for Windows).', { cause: result.error ?? result.stderr });
    }
}

console.log('Локальный HTTPS: при первом открытии подтвердите исключение для сертификата на каждом устройстве.');
process.env.ARENA_DEV_HTTPS = '1';
process.argv = [process.execPath, fileURLToPath(new URL('./run-framework.mjs', import.meta.url)),
    'dev', '--hostname', '0.0.0.0', ...process.argv.slice(2)];
await import('./run-framework.mjs');
