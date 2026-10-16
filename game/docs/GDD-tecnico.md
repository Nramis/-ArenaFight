# GDD Técnico — Juego de pelea 2D (2 shotos), estilo SF2

> Documento de diseño técnico consolidado. Punto de partida: Street Fighter 2, evolucionando hacia un juego propio.
> Estado: **diseño cerrado, sin ambigüedad para v1.** Los valores numéricos son *iniciales* y se afinan jugando.
> Motor: **Godot 4.x** · GDScript · **60 FPS fijos** · v1 **solo local**.

---

## 0. Índice

1. Visión y alcance
2. Decisiones cerradas (tabla maestra)
3. Game loop y timing
4. Sistema de frames (startup / active / recovery, ventaja, stun)
5. Cajas: hitbox / hurtbox / pushbox / throwbox
6. Inputs (6 botones, botones virtuales, buffer, motions)
7. Movimiento y física (caminar, dash, salto)
8. Mecánicas de combate (bloqueo, chip, throws, combos, scaling, hitstop, knockdown)
9. Los 2 personajes (movelist + tabla de frame data)
10. IA del CPU (arquitectura + niveles)
11. Estructura de combate, escenario y cámara
12. Arquitectura de código en Godot (nodos, Resources, archivos)
13. Roadmap por fases (milestones)
14. Glosario

---

## 1. Visión y alcance

Un juego de pelea 1v1, 2D, con **2 personajes shoto** (arquetipo Ryu/Ken: proyectil + antiaéreo invencible + especial que avanza). Fidelidad mecánica a SF2 como base, con libertad para diferenciarnos después. v1 es **local** (2 jugadores en el mismo equipo + modo vs CPU), sin online.

**Pilares de diseño:**
- Neutral clásico: footsies, zoning, antiaéreos, whiff punish.
- Combos por **links y cancels** (normal → especial).
- IA **justa** (no tramposa): la CPU emite los mismos inputs que un humano.
- Arquitectura **data-driven**: la frame data vive en Resources `.tres`, se balancea sin recompilar.

---

## 2. Decisiones cerradas (tabla maestra)

| Área | Decisión |
|---|---|
| Motor | Godot **4.x**, GDScript |
| Timing | **60 FPS fijos**, toda la lógica en `_physics_process` |
| Online | **Solo local** en v1 (sin rollback / sin determinismo estricto) |
| Recursos en pantalla | **Solo barra de vida** (sin súper/EX) |
| Dizzy/mareo | **No** |
| Botones | **6 botones** SF2: `LP MP HP / LK MK HK` |
| Control | Teclado **y** mando (capa de botones virtuales) |
| Bloqueo | Por dirección: **atrás = alto**, **abajo-atrás = bajo** |
| Agacharse | **Sí**, con normales propios agachado |
| Combos | **Links y cancels** (normal → especial) |
| Chip damage | **Sí**, y **puede matar** (estilo SF2) |
| Throws | **Sí**, con **throw tech** (escapables) |
| Salto | **Sí**, saltos comprometidos + cross-up |
| Dash | **Sí**, adelante y atrás |
| Especiales | **3 versiones L/M/H** por especial |
| Normales | **1 por botón y postura** (18 por personaje) |
| Personajes | 2 shotos: **A = zoner paciente**, **B = rushdown agresivo** |
| Rounds | **Best of 3**, timer **99s**, gana quien tenga más vida al agotarse |
| Escenario | Plano con **paredes/esquina**, cámara que sigue a ambos + zoom |
| Arte | **Assets libres / de terceros** (⚠️ revisar licencias si se publica) |
| CPU | **3 niveles**: Fácil / Medio / Difícil (por parámetros, nunca trampa) |

---

## 3. Game loop y timing

- **1 frame = 1/60 s ≈ 16.67 ms.** Es la unidad mínima de tiempo del juego.
- **Toda la lógica** (movimiento, avance de ataques, hitstun, buffers, IA) vive en `_physics_process`. `_process` solo para lo visual (interpolación de sprite, cámara suave, partículas, UI).
- No escalar la lógica por `delta`: se trabaja en **unidades por frame** (`position += velocity_per_frame`). Como v1 es local, usamos `float` con normalidad (no exigimos determinismo bit-a-bit).

