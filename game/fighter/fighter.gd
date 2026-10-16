class_name Fighter
extends CharacterBody2D

## Personaje genérico. La MISMA clase sirve para P1, P2 y CPU: consume un InputFrame por
## tick y no sabe quién lo controla. Los estados deciden QUÉ hacer; el Fighter expone el
## CÓMO (moverse, atacar) e integra física. Las colisiones globales (paredes, pushbox) y
## la resolución de golpes las coordina MatchManager.

@export_group("Movement")
@export var walk_fwd_speed: float = 180.0
@export var walk_back_speed: float = 140.0
@export var dash_fwd_speed: float = 420.0
@export var dash_fwd_frames: int = 16
@export var dash_back_speed: float = 360.0
@export var dash_back_frames: int = 14

@export_group("Jump")
@export var jump_startup_frames: int = 3
@export var jump_speed: float = -660.0
@export var jump_h_speed: float = 180.0
@export var gravity: float = 2200.0

@export_group("Combat")
@export var character_id: String = "kaze"
@export var team: int = 0
@export var max_health: int = 1500
@export var hurtbox_offset: Vector2 = Vector2(0, -48)
@export var hurtbox_size: Vector2 = Vector2(44, 96)
@export var crouch_hurtbox_offset: Vector2 = Vector2(0, -28)
@export var crouch_hurtbox_size: Vector2 = Vector2(44, 56)

@export_group("Setup")
@export var ground_y: float = 180.0
@export var wall_left: float = -100000.0
@export var wall_right: float = 100000.0
@export var body_color: Color = Color(0.2, 0.5, 0.95)
@export var input_source: InputSource

@onready var state_machine: StateMachine = $StateMachine
@onready var visual: Node2D = $Visual
@onready var body: Polygon2D = $Visual/Torso
@onready var head: Polygon2D = $Visual/Head
@onready var limb: Polygon2D = $Visual/Limb
@onready var sprite: AnimatedSprite2D = $Sprite

var _cur_anim: String = ""
var rhythm := CombatRhythm.new()
var air_attack_used := false
var landing_lag_frames := 0
var attack_buffer := ""
var attack_buffer_frames := 0
var landing_frames := 0
var _step_distance := 0.0
var _swing_sounded := false
var last_damage := 0
var last_hit_blocked := false
var last_counter_hit := false
var combo_damage := 0
var combo_display_frames := 0
var quick_special_cooldown: int = 0
var abilities: FighterAbilities
var roster_id := ""

const GROUNDED_STATES := ["Idle", "Walk", "Crouch"]
const BTN_KEYS := ["lp", "mp", "hp", "lk", "mk", "hk"]
const ATTACK_PRIORITY := ["hp", "hk", "mp", "mk", "lp", "lk"]

var input: InputFrame = InputFrame.new()
var vel: Vector2 = Vector2.ZERO
var facing_right: bool = true
var opponent: Fighter = null
var on_ground: bool = true

var health: int = 1500
var moves: Dictionary = {}
var current_move: MoveData = null
var move_has_hit: bool = false
var hitstun_frames: int = 0
var hitstop_frames: int = 0
var blockstun_frames: int = 0
var knockdown_frames: int = 0
var throw_pressed: bool = false
var invuln_frames: int = 0
var combo_count: int = 0
var frozen: bool = false

var specials: Dictionary = {}
var _numpad_history: Array = []
var _projectile_spawned: bool = false

const NEUTRAL_STATES := ["Idle", "Walk", "Crouch"]
const THROW_DAMAGE := 120
const KNOCKDOWN_FRAMES := 52
const WAKEUP_PROTECTION := 18
const MOTION_WINDOW := 12
const NUMPAD_HISTORY := 24
const PUNCHES := ["hp", "mp", "lp"]
const KICKS := ["hk", "mk", "lk"]
const PROJECTILE_SCENE := preload("res://projectile/projectile.tscn")

var dash_frames_current: int = 0
var just_pressed: Array = []

var _dash := DashInput.new()
var _dash_signal: int = 0
var _prev_buttons := [false, false, false, false, false, false]

