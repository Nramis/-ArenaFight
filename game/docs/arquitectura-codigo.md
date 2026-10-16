# Guía de Arquitectura de Código — Juego de pelea en Godot 4

> Cómo estructurar el código para **NO hacer un desastre**. Sigue el consenso del mercado 2025–2026
> (documentación oficial de Godot + repos de referencia + GDQuest).
> Etiquetas: **[OFICIAL]** = doc de Godot · **[CONSENSO]** = práctica aceptada · **[OPINIÓN]** = defendible pero debatible.
>
> Este documento muestra el **molde limpio** (estructura + esqueletos comentados **sin lógica de combate todavía**).
> Cuando empecemos a programar, solo rellenamos huecos en un molde ya ordenado.

---

## 0. Los 8 mandamientos anti-desastre

Si respetas estos 8, es muy difícil que el proyecto degenere en espagueti:

1. **Estructura por feature**, no por tipo de archivo. Cada personaje/sistema es autocontenido. **[CONSENSO]**
2. **State Machine basada en nodos**: un nodo = un estado = un archivo corto. Cero "sopa de booleanos". **[CONSENSO]**
3. **Composición sobre herencia**: capacidades transversales (Vida, Hitbox, Hurtbox) son nodos-componente, no herencia. **[CONSENSO]**
4. **"Call down, signal up"**: llamas hacia los hijos, avisas hacia arriba con señales. **[CONSENSO]**
5. **Nunca `get_node("../../..")`**: usa `@export` de referencias o `%NombreÚnico`. **[CONSENSO]**
6. **Autoloads solo para lo verdaderamente global** (EventBus, GameState, Audio). Es el antipatrón #1 abusarlos. **[OFICIAL]**
7. **Datos en Resources `.tres`** (frame data, personajes), no hardcodeados. Saves en JSON, nunca en Resources. **[OFICIAL]**
8. **Lógica en `_physics_process`, presentación en `_process`**. La animación *lee* el estado; no lo maneja. **[OFICIAL]**

---

## 1. Convenciones de nombres (guía de estilo oficial) [OFICIAL]

| Elemento | Convención | Ejemplo |
|---|---|---|
| Carpetas y archivos | **snake_case** | `state_machine.gd` |
| Nodos en el árbol | **PascalCase** | `HealthBar` |
| `class_name` / clases | **PascalCase** | `class_name Hurtbox` |
| Funciones y variables | **snake_case** | `func take_damage()` |
| Señales | **snake_case**, en **pasado** (evento que ocurrió) | `signal health_depleted` |
| Constantes | **CONSTANT_CASE** | `const MAX_SPEED = 200` |
| Enum: nombre / miembros | PascalCase / CONSTANT_CASE | `enum State { IDLE, WALK }` |
| Variables privadas | prefijo `_` | `var _internal_timer` |

**Orden de miembros dentro de un script** [OFICIAL]: `@tool`/`@icon` → `class_name` → `extends` → docstring `##` → `signal` → `enum` → `const` → `@export` → variables públicas → variables privadas → `@onready` → métodos estáticos → callbacks (`_ready`, `_physics_process`…) → métodos públicos → métodos privados.

Además: **tabs** (no espacios), tipado estático siempre que puedas (`var x: int`), comillas dobles, `and`/`or`/`not` en inglés. Mover/renombrar archivos **dentro del editor de Godot** (fuera desincroniza los UIDs).

---

## 2. Estructura de carpetas (por feature) [CONSENSO]

```
res://
├── addons/                    # plugins de terceros (GUT para tests, etc.)
├── assets/                    # arte/audio COMPARTIDO globalmente
│   ├── fonts/  music/  sfx/
├── globals/                   # autoloads (los mínimos)
│   ├── event_bus.gd           # señales globales (ronda, pausa, KO)
│   └── game_state.gd          # estado persistente (marcador, config)
├── components/                # componentes reutilizables (transversales)
│   ├── health/health.gd
│   ├── hitbox/hitbox.gd
│   ├── hurtbox/hurtbox.gd
│   └── input_buffer/input_buffer.gd
├── fighter/                   # el Fighter genérico (compartido por A y B)
│   ├── fighter.tscn
│   ├── fighter.gd
│   ├── state_machine.gd
│   └── states/                # un archivo por estado
│       ├── state.gd           # clase base (interfaz)
│       ├── idle.gd  walk.gd  crouch.gd  dash.gd
│       ├── jump.gd  attack.gd  block.gd
│       ├── hitstun.gd  blockstun.gd
│       └── throw.gd  knockdown.gd  wakeup.gd
├── input/
│   ├── input_source.gd        # interfaz común
│   ├── human_input.gd         # teclado/mando → InputFrame
│   └── ai_input.gd            # AIController → InputFrame
├── ai/
│   └── ai_controller.gd       # percepción + macro FSM + utility
├── characters/                # POR FEATURE: cada personaje autocontenido
│   ├── kaze/                  # personaje A (zoner)
│   │   ├── kaze.tres          # CharacterData
│   │   ├── moves/             # sus MoveData .tres
│   │   └── sprites/
│   └── homura/                # personaje B (rushdown)
├── stages/
│   └── training_stage.tscn
├── ui/
│   ├── hud.tscn  hud.gd       # barras de vida, timer, pips, combo counter
│   └── menus/
├── match/
│   ├── match.tscn  match_manager.gd   # orquesta rounds, cámara, jugadores
└── resources/                 # definiciones de datos compartidas
    ├── data/move_data.gd       # class_name MoveData
    ├── data/character_data.gd  # class_name CharacterData
    └── data/input_motion.gd    # class_name InputMotion
```