```gdscript
func _ready():
    Engine.physics_ticks_per_second = 60

func _physics_process(_delta):
    frame += 1
    _read_inputs()
    _advance_state_machine()
    _resolve_hits()
```

> Aunque v1 sea local, mantenemos la **higiene**: lógica en `_physics_process`, estado del personaje reducido a variables simples (enteros/enums) y FSM clara. Esto no cuesta nada y deja la puerta abierta a rollback en el futuro sin reescribir el motor.

---

## 4. Sistema de frames

### 4.1 Fases de un ataque

| Fase | Definición | Vulnerabilidad |
|---|---|---|
| **Startup** | Frames hasta el 1.er frame activo (inclusive). El hitbox aún no existe | Interrumpible |
| **Active** | Frames en que el hitbox puede impactar | Vulnerable |
| **Recovery** | Frames tras el active hasta volver a neutral. No puede atacar/bloquear/moverse | Muy vulnerable (whiff punish) |

`Total = Startup + Active + Recovery`. Convención: "4 de startup" = conecta por primera vez en el frame 4. Notación en tablas: `startup / active / recovery`.

### 4.2 Ventaja en frames

```
Frame advantage = (stun del defensor) − (frames de recovery restantes del atacante desde el impacto)
```
- **On hit** siempre más ventajoso que **on block** (hitstun > blockstun).
- **Safe on block**: ventaja ≥ −3/−4 (el jab más rápido no llega a castigar).
- **Unsafe**: si `−(ventaja) ≥ startup del castigo más rápido del rival`.

### 4.3 Estados de aturdimiento

| Estado | Qué es | Valores iniciales |
|---|---|---|
| **Hitstun** | Congela al defensor golpeado; permite combos | light 12 / medium 16 / heavy 20 f |
| **Blockstun** | Igual al bloquear; algo menor que el hitstun | ≈ hitstun − 3 |
| **Hitstop** | Pausa de **ambos** en el impacto (no afecta la ventaja) | light 8 / medium 11 / heavy 14 f |
| **Pushback** | Empuje horizontal al golpear/bloquear | por golpe (ver tablas) |

### 4.4 Knockdown / wakeup / oki

- **Knockdown**: barridos (`cr.HK`), throws y algunos especiales derriban.
- **Wakeup**: tiempo de levantada **fijo y conocido** (v1: ~40 frames desde que toca el suelo) → permite oki y meaties.
- v1: **hard knockdown** simple (sin quick-rise / tech-roll de suelo). Se puede añadir después.

---

## 5. Cajas: hitbox / hurtbox / pushbox / throwbox

| Caja | Rol | Regla |
|---|---|---|
| **Hitbox** | Zona ofensiva del ataque | Activa solo en frames *active* |
| **Hurtbox** | Zona vulnerable | Recibir hit = hitbox rival solapa tu hurtbox |
| **Pushbox** | Ocupación física | No puede solaparse con la del rival → se empujan |
| **Throwbox** | Caja de agarre | Ignora bloqueo; busca hurtbox a rango corto |

- **Invencibilidad** = quitar el hurtbox durante ciertos frames (ej. inicio del Shoryuken).
- **Trade**: si ambos hitboxes solapan el hurtbox contrario el mismo frame, ambos reciben hit.
- **Counter hit**: golpear al rival durante su startup/recovery → hitstun aumentado (v1: +4 f de bonus), abre combos.

Implementación Godot: **dos `Area2D`** (hitbox y hurtbox) con `CollisionShape2D`. `collision_layer` = "lo que eres", `collision_mask` = "lo que buscas". Al activar un hitbox, escanear `get_overlapping_areas()` para no perder solapamientos ya existentes. Detección consultada activamente en `_physics_process` durante los frames activos (control exacto del frame de impacto).

---

## 6. Inputs

### 6.1 Los 6 botones

| | Puños | Patadas |
|---|---|---|
| Light | **LP** (jab) | **LK** (short) |
| Medium | **MP** (strong) | **MK** (forward) |
| Heavy | **HP** (fierce) | **HK** (roundhouse) |

### 6.2 Capa de botones virtuales

No mapear acciones directamente a teclas. Cada frame se construye un **estado de input** (entero con bits): `up/down/fwd/back` + `LP/MP/HP/LK/MK/HK`. `fwd/back` se resuelven según el lado del personaje. Esta capa la alimentan por igual el humano (teclado/mando) y la IA.