func _ready() -> void:
	if GameConfig.roster_enabled and name in ["Player1", "Player2"]:
		roster_id = GameConfig.p1_character if name == "Player1" else GameConfig.p2_character
		character_id = "kaze" if roster_id in ["rafael","vladislav"] else "homura"
	_apply_base_colors()
	_setup_sprite()
	abilities = FighterAbilities.new(self)
	health = max_health
	moves = MoveSet.default_normals()
	specials = Characters.specials_for(character_id)
	var s := Characters.stats(character_id)
	walk_fwd_speed = s["walk_fwd_speed"]
	walk_back_speed = s["walk_back_speed"]
	dash_fwd_speed = s["dash_fwd_speed"]
	dash_fwd_frames = s["dash_fwd_frames"]
	dash_back_speed = s["dash_back_speed"]
	dash_back_frames = s["dash_back_frames"]
	if input_source == null:
		for child in get_children():
			if child is InputSource:
				input_source = child
				break
	state_machine.setup(self)

const SPRITE_SCALE := 0.85
const ATTACK_ANIM := {
	"st.lp": "stand_lp", "st.mp": "stand_mp", "st.hp": "stand_hp",
	"st.lk": "stand_lk", "st.mk": "stand_mk", "st.hk": "stand_hk",
	"cr.lp": "crouch_lp", "cr.mp": "crouch_mp", "cr.hp": "crouch_mp",
	"cr.lk": "crouch_lk", "cr.mk": "crouch_lk", "cr.hk": "crouch_hk",
	"j.lp": "stand_lp", "j.mp": "stand_mp", "j.hp": "stand_hp",
	"j.lk": "stand_lk", "j.mk": "stand_mk", "j.hk": "stand_hk",
}

func _setup_sprite() -> void:
	sprite.visible = false
	visual.visible = false
	var art := Node2D.new()
	art.set_script(preload("res://fighter/combat_art.gd"))
	add_child(art)

func roster_name() -> String:
	return roster_id if roster_id != "" else ("rafael" if character_id == "kaze" else "nikita")

func _sprite_anim(st: String) -> String:
	match st:
		"Walk":
			return "walk_fwd" if input.horizontal() == facing() else "walk_back"
		"Crouch":
			return "crouch"
		"JumpStartup", "Jump":
			return "jump"
		"Dash":
			return "run"
		"Attack":
			return _attack_anim()
		"Blockstun":
			return "guard_crouch" if input.down else "guard"
		"Hitstun":
			return "hurt"
		"Knockdown", "Thrown":
			return "knockdown"
		"Throw":
			return "throw"
		_:
			return "idle"

func _attack_anim() -> String:
	if current_move == null:
		return "stand_hp"
	if current_move.is_special:
		match current_move.move_name:
			"Hadouken":
				return "palm"
			"Shoryuken":
				return "upper"
			"Tatsu":
				return "knee"
		return "palm"
	return ATTACK_ANIM.get(current_move.move_name.to_lower(), "stand_hp")

func _apply_base_colors() -> void:
	($Visual/Torso as Polygon2D).color = body_color
	($Visual/Head as Polygon2D).color = body_color
	($Visual/LegFront as Polygon2D).color = body_color
	($Visual/LegBack as Polygon2D).color = body_color.darkened(0.35)
	($Visual/Limb as Polygon2D).color = body_color.lightened(0.3)

