import {test} from 'node:test';import assert from 'node:assert/strict';import {database,request,pair} from './support.mjs';import {handleRooms} from '../rooms.mjs';
test('two seats and private state',async()=>{const db=database(),[a,b]=await pair(db);assert.equal(a.seat,0);assert.equal(b.seat,1);assert.notEqual(a.token,b.token);assert.equal((await request(db,'/'+a.code)).status,401);assert.equal((await request(db,'/'+a.code+'/join',{})).status,409);const s=(await request(db,'/'+a.code,undefined,b)).data;assert.equal(s.room.host.fighter,'polina');assert(!JSON.stringify(s).includes('hash'));assert(!JSON.stringify(s).includes(a.token))});
test('Ruslan is accepted for both online seats and survives readiness', async () => {
    const db = database();
    const host = (await request(db, '', { name: 'Ruslan', fighter: 'ruslan' })).data;
    const guest = (await request(db, '/' + host.code + '/join', { fighter: 'ruslan' })).data;
    await request(db, '/' + host.code + '/update', { ready: true }, host);
    const result = await request(db, '/' + host.code + '/update', { ready: true }, guest);
    assert.equal(result.status, 200);
    assert.equal(result.data.room.host.fighter, 'ruslan');
    assert.equal(result.data.room.guest.fighter, 'ruslan');
    assert.equal(result.data.room.status, 'connecting');
});
test('both ready start one shared session; host owns stage',async()=>{const db=database(),[a,b]=await pair(db);assert.equal((await request(db,'/'+a.code+'/update',{stage:'office'},b)).status,403);await request(db,'/'+a.code+'/update',{stage:'office'},a);assert.equal((await request(db,'/'+a.code+'/update',{ready:true},a)).data.room.status,'waiting');const r=(await request(db,'/'+a.code+'/update',{ready:true},b)).data.room;assert.equal(r.status,'connecting');assert.equal(r.session,1);assert(r.seed>0);assert.equal((await request(db,'/'+a.code+'/update',{ready:true},a)).data.room.seed,r.seed)});
test('signals are private to seat and scoped to session',async()=>{const db=database(),[a,b]=await pair(db);await request(db,'/'+a.code+'/update',{ready:true},a);await request(db,'/'+a.code+'/update',{ready:true},b);assert.equal((await request(db,'/'+a.code+'/signal',{session:1,messages:[{type:'offer',sdp:'sdp'},{type:'ice',candidate:{candidate:'c'}}]},a)).status,200);assert.equal((await request(db,'/'+a.code,undefined,a)).data.signals.length,0);const s=(await request(db,'/'+a.code,undefined,b)).data.signals;assert.equal(s.length,2);assert.equal((await request(db,'/'+a.code+'?since='+s[1].id,undefined,b)).data.signals.length,0);assert.equal((await request(db,'/'+a.code+'/signal',{session:0,messages:[{type:'offer'}]},a)).status,409)});
test('return and departure reset readiness and allow another guest',async()=>{const db=database(),[a,b]=await pair(db);await request(db,'/'+a.code+'/update',{ready:true},a);await request(db,'/'+a.code+'/update',{ready:true},b);const r=(await request(db,'/'+a.code+'/update',{ready:false,lobby:true},b)).data.room;assert.equal(r.status,'waiting');assert.equal(r.host.ready,false);await request(db,'/'+a.code,undefined,b,'DELETE');assert.equal((await request(db,'/'+a.code,undefined,a)).data.room.guest,null);assert.equal((await request(db,'/'+a.code,undefined,b)).status,403);const c=(await request(db,'/'+a.code+'/join',{})).data;await request(db,'/'+a.code,undefined,a,'DELETE');assert.equal((await request(db,'/'+a.code,undefined,c)).status,404)});

test('host stays ready through guest joining, selections, departure and rejoining', async () => {
    const db = database();
    const host = (await request(db, '', { name: 'Host' })).data;
    const path = '/' + host.code;
    await request(db, path + '/update', { ready: true }, host);
    const guest = (await request(db, path + '/join', { name: 'Guest' })).data;
    for (const [body, player] of [[{ fighter: 'yusup' }, guest], [{ fighter: 'polina' }, host], [{ stage: 'office' }, host]]) {
        const result = await request(db, path + '/update', body, player);
        assert.equal(result.status, 200);
        assert.equal(result.data.room.host.ready, true);
        assert.equal(result.data.room.guest.ready, false);
    }
    await request(db, path, undefined, guest, 'DELETE');
    const replacement = (await request(db, path + '/join', {})).data;
    const room = (await request(db, path, undefined, replacement)).data.room;
    assert.equal(room.host.ready, true);
    assert.equal(room.stage, 'office');
});

