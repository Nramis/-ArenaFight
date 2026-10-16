extends Node

## Añade soporte de mando (joypad) al Jugador 1, sin quitar el teclado.
## XInput/Xbox: cruceta + stick izquierdo para moverse; botones de cara + bumpers para
## los 6 ataques. Layout de pelea: puños = X/Y/RB, patadas = A/B/LB.

func _ready() -> void:
	# Direcciones: cruceta + stick izquierdo
	_add_dir("p1_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_add_dir("p1_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_add_dir("p1_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_add_dir("p1_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	# Puños
	_add_button("p1_lp", JOY_BUTTON_X)
	_add_button("p1_mp", JOY_BUTTON_Y)
	_add_button("p1_hp", JOY_BUTTON_RIGHT_SHOULDER)
	# Patadas
	_add_button("p1_lk", JOY_BUTTON_A)
	_add_button("p1_mk", JOY_BUTTON_B)
	_add_button("p1_hk", JOY_BUTTON_LEFT_SHOULDER)
	# Menú / navegación con el mando
	_add_button("ui_accept", JOY_BUTTON_A)
	_add_button("ui_cancel", JOY_BUTTON_B)

func _add_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = -1   # cualquier mando conectado
	InputMap.action_add_event(action, ev)

func _add_dir(action: String, button: int, axis: int, value: float) -> void:
	_add_button(action, button)
	var m := InputEventJoypadMotion.new()
	m.axis = axis
	m.axis_value = value
	m.device = -1
	InputMap.action_add_event(action, m)

func _enter_tree() -> void:
	var keys := {"toggle_audio":KEY_V,"p1_fly": KEY_F, "p2_fly": KEY_H, "p1_special1": KEY_Q, "p1_special2": KEY_E, "p1_special3": KEY_R, "p2_special1": KEY_P, "p2_special2": KEY_BRACKETLEFT, "p2_special3": KEY_BRACKETRIGHT}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
