import {test} from 'node:test';import assert from 'node:assert/strict';import vm from 'node:vm';import {readFileSync} from 'node:fs';import {database} from './support.mjs';import {handleRooms} from '../rooms.mjs';import {PeerLink as Core,PROTOCOL} from '../../public/network-core.mjs';
class Element{constructor(){this.value='';this.hidden=false;this.disabled=false;this.children=[];this.dataset={};this.style={};this.textContent='';this.parts={};this.classList={toggle:()=>{}}}append(...e){this.children.push(...e)}querySelector(s){return this.parts[s]??=new Element}focus(){}setAttribute(name,value){this[name]=value}}
let pcs=[];
class Channel{readyState='connecting';bufferedAmount=0;send(s){queueMicrotask(()=>this.other?.onmessage?.({data:s}))}close(){this.readyState='closed'}}
class PC{remoteDescription=null;localDescription=null;constructor(){this.id=pcs.length;pcs.push(this)}createDataChannel(){return this.channel=new Channel}async createOffer(){return {type:'offer',sdp:String(this.id)}}async createAnswer(){return {type:'answer',sdp:String(this.id)}}async setLocalDescription(d){this.localDescription=d}async setRemoteDescription(d){this.remoteDescription=d;if(d.type==='answer'){const b=pcs[Number(d.sdp)];b.channel=new Channel;this.channel.other=b.channel;b.channel.other=this.channel;b.ondatachannel({channel:b.channel});queueMicrotask(()=>{for(const p of [this,b]){p.channel.readyState='open';p.channel.onopen?.()}})}}async addIceCandidate(){}close(){}}
class PeerLink extends Core{constructor(o){super({...o,RTCPeerConnectionClass:PC})}}
async function client(db,name,{secure=true,fetchRequest}={}){const els=new Map,$=id=>{if(!els.has(id))els.set(id,new Element);return els.get(id)},listeners={},intervals=[],storage=new Map,starts=[],messages=[];const roster=Object.fromEntries(['rafael','nikita','vladislav','mavrin','ramis','ilgiz','bigboss','azat','polina','yusup'].map(id=>[id,{name:id}]));$('netName').value=name;$('fighter1').value='polina';$('arenaStage').value='office';const hooks={roster,lock:()=>{},stop:()=>{},start:(c,seat)=>{hooks.run=c.run;starts.push({c,seat})},message:d=>messages.push(d)},window={ArenaOnlineHooks:hooks,addEventListener:(t,f)=>(listeners[t]??=[]).push(f)},context=vm.createContext({window,document:{getElementById:$,createElement:()=>new Element,createTextNode:s=>({textContent:s}),body:new Element},location:{origin:'https://arena.test',search:''},isSecureContext:secure,navigator:{clipboard:{writeText:async()=>{}}},sessionStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)},RTCPeerConnection:PC,fetch:(url,o)=>{const dispatch=()=>handleRooms(new Request(new URL(url,'https://arena.test'),o),db);return fetchRequest?fetchRequest(url,o,dispatch):dispatch()},Request,Response,AbortController,URL,URLSearchParams,performance,Date,console,setTimeout,clearTimeout,setInterval:(f,ms)=>intervals.push({f,ms})});const module=new vm.SourceTextModule(readFileSync('public/network.mjs','utf8'),{context});await module.link(specifier=>specifier.includes("networkBrowser")?new vm.SourceTextModule(readFileSync("public/networkBrowser.mjs","utf8"),{context}):specifier.includes("networkRelay")?new vm.SourceTextModule(readFileSync("public/networkRelay.mjs","utf8"),{context}):new vm.SyntheticModule(['PeerLink','PROTOCOL'],function(){this.setExport('PeerLink',PeerLink);this.setExport('PROTOCOL',PROTOCOL)},{context}));await module.evaluate();return {$,starts,messages,async pump(ms){for(const t of intervals)if(t.ms===ms)await t.f();await new Promise(setImmediate)},emit(d){for(const f of listeners.message||[])f({origin:'https://arena.test',source:$('game').contentWindow,data:{...d,run:hooks.run}})}}}
test('two clients create join ready connect load exchange input and return',async()=>{pcs=[];const db=database(),a=await client(db,'A'),b=await client(db,'B');await a.$('netCreate').onclick();b.$('netJoinCode').value=a.$('netCode').textContent;await b.$('netJoin').onclick();await a.pump(1000);await a.$('netReady').onclick();await b.$('netReady').onclick();for(let i=0;i<8;i++){await a.pump(1000);await b.pump(1000);await a.pump(180);await b.pump(180)}assert.equal(a.starts.length,1);assert.equal(b.starts.length,1);assert.equal(JSON.stringify(a.starts[0].c),JSON.stringify(b.starts[0].c));a.emit({type:'arena-network-loaded'});b.emit({type:'arena-network-loaded'});await new Promise(setImmediate);assert(a.messages.some(m=>m.type==='arena-network-go'));assert(b.messages.some(m=>m.type==='arena-network-go'));a.emit({type:'arena-network-input',frame:6,mask:17});await new Promise(setImmediate);assert(b.messages.some(m=>m.type==='arena-network-input'&&m.mask===17));await a.$('netBack').onclick();await new Promise(setImmediate);await a.pump(1000);await b.pump(1000);assert.equal(a.$('netHud').hidden,true);assert.equal(b.$('netHud').hidden,true);await b.$('netLeave').onclick();await a.$('netLeave').onclick()});

