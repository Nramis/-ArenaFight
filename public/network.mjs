import {PeerLink,PROTOCOL} from './network-core.mjs?v=7';
import {copyInvitation} from './networkBrowser.mjs?v=1';
import {RelayLink} from './networkRelay.mjs?v=3';
const $=id=>document.getElementById(id),hooks=window.ArenaOnlineHooks,roster=hooks.roster;
let auth=null,room=null,link=null,cursor=0,session=-1,polling=false,busy=false,signals=[],flushing=false,playing=false,returning=false,prepared=false,localLoaded=false,remoteLoaded=false,went=false,timer=null,lastPong=0,relayAvailable=false,roomRevision=0,handlingFailure=false;
function info(s,error=false){$('netStatus').textContent=s;$('netStatus').classList.toggle('error',error)}
function remember(){try{auth?sessionStorage.setItem('arena-room',JSON.stringify(auth)):sessionStorage.removeItem('arena-room')}catch{}}
async function api(path='',body,method){const abort=new AbortController(),timeout=setTimeout(()=>abort.abort(),10000);try{const r=await fetch('/api/rooms'+path,{method:method||(body?'POST':'GET'),headers:{...(body?{'Content-Type':'application/json'}:{}),...(auth?{Authorization:'Bearer '+auth.token}:{})},body:body?JSON.stringify(body):undefined,signal:abort.signal,cache:'no-store'}),d=await r.json();if(!r.ok)throw Object.assign(new Error(d.error||'Ошибка сервера'),{status:r.status});return d}finally{clearTimeout(timeout)}}
function show(){hooks.openLobby?.();$('netDialog').hidden=false;$('netTitle').focus();render()}
function waitingStatus(){const mine=auth?.seat===0?room?.host:room?.guest;return mine?.ready?'Ты готов. Ждём готовности соперника.':'Выбери бойца и нажми «Я готов»'}
function lock(value){hooks.lock(value);document.body.classList.toggle('network-active',value)}
function render(){
 $('netEntry').hidden=!!auth;$('netRoom').hidden=!auth;if(!auth||!room)return;
 $('netCode').textContent=room.code;$('netShare').textContent=location.origin+'/?room='+room.code;
 for(const [i,p] of [room.host,room.guest].entries()){const node=$('netSeat'+i);node.classList.toggle('is-ready',!!p?.ready);node.querySelector('strong').textContent=p?p.name+(i===auth.seat?' · ты':''):'Ждём друга…';node.querySelector('small').textContent=p?roster[p.fighter].name+' · '+(p.ready?'ГОТОВ':'Выбирает бойца'):'Отправь другу приглашение';}
 const mine=auth.seat===0?room.host:room.guest;for(const c of $('netFighters').children){c.classList.toggle('chosen',c.dataset.fighter===mine?.fighter);c.disabled=busy||returning||room.status!=='waiting'}
 $('netStage').value=room.stage;$('netStage').disabled=busy||returning||auth.seat!==0||room.status!=='waiting';$('netReady').textContent=mine?.ready?'ГОТОВ ✓ · ОТМЕНИТЬ':'Я ГОТОВ →';$('netReady').setAttribute('aria-pressed',String(!!mine?.ready));$('netReady').disabled=busy||returning||(room.status!=='waiting'&&!mine?.ready);$('netHud').hidden=!playing;
}
function resetPeer(){clearTimeout(timer);link?.close();link=null;signals=[];cursor=0;session=-1;prepared=false;localLoaded=false;remoteLoaded=false;went=false}
async function accept(next){room=next;render();if(returning)return;if(next.status==='waiting'){if(playing||link){hooks.stop();playing=false;resetPeer();show();info('Вы в лобби. Можно выбрать бойцов и сыграть снова.')}return}if(next.session!==session){resetPeer();session=next.session;await connect()}}
async function update(body){
    if(!auth||busy||returning)return;
    if(body.ready===true&&globalThis.isSecureContext===false){info('Для запуска игры откройте эту страницу по HTTPS на обоих устройствах.',true);return}
    const current=auth,revision=++roomRevision,cancelling=body.ready===false&&room?.status==='connecting';
    busy=true;render();
    try{
        const result=await api('/'+current.code+'/update',body);
        if(auth!==current||revision!==roomRevision)return;
        if(cancelling)link?.send({t:'lobby'});
        await accept(result.room);
        if(room.status==='waiting')info(waitingStatus());
    }catch(error){info(error.message,true)}finally{busy=false;render()}
}
async function connect(){if(!relayAvailable&&!globalThis.RTCPeerConnection){info('Открой игру в браузере с WebRTC, например Chrome или Firefox.',true);return}info(relayAvailable?'Подключаемся через сервер…':'Подключаемся к сопернику…');const callbacks={onOpen:()=>{lastPong=Date.now();info(relayAvailable?'Связь через сервер установлена. Загружаем бой…':'Связь установлена. Загружаем бой…')},onData:receive,onFailure:connectionError};if(relayAvailable){const url=new URL('/api/rooms/'+auth.code+'/relay',location.origin);url.protocol=url.protocol==='https:'?'wss:':'ws:';url.searchParams.set('session',session);link=new RelayLink({...callbacks,url:url.href,token:auth.token})}else link=new PeerLink({...callbacks,seat:auth.seat,signal:m=>signals.push(m)});timer=setTimeout(()=>{if(!prepared)connectionError(relayAvailable?'Не удалось соединить игроков через сервер. Обновите страницы.':'Не удалось установить прямую связь. Попробуйте другую Wi-Fi сеть.')},30000);if(auth.seat===0)await link.offer()}
async function flushSignals(){if(flushing||!auth||!signals.length||session<0)return;flushing=true;const batch=signals.splice(0,12);try{await api('/'+auth.code+'/signal',{session,messages:batch})}catch(e){if(e.status!==409)signals.unshift(...batch)}finally{flushing=false}}
async function poll(force=false){
    if(!auth||polling||(busy&&!force))return;
    const current=auth,revision=roomRevision;
    polling=true;
    try{
        const data=await api('/'+current.code+'?since='+cursor);
        if(auth!==current||revision!==roomRevision)return;
        relayAvailable=data.relayAvailable===true;
        await accept(data.room);
        for(const message of data.signals||[]){if(link)await link.receive(message);cursor=Math.max(cursor,message.id)}
    }catch(error){
        if(auth!==current||revision!==roomRevision)return;
        if([401,403,404].includes(error.status)){
            resetPeer();auth=null;room=null;remember();lock(false);hooks.stop();playing=false;show();info(error.message,true);
        }else if(!playing)info('Сервер временно не отвечает. Повторяем подключение…',true);
    }finally{polling=false;render()}
}
function receive(d){
 if(d.t==='hello'){if(d.protocol!==PROTOCOL){connectionError('У игроков разные версии. Обновите страницы.');return}if(auth.seat===0&&!prepared){const config={p1:room.host.fighter,p2:room.guest.fighter,stage:room.stage,seed:room.seed,delay:6,protocol:PROTOCOL,run:room.code+':'+room.session+':'+room.seed};link.send({t:'prepare',config});prepare(config)}}
 else if(d.t==='prepare'&&auth.seat===1&&!prepared){const c=d.config;if(c?.protocol!==PROTOCOL||typeof c.run!=='string'||c.run.length>80||!roster[c.p1]||!roster[c.p2]||!['rooftop','taneko','office'].includes(c.stage)||!Number.isInteger(c.seed))return;prepare(c)}
 else if(d.t==='loaded'){remoteLoaded=true;go()}
 else if(d.t==='go'&&auth.seat===1){went=true;clearTimeout(timer);hooks.message({type:'arena-network-go',delay:6})}
 else if(d.t==='input'&&Number.isInteger(d.frame)&&d.frame>=0&&Number.isInteger(d.mask)&&d.mask>=0&&d.mask<=16383)hooks.message({type:'arena-network-input',frame:d.frame,mask:d.mask});
 else if(d.t==='checksum'&&Number.isInteger(d.frame)&&typeof d.hash==='string'&&d.hash.length===64)hooks.message({type:'arena-network-checksum',frame:d.frame,hash:d.hash});
 else if(d.t==='ping')link.send({t:'pong',at:d.at});
 else if(d.t==='pong'){lastPong=Date.now();$('netConnection').textContent=(relayAvailable?'СЕРВЕР · ':'СЕТЬ · ')+Math.max(0,Math.round(performance.now()-Number(d.at)))+' мс'}
 else if(d.t==='lobby'){if(playing)back(false);else poll()}
}
function prepare(c){prepared=true;clearTimeout(timer);timer=setTimeout(()=>{if(!went)connectionError('Не удалось загрузить бой на обоих устройствах. Обновите страницы и попробуйте снова.')},120000);playing=true;$('netDialog').hidden=true;hooks.start(c,auth.seat);render()}
function go(){if(auth?.seat===0&&localLoaded&&remoteLoaded&&!went){went=true;clearTimeout(timer);link.send({t:'go'});hooks.message({type:'arena-network-go',delay:6})}}
async function back(notify=true){
    if(!auth||returning)return;
    const current=auth,previousSession=session;
    returning=true;++roomRevision;
    if(notify)link?.send({t:'lobby'});
    resetPeer();hooks.stop();playing=false;$('netHud').hidden=true;show();info('Возвращаемся в комнату…');
    try{
        const data=await api('/'+current.code+'/update',{ready:false,lobby:true,session:previousSession});
        if(auth!==current)return;
        room=data.room;render();info('Бой завершён. Нажмите «Я готов», чтобы сыграть снова.');
    }catch(error){info(error.message,true)}finally{returning=false;render()}
}
async function connectionError(text){
    if(!auth||returning||handlingFailure)return;
    handlingFailure=true;
    const current=auth,revision=roomRevision;
    try{
        const data=await api('/'+current.code);
        if(auth!==current||revision!==roomRevision)return;
        if(data.room.status==='waiting'){
            await accept(data.room);show();info(waitingStatus());
        }else{await back(false);info(text,true)}
    }catch{if(auth===current&&revision===roomRevision){resetPeer();hooks.stop();playing=false;show();info(text,true)}}
    finally{handlingFailure=false}
}
window.addEventListener('message',e=>{if(e.origin!==location.origin||e.source!==$('game').contentWindow||!auth||!link)return;const d=e.data;if(d?.run!==hooks.run)return;if(d.type==='arena-network-loaded'){localLoaded=true;link.send({t:'loaded'});go()}else if(d.type==='arena-network-input')link.send({t:'input',frame:d.frame,mask:d.mask});else if(d.type==='arena-network-checksum')link.send({t:'checksum',frame:d.frame,hash:d.hash});else if(d.type==='arena-network-menu')back();else if(d.type==='arena-network-error')connectionError(d.message)});
for(const [id,p] of Object.entries(roster)){const c=document.createElement('button');c.className='net-fighter';c.dataset.fighter=id;const image=document.createElement('div');image.className='roster-portrait';image.style.backgroundImage='url(portraits/'+id+'.png)';if(id==='yusup')image.style.backgroundSize='400% 400%';c.append(image,document.createTextNode(p.name));c.onclick=()=>update({fighter:id});$('netFighters').append(c)}
$('networkMode').onclick=()=>playing?window.ArenaMenu?.battle():show();$('netBack').onclick=()=>back();$('netClose').onclick=async()=>{await leave();window.ArenaMenu?.home()};
$('netCreate').onclick=async()=>{if(busy)return;busy=true;$('netCreate').disabled=true;try{auth=await api('',{name:$('netName').value,fighter:$('fighter1').value,stage:$('arenaStage').value});remember();lock(true);await poll(true);info('Отправь другу код или ссылку и выбери бойца.')}catch(e){info(e.message,true)}finally{busy=false;$('netCreate').disabled=false;render()}};
$('netJoin').onclick=async()=>{const code=$('netJoinCode').value.trim().toUpperCase();if(!/^[A-HJ-NP-Z2-9]{6}$/.test(code)){info('Введи код из 6 букв и цифр',true);return}if(busy)return;busy=true;$('netJoin').disabled=true;try{auth=await api('/'+code+'/join',{name:$('netName').value,fighter:$('fighter1').value});remember();lock(true);await poll(true);info('Выбери бойца и нажми «Я готов».')}catch(e){info(e.message,true)}finally{busy=false;$('netJoin').disabled=false;render()}};
$('netReady').onclick=()=>update({ready:!(auth?.seat===0?room?.host:room?.guest)?.ready});$('netStage').onchange=()=>update({stage:$('netStage').value});
$('netCopy').onclick=async()=>{if(!auth)return;const invitation=location.origin+'/?room='+auth.code;if(await copyInvitation(invitation))info('Ссылка скопирована');else{info('Браузер запретил копирование. Скопируйте ссылку из окна вручную.',true);window.prompt('Скопируйте приглашение:',invitation)}};
async function leave(){
    const current=auth;
    ++roomRevision;returning=true;
    link?.send({t:'lobby'});resetPeer();
    if(current){try{await api('/'+current.code,undefined,'DELETE')}catch{}}
    auth=null;room=null;remember();lock(false);playing=false;returning=false;
    hooks.stop();$('netDialog').hidden=true;render();
}
$('netLeave').onclick=async()=>{await leave();window.ArenaMenu?.home()};
setInterval(poll,1000);setInterval(flushSignals,180);setInterval(()=>{if(link?.isOpen){link.send({t:'ping',at:performance.now()});if(playing&&went&&Date.now()-lastPong>20000)connectionError('Соперник перестал отвечать. Бой остановлен.')}},2000);
try{const a=JSON.parse(sessionStorage.getItem('arena-room')||'null');if(a?.code&&a?.token&&[0,1].includes(a.seat))auth=a}catch{}
const code=new URLSearchParams(location.search).get('room');if(code){$('netJoinCode').value=code.toUpperCase();show()}if(auth){lock(true);poll();show()}
window.ArenaOnline={show,leave,backToLobby:back,get active(){return !!auth},get playing(){return playing}};