func _process(_delta: float) -> void:
	# Presentación pura: pose + tinte de la silueta según el estado (lee el estado, no lo maneja).
	if body == null:
		return
	var st: String = String(state_machine.current_state.name) if state_machine.current_state != null else "Idle"
	var sy := 1.0
	var rot := 0.0
	var offx := 0.0          # desplazamiento del rig (lunge al pegar, recoil al recibir)
	var limb_ext := 0.0      # extensión de la extremidad de golpe (0 = oculta)
	match st:
		"Crouch":
			sy = 0.72
		"JumpStartup":
			sy = 0.88
		"Knockdown":
			rot = deg_to_rad(78.0)
		"Hitstun":
			offx = -7.0          # recoil: empujado hacia atrás
			rot = deg_to_rad(-8.0)
		"Blockstun":
			offx = -3.0
		"Attack":
			# Animación completa del golpe: wind-up -> extensión -> retracción.
			if current_move != null and state_machine.current_state != null:
				var ph := MovePhase.phase_at(state_machine.current_state.state_frame, current_move.startup, current_move.active, current_move.recovery)
				match ph:
					MovePhase.STARTUP:
						limb_ext = 0.35; offx = -2.0    # arma el golpe
					MovePhase.ACTIVE:
						limb_ext = 1.0; offx = 6.0       # golpea + lunge adelante
					MovePhase.RECOVERY:
						limb_ext = 0.55; offx = 2.0
	visual.scale = Vector2(float(facing()), sy)
	visual.rotation = rot
	visual.position.x = offx * facing()
	# Extremidad
	limb.visible = limb_ext > 0.0
	limb.scale.x = maxf(limb_ext, 0.01)
	limb.color = body_color.lightened(0.45) if (st == "Attack" and is_attack_active()) else body_color.lightened(0.2)
	# Tinte de la silueta (flash de feedback)
	var tint := body_color
	match st:
		"Hitstun":
			tint = Color(1, 1, 1)
		"Blockstun":
			tint = Color(0.55, 0.92, 1.0)
		"Attack":
			tint = body_color.lightened(0.28) if is_attack_active() else body_color
		"Knockdown":
			tint = body_color.darkened(0.4)
	body.color = tint
	head.color = tint if st == "Hitstun" else body_color
	# Sprite (si está activo): animación por estado + flip por facing (KFM mira a la derecha).
	if sprite.visible and sprite.sprite_frames != null:
		var a := _sprite_anim(st)
		if a != _cur_anim:
			_cur_anim = a
			sprite.play(a)
		sprite.scale = Vector2(SPRITE_SCALE * facing(), SPRITE_SCALE)
	queue_redraw()

func _draw() -> void:
	# Cajas de golpe/daño (modo entrenamiento) para leer alcance y timing.
	var cfg := get_node_or_null("/root/GameConfig")
	if cfg == null or not cfg.show_boxes:
		return
	# Pushbox (verde)
	draw_rect(Rect2(-22.0, -96.0, 44.0, 96.0), Color(0.3, 1.0, 0.4, 0.10), true)
	draw_rect(Rect2(-22.0, -96.0, 44.0, 96.0), Color(0.3, 1.0, 0.4, 0.5), false, 1.0)
	# Hurtbox (azul)
	var crouching := is_crouching_pose()
	var hoff := crouch_hurtbox_offset if crouching else hurtbox_offset
	var hsz := crouch_hurtbox_size if crouching else hurtbox_size
	var hr := Rect2(hoff.x - hsz.x / 2.0, hoff.y - hsz.y / 2.0, hsz.x, hsz.y)
	draw_rect(hr, Color(0.3, 0.6, 1.0, 0.22), true)
	draw_rect(hr, Color(0.4, 0.7, 1.0, 0.7), false, 1.0)
	# Hitbox activo (rojo)
	if is_attack_active():
		var off := current_move.hitbox_offset
		var sz := current_move.hitbox_size
		if sz.x > 0.0 and sz.y > 0.0:
			var xr := Rect2(off.x * facing() - sz.x / 2.0, off.y - sz.y / 2.0, sz.x, sz.y)
			draw_rect(xr, Color(1.0, 0.25, 0.25, 0.35), true)
			draw_rect(xr, Color(1.0, 0.4, 0.4, 0.9), false, 1.0)

