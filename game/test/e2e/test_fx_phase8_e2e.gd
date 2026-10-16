# E2E Fase 8: al conectar un golpe en la escena real, aparece una chispa de impacto.
extends GdUnitTestSuite

const MATCH := preload("res://match/match.tscn")

func after_test() -> void:
	if Input.is_action_pressed("p1_lp"):
		Input.action_release("p1_lp")

func _load() -> Node:
	var m := MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func test_hit_spawns_hitspark() -> void:
	var m := _load()
	var p1: Fighter = m.get_node("Player1")
	var p2: Fighter = m.get_node("Player2")
	p1.position.x = 150.0
	p2.position.x = 200.0
	for i in 2:
		await get_tree().physics_frame
	Input.action_press("p1_lp")
	var spark_seen := false
	for i in 16:
		await get_tree().physics_frame
		if get_tree().get_nodes_in_group("hitspark").size() > 0:
			spark_seen = true
	assert_bool(spark_seen).is_true()
	assert_int(p2.health).is_less(p2.max_health - 0)   # y efectivamente golpeó
