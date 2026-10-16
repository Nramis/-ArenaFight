import http from 'node:http';
import https from 'node:https';
import { WebSocketServer } from 'ws';
import { authorizeRelay, RelaySessions, RELAY_PROTOCOL } from './relaySessions.mjs';

/** @returns {import('vite').Plugin} */
export function localRelay() {
    const sessions = new RelaySessions();
    // The vite prefix tells the Cloudflare adapter that this socket is owned by
    // the local dev server. It is distinct from Vite's own vite-hmr protocol.
    const sockets = new WebSocketServer({ noServer: true, maxPayload: 4096, handleProtocols: protocols => protocols.has(RELAY_PROTOCOL) ? RELAY_PROTOCOL : false });

    return {
        name: 'arena-local-relay',
        apply: 'serve',
        configureServer(server) {
            const listener = server.httpServer;
            if (!listener) return;
            const secure = Boolean(server.config.server.https);

            function readRoom(code, token) {
                return new Promise((resolve, reject) => {
                    const address = listener.address();
                    if (!address || typeof address === 'string') return reject(new Error('Сервер ещё не запущен'));
                    const client = secure ? https : http;
                    const request = client.request({
                        hostname: '127.0.0.1', port: address.port,
                        path: '/api/rooms/' + code, method: 'GET',
                        // This request is restricted to this process's loopback
                        // port; its local certificate is self-signed.
                        rejectUnauthorized: false,
                        headers: { Authorization: 'Bearer ' + token },
                    }, response => {
                        let body = '';
                        response.setEncoding('utf8');
                        response.on('data', chunk => {
                            body += chunk;
                            if (body.length > 32768) request.destroy(new Error('Слишком большой ответ API'));
                        });
                        response.on('error', reject);
                        response.on('end', () => {
                            try {
                                const data = JSON.parse(body);
                                if (response.statusCode !== 200) throw Object.assign(new Error(data.error ?? 'Комната недоступна'), { status: response.statusCode });
                                resolve(data);
                            } catch (error) {
                                reject(error);
                            }
                        });
                    });
                    request.setTimeout(5000, () => request.destroy(new Error('API комнат не отвечает')));
                    request.on('error', reject);
                    request.end();
                });
            }

            listener.on('upgrade', async (request, socket, head) => {
                if (!/^\/api\/rooms\/[A-HJ-NP-Z2-9]{6}\/relay(?:\?|$)/.test(request.url ?? '')) return;
                socket.on('error', () => socket.destroy());
                try {
                    const url = new URL(request.url, `${secure ? 'https' : 'http'}://${request.headers.host}`);
                    const headers = new Headers();
                    for (const name of ['upgrade', 'origin', 'sec-websocket-protocol']) {
                        const value = request.headers[name];
                        if (typeof value === 'string') headers.set(name, value);
                    }
                    const identity = await authorizeRelay(new Request(url, { headers }), readRoom);
                    if (sessions.has(identity)) throw Object.assign(new Error('Игрок уже подключён'), { status: 409 });
                    sockets.handleUpgrade(request, socket, head, peer => {
                        sessions.attach(identity, peer);
                    });
                } catch (error) {
                    const status = error.status ?? 503;
                    const body = JSON.stringify({ error: status === 503 ? 'Сервер игры недоступен' : error.message });
                    socket.end(`HTTP/1.1 ${status} Error\r\nConnection: close\r\nContent-Type: application/json\r\nContent-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`);
                }
            });
        },
        closeBundle() {
            sessions.closeAll();
            for (const peer of sockets.clients) peer.terminate();
            sockets.close();
        },
    };
}
