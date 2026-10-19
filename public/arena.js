const $ = id => document.getElementById(id);
let mode = 'cpu';
let started = false;
let pickerSlot = 0;
let touchEnabled = navigator.maxTouchPoints > 0 && matchMedia('(pointer:coarse)').matches;
let audioEnabled = true;
let audioVolume = 0.8;
const stageNames = { rooftop: 'Крыша', taneko: 'ТАНЕКО', office: 'Татнефть' };
const roster = {
ruslan:{name:"Руслан",tag:"КАПИТАЛ / КОМБО / РИСК",abilities:["Плов на вынос · готовит и бросает три порции","Чёрный день · оба игрока ничего не видят 4 с","Ва-банк · дубль: денежный дождь; иначе −150 HP себе"]},
yusup:{name:"Юсуп",tag:"РАЗГОВОР / ЖАРА / ПЛАВАНИЕ",abilities:["А забей · разговор, затем выносливость врага 0 на 2 с","Мне холодно! · пульт, жара и горение на 3 с","Плавунец · купальник и мельница руками на 5 с"]},
polina:{name:"Полина",tag:"ТЕЛЕПОРТ / ДОЖДЬ / ЖЕСТЫ",abilities:["Нырок · исчезает и ударяет рядом с противником","Просьба · дождь из сигарет и вейпов","Случайный жест · ступор на 3 с, до первого попадания"]},
azat:{name:"Азат",tag:"ТОЛЬКО НЫТЬЁ / НОЛЬ УРОНА",abilities:["Ну почему я? · разводит руками","Я не буду! · жалуется","Всё не так! · драматично ноет"]},
rafael:{name:'Рафаэль',tag:'ДИСТАНЦИЯ / КОНТРОЛЬ',abilities:['Энергетик · скорость ×1,65 / 6 с','Протеин · рост и урон / 7 с','Волна изо рта · отталкивание']},
nikita:{name:'Никита',tag:'ЛОВУШКИ / НАПОР',abilities:['Зелёная сфера · ловушка','Берсерк · красный режим / 6 с','Чёрное пламя · горящие глаза, огонь на земле']},
vladislav:{name:'Владислав',tag:'БУРГЕРЫ / НЕУЯЗВИМОСТЬ',abilities:['Волна из пяти бургеров','Красная рыба · неуязвимость / 3 с','Масса · толще и медленнее / 8 с']},
ilgiz:{name:'Ильгиз',tag:'ПРИЗЫВ / ОСЛАБЛЕНИЕ',abilities:['Собаки · три помощника атакуют врага','Уход с арены · 6 секунд без ударов и атак','Негатив · враг меньше и слабее на 6 секунд']},
bigboss:{name:'Рафаэль Биг Босс',tag:'КОМПАКТНЫЙ / ДАЛЬНИЙ БОЙ',abilities:['Пистолет · одиночный выстрел','Автомат · очередь из шести выстрелов','Улыбка в камеру · толпа и надписи «тик ток»']},
ramis:{name:'Рамис',tag:'МАРИС / СОЛНЕЧНЫЙ РИКОШЕТ',abilities:['Марис · мышцы, четвереньки, скорость / 6 с','Лысина · отражённый солнечный луч','Геморройчики · четыре бегущих существа']},
mavrin:{name:'Маврин',tag:'СЛОВЕСНЫЕ ВОЛНЫ / ПОЛЁТ',abilities:['Словесные волны · нарастающее замедление','Высокий удар ногой · шпагат','Звонок Салахову · 10% шанс мощной серии из пяти ударов']}
};
function updateRoster(){const ids=[$('fighter1').value,$('fighter2').value];$('matchTitle').textContent=roster[ids[0]].name+' × '+roster[ids[1]].name;document.querySelector('.gate .eyebrow').textContent=roster[ids[0]].name+' / '+roster[ids[1]].name;document.querySelectorAll('.controls .panel').forEach((panel,i)=>{const info=roster[ids[i]],keys=i===0?['Q','E','R']:['P','[',']'];const player=panel.querySelector('.player');player.childNodes.forEach(n=>{if(n.nodeType===3)n.textContent=''});player.insertBefore(document.createTextNode(info.name.toUpperCase()+' '),player.querySelector('small'));panel.querySelector('.badge').textContent=info.tag;panel.querySelector('.abilities').innerHTML=info.abilities.map((a,j)=>'<div class="row"><span>'+a+'</span><kbd>'+keys[j]+'</kbd></div>').join('');let extra=panel.querySelector('.flight');if(!extra){extra=document.createElement('div');extra.className='flight';panel.appendChild(extra)}extra.hidden=!["mavrin","azat"].includes(ids[i]);extra.textContent=ids[i]==="azat"?"Все кнопки ударов — нытьё. Атак и урона нет.":(i===0?"F":"H")+" — включить/выключить полёт. Направления — управление в воздухе."})}

