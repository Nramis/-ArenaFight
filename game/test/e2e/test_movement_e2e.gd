# Test END-TO-END: la escena real (match.tscn) con la cadena completa
# InputMap -> HumanInput -> Fighter -> movimiento. Empuja el estado de acciones del
# InputMap directamente (Input.action_press), lo que funciona también en headless,
# y valida que el nombre de acción real ("p1_right") mueve al jugador correcto.
# Requiere gdUnit4.
extends GdUnitTestSuite

const MATCH := preload("res://match/match.tscn")

# Suelta cualquier acción que quedara presionada entre tests.
func after_test() -> void:
	for a in ["p1_left", "p1_right", "p2_left", "p2_right"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)

func _load_match() -> Node:
	var m := MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func _hold(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in frames:
		await get_tree().physics_frame
	Input.action_release(action)

func test_p1_moves_right_when_pressing_p1_right() -> void:
	var m := _load_match()
	var p1: Fighter = m.get_node("Player1")
	var start_x := p1.position.x
	await _hold("p1_right", 10)
	assert_float(p1.position.x).is_greater(start_x)

func test_p2_moves_left_when_pressing_p2_left() -> void:
	var m := _load_match()
	var p2: Fighter = m.get_node("Player2")
	var start_x := p2.position.x
	await _hold("p2_left", 10)
	assert_float(p2.position.x).is_less(start_x)

func test_players_move_independently() -> void:
	var m := _load_match()
	var p1: Fighter = m.get_node("Player1")
	var p2: Fighter = m.get_node("Player2")
	var p2_start := p2.position.x
	# Solo P1 se mueve; P2 debe quedarse quieto.
	await _hold("p1_right", 10)
	assert_float(p2.position.x).is_equal(p2_start)
