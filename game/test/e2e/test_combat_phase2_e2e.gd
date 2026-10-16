# E2E Fase 2: escena real; P1 golpea a P2 cercano con un normal y le baja la vida.
extends GdUnitTestSuite

const MATCH := preload("res://match/match.tscn")

func after_test() -> void:
	for a in ["p1_lp", "p1_right", "p1_down"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)

func _load() -> Node:
	var m := MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func test_p1_lp_damages_nearby_p2() -> void:
	var m := _load()
	var p1: Fighter = m.get_node("Player1")
	var p2: Fighter = m.get_node("Player2")
	p1.position.x = 150.0
	p2.position.x = 200.0
	# dejar que se asiente el facing
	for i in 2:
		await get_tree().physics_frame
	var start_hp := p2.health
	Input.action_press("p1_lp")
	for i in 14:
		await get_tree().physics_frame
	assert_int(p2.health).is_less(start_hp)
