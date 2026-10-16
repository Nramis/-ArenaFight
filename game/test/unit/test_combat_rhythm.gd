extends GdUnitTestSuite
func test_fourth_same_attack_is_denied_but_changing_attack_works() -> void:
	var rhythm := CombatRhythm.new()
	assert_bool(rhythm.try_normal("lp").is_empty()).is_false()
	var second := rhythm.try_normal("lp")
	assert_float(second.damage).is_less(1.0)
	assert_int(second.recovery).is_greater(0)
	rhythm.try_normal("lp")
	assert_bool(rhythm.try_normal("lp").is_empty()).is_true()
	assert_str(rhythm.warning).is_equal("СМЕНИ УДАР")
	assert_bool(rhythm.try_normal("mk").is_empty()).is_false()

func test_pause_restores_stamina_and_clears_repeat_penalty() -> void:
	var rhythm := CombatRhythm.new()
	for i in 3:
		rhythm.try_normal("lp")
	for i in 360:
		rhythm.tick()
	assert_float(rhythm.stamina).is_equal(100.0)
	assert_float(rhythm.try_normal("lp").damage).is_equal(1.0)
