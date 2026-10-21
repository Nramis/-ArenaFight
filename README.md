# Арена

Godot 4.7.2 fighting game, based on Shoto Fighter (MIT), with ten custom characters, keyboard and touch controls. The original game license and art/sound credits are retained. Game source: `game/`. Browser assets and UI: `public/`. The root route serves `public/arena.html`.

## Локальный запуск

Требуются Node.js >= 22.13.0 и pnpm 11.25.0. В корне проекта выполните:

```powershell
pnpm install
pnpm db:migrate:local
pnpm dev:lan
```

Откройте `https://localhost:5173` или `https://<IP компьютера>:5173` с другого устройства в локальной сети. При первом открытии на каждом устройстве подтвердите исключение для локального самоподписанного сертификата. Если политика браузера запрещает исключения, используйте сертификат от доверенного центра, установленного на обоих устройствах.

`dev:lan` создаёт сертификат с адресами сетевых интерфейсов в `.sites-runtime/https` и запускает HTTPS-сервер. Для генерации требуется OpenSSL (в Windows входит в Git for Windows). После смены IP перезапустите команду: сертификат обновится автоматически. Готовая Web-сборка игры находится в `public/play`.

Для разработки на одном компьютере можно использовать `pnpm dev` и `http://localhost:5173`. При доступе через локальный IP нужен HTTPS: Godot Web требует защищённый контекст. Clipboard API также доступен только в защищённом контексте; для HTTP предусмотрено резервное копирование ссылки.

Команда `db:migrate:local` создаёт таблицы комнат и сигналов в локальной D1-базе в `.wrangler/state`. Выполняйте её перед первым запуском и после добавления миграций в `drizzle/`; повторный запуск пропускает уже применённые миграции. Команда работает только с локальной базой.

В режиме разработки онлайн-бой использует WebSocket на том же адресе и порту, что и сайт. Оба устройства подключаются к компьютеру с проектом; прямое WebRTC-соединение между ними не требуется. Сервер проверяет ключ игрока и текущую сессию через API комнат. Перезапуск dev-сервера прерывает активные бои. Этот транспорт работает только с `pnpm dev` / `pnpm dev:lan`; опубликованная сборка использует WebRTC.

## Online rooms

Create a room, send its six-character code or invitation link, select characters and mark both players ready. The host chooses the arena. Rooms expire after 30 minutes. Random seat keys are hashed in D1 and kept in browser session storage. Only room participants can read signaling messages. Both players use P1 controls on their own device.

D1 room/signaling API: `net/rooms.mjs`, with schema and migrations in `db/` and `drizzle/`. WebRTC signaling and lobby UI: `public/network-core.mjs` and `public/network.mjs`. Reliable ordered input packets travel directly between browsers. `game/globals/net_session.gd` coordinates a 60 Hz lockstep simulation with six frames of buffered input, whole-tree pause on missing input and state digest comparison every 120 frames. Audio randomness is separate from seeded gameplay randomness. Network rematches return both players to the lobby.

Hosted builds use public Google and Cloudflare STUN endpoints. No TURN relay is configured, so restrictive mobile or corporate networks may block direct connectivity. Local development instead uses the authenticated WebSocket relay in `net/localRelay.mjs` and `net/relaySessions.mjs`, with the browser transport in `public/networkRelay.mjs`. Two-browser Chrome QA exercises actual Godot input/checksum exchange with WebRTC disabled. Physical Android and cross-device QA still require verification on the target network.

## Build

Export Godot Web to `public/play/game.html`, then run `python compress-web.py`. Build the Worker and assets through the Sites build helper, retaining the existing project ID and audience. Tests: Godot headless gdUnit4 `-s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://test`; pause/resume smoke `-s res://test/network_gate_smoke.gd`; JS API/peer/lobby tests `node --experimental-vm-modules --test net/test/*.test.mjs`.

### Arena update — combos, hub and movement

The main hub has quick play, the existing online lobby, a fighter carousel, arena cards and a combo guide. No network API changes are required. The web and native HUD now show a persistent combo count and scaled total damage, health numbers and a delayed damage trail.

