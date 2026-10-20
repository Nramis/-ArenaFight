class_name AIInput
extends InputSource

## Fuente de input controlada por IA: produce el MISMO InputFrame que un humano (justicia
## mecánica: respeta startup/recovery). Decide con AIBrain cada cierto intervalo (no cada
## frame → reacción "humana"), y traduce la acción a botones/direcciones.
## La dificultad ajusta el intervalo de decisión y la probabilidad de "error" (aperturas).

@export var difficulty: String = "medium"

var fighter: Fighter
var opponent: Fighter

var _timer: int = 0
var _action: String = "idle"

func _params() -> Dictionary:
	match difficulty:
		"easy":
			return {"interval": 16, "mistake": 0.4}
		"hard":
			return {"interval": 3, "mistake": 0.0}
		_:  # medium
			return {"interval": 8, "mistake": 0.15}

func poll() -> InputFrame:
	var f := InputFrame.new()
	if fighter == null or opponent == null:
		return f
	var p := _params()
	var fresh := false
	_timer -= 1
	if _timer <= 0:
		var dist: float = absf(opponent.global_position.x - fighter.global_position.x)
		var opp_recovering: bool = _opp_recovering()
		if randf() < p["mistake"]:
			_action = "idle"          # error deliberado: deja una apertura
		else:
			_action = AIBrain.decide(dist, not opponent.on_ground, opp_recovering, randf())
		_timer = p["interval"]
		fresh = true
	_apply(f, fresh)
	return f

func _opp_recovering() -> bool:
	var st := opponent.state_machine.current_state
	return st != null and st.name == "Attack" and opponent.current_move != null and st.state_frame >= opponent.current_move.startup+opponent.current_move.active

func _apply(f: InputFrame, fresh: bool) -> void:
	var toward: int = 1 if opponent.global_position.x >= fighter.global_position.x else -1
	match _action:
		"approach":
			_set_dir(f, toward)
		"retreat", "block":
			_set_dir(f, -toward)      # mantener atrás = bloquear / alejarse
		"attack":
			var distance := absf(fighter.position.x-opponent.position.x)
			if distance > 82.0*fighter.abilities.size_multiplier():
				_set_dir(f,toward)
			elif fresh:
				if distance > 58:
					f.hk = true
				else:
					match randi()%6:
						0: f.lp = true
						1: f.mp = true
						2: f.hp = true
						3: f.lk = true
						4: f.mk = true
						5: f.hk = true
		"antiair":
			if fresh:
				f.hp = true
				f.down = fighter.roster_name() == "rinat"
		"throw":
			if fresh:
				f.lp = true
				f.lk = true
		"idle":
			pass

func _set_dir(f: InputFrame, screen_dir: int) -> void:
	if screen_dir > 0:
		f.right = true
	elif screen_dir < 0:
		f.left = true