func _physics_process(delta: float) -> void:
	# Congelado entre rounds / fin de match: no procesa nada.
	if frozen:
		return
	rhythm.tick()
	combo_display_frames = maxi(0,combo_display_frames-1)
	landing_lag_frames = maxi(0,landing_lag_frames-1)
	# Hitstop: congela por completo a ambos (impacto). Ni input, ni estado, ni física.
	if abilities != null:
		abilities.tick()
		if abilities.locked():
			return
	# Sample button edges even during impact pause, so short taps are not lost.
	if input_source != null:
		input = input_source.poll()
	_update_button_edges()
	if hitstop_frames > 0:
		hitstop_frames -= 1
		return
	attack_buffer_frames = maxi(0,attack_buffer_frames-1)
	landing_frames = maxi(0,landing_frames-1)
	if attack_buffer_frames == 0:
		attack_buffer = ""
	quick_special_cooldown = maxi(0, quick_special_cooldown - 1)
	if invuln_frames > 0:
		invuln_frames -= 1
	_dash_signal = _dash.update(input.horizontal())
	_update_throw_press()
	if state_machine.current_state != null and state_machine.current_state.name in GROUNDED_STATES:
		_update_facing()
	_push_numpad()
	if abilities != null and abilities.process_flight(delta):
		return
	state_machine.physics_update(delta)
	_integrate(delta)

func _push_numpad() -> void:
	_numpad_history.push_front(current_numpad())
	if _numpad_history.size() > NUMPAD_HISTORY:
		_numpad_history.pop_back()

## Dirección actual en numpad, relativa al facing (adelante = hacia el rival).
func current_numpad() -> int:
	var screen := input.horizontal()
	var fb := 0
	if screen == facing():
		fb = 1
	elif screen == -facing():
		fb = -1
	var v := 0
	if input.up:
		v = 1
	elif input.down:
		v = -1
	return MotionParser.to_numpad(fb, v)

func _integrate(delta: float) -> void:
	var was_airborne := not on_ground
	if on_ground and state_machine.current_state.name == "Walk":
		_step_distance += absf(vel.x)*delta
		if _step_distance >= 48:
			_step_distance = fmod(_step_distance,48)
			emit_sound("step")
	else:
		_step_distance = 0
	position += vel * delta
	position.x = clampf(position.x, wall_left, wall_right)
	if position.y >= ground_y:
		position.y = ground_y
		if vel.y > 0.0:
			vel.y = 0.0
		on_ground = true
		if was_airborne:
			landing_lag_frames = 8 if air_attack_used else 2
			air_attack_used = false
			landing_frames = 8
			emit_sound("knockdown" if state_machine.current_state.name == "Knockdown" else "land")
			_spawn_motion_dust()
	else:
		on_ground = false

func _update_facing() -> void:
	if opponent == null:
		return
	facing_right = opponent.global_position.x >= global_position.x

func _update_button_edges() -> void:
	just_pressed.clear()
	var cur := [input.lp, input.mp, input.hp, input.lk, input.mk, input.hk]
	for i in 6:
		if cur[i] and not _prev_buttons[i]:
			just_pressed.append(BTN_KEYS[i])
	_prev_buttons = cur
	for button in ATTACK_PRIORITY:
		if button in just_pressed:
			attack_buffer = button
			attack_buffer_frames = 12
			break

## Agarre: LP+LK (edge en uno con el otro mantenido), solo desde estado neutro.
func _update_throw_press() -> void:
	if roster_name() == "azat":
		throw_pressed = false
		return
	var st := state_machine.current_state
	var neutral := st != null and st.name in NEUTRAL_STATES
	throw_pressed = neutral and ((("lp" in just_pressed) and input.lk) or (("lk" in just_pressed) and input.lp))

func facing() -> int:
	return 1 if facing_right else -1

func consume_dash() -> int:
	var d: int = _dash_signal
	_dash_signal = 0
	return d

# --- Movimiento (usado por los estados) ---

func walk(screen_dir: int) -> void:
	var is_fwd: bool = screen_dir == facing()
	vel.x = move_toward(vel.x,screen_dir * (walk_fwd_speed if is_fwd else walk_back_speed),(2400.0 if vel.x*screen_dir < 0 else 3000.0)/60.0)

func stop_horizontal() -> void:
	vel.x = 0.0

