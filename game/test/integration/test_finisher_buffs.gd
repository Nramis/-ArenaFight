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
func test_single_heavy_staggers_but_does_not_knock_down() -> void:
	var m := _arena()
	m.p2.receive_hit(m.p1.moves["st.hk"],1)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Hitstun")
	assert_float(m.p2.vel.y).is_equal(0.0)
	assert_float(m.p2.vel.x).is_less_equal(110.0)
func test_two_hits_are_not_enough_but_third_heavy_finishes_combo() -> void:
	var m := _arena()
	m.p2.receive_hit(m.p1.moves["st.lp"],1)
	m.p2.receive_hit(m.p1.moves["st.hk"],1)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Hitstun")
	m.p2.receive_hit(m.p1.moves["st.hk"],1)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Knockdown")
func test_recovered_opponent_does_not_count_as_continuing_combo() -> void:
	var m := _arena()
	m.p2.receive_hit(m.p1.moves["st.lp"],1)
	m.p2.receive_hit(m.p1.moves["st.mp"],1)
	m.p2.state_machine.force_state("Idle")
	m.p2.receive_hit(m.p1.moves["st.hp"],1)
	assert_int(m.p2.combo_count).is_equal(1)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Hitstun")
func test_energy_allows_attacking_with_empty_stamina_but_keeps_repeat_limit() -> void:
	var m := _arena()
	m.p1.rhythm.stamina = 0
	m.p1.abilities.energy_frames = 100
	for i in 3:
		m.p1.just_pressed = ["lp"]
		assert_bool(m.p1.try_start_attack("st")).is_true()
	assert_float(m.p1.rhythm.stamina).is_equal(0.0)
	m.p1.just_pressed = ["lp"]
	assert_bool(m.p1.try_start_attack("st")).is_false()
	m.p1.just_pressed = ["mk"]
	assert_bool(m.p1.try_start_attack("st")).is_true()
	m.p1.abilities.energy_frames = 0
	m.p1.just_pressed = ["mp"]
	assert_bool(m.p1.try_start_attack("st")).is_false()
func test_buffs_accelerate_attack_phases_without_mutating_base_moves() -> void:
	var m := _arena()
	var base: MoveData = m.p1.moves["st.hp"]
	var original := base.total()
	for property in ["energy_frames","protein_frames","rage_frames","maris_frames","fish_frames"]:
		m.p1.abilities.reset()
		m.p1.abilities.set(property,100)
		m.p1.start_move(base)
		assert_int(m.p1.current_move.total()).is_less(original)
		assert_int(base.total()).is_equal(original)
	m.p1.abilities.reset()
	m.p1.start_move(base)
	assert_int(m.p1.current_move.total()).is_equal(original)
