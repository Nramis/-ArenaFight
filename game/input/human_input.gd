class_name HumanInput
extends InputSource

## Fuente de input humana: lee el InputMap del jugador y lo traduce a un InputFrame.
## Un mismo Fighter no cambia si lo controla esto o la IA.

## Prefijo de las acciones del InputMap para este jugador: "p1" o "p2".
@export var player_prefix: String = "p1"

func poll() -> InputFrame:
	if NetSession.enabled:
		return NetSession.input_for(player_prefix)
	var f := InputFrame.new()
	f.left  = Input.is_action_pressed(player_prefix + "_left")
	f.right = Input.is_action_pressed(player_prefix + "_right")
	f.up    = Input.is_action_pressed(player_prefix + "_up")
	f.down  = Input.is_action_pressed(player_prefix + "_down")
	f.lp = Input.is_action_pressed(player_prefix + "_lp")
	f.mp = Input.is_action_pressed(player_prefix + "_mp")
	f.hp = Input.is_action_pressed(player_prefix + "_hp")
	f.lk = Input.is_action_pressed(player_prefix + "_lk")
	f.mk = Input.is_action_pressed(player_prefix + "_mk")
	f.hk = Input.is_action_pressed(player_prefix + "_hk")
	return f
