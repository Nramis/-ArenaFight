import {validSkin} from '../public/skins.mjs';
const fighters=new Set(['rafael','nikita','vladislav','mavrin','ramis','ilgiz','bigboss','azat','polina','yusup','rinat']),stages=new Set(['rooftop','taneko','office']);
const name=v=>String(v||'Игрок').replace(/[<>\x00-\x1f]/g,'').trim().slice(0,24)||'Игрок';
const hash=async v=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(v))),x=>x.toString(16).padStart(2,'0')).join('');
const json=(v,status=200)=>Response.json(v,{status,headers:{'Cache-Control':'no-store'}});
const fail=(message,status=400)=>{throw Object.assign(new Error(message),{status})};
const view=r=>({code:r.code,host:{name:r.host_name,fighter:r.host_fighter,skin:validSkin(r.host_fighter,r.host_skin),ready:!!r.host_ready},guest:r.guest_hash?{name:r.guest_name,fighter:r.guest_fighter,skin:validSkin(r.guest_fighter,r.guest_skin),ready:!!r.guest_ready}:null,stage:r.stage,status:r.status,session:r.session,seed:r.seed});
export async function handleRooms(req,db,{relayAvailable=false}={}){try{
 if(!db)fail('Сервер комнат недоступен',503);
 const u=new URL(req.url),p=u.pathname.replace(/^\/api\/rooms\/?/,'').split('/').filter(Boolean),now=Date.now();let b={};
 if(p.length>2)fail('Не найдено',404);
 if(req.method!=='GET'&&req.headers.get('origin')&&req.headers.get('origin')!==u.origin)fail('Недопустимый источник',403);
 if(req.method==='POST'){const raw=await req.text();if(raw.length>32768)fail('Слишком большой запрос',413);try{b=JSON.parse(raw||'{}')}catch{fail('Неверный запрос')}if(!b||Array.isArray(b)||typeof b!=='object')fail('Неверный запрос');}
 if(!p.length&&req.method==='POST'){
  await db.prepare('DELETE FROM signals WHERE code IN (SELECT code FROM rooms WHERE expires_at<?)').bind(now).run();await db.prepare('DELETE FROM rooms WHERE expires_at<?').bind(now).run();
  if((await db.prepare('SELECT COUNT(*) AS n FROM rooms').first()).n>=120)fail('Слишком много комнат',429);
  if((await db.prepare('SELECT COUNT(*) AS n FROM rooms WHERE created_at>?').bind(now-60000).first()).n>=30)fail('Повтори через минуту',429);
  const alphabet='ABCDEFGHJKLMNPQRSTUVWXYZ23456789',code=Array.from(crypto.getRandomValues(new Uint8Array(6)),x=>alphabet[x%32]).join(''),key=crypto.randomUUID().replaceAll('-','');
  await db.prepare('INSERT INTO rooms(code,host_hash,host_name,host_fighter,host_skin,stage,created_at,expires_at) VALUES(?,?,?,?,?,?,?,?)').bind(code,await hash(key),name(b.name),fighters.has(b.fighter)?b.fighter:'rafael',validSkin(fighters.has(b.fighter)?b.fighter:'rafael',b.skin),stages.has(b.stage)?b.stage:'rooftop',now,now+1800000).run();return json({code,token:key,seat:0},201);
 }
 const code=String(p[0]||'').toUpperCase();if(!/^[A-HJ-NP-Z2-9]{6}$/.test(code))fail('Комната не найдена',404);
 let r=await db.prepare('SELECT * FROM rooms WHERE code=?').bind(code).first();if(!r||r.expires_at<now)fail('Комната закрыта или срок истёк',404);
 if(p[1]==='join'&&req.method==='POST'){
  if(r.guest_hash)fail('В комнате уже два игрока',409);const key=crypto.randomUUID().replaceAll('-','');
  const q=await db.prepare("UPDATE rooms SET guest_hash=?,guest_name=?,guest_fighter=?,guest_skin=?,guest_ready=0 WHERE code=? AND guest_hash IS NULL AND status='waiting'").bind(await hash(key),name(b.name),fighters.has(b.fighter)?b.fighter:'nikita',validSkin(fighters.has(b.fighter)?b.fighter:'nikita',b.skin),code).run();if(q.meta.changes!==1)fail('Место уже занято',409);return json({code,token:key,seat:1},201);
 }
 const key=req.headers.get('authorization')?.replace(/^Bearer /,'')||'';if(!/^[a-f0-9]{32}$/.test(key))fail('Нужен ключ игрока',401);const digest=await hash(key),seat=digest===r.host_hash?0:digest===r.guest_hash?1:-1;if(seat<0)fail('Неверный ключ игрока',403);
 if(req.method==='DELETE'&&!p[1]){await db.prepare('DELETE FROM signals WHERE code=?').bind(code).run();if(seat===0)await db.prepare('DELETE FROM rooms WHERE code=?').bind(code).run();else await db.prepare("UPDATE rooms SET guest_hash=NULL,guest_name='',host_ready=CASE WHEN status='waiting' THEN host_ready ELSE 0 END,guest_ready=0,status='waiting',session=session+1 WHERE code=?").bind(code).run();return json({ok:true});}
 if(req.method==='POST'&&p[1]==='update'){
  if(b.fighter!==undefined&&!fighters.has(b.fighter))fail('Неизвестный боец');if(b.stage!==undefined&&(seat!==0||!stages.has(b.stage)))fail('Арену выбирает хозяин',403);
  const own=seat===0?'host_fighter':'guest_fighter',ready=seat===0?'host_ready':'guest_ready';
  const ownSkin=seat===0?'host_skin':'guest_skin',nextFighter=b.fighter??r[own];
  if(b.skin!==undefined&&validSkin(nextFighter,b.skin)!==b.skin)fail('Этот облик недоступен бойцу');
  const nextSkin=validSkin(nextFighter,b.skin??r[ownSkin]);
  const fields=[],values=[];
  if(b.fighter!==undefined&&b.fighter!==r[own]){fields.push(`${own}=?`);values.push(b.fighter)}
  if(nextSkin!==(r[ownSkin]||'default')){fields.push(`${ownSkin}=?`);values.push(nextSkin)}
  if(b.stage!==undefined&&b.stage!==r.stage){fields.push('stage=?');values.push(b.stage)}
  if(fields.length){if(r.status!=='waiting')fail('Сначала вернитесь в лобби',409);const changed=await db.prepare(`UPDATE rooms SET ${fields.join(',')} WHERE code=? AND status='waiting' AND session=?`).bind(...values,code,r.session).run();if(changed.meta.changes!==1)fail('Бой уже начинается. Вернитесь в комнату для смены настроек.',409);}
  if(b.lobby===true){
    if(b.session!==undefined&&b.session!==r.session)return json({room:view(r),seat});
    if(r.status!=='waiting')await db.prepare("UPDATE rooms SET status='waiting',host_ready=0,guest_ready=0,session=session+1 WHERE code=? AND session=?").bind(code,r.session).run();
  }else if(typeof b.ready==='boolean'){
    if(!b.ready&&r.status!=='waiting')await db.prepare(`UPDATE rooms SET status='waiting',${ready}=0,session=session+1 WHERE code=? AND session=?`).bind(code,r.session).run();
    else await db.prepare(`UPDATE rooms SET ${ready}=? WHERE code=?`).bind(Number(b.ready),code).run();
  }
  const seed=(crypto.getRandomValues(new Uint32Array(1))[0]&0x7fffffff)||1;await db.prepare("UPDATE rooms SET status='connecting',session=session+1,seed=? WHERE code=? AND status='waiting' AND host_ready=1 AND guest_ready=1 AND guest_hash IS NOT NULL").bind(seed,code).run();r=await db.prepare('SELECT * FROM rooms WHERE code=?').bind(code).first();if(!r)fail('Комната закрыта или срок истёк',404);return json({room:view(r),seat});
 }
 if(req.method==='POST'&&p[1]==='signal'){
  if(b.session!==r.session||r.status!=='connecting')fail('Сессия устарела',409);if(!Array.isArray(b.messages)||b.messages.length<1||b.messages.length>24||b.messages.some(m=>!m||!['offer','answer','ice'].includes(m.type)||JSON.stringify(m).length>16000))fail('Неверные данные подключения');
  const n=await db.prepare('SELECT COUNT(*) AS n FROM signals WHERE code=? AND session=?').bind(code,r.session).first();if(n.n+b.messages.length>512)fail('Слишком много данных',429);await db.batch(b.messages.map(m=>db.prepare('INSERT INTO signals(code,session,seat,payload) VALUES(?,?,?,?)').bind(code,r.session,seat,JSON.stringify(m))));return json({ok:true});
 }
 if(req.method==='GET'&&!p[1]){const since=Math.max(0,Math.min(Number(u.searchParams.get('since'))||0,Number.MAX_SAFE_INTEGER)),ss=await db.prepare('SELECT id,payload FROM signals WHERE code=? AND session=? AND seat!=? AND id>? ORDER BY id LIMIT 64').bind(code,r.session,seat,since).all();return json({room:view(r),seat,relayAvailable,signals:ss.results.map(s=>({id:s.id,...JSON.parse(s.payload)}))});}
 fail('Не найдено',404);
}catch(e){if(e.status)return json({error:e.message},e.status);console.error('Room API:',String(e.message));return json({error:'Сбой сервера комнат'},500)}}
