export const RELAY_PROTOCOL = 'vite-arena-relay';
const messageTypes = new Set(['hello', 'prepare', 'loaded', 'go', 'input', 'checksum', 'ping', 'pong', 'lobby']);
const fail = (message, status) => { throw Object.assign(new Error(message), { status }); };

export async function authorizeRelay(request, readRoom) {
    const url = new URL(request.url);
    const match = /^\/api\/rooms\/([A-HJ-NP-Z2-9]{6})\/relay$/.exec(url.pathname);
    if (!match) fail('Не найдено', 404);
    if (request.headers.get('upgrade')?.toLowerCase() !== 'websocket') fail('Нужно WebSocket-соединение', 426);
    if (request.headers.get('origin') !== url.origin) fail('Недопустимый источник', 403);
    const protocols = (request.headers.get('sec-websocket-protocol') ?? '').split(',').map(value => value.trim());
    if (protocols.length !== 2 || protocols[0] !== RELAY_PROTOCOL || !/^[a-f0-9]{32}$/.test(protocols[1])) fail('Нужен ключ игрока', 401);
    const code = match[1];
    const session = Number(url.searchParams.get('session'));
    const data = await readRoom(code, protocols[1]);
    if (![0, 1].includes(data.seat)) fail('Неверный ключ игрока', 403);
    if (data.room.status !== 'connecting' || !Number.isInteger(session) || session !== data.room.session) fail('Сессия устарела', 409);
    return {
        code, session, seat: data.seat,
        async validate() {
            const current = await readRoom(code, protocols[1]);
            return current.room.session === session && current.room.status === 'connecting' && current.seat === data.seat;
        },
    };
}

export class RelaySessions {
    groups = new Map();

    has(identity) {
        return this.groups.get(identity.code + ':' + identity.session)?.sockets.has(identity.seat) ?? false;
    }

    close(group, message) {
        if (group.closed) return;
        group.closed = true;
        clearTimeout(group.timeout);
        clearInterval(group.validation);
        this.groups.delete(group.key);
        for (const socket of group.sockets.values()) {
            try {
                socket.send(JSON.stringify({ t: 'relay-error', message }));
                socket.close(1000, message);
            } catch {
                // The other socket may already be closed.
            }
        }
    }

    attach(identity, socket) {
        if (this.has(identity)) throw new Error('Игрок уже подключён');
        const key = identity.code + ':' + identity.session;
        let group = this.groups.get(key);
        if (!group) {
            group = { key, sockets: new Map(), identities: [], closed: false, timeout: null, validation: null };
            this.groups.set(key, group);
            const current = group;
            group.timeout = setTimeout(() => this.close(current, 'Соперник не подключился к серверу'), 25000);
            group.validation = setInterval(async () => {
                try {
                    if (!(await Promise.all(current.identities.map(player => player.validate()))).every(Boolean)) {
                        this.close(current, 'Комната или сессия закрыта');
                    }
                } catch {
                    this.close(current, 'Не удалось проверить состояние комнаты');
                }
            }, 10000);
            group.timeout.unref?.();
            group.validation.unref?.();
        }
        group.sockets.set(identity.seat, socket);
        group.identities.push(identity);
        let windowStart = Date.now();
        let count = 0;
        socket.addEventListener('message', event => {
            if (group.closed) return;
            if (Date.now() - windowStart >= 1000) {
                windowStart = Date.now();
                count = 0;
            }
            if (++count > 240 || typeof event.data !== 'string' || event.data.length > 4000) {
                this.close(group, 'Превышен лимит сетевых сообщений');
                return;
            }
            let data;
            try {
                data = JSON.parse(event.data);
            } catch {
                this.close(group, 'Неверное сетевое сообщение');
                return;
            }
            if (!data || !messageTypes.has(data.t)) {
                this.close(group, 'Неверное сетевое сообщение');
                return;
            }
            const other = group.sockets.get(1 - identity.seat);
            if (other) {
                try {
                    if (other.bufferedAmount > 131072) throw new Error('Backpressure');
                    other.send(event.data);
                } catch {
                    this.close(group, 'Сеть соперника не успевает принимать данные');
                }
            }
        });
        socket.addEventListener('close', () => this.close(group, 'Соперник отключился от сервера'));
        socket.addEventListener('error', () => this.close(group, 'Ошибка соединения с сервером'));
        if (group.sockets.size === 2) {
            clearTimeout(group.timeout);
            group.timeout = setTimeout(() => this.close(group, 'Срок действия комнаты истёк'), 1800000);
            group.timeout.unref?.();
            for (const peer of group.sockets.values()) peer.send(JSON.stringify({ t: 'relay-ready' }));
        }
    }

    closeAll() {
        for (const group of this.groups.values()) this.close(group, 'Сервер игры остановлен');
    }
}
