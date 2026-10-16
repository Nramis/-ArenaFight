extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")
func _match() -> MatchManager:
	GameConfig.p2_is_cpu = false
	GameConfig.menu_open = false
	var m: MatchManager = MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func test_one_aerial_attack_until_next_landing() -> void:
	var m := _match()
	m.p1.launch_jump(0)
	m.p1.just_pressed = ["lp"]
	assert_bool(m.p1.try_start_attack("j")).is_true()
	m.p1.just_pressed = ["mk"]
	assert_bool(m.p1.try_start_attack("j")).is_false()
	m.p1.position.y = 179
	m.p1.vel.y = 120
	m.p1._integrate(1.0/60)
	assert_bool(m.p1.air_attack_used).is_false()
	assert_int(m.p1.landing_lag_frames).is_equal(8)

func test_crouching_attack_keeps_low_hurtbox() -> void:
	var m := _match()
	m.p1.start_move(m.p1.moves["cr.lp"])
	m.p1.state_machine.force_state("Attack")
	assert_bool(m.p1.is_crouching_pose()).is_true()
	assert_float(m.p1.hurtbox_rect().size.y).is_equal(56.0)
	assert_bool(m.p1.moves["cr.hk"].hits_low).is_true()
	assert_bool(m.p1.moves["cr.hk"].causes_knockdown).is_true()
	for key: String in m.p1.moves:
		if key.begins_with("j."):
			assert_bool(m.p1.moves[key].hits_overhead).is_true()

func test_final_buttons_rematch_and_selection_exist() -> void:
	var m := _match()
	var panel = m.get_node("Presentation")
	m.match_state.p1_rounds = 2
	m.match_state.last_winner = 1
	m.match_state.phase = MatchState.MATCH_END
	panel._process(0.0)
	assert_bool(panel.rematch_button.visible).is_true()
	assert_bool(panel.select_button.visible).is_true()
	assert_str(panel.title.text).is_equal("ПОБЕДА!")
	m.rematch()
	assert_int(m.match_state.phase).is_equal(MatchState.INTRO)
	assert_float(m.p1.rhythm.stamina).is_equal(100.0)