Regla: **una escena = un script controlador en su raíz, con el mismo nombre**. Cada escena es autocontenida (lleva lo que solo ella usa).

---

## 3. El corazón: State Machine basada en nodos [CONSENSO — estándar de facto]

**Por qué así y no con un `enum` gigante:** con un `match state:` enorme, todo el comportamiento de todos los estados vive en un solo archivo → God object. Con nodos, cada estado es un archivo corto y aislado, y **cada estado decide sus propias transiciones** (la máquina no tiene un `if` que lo decide todo).

**El truco que elimina la sopa de booleanos:** no existe `is_attacking`/`is_jumping`/`is_blocking`. Existe **un** estado activo. Es imposible estar "atacando y saltando" a la vez porque solo hay un `current_state`.

### `state.gd` — clase base (aquí SÍ es correcta la herencia: es un contrato/interfaz)

```gdscript
## Clase base de todos los estados. Define el "contrato" que cada estado cumple.
class_name State
extends Node

var fighter: Fighter                 # el personaje dueño (inyectado por la máquina)
var state_machine: StateMachine      # para pedir transiciones

## Se llama UNA vez al entrar al estado. Aquí: arrancar animación, fijar velocidad,
## conectar la señal de "me golpearon" si este estado puede recibir daño.
func enter() -> void: pass

## Se llama UNA vez al salir. Aquí: limpiar timers, DESCONECTAR señales.
func exit() -> void: pass

## Lógica del estado cada tick de física (60 fps). Aquí: mover, contar frames,
## decidir transiciones (state_machine.transition_to("Idle")).
func physics_update() -> void: pass
```

### `state_machine.gd` — el coordinador (delega, no decide)

```gdscript
## Máquina de estados. NO contiene lógica de comportamiento: solo delega en el estado
## activo y ejecuta las transiciones que los propios estados piden.
class_name StateMachine
extends Node

@export var initial_state: State     # asignado en el editor (referencia tipada, no ruta)
var current_state: State

func setup(owner_fighter: Fighter) -> void:
    for child in get_children():
        if child is State:
            child.fighter = owner_fighter
            child.state_machine = self
    current_state = initial_state
    current_state.enter()

func transition_to(state_name: String) -> void:
    if not has_node(state_name):
        push_warning("Estado inexistente: " + state_name)
        return
    current_state.exit()
    current_state = get_node(state_name)
    current_state.enter()

func physics_update() -> void:
    current_state.physics_update()
```

### Un estado concreto (ejemplo de MOLDE, sin números finales)

```gdscript
## Estado de salto. Corto y aislado: solo sabe de saltar.
extends State

func enter() -> void:
    fighter.start_jump()             # el Fighter sabe CÓMO; el estado dice CUÁNDO
    fighter.play_anim("jump")

func physics_update() -> void:
    fighter.apply_gravity()
    fighter.move()
    if fighter.is_on_floor():
        state_machine.transition_to("Idle")
```

> Patrón clave para combate: en `enter()` de un estado que puede recibir golpes, **conecta** la señal `hit_taken` del Hurtbox; en `exit()`, la **desconecta**. Así un estado invulnerable (ej. `Dash` con i-frames) simplemente no la conecta. La invulnerabilidad emerge de la estructura, sin flags.

---

## 4. Composición: los componentes [CONSENSO]

Un **componente** = nodo hijo que aporta un comportamiento aislado y habla por señales. No sabe quién es su dueño.

### `health.gd`

