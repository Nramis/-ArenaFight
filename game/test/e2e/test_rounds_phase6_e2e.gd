# E2E Fase 6: en la escena real, un KO otorga el round y reinicia para el siguiente.
extends GdUnitTestSuite

const MATCH := preload("res://match/match.tscn")

func _load() -> Node:
	var m := MATCH.instantiate()
	add_child(m)
	auto_free(m)
	return m

func test_ko_awards_round_and_resets_for_next() -> void:
	var m := _load()
	var p2: Fighter = m.get_node("Player2")
	# pasar la intro hasta la fase de pelea
	for i in MatchState.INTRO_FRAMES+5:
		await get_tree().physics_frame
	assert_int(m.match_state.phase).is_equal(MatchState.FIGHT)
	# forzar un KO de P2
	p2.health = 0
	# correr el fin de round + reset del siguiente
	for i in MatchState.ROUND_END_FRAMES+10:
		await get_tree().physics_frame
	assert_int(m.match_state.p1_rounds).is_equal(1)      # P1 se llevó el round
	assert_int(p2.health).is_greater(0)                   # vida reiniciada para el siguiente