### 6.3 Input buffer

Anillo de ~60 frames (1 s) con el input de cada frame + su dirección en **notación numpad**. Sirve para leniency de ejecución y para detectar motions.

### 6.4 Motions (numpad)

```
7 8 9      6 = adelante   2 = abajo   4 = atrás
4 5 6      5 = neutro     3 = abajo-adelante ...
1 2 3
```

| Motion | Nombre | Especial |
|---|---|---|
| `236P` | Quarter-circle forward | **Hadouken** |
| `623P` | Dragon punch (Z) | **Shoryuken** |
| `214K` | Quarter-circle back | **Tatsumaki** |

Matching: recorrer el buffer **hacia atrás** desde el frame del botón, validando cada dirección dentro de una ventana de tolerancia (~12 f) con matching **difuso** (acepta diagonales adyacentes). Prioridad al comprobar: `623` antes que `236` antes que normales. Dash = doble toque de dirección (ventana ~10 f).

---

## 7. Movimiento y física

Valores **iniciales** (px/frame a 60 fps), a afinar. Personaje A / Personaje B donde difieren.

| Acción | Personaje A (zoner) | Personaje B (rushdown) |
|---|---|---|
| Caminar adelante | 3 px/f | 4 px/f |
| Caminar atrás | 2 px/f | 3 px/f |
| Dash adelante | ~7 px/f, 14 f total (3 startup / 8 move / 3 recovery) | ~8 px/f, 12 f total |
| Dash atrás | ~6 px/f, 16 f (con pocos i-frames iniciales) | igual |
| Salto | prejump 4 f, arco ~44 f en aire | igual |
| Altura de salto | gravedad 1, vel. inicial ~22 | igual |

- **Saltos comprometidos**: se elige dirección (neutral / adelante / atrás) al despegar; **sin control aéreo**.
- **Cross-up** permitido (saltar por encima y golpear del otro lado → invierte el bloqueo).
- **Dash**: adelante da movilidad al rushdown; atrás para reposicionar. El rushdown (B) tiene dash más rápido/corto.
- **Esquina**: el pushbox tope contra la pared del escenario permite acorralar.

---

## 8. Mecánicas de combate

### 8.1 Bloqueo
- **Atrás** = bloqueo alto (defiende golpes altos/medios y proyectiles).
- **Abajo-atrás** = bloqueo bajo (defiende golpes bajos).
- **Overheads** (algunos jump-ins y golpes designados) deben bloquearse alto.
- **Bajos** (`cr.MK`, `cr.HK`) deben bloquearse abajo.
- No se puede bloquear en el aire (v1). No hay auto-block.

### 8.2 Chip damage
- Bloquear un **especial** inflige chip (~15% del daño del golpe).
- El chip **puede matar** (dejar la vida a 0). Los **normales bloqueados NO** hacen chip.

### 8.3 Throws
- Rango corto (throwbox). Startup ~5 f. Daño ~120. Provoca **knockdown**.
- **Throw tech**: si el defensor pulsa throw dentro de una ventana (~7 f) tras el intento rival, el agarre se rompe (ambos se separan, sin daño).
- No se puede agarrar a un rival en hitstun/blockstun/aire.

### 8.4 Combos
- **Links**: encadenar dos normales completos aprovechando la ventaja on hit. Ventana = `ventaja − startup + 1`.
- **Cancels**: interrumpir el recovery de un normal en un especial (`cr.MK xx Hadouken`). Cada `MoveData` declara en qué especiales es cancelable.
- Jerarquía: **Normal → Especial** (v1 no hay súper, así que no hay super-cancel).

### 8.5 Damage scaling
Para evitar que un combo mate de un toque:

| Hit del combo | Multiplicador |
|---|---|
| 1.º – 2.º | 100% |
| 3.º | 80% |
| 4.º | 60% |
| 5.º | 40% |
| 6.º+ | 20% (piso) |

Además, **hitstun decay**: cada hit del combo reduce ligeramente el hitstun, para que el combo no se alargue indefinidamente.

### 8.6 Health
- Vida total = **1000** puntos (fácil de balancear). Igual para ambos personajes (sin diferencias de stamina en v1).

