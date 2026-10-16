# E2E Fase 4: en la escena real, P1 hace 236+LP y el proyectil cruza y golpea a P2 lejano.
extends GdUnitTestSuite

const MATCH := preload("res://match/match.tscn")

func after_test() -> void:
	for a in ["p1_left", "p1_right", "p1_up", "p1_down", "p1_lp"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)

func _load() -> Node:
	var m := MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func test_hadouken_projectile_crosses_and_hits() -> void:
	var m := _load()
	var p1: Fighter = m.get_node("Player1")
	var p2: Fighter = m.get_node("Player2")
	p1.position.x = 100.0
	p2.position.x = 300.0
	for i in 2:
		await get_tree().physics_frame
	var start_hp := p2.health
	# 236 + LP: abajo -> abajo-adelante -> adelante -> puño
	Input.action_press("p1_down")
	for i in 2:
		await get_tree().physics_frame
	Input.action_press("p1_right")
	for i in 2:
		await get_tree().physics_frame
	Input.action_release("p1_down")
	for i in 2:
		await get_tree().physics_frame
	Input.action_press("p1_lp")
	for i in 2:
		await get_tree().physics_frame
	Input.action_release("p1_lp")
	Input.action_release("p1_right")
	# esperar a que el proyectil recorra la pantalla
	var projectile_seen := false
	for i in 100:
		await get_tree().physics_frame
		if get_tree().get_nodes_in_group("projectile").size() > 0:
			projectile_seen = true
	assert_bool(projectile_seen).is_true()      # se generó el proyectil
	assert_int(p2.health).is_less(start_hp)      # y golpeó a P2