function notifyNavigation() {
    window.dispatchEvent(new CustomEvent('arena:navigation'));
}

function message(data) {
    $('game').contentWindow?.postMessage(data, location.origin);
}

function reflectAudio() {
    $('soundToggle').textContent = audioEnabled ? 'Звук: вкл.' : 'Звук: выкл.';
    $('soundToggle').setAttribute('aria-pressed', String(audioEnabled));
    $('soundVolume').value = String(Math.round(audioVolume * 100));
    try { localStorage.setItem('arena-audio', JSON.stringify({ enabled: audioEnabled, volume: audioVolume })); } catch {}
}

function reflectTouch() {
    $('touchToggle').textContent = touchEnabled ? 'Сенсорные кнопки: вкл.' : 'Сенсорные кнопки';
    $('touchToggle').setAttribute('aria-pressed', String(touchEnabled));
}

async function enterFullscreen() {
    try {
        if (!document.fullscreenElement) await $('gamebox').requestFullscreen();
        if (touchEnabled && screen.orientation?.lock) await screen.orientation.lock('landscape').catch(() => {});
        $('game').focus();
    } catch {}
}

function closeBattle(resume = true) {
    if ($('battleMenu').open) $('battleMenu').close();
    if (resume && started) {
        if (!window.ArenaOnline?.active) message({ type: 'arena-menu-state', paused: false });
        $('game').focus();
    }
}

function showMenu(network = false, scroll = false) {
    closeBattle(false);
    started = false;
    $('game').src = 'about:blank';
    $('gate').hidden = true;
    document.body.classList.remove('arena-started');
    $('fighterPicker').hidden = network;
    $('netDialog').hidden = !network;
    if (document.fullscreenElement) document.exitFullscreen().catch(() => {});
    refreshPicker();
    notifyNavigation();
    if (scroll) requestAnimationFrame(() => (network ? $('netTitle') : $('pickerTitle')).scrollIntoView({ behavior: 'smooth', block: 'start' }));
}

