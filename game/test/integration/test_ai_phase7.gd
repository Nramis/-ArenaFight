# Integración Fase 7: un fighter controlado por IA se acerca a un rival lejano.
extends GdUnitTestSuite

const FIGHTER := preload("res://fighter/fighter.tscn")

func test_ai_fighter_approaches_distant_opponent() -> void:
	var ai_f: Fighter = FIGHTER.instantiate()
	var opp: Fighter = FIGHTER.instantiate()
	var ai := AIInput.new()
	ai.difficulty = "hard"
	ai.fighter = ai_f
	ai.opponent = opp
	ai_f.input_source = ai
	auto_free(ai)
	ai_f.position = Vector2(100.0, ai_f.ground_y)
	opp.position = Vector2(300.0, opp.ground_y)
	ai_f.opponent = opp
	opp.opponent = ai_f
	ai_f.facing_right = true
	add_child(ai_f); add_child(opp)
	auto_free(ai_f); auto_free(opp)

	var start_x := ai_f.position.x
	for i in 40:
		await get_tree().physics_frame
	# el rival está a la derecha -> la IA debería avanzar a la derecha
	assert_float(ai_f.position.x).is_greater(start_x + 15.0)
