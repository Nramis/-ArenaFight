import { PROTOCOL } from './network-core.mjs?v=9-kudesnik';

export class RelayLink {
    constructor({ url, token, onData, onOpen, onFailure, WebSocketClass = globalThis.WebSocket }) {
        Object.assign(this, { onData, onOpen, onFailure, closed: false, ready: false });
        this.socket = new WebSocketClass(url, ['vite-arena-relay', token]);
        this.socket.onmessage = event => {
            if (this.closed || typeof event.data !== 'string' || event.data.length > 4000) return;
            let data;
            try {
                data = JSON.parse(event.data);
            } catch {
                return;
            }
            if (data?.t === 'relay-ready' && !this.ready) {
                this.ready = true;
                this.send({ t: 'hello', protocol: PROTOCOL });
                onOpen();
            } else if (data?.t === 'relay-error') {
                this.fail(data.message || 'Ошибка соединения с сервером');
            } else if (this.ready && data && typeof data === 'object') {
                onData(data);
            }
        };
        this.socket.onclose = () => this.fail('Соединение с сервером закрыто. Вернитесь в комнату.');
        this.socket.onerror = () => this.fail('Не удалось подключиться к серверу игры. Обновите страницу.');
    }

    get isOpen() {
        return !this.closed && this.ready && this.socket.readyState === 1;
    }

    async offer() {}
    async receive() {}

    send(data) {
        if (!this.isOpen) return false;
        if (this.socket.bufferedAmount > 131072) {
            this.fail('Сеть не успевает передавать управление');
            return false;
        }
        this.socket.send(JSON.stringify(data));
        return true;
    }

    fail(message) {
        if (this.closed) return;
        this.close();
        this.onFailure(message);
    }

    close() {
        this.closed = true;
        this.ready = false;
        this.socket.close();
    }
}