---

## 9. Los 2 personajes

Ambos comparten la **base de normales** y la **tríada** (`236P` / `623P` / `214K`). Se diferencian por **propiedades de especiales, velocidad y matices de frame data**. Nombres temporales: **A = "Kaze"** (zoner), **B = "Homura"** (rushdown) — provisional, cámbialos cuando quieras.

### 9.1 Normales (frame data inicial, compartida salvo notas)

Formato: `startup / active / recovery` · dmg · `on block` / `on hit` · cancelable.

**De pie:**
| Botón | S/A/R | Dmg | Block/Hit | Cancel | Rol |
|---|---|---|---|---|---|
| st.LP | 4/3/7 | 30 | −1 / +2 | Sí | jab rápido |
| st.MP | 6/3/12 | 60 | −2 / +2 | Sí | starter |
| st.HP | 9/4/18 | 90 | −5 / +1 | No | daño |
| st.LK | 5/3/8 | 30 | −2 / +1 | No | poke corto |
| st.MK | 7/4/14 | 60 | −3 / +2 | No | poke (footsie) |
| st.HK | 11/4/20 | 90 | −7 / KD | No | poke largo |

**Agachado:**
| Botón | S/A/R | Dmg | Block/Hit | Cancel | Rol |
|---|---|---|---|---|---|
| cr.LP | 4/3/6 | 25 | 0 / +3 | Sí | presión |
| cr.MP | 6/3/11 | 55 | −2 / +2 | Sí | antiaéreo cercano |
| cr.HP | 8/4/16 | 85 | −4 / +1 | No | **antiaéreo** |
| cr.LK | 5/2/7 | 20 | −2 / +1 | Sí | **bajo** rápido |
| cr.MK | 7/3/14 | 55 | −3 / +2 | Sí | **bajo, starter estrella** |
| cr.HK | 9/3/22 | 90 | −12 / KD | No | **barrido** (knockdown) |

**En el aire (jump-in):**
| Botón | S/A | Dmg | Rol |
|---|---|---|---|
| j.LP | 4/6 | 30 | air-to-air |
| j.MP | 6/5 | 55 | air-to-air |
| j.HP | 8/4 | 90 | **jump-in** fuerte |
| j.LK | 5/8 | 30 | **cross-up** |
| j.MK | 7/5 | 55 | cross-up / jump-in |
| j.HK | 9/4 | 90 | jump-in fuerte |

### 9.2 Especiales (3 versiones L/M/H)

**Hadouken `236P`** — proyectil de zoning. L/M/H cambian la **velocidad** del proyectil.
| Versión | Startup | Recovery | Vel. proyectil | Dmg |
|---|---|---|---|---|
| A (Kaze) L/M/H | 11 | **34** | lenta / media / rápida | 60 |
| B (Homura) L/M/H | 13 | **40** | lenta / media / rápida | 55 |

> Diferenciación: **A tiene mejor fireball** (menos recovery → mejor zoning).

**Shoryuken `623P`** — antiaéreo invencible, muy castigable al aterrizar.
| Versión | Startup | i-frames | Dmg | Notas |
|---|---|---|---|---|
| A L / M / H | 4 / 4 / 5 | 1–5 | 80 / 100 / 120 | 1 hit; DP **seguro/invencible fiable** |
| B L / M / H | 3 / 4 / 5 | 1–4 | 90 / 110 / 130 | **multi-hit** en M/H; más daño, algo más punible |

> Diferenciación: **B tiene mejor DP** (más rápido, multi-hit, más daño; a cambio menos i-frames).

**Tatsumaki `214K`** — movimiento/combo; L/M/H cambian **distancia y nº de hits**.
| Versión | Startup | Recovery | Dmg | Notas |
|---|---|---|---|---|
| A L/M/H | 11 | 12 | 70/80/90 | 1–2 hits; para combo/escape |
| B L/M/H | 11 | 8 | 70/85/100 | multi-hit + **mixup de cruce** en knockdown |

### 9.3 Throw
- `LP+LK` (o botón dedicado): rango corto, 120 dmg, knockdown, techable ~7 f.

