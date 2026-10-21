import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {database,request,pair} from './support.mjs';
import {skinOptions,validSkin,skinNames,portraitUrl} from '../../public/skins.mjs';

const extraSkins = {
    rafael:'neon_champion',nikita:'water_shinobi',vladislav:'luchador',mavrin:'disco_coach',
    ramis:'solar_knight',ilgiz:'forest_ranger',bigboss:'cheese_baron',azat:'catboy',
    polina:'storm_witch',yusup:'polar_penguin',rinat:'ice_ninja'
};

test('skins are restricted to their fighter and default safely',()=>{
    assert.deepEqual(skinOptions('rinat'),['default','scorpion','ice_ninja']);
    assert.deepEqual(skinOptions('vladislav'),['default','paquito','luchador']);
    assert.equal(validSkin('nikita','scorpion'),'default');
    assert.equal(validSkin('rinat','paquito'),'default');
});

test('all eleven fighters have their own additional cosmetic, matching Godot selection',()=>{
    const godot = readFileSync(new URL('../../game/core/skins.gd',import.meta.url),'utf8');
    const ids = JSON.parse(godot.match(/const IDS := (\{[\s\S]*?\n\})/)[1]);
    const names = JSON.parse(godot.match(/const NAMES := (\{[\s\S]*?\n\})/)[1]);
    assert.equal(Object.keys(extraSkins).length,11);
    for(const [fighter,skin] of Object.entries(extraSkins)){
        assert.deepEqual(skinOptions(fighter),ids[fighter]);
        assert.equal(validSkin(fighter,skin),skin);
        assert.equal(skinNames[skin],names[skin]);
        assert.equal(portraitUrl(fighter,skin),'portraits/'+fighter+'.png');
        for(const other of Object.keys(extraSkins)){
            if(other!==fighter) assert.equal(validSkin(other,skin),'default');
        }
    }
    assert.deepEqual(skinOptions('__proto__'),['default']);
    assert.deepEqual(skinOptions('constructor'),['default']);
    assert.equal(portraitUrl('rinat','scorpion'),'portraits/rinat-scorpion.png');
    assert.equal(portraitUrl('vladislav','paquito'),'portraits/vlad-paquito.png');
});

test('each new skin survives room creation and fighter changes clear it',async()=>{
    const db=database();
    for(const [fighter,skin] of Object.entries(extraSkins)){
        const host=(await request(db,'',{fighter,skin})).data;
        const initial=(await request(db,'/'+host.code,undefined,host)).data.room;
        assert.equal(initial.host.skin,skin);
        const other=fighter==='nikita'?'rafael':'nikita';
        const updated=await request(db,'/'+host.code+'/update',{fighter:other},host);
        assert.equal(updated.status,200);
        assert.equal(updated.data.room.host.skin,'default');
    }
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