Confirmed normals can chain LP → LK → MP → MK → HP/HK. Reverse links are rejected; heavy standing attacks end a combo of at least three hits in knockdown, have extra startup/recovery and launch away. Knockdown cannot be re-hit; wake-up has 18 frames of protection which attacking cancels. A counter during startup adds four stun frames. Repeat-button stamina penalties remain enabled. Original nonverbal WAV effects are reproducible with `python tools/create_arena_sounds.py`.

Movement retains fixed-step simulation. Vertical body separation permits jumping across an opponent, with facing updated on landing. Polina teleports across the target; at the arena edge the pair is placed inward to preserve the 46-pixel spacing. Walking has softer reversals and less bob, plus continuous weight shifts. Jump source bounds exclude neighbouring kick shoes without changing the original PNG atlases.

### Eight-frame locomotion and hub typography

Nine fighters now have dedicated eight-frame walk cycles in three shared transparent atlases. Maris has a separate eight-frame quadrupedal cycle with idle breathing and movement tied to distance. `LocomotionAtlas` keeps source UV bounds; `LocomotionArt` replaces the old frame renderer only for applicable states, preserving hit reactions and ability poses. Original PNG files are used unchanged. Health is 1500 for every fighter; attacks retain their damage. Damage tests now compare with each fighter's maximum health.

The hub uses bundled Oswald and Manrope variable fonts, charcoal/chartreuse styling, a new matchup illustration, four functional mode entries and responsive fighter/arena rails. Existing selection, touch controls and online rooms remain connected. Network protocol 3 rejects old clients with incompatible health rules.

### HUD, combo finishers and accelerated buffs

Standing heavy attacks knock down only on hit three or later in a continuous combo; isolated hits use normal stagger and capped pushback. Sweeps and throws retain knockdown. Rafael's energy makes normals cost zero stamina, including when empty, while retaining repeat-button restrictions. Positive buffs shorten attack startup, active and recovery on a private move copy (energy 1.45, protein 1.15, rage 1.25, Maris 1.5, fish 1.1; stacking capped at 2.1). Protein/fish also give small movement boosts. Active attacks keep their sampled timing until complete; subsequent attacks return to normal after the buff.

The native HUD now has framed health panels, bundled Manrope typography, numeric HP, critical-health color and an energy no-cost status. Touch controls keep their positions and keyboard mapping, with rounded square buttons, larger normal labels, pressed states and cooldown progress arcs based on each ability's actual cooldown.

### Combo cameo

A completed series of three or more clean hits pops a user-photo cameo up from the bottom center with “ТВИСТИИ!” and the user-requested original short Toasty voice excerpt. Knockdown finishers trigger immediately; non-knockdown combos trigger when stun ends. The presentation never changes combat state, checksums or inputs. A three-second cosmetic cooldown prevents overlapping cameos, round reset clears pending effects, and the existing audio mute/volume controls apply. Audio attribution and its separate non-CC0 provenance are in the sound sources and public credits.

### Mavrin's rare phone assist

Each accepted phone activation draws one uniform seeded roll from 0..9; only zero summons Salahov (10%). The answer resolves after 24 simulation frames and an interrupt before then cancels it. Failure stays cosmetic. The helper arrives with a warning, closes some distance and performs five localized strikes (80,80,100,100,180 base damage) with existing combo damage scaling; the final kick is a combo finisher. Opponents can block, evade the strike zone or use invulnerability. After spawning, the helper completes independently of Mavrin being hit; round transitions pause/clear it like other effects. The CPU can now also use the phone. Shared RNG, phone timers/rolls and summon progression are covered by deterministic sync diagnostics; protocol 5 rejects incompatible older clients.

The helper's eight-pose transparent atlas is original ImageGen art based on the supplied reference. UV bounds and the extended-kick polygon exclude neighbouring poses without editing the original raster.

### Юсуп

Новый боец по фотографии: «А забей» останавливает обоих участников на время двух последовательных реплик и затем удерживает выносливость противника на нуле 120 кадров; «Мне холодно!» после поднятия пульта включает красный фильтр арены и горение на 180 кадров; «Плавунец» меняет костюм и наносит контактный урон мельницей руками в течение 300 кадров. Таймеры работают при 60 Гц и включены в сетевую диагностику; протокол 6 отклоняет несовместимые старые клиенты. Перезарядки: 10, 12 и 11 секунд.

