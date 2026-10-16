# Shoto Fighter 🥋

A 2D fighting game in the style of **Street Fighter II**, built with **Godot 4** and GDScript.
Clean, data-driven architecture, **verified by 98 automated tests** (unit, integration and end-to-end).

> Full local game: movement, combat, specials, best-of-3 rounds, a CPU opponent with 3
> difficulty levels, and a main menu. Characters are rendered with **Kung Fu Man** sprites
> (26 animations, extracted from M.U.G.E.N) driven by the state machine — swappable for any
> other art without touching the gameplay logic (a clean geometric rig is the built-in fallback).

---

## ✨ Features (implemented and tested)

**Movement**
- Walk (forward/back relative to the opponent), crouch, committed jump (no air control), **dash** (double-tap)
- Stage walls / corner, pushbox (fighters can't overlap), camera with dynamic zoom

**Combat**
- **Data-driven** attack system with real frame data: *startup / active / recovery*
- Hitbox / hurtbox (AABB), **hitstun**, **hitstop**, pushback
- **18 normals** per character (6 standing · 6 crouching · 6 aerial)
- **Directional blocking** (high = back, low = down-back), **blockstun**, **chip damage** (lethal, like SF2)
- **Throws** with **throw tech** (break), **knockdown** (sweeps and grabs)

**Specials (shoto archetype)**
- **Hadouken** (`236P`) fireball · **Shoryuken** (`623P`) invincible anti-air · **Tatsu** (`214K`)
- Three **L/M/H** versions per special · numpad-notation motion detection + input buffer
- **Cancels** (normal → special) · combo **damage scaling** (100/100/80/60/40/20 %)

**Match & modes**
- **Two differentiated shotos**: Kaze (zoner — better fireball, safe DP) vs Homura (rushdown — faster, stronger DP)
- **Best-of-3 rounds**, 99s timer, KO / time-decision, rematch
- **CPU opponent** with 3 fair difficulty levels (Easy / Medium / Hard) — the AI feeds the same inputs a human would
- **Main menu**: 2 Players or vs CPU

**Presentation**
- Geometric fighter silhouettes with a strike limb · **hit sparks** · **screen shake** · **health-bar HUD** · procedural SFX

---

## 🎮 Controls (2 players, shared keyboard)

| Action | Player 1 (blue) | Player 2 (red) |
|---|---|---|
| Left / Right | `A` / `D` | `←` / `→` |
| Crouch / Jump | `S` / `W` | `↓` / `↑` |
| Dash | double-tap `A`/`D` | double-tap `←`/`→` |
| Punches (L/M/H) | `U` / `I` / `O` | `,` / `.` / `/` |
| Kicks (L/M/H) | `J` / `K` / `L` | `N` / `M` / `B` |
| Throw | `U` + `J` | `,` + `N` |

**Specials (P1, facing right):**
- Hadouken: `S → D + U`  ·  Shoryuken: `D → S → D + U`  ·  Tatsu: `S → A + J`

---

## 🚀 Running the game

Requires **Godot 4.4 or newer** (tested on 4.7.1).

```bash
git clone https://github.com/aminRX/shoto-fighter-godot.git
```

Open the project in Godot and press **Play** (main scene: `res://match/match.tscn`).

---

## 🧪 Tests

The project uses **[gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4)** (bundled in `addons/`).
The suite covers the combat logic end to end:

- **Unit** (~70%): damage scaling, motion detection, frame data, stage physics, block rules
- **Integration**: hitbox+hurtbox+health, throws, blocking, specials
- **End-to-end**: full combat in the real scene driving real inputs (e.g. a Hadouken crossing the screen and connecting)

Run the suite (headless):

```bash
powershell -File run_tests.ps1
```

Or directly:

```bash
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://test
```

**Current status: 78/78 passing.** ✅

---

## 🏗️ Architecture

Built to avoid spaghetti code (following the Godot community consensus, 2025–2026):

- **Node-based state machine**: one node = one state (no "boolean soup")
- **Composition over inheritance**: hitbox / hurtbox / health as components
- **Data-driven**: frame data lives in data objects, tunable without recompiling
- **A single `Fighter`** for human and (future) AI: both feed the same `InputFrame`
- **Logic separated from presentation**: the view *reads* the state — which is why the art can be swapped for sprites without touching the logic or breaking the tests

Design docs live in [`docs/`](docs/) (in Spanish):
- `GDD-tecnico.md` — what the game is (mechanics, characters, frame data)
- `arquitectura-codigo.md` — how the code is structured
- `estrategia-testing.md` — how it's tested

```
fighter/     Fighter + StateMachine + states
core/        pure testable logic (frame data, motions, damage, physics)
input/       InputFrame, InputSource, HumanInput
match/       main scene + MatchManager (collisions, hits, camera)
projectile/  Hadouken projectile
fx/  ui/     hit sparks · HUD
test/        unit / integration / e2e
```

---

## 🗺️ Roadmap

- [x] **Phase 0–1** — Skeleton + movement (walk, crouch, jump, dash, corner, camera)
- [x] **Phase 2** — Attacks, hitbox/hurtbox, hitstun/hitstop
- [x] **Phase 3** — Defense (blocking, chip, throws + tech, knockdown)
- [x] **Phase 4** — Specials (motions, L/M/H, projectile, cancels, damage scaling)
- [x] **Phase 5** — Differentiated shotos (Kaze zoner vs Homura rushdown)
- [x] **Phase 6** — Best-of-3 rounds, timer, KO, rematch, HUD
- [x] **Phase 7** — CPU AI (3 fair difficulty levels)
- [x] **Phase 8** — Geometric art, HUD, hit sparks, screen shake, procedural SFX, main menu
- [ ] **Future** — Real sprite art (the architecture makes this a drop-in swap), online rollback netcode

**All core phases complete · 98/98 tests passing.**

---

## 🛠️ Tech

Godot 4.x · GDScript · gdUnit4 (tests) · fixed 60 FPS · no external runtime dependencies.

## 📄 License & credits

- **Code:** [MIT](LICENSE) — free to use, modify and share.
- **Character sprites:** *Kung Fu Man* by **Elecbyte** (the M.U.G.E.N sample character),
  **CC BY-NC** — this is a **non-commercial** learning project. It must not be sold with
  these sprites; swap them for your own / CC0 art to go commercial (art and logic are
  fully separated). See [CREDITS.md](CREDITS.md).
- **Tests:** gdUnit4 by Mike Schulze (MIT), in `addons/gdUnit4/`.
