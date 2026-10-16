import { test } from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';

async function browser({ clipboard, copyResult = true } = {}) {
    const state = { copied: '', fallbackCalls: 0, removed: false, focused: false, selection: null };
    const input = {
        style: {},
        focus() {},
        select() {},
        setSelectionRange(start, end) { state.selection = [start, end]; },
        remove() { state.removed = true; },
    };
    const context = vm.createContext({
        navigator: { clipboard },
        document: {
            activeElement: { focus() { state.focused = true; } },
            createElement: () => input,
            body: { append() {} },
            execCommand(command) {
                assert.equal(command, 'copy');
                state.fallbackCalls++;
                state.copied = input.value;
                return copyResult;
            },
        },
    });
    const module = new vm.SourceTextModule(readFileSync('public/networkBrowser.mjs', 'utf8'), { context });
    await module.link(() => { throw new Error('Unexpected import'); });
    await module.evaluate();
    return { copy: module.namespace.copyInvitation, state };
}

test('invitation uses the clipboard API when available', async () => {
    let copied = '';
    const client = await browser({ clipboard: { async writeText(text) { copied = text; } } });
    assert.equal(await client.copy('https://arena.test/?room=ABC234'), true);
    assert.equal(copied, 'https://arena.test/?room=ABC234');
    assert.equal(client.state.fallbackCalls, 0);
});

test('HTTP LAN invitation falls back to copying a selection and restores focus', async () => {
    const client = await browser();
    const invitation = 'http://10.20.10.45:5173/?room=ABC234';
    assert.equal(await client.copy(invitation), true);
    assert.equal(client.state.copied, invitation);
    assert.deepEqual(client.state.selection, [0, invitation.length]);
    assert.equal(client.state.removed, true);
    assert.equal(client.state.focused, true);
});

test('denied clipboard permission falls back to copying a selection', async () => {
    const client = await browser({ clipboard: { async writeText() { throw new Error('Denied'); } } });
    assert.equal(await client.copy('invitation'), true);
    assert.equal(client.state.copied, 'invitation');
});

test('failed copying reports failure so the UI can offer manual copying', async () => {
    const client = await browser({ copyResult: false });
    assert.equal(await client.copy('invitation'), false);
    assert.equal(client.state.removed, true);
});
