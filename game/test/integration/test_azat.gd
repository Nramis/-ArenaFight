extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")

func _arena() -> MatchManager:
	GameConfig.roster_enabled = true
	GameConfig.p1_character = "azat"
	GameConfig.p2_character = "nikita"
	GameConfig.p2_is_cpu = false
	GameConfig.menu_open = false
	var m: MatchManager = MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func after_test() -> void:
	GameConfig.roster_enabled = false
	GameConfig.p1_character = "rafael"
	GameConfig.p2_character = "nikita"

func test_every_attack_button_only_complains_in_every_stance() -> void:
	var m := _arena()
	for stance in ["st","cr","j"]:
		for button in Fighter.BTN_KEYS:
			m.p1.abilities.reset()
			m.p1.just_pressed = [button]
			assert_bool(m.p1.try_start_attack(stance)).is_false()
			assert_bool(m.p1.is_attack_active()).is_false()
			assert_object(m.p1.current_move).is_null()
			assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
	assert_float(m.p1.rhythm.stamina).is_equal(100.0)

func test_all_three_abilities_are_cosmetic_even_after_full_duration() -> void:
	var m := _arena()
	for slot in 3:
		m.p1.abilities.reset()
		assert_bool(m.p1.abilities.activate(slot)).is_true()
		assert_int(m.p1.abilities.pose_frames).is_greater(0)
		assert_str(m.p1.abilities.status_text()).is_not_empty()
		for i in 120:
			m.p1.abilities.tick()
		assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
		assert_int(m.p2.abilities.freeze_frames).is_equal(0)
		assert_int(m.p2.abilities.slow_frames).is_equal(0)
		assert_int(m.p2.abilities.shrink_frames).is_equal(0)
		assert_int(m.p2.abilities.burn_frames).is_equal(0)
	assert_array(get_tree().get_nodes_in_group("ability_effect")).is_empty()

func test_motion_specials_projectiles_and_throws_cannot_bypass_no_attack_rule() -> void:
	var m := _arena()
	m.p1.just_pressed = ["hp"]
	m.p1._numpad_history = [6,3,2]
	assert_bool(m.p1.try_start_special()).is_false()
	m.p1.start_move(m.p1.moves["st.hp"])
	assert_object(m.p1.current_move).is_null()
	m.p1.spawn_projectile(m.p1.specials["hadouken.h"])
	m.p1.input.lp = true
	m.p1.input.lk = true
	m.p1.just_pressed = ["lp","lk"]
	m.p1._update_throw_press()
	assert_bool(m.p1.throw_pressed).is_false()
	m.p1.do_throw(m.p2)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
	assert_str(str(m.p2.state_machine.current_state.name)).is_not_equal("Knockdown")
	assert_bool("azat" in Roster.IDS).is_true()
