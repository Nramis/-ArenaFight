import {test} from 'node:test';import assert from 'node:assert/strict';import {database,request,pair} from './support.mjs';import {handleRooms} from '../rooms.mjs';
test('two seats and private state',async()=>{const db=database(),[a,b]=await pair(db);assert.equal(a.seat,0);assert.equal(b.seat,1);assert.notEqual(a.token,b.token);assert.equal((await request(db,'/'+a.code)).status,401);assert.equal((await request(db,'/'+a.code+'/join',{})).status,409);const s=(await request(db,'/'+a.code,undefined,b)).data;assert.equal(s.room.host.fighter,'polina');assert(!JSON.stringify(s).includes('hash'));assert(!JSON.stringify(s).includes(a.token))});
test('both ready start one shared session; host owns stage',async()=>{const db=database(),[a,b]=await pair(db);assert.equal((await request(db,'/'+a.code+'/update',{stage:'office'},b)).status,403);await request(db,'/'+a.code+'/update',{stage:'office'},a);assert.equal((await request(db,'/'+a.code+'/update',{ready:true},a)).data.room.status,'waiting');const r=(await request(db,'/'+a.code+'/update',{ready:true},b)).data.room;assert.equal(r.status,'connecting');assert.equal(r.session,1);assert(r.seed>0);assert.equal((await request(db,'/'+a.code+'/update',{ready:true},a)).data.room.seed,r.seed)});
test('signals are private to seat and scoped to session',async()=>{const db=database(),[a,b]=await pair(db);await request(db,'/'+a.code+'/update',{ready:true},a);await request(db,'/'+a.code+'/update',{ready:true},b);assert.equal((await request(db,'/'+a.code+'/signal',{session:1,messages:[{type:'offer',sdp:'sdp'},{type:'ice',candidate:{candidate:'c'}}]},a)).status,200);assert.equal((await request(db,'/'+a.code,undefined,a)).data.signals.length,0);const s=(await request(db,'/'+a.code,undefined,b)).data.signals;assert.equal(s.length,2);assert.equal((await request(db,'/'+a.code+'?since='+s[1].id,undefined,b)).data.signals.length,0);assert.equal((await request(db,'/'+a.code+'/signal',{session:0,messages:[{type:'offer'}]},a)).status,409)});
test('return and departure reset readiness and allow another guest',async()=>{const db=database(),[a,b]=await pair(db);await request(db,'/'+a.code+'/update',{ready:true},a);await request(db,'/'+a.code+'/update',{ready:true},b);const r=(await request(db,'/'+a.code+'/update',{ready:false},b)).data.room;assert.equal(r.status,'waiting');assert.equal(r.host.ready,false);await request(db,'/'+a.code,undefined,b,'DELETE');assert.equal((await request(db,'/'+a.code,undefined,a)).data.room.guest,null);assert.equal((await request(db,'/'+a.code,undefined,b)).status,403);const c=(await request(db,'/'+a.code+'/join',{})).data;await request(db,'/'+a.code,undefined,a,'DELETE');assert.equal((await request(db,'/'+a.code,undefined,c)).status,404)});
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