Реплики синтезированы Microsoft Pavel и сопровождаются субтитрами. Новый RGBA-атлас создан встроенным ImageGen по фотографии; файлы и UV-границы описаны в game/assets/yusupArt.md.

### Ринат, апперкот и облики

Ринат добавлен в обычный бой, против ИИ и онлайн. Q: «Ты Орлов? Иди сюда!» — блокируемая цепь, притягивание, затем удержание на 60 кадров; откат 8 с. E: 36 кадров питья, которые прерываются ударом, затем 15 с пьяного мастера: +25% урона, пластичные позы, случайное разрывание рубашки и оригинальные синтетические татарские выкрики. Пение замедляет соперника на 30% на 1,5 с и не блокирует собственные атаки. Откат — 20 с после окончания режима. R: большой вейп и облако на 2 с; четыре тика по 6 HP, откат 3 с. Между раундами всё останавливается и очищается.

Только у Рината: вниз + любая рука (S + U/I/O, либо ↓ + Р1/Р2/Р3) — апперкот с подбросом и отбрасыванием. Нокаутирующий удар освобождает противника из цепи. Скины выбираются отдельно для каждого игрока: Ринат — обычный/Скорпион; Владислав — обычный/Пакито. Они косметические; выбор сохраняется на устройстве и синхронизируется через комнату, сервер проверяет совместимость бойца и скина. Миграция `0001_mighty_mesmero.sql` добавляет поля обликов без изменения старых миграций. Сетевой протокол `arena-net-8-rinat` отклоняет старые клиенты.

Пять прозрачных ImageGen-атласов содержат 160 поз. PNG не редактировались; `tools/build_rinat_regions.py` воспроизводит контуры/опорные точки по альфа-каналу. Брифы и SHA-256 — `game/assets/rinat/ART.md`; синтетическая озвучка и оригинальный звук пара воспроизводятся через `tools/create_rinat_audio.py`. После экспорта Godot выполняйте `python compress-web.py`: пакет разбивается на проверяемые SHA-256 части по 2 МиБ, промежуточные PCK/WASM не входят в статические файлы. Загрузчик/упаковщик совместим с работой над Русланом в PR #4.

Проверка Рината/обликов: `--headless --path game -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://test/integration/test_rinat.gd -a res://test/integration/test_rinat_art.gd`; native visual smoke: `--path game -s res://test/rinat_visual_smoke.gd -- /absolute/output/directory`. Браузерный прогон и два физических устройства требуют отдельной проверки.

### КУДЕСНИК — Суйтон, сырки и фаталити

Никита получил 128 новых кадров в четырёх атласах: движение, удары, печати/струя/старые способности, реакции/падения/победа. T (игрок 2: −): печати 36 кадров, тонкая водяная струя на 30 кадров, до 180 базового урона за одно попадание; откат 900 кадров (15 с). Питьё/печати можно прервать ударом, струю можно блокировать или избежать присев/прыгнув.

Рафаэль Биг Босс: T достаёт/убирает коробку сырков «Александров», запас строго 12 за раунд. Любая кнопка удара бросает один сырок (55 базового урона, пауза 26 кадров); в этом режиме отключены обычные атаки, броски и Q/E/R. Убирание коробки не пополняет запас. Новый атлас содержит 31 позу с коробкой; один слот отдан летящему сырку и в метаданных удерживает предыдущую позу тела.

Маврин: T — «КЭТ», один случайный союзник из текущего ростера с характерным ударом, откат 12 с. G рядом с Полиной — разговорный захват/потряхивание без урона и без отката; G через полсекунды отпускает раньше. На сенсорном управлении есть отдельные кнопки. Исходные три способности и полёт сохранены.

Ринат: полёт цепи замедлен, проверка пересечения идёт во время полёта. Захват держится 120 кадров, удержание любой атаки тянет врага к Ринату; без нажатия автоматического притягивания нет. Кровь — короткие косметические частицы при чистом попадании/броске, с отдельным RNG. Разгон/торможение мягче, управление в воздухе слабее, падение немного тяжелее.

