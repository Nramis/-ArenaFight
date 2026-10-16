extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")
func _arena() -> MatchManager:
	GameConfig.roster_enabled = true
	GameConfig.p1_character = "rafael"
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
func test_finisher_shows_face_once_and_respects_cooldown() -> void:
	var m := _arena()
	for key in ["st.lp","st.mp","st.hp"]:
		m.p2.receive_hit(m.p1.moves[key],1)
		m._on_hit(m.p2)
	assert_int(m.cameo.appearances).is_equal(1)
	assert_bool(m.cameo.visible).is_true()
	assert_bool(m.cameo.show_cameo()).is_false()
	m.cameo._process(0.3)
	assert_float(m.cameo.position.y).is_equal(216.0)
	m.cameo._process(1.3)
	assert_bool(m.cameo.visible).is_false()
func test_short_series_does_not_show_but_completed_three_hit_series_does() -> void:
	var m := _arena()
	for i in 2:
		m.p2.receive_hit(m.p1.moves["st.lp"],1)
		m._on_hit(m.p2)
	assert_int(m.cameo.appearances).is_equal(0)
	m.p2.receive_hit(m.p1.moves["st.mp"],1)
	m._on_hit(m.p2)
	assert_int(m.cameo.appearances).is_equal(0)
	m.p2.state_machine.force_state("Idle")
	m.cameo._physics_process(1.0/60)
	assert_int(m.cameo.appearances).is_equal(1)
func test_round_reset_clears_face_and_pending_combo() -> void:
	var m := _arena()
	m.cameo.show_cameo()
	m.cameo.pending[m.p2] = 3
	m._reset_round()
	assert_bool(m.cameo.visible).is_false()
	assert_bool(m.cameo.pending.is_empty()).is_true()
	assert_float(m.cameo.cooldown).is_equal(0.0)
func test_original_short_voice_is_loaded_without_random_pitch() -> void:
	var m := _arena()
	GameConfig.set_audio(true,0.8)
	m.sfx.play_event("toasty")
	assert_bool(m.sfx.voices[0].stream in m.sfx.bank["toasty"]).is_true()
	assert_float(m.sfx.voices[0].pitch_scale).is_equal(1.0)
	assert_float(m.sfx.voices[0].stream.get_length()).is_less(1.0)
