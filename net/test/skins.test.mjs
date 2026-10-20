import {test} from 'node:test';
import assert from 'node:assert/strict';
import {database,request,pair} from './support.mjs';
import {skinOptions,validSkin} from '../../public/skins.mjs';

test('skins are restricted to their fighter and default safely',()=>{
    assert.deepEqual(skinOptions('rinat'),['default','scorpion']);
    assert.deepEqual(skinOptions('vladislav'),['default','paquito']);
    assert.equal(validSkin('nikita','scorpion'),'default');
    assert.equal(validSkin('rinat','paquito'),'default');
});

test('both players retain their own skin through ready, match and lobby return',async()=>{
    const db=database();
    const host=(await request(db,'',{fighter:'rinat',skin:'scorpion'})).data;
    const guest=(await request(db,'/'+host.code+'/join',{fighter:'vladislav',skin:'paquito'})).data;
    const path='/'+host.code;
    await request(db,path+'/update',{ready:true},host);
    const connected=(await request(db,path+'/update',{ready:true},guest)).data.room;
    assert.equal(connected.host.skin,'scorpion');
    assert.equal(connected.guest.skin,'paquito');
    assert.equal(connected.status,'connecting');
    assert.equal((await request(db,path+'/update',{skin:'default'},host)).status,409);
    const returned=(await request(db,path+'/update',{lobby:true,session:connected.session},host)).data.room;
    assert.equal(returned.host.skin,'scorpion');
    assert.equal(returned.guest.skin,'paquito');
});

test('changing fighter clears incompatible skin and rejects invalid skin writes',async()=>{
    const db=database(),[host]=await pair(db),path='/'+host.code+'/update';
    let r=await request(db,path,{fighter:'rinat',skin:'scorpion'},host);
    assert.equal(r.status,200);
    assert.equal(r.data.room.host.skin,'scorpion');
    assert.equal((await request(db,path,{skin:'paquito'},host)).status,400);
    r=await request(db,path,{fighter:'nikita'},host);
    assert.equal(r.data.room.host.skin,'default');
    r=await request(db,path,{fighter:'vladislav',skin:'paquito'},host);
    assert.equal(r.data.room.host.skin,'paquito');
});

test('skin updates preserve the other seat and readiness',async()=>{
    const db=database(),[a,b]=await pair(db),path='/'+a.code;
    await request(db,path+'/update',{fighter:'rinat',ready:true},a);
    await request(db,path+'/update',{fighter:'vladislav',skin:'paquito'},b);
    const r=(await request(db,path+'/update',{skin:'scorpion'},a)).data.room;
    assert.equal(r.host.ready,true);
    assert.equal(r.host.skin,'scorpion');
    assert.equal(r.guest.skin,'paquito');
});