После решающего нокаута матча автоматически играет одно из 11 уникальных фаталити на основе способностей победителя. Новые косметические скины — палитры одежды и анимированные аксессуары; Скорпион/Пакито сохранены. Протокол `arena-net-10-counter-shave` использует 16-битные маски, таймеры/боезапас/помощники включены в контрольные суммы.

`game/assets/nikita-v2/ART.md` содержит брифы и происхождение атласов. `python tools/measure_expansion_atlases.py` измеряет альфа-компоненты, не редактируя PNG. Для пересборки игрового пакета с прежним Web-движком: `godot --headless --path game --export-pack Web ../public/play/game.pck`, затем `node scripts/package-game.mjs` и переместите `public/play/game.pck` в `game.pck.intermediate` вне каталога public (иначе статический хост получит лишний файл >25 МиБ). Web WASM/JS не изменились. Проверки: `test_kudesnik.gd`, обновлённый `test_rinat.gd`, сетевые Node-тесты.

Захват Полины Мавриным: совместный ImageGen-атлас на 12 поз заменяет линейную заглушку. Обе руки держат Полину за корпус, затем следуют подъём, встряхивания и опускание. Пара зеркалится по направлению бойца; урон, таймер и реплики сохранены. Метаданные контуров: `tools/measure_hold_atlas.py`, бриф: `game/assets/grapples/ART.md`.


Полина: в 50% захватов Маврина появляется случайная кнопка атаки. Окно — с 60-го кадра до последних 60 кадров захвата; одна попытка, неверная кнопка её расходует. Успех запускает 16 парных поз на 96 кадров, на 30-м кадре контакта Маврин получает 300 урона, Полина освобождается. Без подсказки/нажатия сам захват по-прежнему не наносит урон.

Рамис: T (второй локальный игрок: −) запускает бритьё на 120 кадров, откат с начала 600 кадров. Попадание, бросок или заморозка прерывает подготовку без усиления. Завершение оставляет лысую форму до конца раунда и один заряд: следующий попавший обычный удар нокаутирует, включая блок. Промах и спецприёмы заряд не тратят. Новый атлас на 24 позы содержит бритьё, лысую стойку, движение, реакции и удар. Описание и промпты: `game/assets/grapples/COUNTER-SHAVE-ART.md`. Новые таймеры, результат случайного выбора и заряд входят в lockstep digest; протокол обновлён, чтобы исключить бой разных версий.

После победы усиленным ударом Рамис разрывает рубашку, остаётся с голым торсом и поворачивается к камере. Для обычного раунда выделены 150 кадров; в решающем раунде используется отдельная победная сцена вместо солнечного фаталити.


### Рамис — серьёзный удар

После успешного бритья Рамис превращается в героя: жёлтый комбинезон, красные перчатки/сапоги, белый плащ; лицо и очки сохранены. Новые 96 поз в шести атласах (переодевание, движение, замах, разгон, удар о землю, победа) и отдельный портрет слева. Костюм сохраняется до следующего раунда.

Первый попавший обычный удар, включая удар в блок, запускает сцену на 204 тика. Урон и нокаут происходят на 114-м тике, затем заканчивается вбивание и восстановление. До конца сцены таймер раунда и переход к KO приостановлены, оба бойца заблокированы; проигравший остаётся частично в кратере. После сцены обычный экран победы освобождает обзор на лицо героя; повторного фаталити нет. Кратер, скрытие соперника, костюм и состояние сцены очищаются при новом раунде. Промах не расходует заряд. Перезарядка бритья 10 с, подготовка 2 с и возможность её сбить сохранены.

Протокол `arena-net-11-ramis-ultimate`: возраст сцены, связи бойцов, положение кратера и момент попадания включены в digest. Визуальные эффекты без игрового RNG. Тесты: `test_ramis_ultimate.gd`, `test_counter_shave.gd`, `test_kudesnik.gd`; визуальная проверка `test/ramis_ultimate_visual.gd`. Брифы и исходники: `game/assets/ramis-hero/ART.md`.