test('HTTP LAN readiness explains the HTTPS requirement before connecting', async () => {
    const db = database();
    const player = await client(db, 'HTTP player', { secure: false });
    await player.$('netCreate').onclick();
    await player.$('netReady').onclick();
    assert.match(player.$('netStatus').textContent, /HTTPS/);
    await player.pump(1000);
    assert.match(player.$('netSeat0').querySelector('small').textContent, /Выбирает бойца/);
    assert.equal(player.starts.length, 0);
    await player.$('netLeave').onclick();
});

test('ready button persists through joining, selection changes and an older poll response', async () => {
    const db = database();
    let holdPoll = false;
    let releasePoll;
    let pollCaptured;
    const captured = new Promise(resolve => { pollCaptured = resolve; });
    const host = await client(db, 'Host', {
        async fetchRequest(url, options, dispatch) {
            const response = await dispatch();
            if (holdPoll && options.method === 'GET') {
                holdPoll = false;
                pollCaptured();
                await new Promise(resolve => { releasePoll = resolve; });
            }
            return response;
        },
    });
    await host.$('netCreate').onclick();
    holdPoll = true;
    const olderPoll = host.pump(1000);
    await captured;
    await host.$('netReady').onclick();
    assert.equal(host.$('netReady')['aria-pressed'], 'true');
    releasePoll();
    await olderPoll;
    assert.equal(host.$('netReady')['aria-pressed'], 'true');
    const guest = await client(db, 'Guest');
    guest.$('netJoinCode').value = host.$('netCode').textContent;
    await guest.$('netJoin').onclick();
    await host.pump(1000);
    assert.equal(host.$('netReady')['aria-pressed'], 'true');
    await guest.$('netFighters').children.find(card => card.dataset.fighter === 'yusup').onclick();
    host.$('netStage').value = 'rooftop';
    await host.$('netStage').onchange();
    await host.pump(1000);
    assert.equal(host.$('netReady')['aria-pressed'], 'true');
    await guest.$('netLeave').onclick();
    await host.pump(1000);
    assert.equal(host.$('netReady')['aria-pressed'], 'true');
    await host.$('netLeave').onclick();
});

test('returning to a room disables readiness until the server confirms the return', async () => {
    pcs = [];
    const db = database();
    let releaseReturn;
    let returnCaptured;
    let readyRequests = 0;
    const returned = new Promise(resolve => { returnCaptured = resolve; });
    const host = await client(db, 'Host', {
        async fetchRequest(url, options, dispatch) {
            const body = options.body ? JSON.parse(options.body) : {};
            if (typeof body.ready === 'boolean' && !body.lobby) readyRequests++;
            const response = await dispatch();
            if (body.lobby) {
                returnCaptured();
                await new Promise(resolve => { releaseReturn = resolve; });
            }
            return response;
        },
    });
    const guest = await client(db, 'Guest');
    await host.$('netCreate').onclick();
    guest.$('netJoinCode').value = host.$('netCode').textContent;
    await guest.$('netJoin').onclick();
    await host.$('netReady').onclick();
    await guest.$('netReady').onclick();
    for (let i = 0; i < 8; i++) {
        await host.pump(1000); await guest.pump(1000);
        await host.pump(180); await guest.pump(180);
    }
    assert.equal(host.starts.length, 1);
    const back = host.$('netBack').onclick();
    await returned;
    assert.equal(host.$('netReady').disabled, true);
    await host.$('netReady').onclick();
    assert.equal(readyRequests, 1);
    releaseReturn();
    await back;
    assert.equal(host.$('netReady').disabled, false);
    assert.equal(host.$('netReady')['aria-pressed'], 'false');
    await guest.$('netLeave').onclick();
    await host.$('netLeave').onclick();
});