### 9.4 Resumen de identidad
- **A (Kaze) — zoner paciente**: mejor fireball, DP fiable y seguro, caminado normal. Premia control de espacio y whiff punish.
- **B (Homura) — rushdown**: fireball peor, **dash más rápido**, DP/Tatsu multi-hit, mejor caminado. Premia presión y oki de esquina.

---

## 10. IA del CPU

### 10.1 Principio rector
La IA **no llama funciones de gameplay**; produce **los mismos inputs virtuales** que un humano, que alimentan la **misma FSM** del `Fighter`. Justicia mecánica gratis (respeta startup/recovery/anti-mashing).

### 10.2 Arquitectura (2 capas)
- **Percepción retrasada**: la IA "ve" un snapshot de hace `reaction_delay_frames` (~15 f ≈ 250 ms). Si un golpe rival tiene menos startup que el delay, la IA **no puede reaccionar** → debe predecir (como un humano).
- **Macro (FSM)** por distancia: `ZONING` (fullscreen) / `FOOTSIE` (media) / `RUSHDOWN` (corta) / `ANTIAIR` (rival en el aire, prioridad) / `DEFEND`.
- **Micro (Utility scoring)**: dentro del modo, puntúa las acciones candidatas (poke, whiff-punish, throw, dash, antiaéreo, proyectil) y elige por **selección ponderada** (no siempre la óptima → carácter predecible pero no explotable).

### 10.3 Niveles de dificultad (por parámetros, nunca trampa)

| Parámetro | Fácil | Medio | Difícil |
|---|---|---|---|
| Reaction delay (f) | 25–30 | 16–20 | 12–15 |
| Re-decisión cada (f) | 12–15 | 6–8 | 2–3 |
| Prob. de bloquear reaccionable | 30–50% | 60–75% | 85–95% |
| Calidad de combo | corto, dropea | medio | óptimo |
| Whiff-punish | rara vez | a veces | casi siempre |
| Ruido/errores | alto | medio | bajo |

Loop de la IA en `_physics_process`: **PERCIBIR** (buffer retrasado) → **DECIDIR** (cada N frames, si `fighter.can_act()`) → **EJECUTAR** (drenar 1 input virtual por frame).

---

## 11. Estructura de combate, escenario y cámara

- **Rounds**: best of 3 (primero a 2). **Timer 99 s**; al agotarse gana quien tenga más vida (doble KO / empate si igual → round extra o ambos pierden, a decidir en tuneo).
- **Escenario**: plano, ancho limitado con **paredes**. El pushbox tope contra la pared → **esquina** (clave para la presión/oki).
- **Cámara**: sigue el punto medio de ambos personajes; **zoom** dinámico según la distancia (acercar cuando están juntos, alejar hasta el límite del escenario).
- **Resolución interna**: estilo arcade (~**384×224**) escalada a pantalla con filtro nearest (pixel perfecto).
- **UI**: 2 barras de vida (arriba), timer central, pips de rounds ganados, indicador de combo counter.

---

## 12. Arquitectura de código en Godot

### 12.1 Nodos del personaje
```
Fighter (CharacterBody2D)          # misma clase para P1, P2 y CPU
├── Sprite2D / AnimatedSprite2D
├── AnimationPlayer                # anima frame + conmuta hitboxes
├── Hurtbox (Area2D)
│   └── CollisionShape2D
├── Hitbox (Area2D)                # activada por frame
│   └── CollisionShape2D  (disabled por defecto)
├── Pushbox (colisión física)
└── Throwbox (Area2D)
```

### 12.2 Fuente de inputs (desacople humano/IA)
```
InputSource (interfaz)
├── HumanInputSource  → teclado/mando → InputFrame
└── AIInputSource     → AIController  → InputFrame
El Fighter recibe un InputFrame por tick y NO sabe quién lo controla.
```

### 12.3 Data-driven (Resources `.tres`)
- **`MoveData`** (`extends Resource`): `startup, active, recovery, damage, hitstun, blockstun, pushback, launch, cancelable_into[], input_motion, animation, hitbox_shape`.
- **`CharacterData`** (`extends Resource`): `max_health, walk_speed, dash_data, jump_velocity, gravity, sprite_frames, moves[]`.
- **`InputMotion`** (`extends Resource`): `directions[], window, strict`.
- Balancear = editar `.tres` en el Inspector, sin recompilar.