func begin_dash(screen_dir: int) -> void:
	emit_sound("swing_heavy")
	var is_fwd: bool = screen_dir == facing()
	vel.x = screen_dir * (dash_fwd_speed if is_fwd else dash_back_speed)
	dash_frames_current = dash_fwd_frames if is_fwd else dash_back_frames
	_spawn_motion_dust()

func launch_jump(h_dir: int) -> void:
	air_attack_used = false
	emit_sound("swing")
	vel.y = jump_speed
	vel.x = h_dir * jump_h_speed
	on_ground = false

func steer_air(delta: float) -> void:
	var dir := input.horizontal()
	if dir != 0:
		vel.x = move_toward(vel.x,dir*jump_h_speed,650.0*delta)

func _spawn_motion_dust() -> void:
	if not is_inside_tree():
		return
	var dust := Node2D.new()
	dust.set_script(preload("res://fx/motion_dust.gd"))
	dust.position = position
	get_parent().add_child(dust)

func apply_gravity(delta: float) -> void:
	vel.y += gravity * delta

# --- Ataques ---

## Intenta iniciar un normal según la postura ("st"/"cr"/"j"). Devuelve true si arrancó.
func try_start_attack(stance: String) -> bool:
	if roster_name() == "azat":
		for button in BTN_KEYS:
			if button in just_pressed:
				abilities.activate(BTN_KEYS.find(button)%3)
				break
		attack_buffer = ""
		attack_buffer_frames = 0
		return false
	if landing_lag_frames > 0 or (stance == "j" and air_attack_used and not (abilities != null and abilities.flying)):
		return false
	for btn in ATTACK_PRIORITY:
		if btn in just_pressed or (attack_buffer_frames > 0 and btn == attack_buffer):
			var key: String = stance + "." + btn
			if moves.has(key):
				var result := rhythm.try_normal(btn,abilities != null and abilities.energy_frames > 0)
				if result.is_empty():
					attack_buffer = ""
					attack_buffer_frames = 0
					return false
				var move: MoveData = moves[key].duplicate()
				move.damage = int(round(move.damage*result.damage))
				move.recovery += int(result.recovery)
				if stance == "j":
					air_attack_used = true
				start_move(move)
				return true
	return false

func try_chain_normal() -> bool:
	if current_move == null or not current_move.cancelable or not move_has_hit or attack_buffer_frames == 0:
		return false
	var ranks := {"lp":0,"lk":0,"mp":1,"mk":1,"hp":2,"hk":2}
	var current_button := current_move.move_name.to_lower().get_slice(".",1)
	var paired_kick := (current_button == "lp" and attack_buffer == "lk") or (current_button == "mp" and attack_buffer == "mk")
	if not ranks.has(current_button) or not ranks.has(attack_buffer) or (ranks[attack_buffer] <= ranks[current_button] and not paired_kick):
		return false
	return try_start_attack("cr" if input.down else "st")

func start_move(m: MoveData) -> void:
	if roster_name() == "azat":
		return
	_swing_sounded = false
	attack_buffer = ""
	attack_buffer_frames = 0
	if abilities != null and (abilities.damage_multiplier() != 1.0 or abilities.size_multiplier() != 1.0):
		m = m.duplicate()
		m.damage = int(round(m.damage * abilities.damage_multiplier()))
		m.hitbox_offset *= abilities.size_multiplier()
		m.hitbox_size *= abilities.size_multiplier()
	if abilities != null and abilities.attack_speed_multiplier() > 1.0:
		m = m.duplicate()
		var speed := minf(2.1,abilities.attack_speed_multiplier())
		m.startup = maxi(2,int(ceil(m.startup/speed)))
		m.active = maxi(2,int(ceil(m.active/speed)))
		m.recovery = maxi(0,int(ceil(m.recovery/speed)))
	current_move = m
	move_has_hit = false
	_projectile_spawned = false
	invuln_frames = m.invuln_startup
	if on_ground:
		vel.x = 0.0

