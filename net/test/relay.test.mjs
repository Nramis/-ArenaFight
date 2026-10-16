import { test } from 'node:test';
import assert from 'node:assert/strict';
import { authorizeRelay, RelaySessions, RELAY_PROTOCOL } from '../relaySessions.mjs';
import { RelayLink } from '../../public/networkRelay.mjs';
import { database, pair, request } from './support.mjs';

class Socket {
    readyState = 1;
    bufferedAmount = 0;
    messages = [];
    listeners = new Map();
    accept() {}
    addEventListener(type, listener) {
        this.listeners.set(type, listener);
    }
    send(data) {
        if (this.readyState !== 1) throw new Error('Socket closed');
        this.other.messages.push(JSON.parse(data));
        this.other.listeners.get('message')?.({ data });
    }
    close() {
        if (this.readyState === 3) return;
        this.readyState = 3;
        this.listeners.get('close')?.({});
    }
}

function relay() {
    const sessions = new RelaySessions();
    return async (upgradeRequest, db) => {
        try {
            const identity = await authorizeRelay(upgradeRequest, async (code, token) => {
                const result = await request(db, '/' + code, undefined, { token });
                if (result.status !== 200) throw Object.assign(new Error(result.data.error), { status: result.status });
                return result.data;
            });
            if (sessions.has(identity)) return { status: 409 };
            const client = new Socket();
            const server = new Socket();
            client.other = server;
            server.other = client;
            sessions.attach(identity, server);
            return { status: 101, webSocket: client };
        } catch (error) {
            return { status: error.status ?? 500 };
        }
    };
}

function upgrade(player, { session = 1, origin = 'https://arena.test', token = player.token } = {}) {
    return new Request(`https://arena.test/api/rooms/${player.code}/relay?session=${session}`, {
        headers: { Upgrade: 'websocket', Origin: origin, 'Sec-WebSocket-Protocol': `${RELAY_PROTOCOL}, ${token}` },
    });
}

async function room() {
    const db = database();
    const [host, guest] = await pair(db);
    await request(db, '/' + host.code + '/update', { ready: true }, host);
    await request(db, '/' + host.code + '/update', { ready: true }, guest);
    return { db, host, guest };
}

test('local relay pairs authenticated seats and forwards ordered game messages', async () => {
    const { db, host, guest } = await room();
    const handle = relay();
    const a = await handle(upgrade(host), db);
    const b = await handle(upgrade(guest), db);
    try {
        assert.equal(a.status, 101);
        assert.equal(b.status, 101);
        assert.deepEqual(a.webSocket.messages, [{ t: 'relay-ready' }]);
        assert.deepEqual(b.webSocket.messages, [{ t: 'relay-ready' }]);
        for (let frame = 6; frame < 206; frame++) {
            a.webSocket.send(JSON.stringify({ t: 'input', frame, mask: 17 }));
        }
        assert.equal(b.webSocket.messages.length, 201);
        assert.deepEqual(b.webSocket.messages.at(-1), { t: 'input', frame: 205, mask: 17 });
        b.webSocket.send(JSON.stringify({ t: 'loaded' }));
        assert.deepEqual(a.webSocket.messages.at(-1), { t: 'loaded' });
        assert.equal((await handle(upgrade(host), db)).status, 409);
    } finally {
        a.webSocket.other.close();
    }
    assert.equal(b.webSocket.other.readyState, 3);
});

test('relay rejects wrong origin, token, session and rooms that are not ready', async () => {
    const { db, host } = await room();
    const handle = relay();
    assert.equal((await handle(upgrade(host, { origin: 'https://evil.test' }), db)).status, 403);
    assert.equal((await handle(upgrade(host, { token: 'a'.repeat(32) }), db)).status, 403);
    assert.equal((await handle(upgrade(host, { token: '' }), db)).status, 401);
    assert.equal((await handle(upgrade(host, { session: 0 }), db)).status, 409);
    await request(db, '/' + host.code + '/update', { ready: false }, host);
    assert.equal((await handle(upgrade(host, { session: 2 }), db)).status, 409);
});

test('relay rejects oversized packets and closes both seats', async () => {
    const { db, host, guest } = await room();
    const handle = relay();
    const a = await handle(upgrade(host), db);
    const b = await handle(upgrade(guest), db);
    try {
        a.webSocket.send(JSON.stringify({ t: 'input', payload: 'x'.repeat(4001) }));
        assert.equal(a.webSocket.other.readyState, 3);
        assert.equal(b.webSocket.other.readyState, 3);
        assert.equal(b.webSocket.messages.at(-1).t, 'relay-error');
    } finally {
        a.webSocket.other.close();
    }
});

test('relay never forwards packets between different rooms', async () => {
    const first = await room();
    const [secondHost, secondGuest] = await pair(first.db);
    await request(first.db, '/' + secondHost.code + '/update', { ready: true }, secondHost);
    await request(first.db, '/' + secondGuest.code + '/update', { ready: true }, secondGuest);
    const handle = relay();
    const a = await handle(upgrade(first.host), first.db);
    const b = await handle(upgrade(secondGuest), first.db);
    try {
        a.webSocket.send(JSON.stringify({ t: 'input', frame: 6, mask: 17 }));
        assert.equal(b.webSocket.messages.length, 0);
    } finally {
        a.webSocket.other.close();
        b.webSocket.other.close();
    }
});

class BrowserSocket {
    readyState = 1;
    bufferedAmount = 0;
    sent = [];
    constructor(url, protocols) {
        this.url = url;
        this.protocols = protocols;
    }
    send(data) { this.sent.push(JSON.parse(data)); }
    close() { this.readyState = 3; this.onclose?.(); }
    receive(data) { this.onmessage?.({ data: JSON.stringify(data) }); }
}

test('relay client starts only when both seats are connected and sends the game protocol', () => {
    let opened = 0;
    const messages = [];
    const failures = [];
    const link = new RelayLink({
        url: 'wss://arena.test/api/rooms/ABC234/relay?session=1', token: 'a'.repeat(32),
        onOpen: () => opened++, onData: message => messages.push(message), onFailure: message => failures.push(message),
        WebSocketClass: BrowserSocket,
    });
    assert.equal(link.send({ t: 'input' }), false);
    assert.equal(link.socket.url.includes('a'.repeat(32)), false);
    link.socket.receive({ t: 'relay-ready' });
    assert.equal(link.isOpen, true);
    assert.equal(opened, 1);
    assert.equal(link.socket.sent[0].t, 'hello');
    link.socket.receive({ t: 'input', frame: 6, mask: 17 });
    assert.deepEqual(messages, [{ t: 'input', frame: 6, mask: 17 }]);
    link.close();
    assert.equal(failures.length, 0);
});

test('relay client reports server failure once and stops sending', () => {
    const failures = [];
    const link = new RelayLink({ url: 'wss://arena.test/', token: 'a'.repeat(32), onOpen() {}, onData() {}, onFailure: message => failures.push(message), WebSocketClass: BrowserSocket });
    link.socket.receive({ t: 'relay-error', message: 'Room closed' });
    assert.deepEqual(failures, ['Room closed']);
    assert.equal(link.send({ t: 'input' }), false);
});
