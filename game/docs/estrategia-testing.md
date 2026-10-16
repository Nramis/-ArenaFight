# Estrategia de Testing — Juego de pelea en Godot 4

> Cómo se prueban unidad, integración y end-to-end (E2E). Basado en el consenso Godot 2025–2026.
> Etiquetas: **[CONSENSO]** = mejor práctica aceptada · **[OPINIÓN]** = recomendación fundamentada, revisable.
> Idioma: **código y tests en inglés**; comentarios y este documento en español.

---

## 0. La idea de fondo

**El código limpio y el código testeable son lo mismo.** La arquitectura que ya definimos (lógica separada de presentación, datos en Resources, componentes con lógica pura, FSM por nodos, todo en `_physics_process`) es *exactamente* lo que hace que se pueda testear. No es trabajo extra: es la misma decisión de diseño.

**Qué es crítico probar en un juego de pelea** [CONSENSO]: frame data, daño y **damage scaling**, detección de **motions** (236/623/214), transiciones de la **FSM**, y colisiones **hitbox/hurtbox**. Un bug de 1 frame o de escalado rompe el balance competitivo — ahí es donde los tests dan más valor.

**Qué NO se testea automáticamente** [CONSENSO]: arte, animación visual, "game feel", VFX, audio, timing subjetivo. Eso se valida jugando (playtesting humano). De la animación solo probamos *indirectamente* que el hitbox esté activo en los frames correctos, no cómo se ve.

---

## 1. Framework: gdUnit4 (recomendado) [OPINIÓN fundamentada]

**Elegimos gdUnit4** como framework principal. Razón: su **Scene Runner** resuelve directamente lo que más necesita un fighting game — **simular inputs de jugador y avanzar frames de física de forma determinista**. Con GUT tendríamos que construir ese andamiaje a mano.