## Intenta iniciar un especial según el buffer de motion + botón. Prioridad: DP > QCF > QCB.
func try_start_special() -> bool:
	if roster_name() == "azat":
		return false
	var punch := _pressed_strength(PUNCHES)
	var kick := _pressed_strength(KICKS)
	if punch != "" and MotionParser.matches(_numpad_history, [6, 2, 3], MOTION_WINDOW):
		start_move(specials["dp." + punch])
		return true
	if punch != "" and MotionParser.matches(_numpad_history, [2, 3, 6], MOTION_WINDOW):
		start_move(specials["hadouken." + punch])
		return true
	if kick != "" and MotionParser.matches(_numpad_history, [2, 1, 4], MOTION_WINDOW):
		start_move(specials["tatsu." + kick])
		return true
	return false

## Devuelve "l"/"m"/"h" del botón más fuerte recién pulsado de la lista, o "" si ninguno.
func _pressed_strength(buttons: Array) -> String:
	for i in buttons.size():
		if buttons[i] in just_pressed:
			return ["h", "m", "l"][i]   # buttons van de fuerte a débil
	return ""

func spawn_projectile(m: MoveData) -> void:
	if roster_name() == "azat":
		return
	var proj: Projectile = PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position + Vector2(facing() * 44.0, -60.0)
	proj.velocity_x = facing() * m.projectile_speed
	proj.team = team
	proj.owner_facing = facing()
	proj.move = m
	get_parent().add_child(proj)

func is_invulnerable() -> bool:
	return invuln_frames > 0 or (state_machine.current_state != null and state_machine.current_state.name == "Knockdown") or (abilities != null and (abilities.fish_frames > 0 or abilities.away_frames > 0 or (abilities.teleport_frames > 24 and abilities.teleport_frames <= 32)))

## True si el fighter tiene un hitbox activo este frame.
func is_attack_active() -> bool:
	if roster_name() == "azat":
		return false
	if current_move == null:
		return false
	var st := state_machine.current_state
	if st == null or st.name != "Attack":
		return false
	return MovePhase.phase_at(st.state_frame, current_move.startup, current_move.active, current_move.recovery) == MovePhase.ACTIVE

func hitbox_rect() -> Rect2:
	var off := current_move.hitbox_offset
	var cx := global_position.x + off.x * facing()
	var cy := global_position.y + off.y
	var sz := current_move.hitbox_size
	return Rect2(cx - sz.x / 2.0, cy - sz.y / 2.0, sz.x, sz.y)

func hurtbox_rect() -> Rect2:
	var crouching := is_crouching_pose()
	var off := crouch_hurtbox_offset if crouching else hurtbox_offset
	var sz := crouch_hurtbox_size if crouching else hurtbox_size
	if abilities != null:
		if abilities.maris_frames > 0:
			off = Vector2(0,-30)
			sz = Vector2(56,60)
		off *= abilities.size_multiplier()
		sz *= abilities.size_multiplier()
		sz.x *= abilities.width_multiplier()
	var c := global_position + off
	return Rect2(c.x - sz.x / 2.0, c.y - sz.y / 2.0, sz.x, sz.y)

func set_hitstop(n: int) -> void:
	hitstop_frames = n

## True si el defensor está bloqueando este golpe (dirección + postura correctas).
func is_blocking(m: MoveData) -> bool:
	if abilities != null and abilities.locked():
		return false
	if not on_ground:
		return false
	var st := state_machine.current_state
	if st == null or not (st.name in ["Idle", "Walk", "Crouch", "Blockstun"]):
		return false
	var holding_back := input.horizontal() == -facing()
	return BlockRules.can_block(holding_back, input.down, m.hits_low, m.hits_overhead)

