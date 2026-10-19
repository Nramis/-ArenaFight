# Арена

### Руслан: капитал, комбо и риск

Одиннадцатый боец с 144 вариантами поз (48 поз в каждом из трёх атласов одежды). Капитал равен HP: при снижении до 66% исчезает куртка, до 33% — остаются спортивные шорты. Лечение возвращает одежду; при получении ударов выпадают монеты.

Три чистых нормальных попадания лечат один раз за комбо: 24% урона серии, максимум 90 HP. «Коллектор» (рука 1 → рука 2 → рука 3) усиливает тяжёлый удар на 18% и возвращает 32% урона серии. «Пенальти» (нога 1 → нога 2 → нога 3) усиливает удар на 12% и отброс на 90. Смешанная серия даёт +5 кадров оглушения. Блок, плов и дождь лечения не дают.

Q / ПЛОВ: подготовка 30 кадров, затем три летящие порции с уроном 54 до масштабирования; перезарядка 7 с. E / ТЕМНОТА: подготовка 36 кадров, силуэт Руслана темнеет, затем арена скрывается для обоих на ровно 240 кадров (4 с); управление остаётся доступным, перезарядка 16 с. R / КУБИКИ: два честных броска d6 из общего сетевого RNG. Дубль (1/6) вызывает 14 купюр с уроном 80 до масштабирования в отмеченной зоне; от дождя можно уйти или защищаться стоя. Иначе Руслан теряет 150 HP и может проиграть; перезарядка 12 с. Удар прерывает подготовку любой способности; уже выпущенные порции и дождь продолжаются. Короткие подсказки появляются на 3,5 с раз в 15 с.

Таймеры, результаты кубиков, история подтверждённых ударов и состояние снарядов включены в сетевую диагностику. Протокол 7 отклоняет несовместимые клиенты. Тесты Руслана: `res://test/integration/test_ruslan.gd`. Атласы и промпты описаны в `game/assets/ruslan/ART.md`.

Godot 4.7.2 fighting game, based on Shoto Fighter (MIT), with eleven custom characters, keyboard and touch controls. The original game license and art/sound credits are retained. Game source: `game/`. Browser assets and UI: `public/`. The root route serves `public/arena.html`.

## Локальный запуск

Требуются Node.js >= 22.13.0 и pnpm 11.25.0. В корне проекта выполните:

```powershell
pnpm install
pnpm db:migrate:local
pnpm dev:lan
```

Откройте `https://localhost:5173` или `https://<IP компьютера>:5173` с другого устройства в локальной сети. При первом открытии на каждом устройстве подтвердите исключение для локального самоподписанного сертификата. Если политика браузера запрещает исключения, используйте сертификат от доверенного центра, установленного на обоих устройствах.

`dev:lan` создаёт сертификат с адресами сетевых интерфейсов в `.sites-runtime/https` и запускает HTTPS-сервер. Для генерации требуется OpenSSL (в Windows входит в Git for Windows). После смены IP перезапустите команду: сертификат обновится автоматически. Готовая Web-сборка игры находится в `public/play`. Игровой пакет хранится в Git как части по 2 МиБ и манифест `pack.json`; браузер проверяет SHA-256 каждой части и собирает пакет при загрузке. После отдельного `--export-pack` выполните `node scripts/package-game.mjs`. Полный `game.pck` — локальный промежуточный файл.

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