- Soporta GDScript (y C# si algún día hiciera falta).
- Assertions fluidas: `assert_int(x).is_equal(y)`, `assert_str(...)`, `assert_signal(...)`.
- Scene Runner: `simulate_frames()`, `simulate_action_pressed()`, `set_time_factor()`, `invoke()`, `get_property()`.
- Action oficial de GitHub para CI (reportes JUnit/HTML + exit code).

> **Alternativa válida: GUT 9.x.** Igual de sólido y más veterano; mejor si algún día priorizamos *cobertura de código* o mocking de singletons. **Ambos son consenso como opciones legítimas en 2025–2026.** Si prefieres GUT, cambiamos — la estructura de carpetas y la filosofía son idénticas, solo cambia la sintaxis de las assertions. **Decisión reversible con poco coste al principio, cara si esperamos mucho.**

---

## 2. La pirámide de testing para nuestro juego

```
        ╱╲        E2E (pocos, lentos, frágiles)
       ╱  ╲       ~10%  · un special por motion, un combo BnB, un round con KO
      ╱────╲
     ╱      ╲     Integración (medios)
    ╱        ╲    ~20%  · hitbox+hurtbox+health, input buffer + FSM
   ╱──────────╲
  ╱            ╲  Unidad (muchos, rápidos, baratos)
 ╱______________╲ ~70%  · daño, scaling, motions, transiciones FSM, frame data
```

Proporción orientativa [CONSENSO], no dogma. En un fighting game la base de unit es ancha porque la mecánica es esencialmente **una máquina determinista de números y estados** → candidato ideal para **TDD** en la lógica de combate.

---

## 3. La clave: extraer la lógica a clases puras [CONSENSO]

Para que el 70% de los tests sean unit rápidos (milisegundos, sin abrir el juego), la lógica crítica vive en clases `RefCounted` **puras** (sin `Node`, sin escena, sin `_process`): reciben datos, devuelven resultados.

```gdscript
# src/combat/damage_calculator.gd — pure logic, no nodes
class_name DamageCalculator
extends RefCounted

# Damage scaling clásico: cada golpe del combo pega menos.
# Tabla del GDD: hits 1-2 = 100%, 3º = 80%, 4º = 60%, 5º = 40%, 6º+ = 20%.
static func scaled_damage(base: int, combo_hits_before: int) -> int:
    var scale := _scale_for_hit(combo_hits_before)
    return int(round(base * scale))

static func _scale_for_hit(n: int) -> float:
    match n:
        0, 1: return 1.0
        2: return 0.8
        3: return 0.6
        4: return 0.4
        _: return 0.2   # piso
```

Lo mismo para `MotionParser` (detección de 236/623/214) y para la lógica de transición de la FSM. **Esto es lo que hace testeable el juego.**

---

## 4. Estructura de carpetas de tests

```
res://
├── src/
│   ├── combat/
│   │   ├── damage_calculator.gd     # RefCounted puro → unit
│   │   ├── motion_parser.gd         # RefCounted puro → unit
│   │   └── frame_data.gd
│   └── fighter/ ...
├── data/moves/*.tres                # frame data (se testea como datos)
├── addons/gdUnit4/
└── test/
    ├── unit/                        # RÁPIDOS, sin escena → en cada PR
    │   ├── test_damage_calculator.gd
    │   ├── test_motion_parser.gd
    │   └── test_fighter_state_machine.gd
    ├── integration/                 # instancian nodos/escenas
    │   ├── test_hitbox_hurtbox.gd
    │   └── test_input_buffer_fsm.gd
    └── e2e/                         # LENTOS, Scene Runner + inputs → en merge a main
        ├── test_special_moves.gd
        └── test_combos.gd
```

**Convenciones** [CONSENSO]: archivos `test_*.gd`, funciones `func test_...()`, naming `test_<sujeto>_<condición>_<resultado>`, patrón **Arrange–Act–Assert**, un concepto por test. Carpetas separadas para poder correr solo `test/unit/` en cada PR y la suite completa aparte.

---

## 5. Nivel UNIDAD — ejemplos de nuestro juego

```gdscript
# test/unit/test_damage_calculator.gd
extends GdUnitTestSuite

func test_first_hit_deals_full_damage() -> void:
    assert_int(DamageCalculator.scaled_damage(100, 0)).is_equal(100)

func test_third_hit_is_scaled_to_80_percent() -> void:
    assert_int(DamageCalculator.scaled_damage(100, 2)).is_equal(80)

# Tabla parametrizada: verifica todo el scaling de una vez
@warning_ignore("unused_parameter")
func test_scaling_table(hits: int, expected: int,
        test_parameters := [[0,100],[1,100],[2,80],[3,60],[4,40],[5,20]]) -> void:
    assert_int(DamageCalculator.scaled_damage(100, hits)).is_equal(expected)
```

```gdscript
# test/unit/test_motion_parser.gd — que 2→3→6 + P se reconozca como Hadouken
extends GdUnitTestSuite

func test_qcf_sequence_detects_hadouken() -> void:
    var buffer := [2, 3, 6]                 # abajo, abajo-adelante, adelante
    assert_bool(MotionParser.matches(buffer, MotionParser.QCF)).is_true()

func test_incomplete_motion_does_not_trigger() -> void:
    var buffer := [2, 6]                     # falta la diagonal
    assert_bool(MotionParser.matches(buffer, MotionParser.QCF)).is_false()
```

```gdscript
# test/unit/test_fighter_state_machine.gd — transiciones sin nodos
extends GdUnitTestSuite

var fsm: FighterStateMachineLogic
func before_test() -> void:
    fsm = FighterStateMachineLogic.new()

func test_cannot_attack_during_hitstun() -> void:
    fsm.set_state("hitstun")
    fsm.handle_input("LP")
    assert_str(fsm.current_state).is_equal("hitstun")  # el golpe no cancela hitstun
```

```gdscript
# test/unit/test_move_data.gd — validar frame data de un Resource
extends GdUnitTestSuite

func test_hadouken_kaze_frame_data() -> void:
    var move: MoveData = load("res://characters/kaze/moves/hadouken.tres")
    assert_int(move.startup).is_equal(11)
    assert_int(move.total_frames()).is_equal(move.startup + move.active + move.recovery)
```

---

## 6. Nivel INTEGRACIÓN — varios nodos juntos

Prueba que `Hitbox` + `Hurtbox` + `Health` cooperen: un golpe activo que solapa el hurtbox debe restar la vida correcta y meter al rival en hitstun.

```gdscript
# test/integration/test_hitbox_hurtbox.gd
extends GdUnitTestSuite

func test_active_hit_applies_damage_and_hitstun() -> void:
    var runner := scene_runner("res://test/fixtures/training_room.tscn")
    var attacker: Fighter = runner.get_property("attacker")
    var defender: Fighter = runner.get_property("defender")
    var hp_before := defender.health.current_health

    runner.invoke("attacker_start_move", "cr_mk")   # arranca el golpe
    await runner.simulate_frames(10)                # deja correr startup+active

    assert_int(defender.health.current_health).is_less(hp_before)
    assert_str(defender.state_machine.current_state.name).is_equal("Hitstun")
```

---

## 7. Nivel E2E — combate completo simulando inputs reales

El Scene Runner inyecta acciones del InputMap y avanza frames. Aquí probamos el juego "de punta a punta".

```gdscript
# test/e2e/test_special_moves.gd — motion 236P → sale el Hadouken
extends GdUnitTestSuite

func test_qcf_punch_triggers_hadouken() -> void:
    var runner := scene_runner("res://test/fixtures/training_room.tscn")
    var p1: Fighter = runner.get_property("player1")

    runner.simulate_action_press("down");     await runner.simulate_frames(2)
    runner.simulate_action_press("forward")   # ahora abajo+adelante
    await runner.simulate_frames(2)
    runner.simulate_action_release("down")    # solo adelante
    await runner.simulate_frames(2)
    runner.simulate_action_pressed("LP")      # puñetazo
    await runner.simulate_frames(4)           # ventana del buffer

    assert_str(p1.state_machine.current_state.name).is_equal("Hadouken")
    assert_int(p1.active_projectiles.size()).is_greater(0)
```

```gdscript
# test/e2e/test_combos.gd — combo cr.MK xx Hadouken hace el daño esperado
extends GdUnitTestSuite

func test_crmk_xx_hadouken_deals_expected_damage() -> void:
    var runner := scene_runner("res://test/fixtures/training_room.tscn")
    var dummy: Fighter = runner.get_property("player2")
    var hp0 := dummy.health.current_health

    runner.simulate_action_pressed("MK")      # cr.MK (agachado + MK)
    await runner.simulate_frames(6)
    # cancel a Hadouken
    runner.simulate_action_press("down");     await runner.simulate_frames(2)
    runner.simulate_action_press("forward");  await runner.simulate_frames(2)
    runner.simulate_action_pressed("LP")
    await runner.simulate_frames(30)          # deja resolver el combo

    var dmg := hp0 - dummy.health.current_health
    assert_int(dmg).is_between(95, 115)       # cr.MK(55) + Hadouken(60) con scaling
```

---

## 8. Determinismo en tests [CONSENSO — crítico]

Sin esto, los tests de combate son inestables (flaky):
- **Avanzar por frames** (`simulate_frames`), nunca por tiempo real de reloj.
- **Física a tick fijo** (60 Hz) y toda la lógica en `_physics_process`.
- **Semilla RNG fija** en `before_test()` para cualquier daño aleatorio/crítico.
- **Resetear estado global** entre tests (autoloads como `GameState`).

---

## 9. CI/CD (GitHub Actions, headless)

- Correr en **headless**: `godot --headless` con el runner de gdUnit4 (o la action oficial `gdUnit4-action`).
- **Importar el proyecto antes de testear** (`godot --headless --import`) para generar `.godot/`.
- **Unit tests en cada push/PR** (rápidos). **Suite completa (incl. E2E) en merge a `main`** o nocturna (lentos).
- Reportes **JUnit XML** + **exit code** como gate del PR.
- Cachear `.godot/` y la instalación de Godot para acelerar.

```yaml
# .github/workflows/tests.yml (esquema con la action oficial de gdUnit4)
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: godot-gdunit-labs/gdUnit4-action@v1
        with:
          godot-version: "4.x"
          paths: "res://test/unit"          # en PR solo unit; suite completa en main
          report-name: test_report.xml
```

---

## 10. ¿TDD? [CONSENSO matizado]

- **Sí, TDD** para la lógica determinista: daño, scaling, motions, FSM, throws, chip. Escribes el test primero (la tabla de scaling del GDD es literalmente una spec de tests).
- **No TDD** para prototipado de gameplay, animación, feel — eso se itera jugando.

Un fighting game es el caso ideal: la mecánica *es* una spec numérica. Muchos valores del GDD (frame data, scaling 100/80/60/40/20, hitstun por fuerza) se convierten directamente en tests.

---

## Resumen accionable

1. **Framework:** gdUnit4 (Scene Runner). GUT como alternativa si priorizas cobertura.
2. **Arquitectura testeable primero:** `DamageCalculator`, `MotionParser`, `FighterStateMachineLogic` como clases `RefCounted` puras.
3. **3 niveles en `test/unit|integration|e2e/`**: 70/20/10.
4. **Determinismo:** frames fijos, RNG sembrado, sin `_process`.
5. **CI:** headless, unit en PR, suite completa en `main`.
6. **TDD** en la lógica de combate; playtesting para el feel.

> En el roadmap del GDD, los tests entran **junto con cada fase**, no al final: al implementar el damage scaling (Fase 4) se escribe su test unit; al implementar hitbox/hurtbox (Fase 2), su test de integración; los E2E de combos llegan con la Fase 4-5.

---

*Referencias: docs de gdUnit4 y GUT, Godot InputEvent docs, GodotCon US 2025 "Unit Testing Games (TDD/Godot/GUT)", guías de CI 2026. Detalle completo en las notas de investigación de la sesión.*
