const $ = id => document.getElementById(id);
const menu = window.ArenaMenu;
const hub = document.createElement('section');
hub.className = 'hub';
hub.id = 'arenaHub';
hub.setAttribute('aria-label', 'Главное меню');
hub.innerHTML = `<div class="hub-hero"><img class="hub-hero-art" src="hub-matchup.png" alt="Рафаэль и Полина перед боем"><div class="hub-copy"><h2>ВСЕ СВОИ.<br>КАЖДЫЙ ЗА СЕБЯ.</h2><p>Друзья. Знакомые места.<br>2D файтинг про нас — с характером и без правил.</p><div class="hub-actions"><button id="hubFight" class="hub-play">ВЫБРАТЬ БОЙЦОВ <span>↓</span></button><button id="hubOnline" class="hub-secondary">ОНЛАЙН С ДРУГОМ</button></div></div></div>
<div class="hub-paths"><button class="hub-path" id="hubCpu"><b>01</b><div><strong>ПРОТИВ ИИ</strong><span>Проверь себя</span></div><i>›</i></button><button class="hub-path" id="hubDuo"><b>02</b><div><strong>ВДВОЁМ</strong><span>На одном компьютере</span></div><i>›</i></button><button class="hub-path" id="hubNet"><b>03</b><div><strong>ОНЛАЙН</strong><span>Сразись с другом</span></div><i>›</i></button><button class="hub-path" id="hubGuide"><b>04</b><div><strong>ШКОЛА СЕРИЙ</strong><span>Освой комбо</span></div><i>›</i></button></div>
<section id="hubSetup" class="hub-setup" aria-label="Настройка боя"></section>`;
document.querySelector('.intro').before(hub);
const setup = $('hubSetup');
setup.append($('fighterPicker'), $('netDialog'));
const guide=document.createElement('dialog');guide.className='hub-guide';guide.setAttribute('aria-labelledby','comboTitle');guide.innerHTML=`<header><h2 id="comboTitle">Серия начинается с тебя</h2><button id="guideClose" aria-label="Закрыть подсказки">✕</button></header><p>Нажимай следующий удар после попадания предыдущего. На блоке соперник может выждать паузу и ответить. Азат остаётся исключением: он только жалуется.</p><div class="hub-combo">РУКА → НОГА → СР. РУКА → СР. НОГА → ТЯЖЁЛЫЙ<br><kbd>U</kbd> → <kbd>J</kbd> → <kbd>I</kbd> → <kbd>K</kbd> → <kbd>O</kbd> / <kbd>L</kbd></div><ol><li><strong>Начни с трёх.</strong> U → I → O: лёгкий, средний, тяжёлый. Добавляй ноги, когда привыкнешь к ритму.</li><li><strong>Заверши падением.</strong> Тяжёлая рука O или нога L сбивает с ног на третьем и последующих попаданиях комбо. Одиночный тяжёлый удар оставляет соперника стоять. Внизу + L — подсечка. У Рината вниз + любая рука — апперкот с подбросом и отбрасыванием. Лежачий защищён, при подъёме ненадолго светится.</li><li><strong>Поймай контрудар.</strong> Попади во время чужого замаха: соперник дольше не может ответить.</li><li><strong>Меняй рисунок.</strong> Прыжок + удар — атака сверху. Вниз + удар — атака сидя. Отход от соперника — блок, отход + вниз — низкий блок.</li></ol><p>На телефоне: РУКА 1 → НОГА 1 → РУКА 2 → НОГА 2 → РУКА 3 или НОГА 3. Не нужно удерживать кнопки — делай отдельные нажатия. Полоска под здоровьем — выносливость; повтор одной атаки расходует её быстрее.</p><button class="start" id="guidePlay">ВЫБРАТЬ БОЙЦА →</button>`;document.body.append(guide);

function settings(value = menu.mode) { return menu.configure(value); }
function online() { window.ArenaOnline.show(); $('netTitle').scrollIntoView({ behavior: 'smooth', block: 'start' }); }
function help() { guide.showModal(); }
$('hubFight').onclick = () => settings();
$('hubCpu').onclick = () => settings('cpu');
$('hubDuo').onclick = () => settings('2p');
for (const id of ['hubOnline', 'hubNet']) $(id).onclick = online;
$('hubGuide').onclick = help;
$('guideClose').onclick = () => guide.close();
$('guidePlay').onclick = () => { guide.close(); settings(); };
guide.addEventListener('click', event => {
    if (event.target !== guide) return;
    const bounds = guide.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) guide.close();
});

const header = document.querySelector('main > header');
header.querySelector('.brand').textContent = 'АРЕНА';
header.querySelector('.tag').remove();
const nav = document.createElement('nav');
nav.className = 'hub-nav';
nav.setAttribute('aria-label', 'Навигация');
for (const [label, action] of [['Настроить бой', () => settings()], ['Онлайн', online], ['Как играть', help]]) {
    const button = document.createElement('button');
    button.textContent = label;
    button.className = 'home-nav';
    button.onclick = action;
    nav.append(button);
}
const battle = document.createElement('button');
battle.id = 'headerBattleMenu';
battle.textContent = '☰ Меню боя';
battle.onclick = menu.battle;
nav.append(battle);
header.append(nav);

function sync() {
    const onlineVisible = !$('netDialog').hidden;
    for (const [id, active] of [['hubCpu', !onlineVisible && menu.mode === 'cpu'], ['hubDuo', !onlineVisible && menu.mode === '2p'], ['hubNet', onlineVisible]]) {
        $(id).classList.toggle('active', active);
        $(id).setAttribute('aria-pressed', String(active));
    }
    battle.hidden = !menu.playing;
    for (const button of nav.querySelectorAll('.home-nav')) button.hidden = menu.playing;
    document.body.classList.remove('hub-dialog-open');
}
window.addEventListener('arena:navigation', sync);
new MutationObserver(sync).observe($('netDialog'), { attributes: true, attributeFilter: ['hidden'] });
if ($('netDialog').hidden) menu.mount();
sync();