### 12.4 FSM del personaje
**State Machine basada en nodos** (mejor práctica 2026 para proyectos local/mantenibles: un nodo = un estado = un archivo corto; cada estado decide sus propias transiciones; la máquina solo delega). Evita la "sopa de booleanos". Estados: `Idle, WalkFwd, WalkBack, Crouch, DashFwd, DashBack, JumpStartup, Jump, Attack, BlockHigh, BlockLow, Hitstun, Blockstun, Throw, Thrown, Knockdown, Wakeup`.

> **Ver el detalle completo (esqueletos de clases comentados, componentes, event bus, antipatrones) en** [arquitectura-codigo.md](arquitectura-codigo.md), basado en el consenso Godot 2025–2026.

### 12.5 Estructura de archivos (propuesta)
```
juego-pelea-shotos/
├── docs/GDD-tecnico.md
├── scenes/
│   ├── Fighter.tscn
│   ├── Stage.tscn
│   └── Match.tscn            # HUD, rounds, cámara
├── scripts/
│   ├── fighter.gd
│   ├── state_machine.gd
│   ├── input_source.gd / human_input.gd / ai_input.gd
│   ├── ai_controller.gd
│   ├── input_buffer.gd
│   └── match_manager.gd
├── data/
│   ├── characters/kaze.tres / homura.tres
│   ├── moves/kaze_*.tres / homura_*.tres
│   └── motions/qcf.tres / dp.tres / qcb.tres
└── assets/ (sprites, sfx — placeholder/libres)
```

---

## 13. Roadmap por fases (milestones)

Cada fase es jugable y valida algo antes de pasar a la siguiente. **Arte con cajas/placeholder al inicio** aunque usemos assets libres después.

- **Fase 0 — Esqueleto**: proyecto Godot, loop 60 fps, un `Fighter` con caja, mover izquierda/derecha, dos jugadores en teclado.
- **Fase 1 — Movimiento**: caminar, agacharse, saltar (comprometido), dash, paredes/esquina, cámara con zoom.
- **Fase 2 — Ataques y cajas**: FSM de ataque (startup/active/recovery), hitbox/hurtbox, los 18 normales con frame data desde `MoveData`, hitstun/hitstop.
- **Fase 3 — Defensa**: bloqueo alto/bajo, blockstun, chip, pushback, throws + throw tech, knockdown/wakeup.
- **Fase 4 — Especiales y combos**: input buffer + motions (236/623/214), 3 versiones L/M/H, cancels y links, damage scaling.
- **Fase 5 — Los 2 personajes**: diferenciación A/B (fireball, DP, tatsu, velocidad), balance inicial.
- **Fase 6 — Match**: rounds best-of-3, timer 99s, HUD (vida, timer, pips, combo counter), KO, rematch.
- **Fase 7 — IA**: `AIController` (percepción retrasada, macro FSM + utility), 3 niveles de dificultad.
- **Fase 8 — Arte y pulido**: integrar sprites/assets libres, SFX, efectos de impacto, pantallas de menú.

---

## 14. Glosario

| Término | Definición |
|---|---|
| Frame | Tick lógico, 1/60 s |
| Startup / Active / Recovery | Inicio / golpe activo / recuperación de un ataque |
| Frame advantage | Ventaja en frames tras hit/bloqueo |
| Hitstun / Blockstun | Congelamiento del defensor al golpear / bloquear |
| Hitstop | Pausa de ambos en el impacto |
| Hitbox / Hurtbox / Pushbox / Throwbox | Caja de golpe / de daño / de empuje / de agarre |
| Cancel / Link | Interrumpir recovery en especial / encadenar normales completos |
| Meaty | Golpear con el último frame activo sobre un rival que se levanta |
| Oki (okizeme) | Presión sobre el rival caído |
| Cross-up | Saltar por encima para golpear del lado contrario |
| Shoto | Arquetipo Ryu/Ken: fireball + antiaéreo invencible + especial que avanza |
| Numpad notation | 236 = QCF, 623 = DP, 214 = QCB |

---

*Fin del GDD técnico v1. Todo aprobado y sin ambigüedad de diseño. Los números son iniciales y se afinan jugando. Siguiente paso: cuando lo apruebes, empezamos por la **Fase 0** del roadmap.*
