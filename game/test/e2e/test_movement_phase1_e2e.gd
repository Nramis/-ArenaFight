# E2E Fase 1: escena real (match.tscn) con InputMap -> HumanInput -> Fighter,
# incluyendo paredes y pushbox aplicados por MatchManager. Requiere gdUnit4.
extends GdUnitTestSuite

const MATCH := preload("res://match/match.tscn")

func after_test() -> void:
	for a in ["p1_left", "p1_right", "p1_up", "p1_down", "p2_left", "p2_right"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)

func _load() -> Node:
	var m := MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func test_crouch_e2e() -> void:
	var m := _load()
	var p1: Fighter = m.get_node("Player1")
	Input.action_press("p1_down")
	for i in 3:
		await get_tree().physics_frame
	assert_str(p1.state_machine.current_state.name).is_equal("Crouch")

func test_jump_e2e() -> void:
	var m := _load()
	var p1: Fighter = m.get_node("Player1")
	Input.action_press("p1_up")
	var airborne := false
	for i in 20:
		await get_tree().physics_frame
		if not p1.on_ground:
			airborne = true
	assert_bool(airborne).is_true()

func test_wall_clamp_left_e2e() -> void:
	var m := _load()
	var p1: Fighter = m.get_node("Player1")
	Input.action_press("p1_left")
	for i in 130:
		await get_tree().physics_frame
	assert_float(p1.position.x).is_greater_equal(m.stage_left - 1.0)

func test_pushbox_prevents_overlap_e2e() -> void:
	var m := _load()
	var p1: Fighter = m.get_node("Player1")
	var p2: Fighter = m.get_node("Player2")
	Input.action_press("p1_right")
	for i in 120:
		await get_tree().physics_frame
	Input.action_release("p1_right")     # soltar y dejar que el manager estabilice
	for i in 5:
		await get_tree().physics_frame
	assert_float(absf(p2.position.x - p1.position.x)).is_greater_equal(m.pushbox_min_sep - 1.0)