```gdscript
## Componente de vida. No sabe nada del personaje; solo gestiona HP y avisa.
class_name Health
extends Node

signal health_changed(current: int, max: int)
signal died

@export var max_health: int = 1000
var current_health: int

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int) -> void:
    current_health = max(current_health - amount, 0)
    health_changed.emit(current_health, max_health)
    if current_health == 0:
        died.emit()
```

La barra de vida escucha `health_changed`. El `MatchManager` escucha `died` para terminar el round. El personaje **no** contiene la lógica de vida → cero acoplamiento.

### `hurtbox.gd` y `hitbox.gd` (patrón canónico GDQuest)

```gdscript
## HURTBOX: zona que PUEDE ser golpeada. Solo es detectada, nunca escanea.
class_name Hurtbox
extends Area2D

signal hit_taken(move: MoveData, source: Node)
@export var team: int = 0

func receive_hit(move: MoveData, source: Node) -> void:
    hit_taken.emit(move, source)     # el estado activo del Fighter decide qué hacer
```

```gdscript
## HITBOX: zona que GOLPEA. Solo escanea; al tocar un Hurtbox rival, le pasa el MoveData.
class_name Hitbox
extends Area2D

@export var move: MoveData           # qué golpe representa (datos, no lógica)
@export var team: int = 0

func _on_area_entered(area: Area2D) -> void:
    if area is Hurtbox and area.team != team:
        area.receive_hit(move, owner)
```

Añadir teams, i-frames y knockback = **datos** en estos componentes, no herencia ni flags dispersos.

---

## 5. El desacople humano/IA (la pieza que evita duplicar código) [CONSENSO]

El `Fighter` **no sabe** si lo controla un humano o la IA. Ambos producen un `InputFrame` por tick.

```gdscript
## Interfaz común. El Fighter pide get_input() cada tick, sin saber la fuente.
class_name InputSource
extends Node

func get_input() -> InputFrame:
    return InputFrame.new()          # las subclases lo sobreescriben
```

```
HumanInput ──┐
             ├──→  InputFrame {dir, LP, MP, HP, LK, MK, HK}  ──→  Fighter (una FSM)
AIController ┘
```

- `human_input.gd` lee teclado/mando y rellena el `InputFrame`.
- `ai_input.gd` toma la decisión del `AIController` y la traduce a `InputFrame`.
- El `Fighter` procesa el `InputFrame` igual venga de donde venga → la IA respeta startup/recovery automáticamente (justicia mecánica gratis) y **no hay código duplicado**.

---

## 6. Comunicación: "call down, signal up" + event bus [CONSENSO]

| Situación | Mecanismo |
|---|---|
| Padre controla a un hijo suyo | **Llamada directa** (`hurtbox.receive_hit(...)`) |
| Hijo avisa de algo hacia arriba | **Señal** (`died`, `hit_taken`) |
| Nodo necesita a otro nodo cercano | **`@export var ref: Node`** asignado en el editor |
| Nodo interno estable de la escena | **`%NombreÚnico`** (Scene Unique Name) |
| Conjunto ("todos los hurtboxes team 2") | **Grupos** |
| Nodos LEJANOS reaccionan a evento global | **Event bus** (autoload de solo señales) |

### `event_bus.gd` (autoload) — para lo global, con moderación

```gdscript
## Único bus de señales globales. Nadie conoce a nadie: emiten y escuchan.
## SOLO para eventos verdaderamente globales (ronda, pausa, KO). No para todo.
extends Node

signal round_started(round_number: int)
signal round_ended(winner: int)
signal match_ended(winner: int)
signal game_paused(is_paused: bool)
```

Reglas del event bus: **conectar por código** (no por el editor), `connect` en `_ready()` y `disconnect` en `_exit_tree()`. No lo conviertas en cajón de sastre.

> ⚠️ **Antipatrón #1 (oficial):** abusar de autoloads. La regla: ¿lo necesita *todo* el juego y debe *sobrevivir* al cambio de escena? → autoload. Si no → señal, `@export` o inyección. En v1 nos bastan **2-3 autoloads**: `EventBus`, `GameState` y (opcional) `AudioManager`.

---

## 7. Datos en Resources [OFICIAL]

Los `Resource` son datos puros con editor gratis en el Inspector. Sacan los números del código.

```gdscript
class_name MoveData
extends Resource

@export var move_name: String
@export_group("Frame Data")
@export var startup: int = 4
@export var active: int = 3
@export var recovery: int = 8
@export_group("On Hit")
@export var damage: int = 30
@export var hitstun: int = 12
@export var blockstun: int = 9
@export var pushback: int = 20
@export_group("Combo")
@export var cancelable_into: Array[String] = []
@export var input_motion: InputMotion
@export var animation: String
```