test('concurrent guest fighter and host arena changes do not overwrite each other', async () => {
    const db = database();
    const [host, guest] = await pair(db);
    await Promise.all([
        request(db, '/' + host.code + '/update', { stage: 'office' }, host),
        request(db, '/' + host.code + '/update', { fighter: 'yusup' }, guest),
    ]);
    const room = (await request(db, '/' + host.code, undefined, host)).data.room;
    assert.equal(room.stage, 'office');
    assert.equal(room.guest.fighter, 'yusup');
});

test('a fighter update delayed until match start cannot change the running matchup', async () => {
    const db = database();
    const [host, guest] = await pair(db);
    const path = '/' + host.code + '/update';
    await request(db, path, { ready: true }, guest);
    let release;
    let captured;
    const gate = new Promise(resolve => { release = resolve; });
    const pending = new Promise(resolve => { captured = resolve; });
    const prepare = db.prepare.bind(db);
    db.prepare = sql => {
        const query = prepare(sql);
        if (sql.startsWith('UPDATE rooms SET guest_fighter=?')) {
            const run = query.run.bind(query);
            query.run = async () => { captured(); await gate; return run(); };
        }
        return query;
    };
    const selection = request(db, path, { fighter: 'yusup' }, guest);
    await pending;
    const started = (await request(db, path, { ready: true }, host)).data.room;
    assert.equal(started.status, 'connecting');
    release();
    assert.equal((await selection).status, 409);
    const room = (await request(db, '/' + host.code, undefined, host)).data.room;
    assert.equal(room.guest.fighter, started.guest.fighter);
});

test('cancelling connection clears only own readiness; stale lobby return preserves new readiness', async () => {
    const db = database();
    const [host, guest] = await pair(db);
    const path = '/' + host.code + '/update';
    await request(db, path, { ready: true }, host);
    const connected = (await request(db, path, { ready: true }, guest)).data.room;
    const cancelled = (await request(db, path, { ready: false }, guest)).data.room;
    assert.equal(cancelled.status, 'waiting');
    assert.equal(cancelled.host.ready, true);
    assert.equal(cancelled.guest.ready, false);
    const restarted = (await request(db, path, { ready: true }, guest)).data.room;
    assert.equal(restarted.status, 'connecting');
    const stale = (await request(db, path, { lobby: true, session: connected.session }, host)).data.room;
    assert.equal(stale.session, restarted.session);
    assert.equal(stale.host.ready, true);
    assert.equal(stale.guest.ready, true);
    const returned = (await request(db, path, { lobby: true, session: restarted.session }, host)).data.room;
    assert.equal(returned.status, 'waiting');
    assert.equal(returned.host.ready, false);
    assert.equal(returned.guest.ready, false);
    await request(db, path, { ready: true }, host);
    const duplicate = (await request(db, path, { lobby: true, session: restarted.session }, guest)).data.room;
    assert.equal(duplicate.host.ready, true);
});
test('invalid input and wrong origin rejected',async()=>{const db=database(),[a]=await pair(db);assert.equal((await request(db,'/'+a.code+'/update',{fighter:'bad'},a)).status,400);const r=await handleRooms(new Request('https://arena.test/api/rooms',{method:'POST',headers:{origin:'https://bad.test'},body:'{}'}),db);assert.equal(r.status,403)});

test('leaving while the other player returns to the lobby never causes a server failure', async () => {
    for (const reverse of [false, true]) {
        const db = database();
        const [host, guest] = await pair(db);
        await request(db, '/' + host.code + '/update', { ready: true }, host);
        await request(db, '/' + guest.code + '/update', { ready: true }, guest);
        const leave = () => request(db, '/' + host.code, undefined, host, 'DELETE');
        const back = () => request(db, '/' + guest.code + '/update', { ready: false }, guest);
        const operations = reverse ? [back, leave] : [leave, back];
        const results = await Promise.all(operations.map(operation => operation()));
        assert(results.every(result => [200, 404].includes(result.status)));
    }
});
