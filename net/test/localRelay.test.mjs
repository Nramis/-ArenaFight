import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { once } from 'node:events';
import WebSocket from 'ws';
import { localRelay } from '../localRelay.mjs';
import { RelayLink } from '../../public/networkRelay.mjs';
import { handleRooms } from '../rooms.mjs';
import { database, pair, request } from './support.mjs';

test('local HTTP server authenticates two WebSockets and relays a game without WebRTC', { timeout: 8000 }, async () => {
    const db = database();
    const [host, guest] = await pair(db);
    await request(db, '/' + host.code + '/update', { ready: true }, host);
    await request(db, '/' + guest.code + '/update', { ready: true }, guest);
    const listener = createServer(async (incoming, outgoing) => {
        const result = await handleRooms(new Request(new URL(incoming.url, 'http://localhost'), { headers: incoming.headers }), db);
        outgoing.writeHead(result.status, Object.fromEntries(result.headers));
        outgoing.end(await result.text());
    });
    const plugin = localRelay();
    plugin.configureServer({ httpServer: listener, config: { server: {} } });
    listener.listen(0, '127.0.0.1');
    await once(listener, 'listening');
    const origin = 'http://127.0.0.1:' + listener.address().port;
    class LocalSocket extends WebSocket {
        constructor(url, protocols) {
            super(url, protocols, { origin });
        }
    }
    const links = [];
    const failures = [];
    try {
        const ready = [];
        const inputs = [];
        for (const player of [host, guest]) {
            ready.push(new Promise((resolve, reject) => {
                const link = new RelayLink({
                    url: origin.replace('http:', 'ws:') + '/api/rooms/' + player.code + '/relay?session=1',
                    token: player.token, WebSocketClass: LocalSocket,
                    onOpen: resolve,
                    onFailure(message) { failures.push(message); reject(new Error(message)); },
                    onData(data) { if (player.seat === 1 && data.t === 'input') inputs.push(data); },
                });
                links.push(link);
            }));
        }
        await Promise.all(ready);
        const received = new Promise(resolve => {
            links[1].socket.addEventListener('message', event => {
                if (JSON.parse(event.data).frame === 125) resolve();
            });
        });
        for (let frame = 6; frame < 126; frame++) assert.equal(links[0].send({ t: 'input', frame, mask: 17 }), true);
        await received;
        assert.equal(inputs.length, 120);
        assert.deepEqual(inputs.at(-1), { t: 'input', frame: 125, mask: 17 });
        assert.equal(failures.length, 0);
        const disconnected = new Promise(resolve => {
            links[1].onFailure = message => { failures.push(message); resolve(); };
        });
        links[0].close();
        await disconnected;
        assert.match(failures[0], /отключился/);
        assert.equal(links[1].isOpen, false);
    } finally {
        for (const link of links) link.close();
        plugin.closeBundle();
        await new Promise(resolve => listener.close(resolve));
    }
});