- Balancear un golpe = editar `hadouken_kaze.tres` en el Inspector. **Sin recompilar, sin tocar lógica.**
- **`.tres`** (texto) en desarrollo (se ve el diff en Git). `.res` (binario) opcional en release.
- ⚠️ **Nunca uses Resources para archivos de guardado** (pueden llevar script embebido = agujero de seguridad). Saves → **JSON**.

---

## 8. Lógica vs presentación [OFICIAL]

- **`_physics_process`** (60 Hz fijo): movimiento, avance del FSM, combate, hitboxes. Todo lo que afecta jugabilidad.
- **`_process`** (variable): animación visual, cámara suave, UI, partículas.
- **Input**: se *graba* en `_process` (no perder pulsaciones) y se *consume* en `_physics_process` (aplicación consistente). Es la base del input buffer.
- **La animación LEE el estado**, no lo maneja. El sprite es consecuencia del estado, nunca la causa → nunca se desincronizan.

```gdscript
## fighter.gd (ESQUELETO — sin lógica de combate todavía)
class_name Fighter
extends CharacterBody2D

@export var data: CharacterData          # inyectado: quién es este fighter
@export var input_source: InputSource    # inyectado: humano o IA

@onready var state_machine: StateMachine = %StateMachine
@onready var health: Health = %Health
@onready var hurtbox: Hurtbox = %Hurtbox

var facing_right: bool = true
var current_input: InputFrame

func _ready() -> void:
    state_machine.setup(self)

func _physics_process(_delta: float) -> void:
    current_input = input_source.get_input()   # humano o IA, da igual
    state_machine.physics_update()             # delega en el estado activo
    # (el estado activo lee current_input, mueve, resuelve hits...)

# --- Métodos que los estados USAN (el "cómo"; el estado dice "cuándo") ---
func start_jump() -> void: pass
func apply_gravity() -> void: pass
func move() -> void: pass
func play_anim(name: String) -> void: pass
```

---

## 9. Antipatrones a evitar (checklist) 

| ❌ Antipatrón | ✅ Solución |
|---|---|
| `player.gd` de 1000 líneas (God object) | FSM por nodos + componentes; cada archivo corto |
| `is_jumping`, `is_attacking`… (sopa de booleanos) | Un solo `current_state` |
| 5 autoloads "cajón de sastre" | Máx. 2-3 autoloads globales reales |
| `get_node("../../../Enemy")` | `@export` de referencia o `%NombreÚnico` |
| Conectar señales en el editor en proyecto grande | Conectar por código, con `disconnect` emparejado |
| Herencia de escenas de varias capas | Composición; máx. 1 capa de herencia |
| Lógica de combate en `_process` | Todo en `_physics_process` |
| Números de daño/frames hardcodeados | En `MoveData.tres` |

---

## 10. Testing (opcional pero recomendado) [CONSENSO]

- **GUT** (Godot Unit Test), versión 9.x para Godot 4, en `addons/gut`.
- Testea lo que más duele en un fighting game: **cálculo de daño, damage scaling, detección de motions/combos, transiciones de FSM**.
- La arquitectura de arriba es justo la que hace el código testeable: componentes con lógica pura, datos en Resources, lógica separada de la presentación → se prueban sin abrir el juego.

---

## Resumen: el orden de construcción limpio

1. Monta la **estructura de carpetas** (§2) vacía.
2. Crea los **Resources** (`MoveData`, `CharacterData`, `InputMotion`) — el vocabulario de datos (§7).
3. Crea el **Fighter** con su **StateMachine por nodos** (§3) y estados vacíos.
4. Añade los **componentes** (`Health`, `Hitbox`, `Hurtbox`) por composición (§4).
5. Añade la **fuente de input** (humano primero; IA después) (§5).
6. Conecta lo global con **EventBus/GameState** (§6).
7. Rellena la lógica estado por estado, **siempre en `_physics_process`** (§8).

Con este molde, añadir un personaje = crear datos + sprites (no tocar lógica). Añadir un golpe = crear un `.tres`. Añadir un estado = crear un archivo corto. **Eso es lo contrario del desastre.**

---

*Referencias: documentación oficial de Godot (project organization, GDScript style guide, autoloads, scene unique nodes), repo `abmarnie/godot-architecture-organization-advice`, GDQuest (FSM y hitbox/hurtbox demos), Febucci (signals architecture 2026). Detalle completo de fuentes en las notas de investigación de la sesión.*