## Recibe un golpe limpio (con damage scaling si es continuación de combo).
func receive_hit(m: MoveData, attacker_facing: int) -> void:
	if is_invulnerable():
		return
	if abilities != null:
		abilities.interrupt_cast()
	var st := state_machine.current_state
	last_counter_hit = st != null and st.name == "Attack" and current_move != null and st.state_frame < current_move.startup
	if st != null and st.name == "Hitstun":
		combo_count += 1
	else:
		combo_count = 1
		combo_damage = 0
	var dmg := DamageCalculator.scaled_damage(m.damage, combo_count - 1)
	last_damage = dmg
	combo_damage += dmg
	combo_display_frames = 90
	last_hit_blocked = false
	health = max(health - dmg, 0)
	var finisher := m.combo_finisher and combo_count >= 3
	var push := m.pushback if not m.combo_finisher or finisher else minf(m.pushback,110.0)
	vel = Vector2(attacker_facing * (push + maxf(0,combo_count-2)*18.0), 0.0)
	if last_counter_hit:
		emit_sound("counter")
	if m.causes_knockdown or finisher:
		if m.pushback >= 300:
			vel.y = -210.0
			on_ground = false
		knockdown_frames = KNOCKDOWN_FRAMES
		state_machine.transition_to("Knockdown")
	else:
		hitstun_frames = maxi(6,m.hitstun-maxi(0,combo_count-3)*2)+(4 if last_counter_hit else 0)
		state_machine.transition_to("Hitstun")

## Recibe un golpe bloqueado: chip damage (puede matar) + blockstun + poco pushback.
func receive_block(m: MoveData, attacker_facing: int) -> void:
	var chip: int = int(round(m.damage * 0.15))
	last_damage = chip
	last_hit_blocked = true
	health = max(health - chip, 0)
	blockstun_frames = m.blockstun
	vel = Vector2(attacker_facing * minf(m.pushback,140.0) * 0.5, 0.0)
	state_machine.transition_to("Blockstun")

func is_throwable() -> bool:
	return not is_invulnerable() and on_ground and (state_machine.current_state != null and state_machine.current_state.name in NEUTRAL_STATES)

func do_throw(victim: Fighter) -> void:
	if roster_name() == "azat":
		return
	current_move = null
	state_machine.transition_to("Throw")
	victim.get_thrown(facing())

func get_thrown(thrower_facing: int) -> void:
	if is_invulnerable():
		return
	if abilities != null:
		abilities.interrupt_cast()
	health = max(health - THROW_DAMAGE, 0)
	knockdown_frames = KNOCKDOWN_FRAMES
	vel = Vector2(thrower_facing * 120.0, 0.0)
	state_machine.transition_to("Knockdown")

func throw_tech() -> void:
	current_move = null
	vel = Vector2(-facing() * 200.0, 0.0)
	state_machine.transition_to("Idle")

## Reinicia al fighter para un nuevo round.
func reset_for_round(pos: Vector2, faces_right: bool) -> void:
	rhythm.reset()
	air_attack_used = false
	landing_lag_frames = 0
	_step_distance = 0
	_swing_sounded = false
	attack_buffer = ""
	attack_buffer_frames = 0
	landing_frames = 0
	last_damage = 0
	_prev_buttons = [false,false,false,false,false,false]
	just_pressed.clear()
	throw_pressed = false
	quick_special_cooldown = 0
	if abilities != null:
		abilities.reset()
	position = pos
	vel = Vector2.ZERO
	health = max_health
	facing_right = faces_right
	hitstun_frames = 0
	blockstun_frames = 0
	knockdown_frames = 0
	hitstop_frames = 0
	invuln_frames = 0
	combo_count = 0
	combo_damage = 0
	combo_display_frames = 0
	last_counter_hit = false
	current_move = null
	move_has_hit = false
	on_ground = true
	_numpad_history.clear()
	state_machine.force_state("Idle")

func emit_sound(event: String) -> void:
	var manager := get_parent()
	if manager != null and manager.has_method("play_fighter_sound"):
		manager.play_fighter_sound(event)

func is_crouching_pose() -> bool:
	if roster_name() == "polina" and abilities != null and abilities.pose_kind == "rain_prayer" and abilities.pose_frames > 0:
		return true
	var state := state_machine.current_state
	return state != null and (state.name == "Crouch" or (state.name == "Blockstun" and input.down) or (state.name == "Attack" and current_move != null and current_move.move_name.begins_with("cr.")))
