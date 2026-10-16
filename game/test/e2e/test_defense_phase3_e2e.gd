# E2E Fase 3: escena real; P2 mantiene atrás y bloquea el normal de P1 (solo chip).
extends GdUnitTestSuite

const MATCH := preload("res://match/match.tscn")

func after_test() -> void:
	for a in ["p1_lp", "p1_right", "p2_left", "p2_right"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)

func _load() -> Node:
	var m := MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func test_p2_blocks_p1_normal_takes_only_chip() -> void:
	var m := _load()
	var p1: Fighter = m.get_node("Player1")
	var p2: Fighter = m.get_node("Player2")
	p1.position.x = 170.0
	p2.position.x = 214.0
	# P2 a la derecha mira a la izquierda; "atrás" = derecha
	Input.action_press("p2_right")
	for i in 2:
		await get_tree().physics_frame
	Input.action_press("p1_lp")
	var was_block := false
	var min_hp := p2.health
	for i in 18:
		await get_tree().physics_frame
		if p2.state_machine.current_state.name == "Blockstun":
			was_block = true
		min_hp = mini(min_hp, p2.health)
	assert_bool(was_block).is_true()
	assert_int(min_hp).is_greater(970)     # bloqueó: solo chip, no el golpe completo