async function home() {
    if (window.ArenaOnline?.active) await window.ArenaOnline.leave();
    showMenu(false);
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function openBattle() {
    if (!started || $('battleMenu').open) return;
    const online = window.ArenaOnline?.playing === true;
    $('battleTitle').textContent = online ? 'Меню сетевого боя' : 'Пауза';
    $('battleHint').textContent = online ? 'Бой продолжается. Возврат в комнату завершит текущий матч для обоих игроков.' : 'Бой приостановлен. Можно продолжить или вернуться к настройке.';
    $('battleSettings').hidden = online;
    $('battleRestart').hidden = online;
    $('netBack').hidden = !online;
    if (!online) message({ type: 'arena-menu-state', paused: true });
    $('battleMenu').showModal();
    $('battleResume').focus();
}

function setMode(value) {
    mode = value === '2p' ? '2p' : 'cpu';
    $('pickMode').value = mode;
    for (const id of ['cpu', 'two']) {
        $(id).classList.toggle('active', id === (mode === 'cpu' ? 'cpu' : 'two'));
        $(id).setAttribute('aria-pressed', String(id === (mode === 'cpu' ? 'cpu' : 'two')));
    }
    $('difficulty').disabled = mode !== 'cpu';
    $('p2Label').textContent = mode === 'cpu' ? 'Компьютер' : 'Игрок 2';
}

function refreshPicker() {
    $('pickerTitle').textContent = 'Настрой бой';
    $('pickP1').textContent = 'ТВОЙ БОЕЦ: ' + roster[$('fighter1').value].name;
    $('pickP2').textContent = (mode === 'cpu' ? 'ПРОТИВНИК ИИ: ' : 'ИГРОК 2: ') + roster[$('fighter2').value].name;
    for (const [slot, id] of ['pickP1', 'pickP2'].entries()) {
        $(id).classList.toggle('active', pickerSlot === slot);
        $(id).setAttribute('aria-pressed', String(pickerSlot === slot));
    }
    for (const card of $('rosterCards').children) {
        const selected = card.dataset.fighter === $('fighter' + (pickerSlot + 1)).value;
        card.classList.toggle('chosen', selected);
        card.setAttribute('aria-pressed', String(selected));
    }
    $('pickerTarget').textContent = pickerSlot === 0 ? 'Выбираешь своего бойца' : (mode === 'cpu' ? 'Выбираешь противника ИИ' : 'Выбираешь бойца второго игрока');
    $('pickDifficulty').closest('label').hidden = mode !== 'cpu';
    $('pickerSummary').textContent = roster[$('fighter1').value].name + ' × ' + roster[$('fighter2').value].name + ' · ' + stageNames[$('pickStage').value];
}

function openPicker(slot = 0) {
    if (window.ArenaOnline?.active) { window.ArenaOnline.show(); return; }
    pickerSlot = slot;
    showMenu(false, true);
}

async function configure(value = mode) {
    if (window.ArenaOnline?.active) await window.ArenaOnline.leave();
    setMode(value);
    showMenu(false, true);
}

function launch() {
    closeBattle(false);
    $('arenaStage').value = $('pickStage').value;
    $('difficulty').value = $('pickDifficulty').value;
    setMode($('pickMode').value);
    updateRoster();
    started = true;
    $('fighterPicker').hidden = true;
    $('netDialog').hidden = true;
    $('gate').hidden = true;
    $('modeLabel').textContent = roster[$('fighter1').value].name + ' × ' + roster[$('fighter2').value].name;
    document.querySelector('.live').lastChild.textContent = stageNames[$('arenaStage').value].toUpperCase();
    document.body.classList.add('arena-started');
    const query = new URLSearchParams({ v: '23', quickstart: '1', touch: String(Number(touchEnabled)), stage: $('arenaStage').value, sound: String(Number(audioEnabled)), volume: String(audioVolume), mode, difficulty: $('difficulty').value, p1: $('fighter1').value, p2: $('fighter2').value });
    $('game').src = 'play/game.html?' + query;
    $('game').focus();
    notifyNavigation();
    requestAnimationFrame(() => $('gamebox').scrollIntoView({ behavior: 'smooth', block: 'center' }));
    if (touchEnabled) enterFullscreen();
}

for (const [id, fighter] of Object.entries(roster)) {
    const card = document.createElement('button');
    card.className = 'roster-card';
    card.dataset.fighter = id;
    card.setAttribute('aria-label', 'Выбрать: ' + fighter.name);
    const portrait = document.createElement('div');
    portrait.className = 'roster-portrait';
    portrait.style.backgroundImage = 'url(portraits/' + id + '.png)';
    if (id === 'yusup') portrait.style.backgroundSize = '400% 400%';
    const name = document.createElement('strong');
    name.textContent = fighter.name;
    const abilities = document.createElement('small');
    abilities.textContent = fighter.abilities.map(ability => ability.split(' · ')[0]).join(' · ');
    card.append(portrait, name, abilities);
    card.onclick = () => {
        $('fighter' + (pickerSlot + 1)).value = id;
        updateRoster();
        refreshPicker();
    };
    $('rosterCards').append(card);
}

$('pickP1').onclick = () => { pickerSlot = 0; refreshPicker(); };
$('pickP2').onclick = () => { pickerSlot = 1; refreshPicker(); };
$('pickMode').onchange = () => { setMode($('pickMode').value); refreshPicker(); notifyNavigation(); };
$('pickStage').onchange = () => { $('arenaStage').value = $('pickStage').value; refreshPicker(); };
$('pickerFight').onclick = launch;
$('start').onclick = () => openPicker();
$('restart').onclick = () => openPicker();
$('cpu').onclick = () => configure('cpu');
$('two').onclick = () => configure('2p');
$('full').onclick = enterFullscreen;
$('battleOpen').onclick = openBattle;
$('battleResume').onclick = () => closeBattle();
$('battleHome').onclick = home;
$('battleSettings').onclick = () => openPicker();
$('battleRestart').onclick = launch;
$('battleMenu').addEventListener('cancel', event => { event.preventDefault(); closeBattle(); });
$('soundToggle').onclick = () => { audioEnabled = !audioEnabled; reflectAudio(); if (started) message({ type: 'arena-audio', enabled: audioEnabled, volume: audioVolume }); };
$('soundVolume').oninput = () => { audioVolume = Number($('soundVolume').value) / 100; reflectAudio(); if (started) message({ type: 'arena-audio', enabled: audioEnabled, volume: audioVolume }); };
$('touchToggle').onclick = () => { touchEnabled = !touchEnabled; reflectTouch(); if (started) launch(); };
window.addEventListener('keydown', event => {
    if (event.key === 'Escape' && started && !$('battleMenu').open) { event.preventDefault(); openBattle(); }
});
window.addEventListener('message', event => {
    if (event.origin !== location.origin || event.source !== $('game').contentWindow) return;
    const data = event.data;
    if (data?.type === 'arena-open-menu') {
        if (data.view === 'settings' && !window.ArenaOnline?.active) openPicker(); else openBattle();
    } else if (data?.type === 'arena-audio-state' && typeof data.enabled === 'boolean' && Number.isFinite(data.volume)) {
        audioEnabled = data.enabled; audioVolume = Math.max(0, Math.min(1, data.volume)); reflectAudio();
    }
});

try {
    const audio = JSON.parse(localStorage.getItem('arena-audio') || 'null');
    if (audio && typeof audio.enabled === 'boolean' && Number.isFinite(audio.volume)) {
        audioEnabled = audio.enabled;
        audioVolume = Math.max(0, Math.min(1, audio.volume));
    }
} catch {}
reflectAudio();
reflectTouch();
setMode(mode);
updateRoster();
refreshPicker();

window.ArenaMenu = { home, configure, mount: () => showMenu(false), settings: openPicker, battle: openBattle, get playing() { return started; }, get mode() { return mode; } };
window.ArenaOnlineHooks = {
    roster,
    lock(active) {
        for (const id of ['cpu', 'two', 'fighter1', 'fighter2', 'arenaStage', 'difficulty', 'restart', 'start', 'touchToggle']) $(id).disabled = active;
    },
    openLobby() { if (started) showMenu(true); else { $('fighterPicker').hidden = true; $('netDialog').hidden = false; notifyNavigation(); } },
    message(data) { message({ ...data, run: this.run }); },
    start(config, seat) {
        closeBattle(false);
        this.run = config.run;
        $('fighter1').value = config.p1;
        $('fighter2').value = config.p2;
        $('arenaStage').value = config.stage;
        $('pickStage').value = config.stage;
        setMode('2p');
        updateRoster();
        started = true;
        $('fighterPicker').hidden = true;
        $('netDialog').hidden = true;
        $('gate').hidden = true;
        $('modeLabel').textContent = 'ОНЛАЙН · ТЫ ИГРОК ' + (seat + 1);
        document.body.classList.add('arena-started');
        const query = new URLSearchParams({ v: '23', quickstart: '1', net: '1', seat: String(seat), seed: String(config.seed), run: config.run, mode: '2p', touch: String(Number(touchEnabled)), stage: config.stage, sound: String(Number(audioEnabled)), volume: String(audioVolume), p1: config.p1, p2: config.p2 });
        $('game').src = 'play/game.html?' + query;
        $('game').focus();
        notifyNavigation();
        requestAnimationFrame(() => $('gamebox').scrollIntoView({ behavior: 'smooth', block: 'center' }));
    },
    stop() { showMenu(window.ArenaOnline?.active === true); },
};
