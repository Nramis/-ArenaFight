extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")
func _arena() -> MatchManager:
	GameConfig.roster_enabled = true
	GameConfig.p1_character = "mavrin"
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
func _assist(m: MatchManager) -> SalahovAssist:
	for c in m.get_children():
		if c is SalahovAssist:
			return c
	return null
func test_exactly_one_of_ten_rolls_succeeds() -> void:
	var successes := 0
	for roll in 10:
		if FighterAbilities.phone_succeeds(roll):
			successes += 1
	assert_int(successes).is_equal(1)
func test_failed_call_and_interrupted_call_spawn_nothing() -> void:
	var m := _arena()
	m.p1.abilities.activate(2)
	m.p1.abilities.phone_roll = 1
	for i in 24:
		m.p1.abilities.tick()
	assert_object(_assist(m)).is_null()
	assert_int(m.p2.health).is_equal(1500)
	assert_str(m.p1.abilities.effect_name).is_equal("НЕ ОТВЕЧАЕТ...")
	m.p1.abilities.reset()
	m.p1.abilities.activate(2)
	m.p1.abilities.phone_roll = 0
	m.p1.receive_hit(MoveData.new(),-1)
	for i in 30:
		m.p1.abilities.tick()
	assert_object(_assist(m)).is_null()
func test_success_waits_for_answer_and_does_five_hits_then_knockdown() -> void:
	var m := _arena()
	m.p1.frozen = false
	m.p2.frozen = false
	m.p1.abilities.activate(2)
	m.p1.abilities.phone_roll = 0
	for i in 23:
		m.p1.abilities.tick()
	assert_object(_assist(m)).is_null()
	m.p1.abilities.tick()
	var assist := _assist(m)
	assert_object(assist).is_not_null()
	for i in 84:
		assist._physics_process(1.0/60)
		m.p2._physics_process(1.0/60)
	assert_int(assist.strikes).is_equal(5)
	assert_int(m.p2.health).is_equal(1128)
	assert_int(m.p2.combo_count).is_equal(5)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Knockdown")
func test_invulnerability_and_leaving_strike_zone_avoid_damage() -> void:
	var m := _arena()
	m.p1.frozen = false
	var a := SalahovAssist.new()
	a.attacker = m.p1
	a.target = m.p2
	m.add_child(a)
	m.p2.abilities.fish_frames = 300
	for i in 84:
		a._physics_process(1.0/60)
	assert_int(m.p2.health).is_equal(1500)
	m.p2.abilities.reset()
	a.age = 24
	a.position.x = 40
	m.p2.position.x = 344
	for i in 60:
		a._physics_process(1.0/60)
	assert_int(m.p2.health).is_equal(1500)
func test_seeded_phone_rolls_repeat_and_round_reset_removes_helper() -> void:
	var m := _arena()
	var rolls: Array[int] = []
	seed(8012)
	for i in 10:
		m.p1.abilities.reset()
		m.p1.abilities.activate(2)
		rolls.append(m.p1.abilities.phone_roll)
	seed(8012)
	for i in 10:
		m.p1.abilities.reset()
		m.p1.abilities.activate(2)
		assert_int(m.p1.abilities.phone_roll).is_equal(rolls[i])
	m.p1.abilities.phone_roll = 0
	for i in 24:
		m.p1.abilities.tick()
	var a := _assist(m)
	assert_object(a).is_not_null()
	m._reset_round()
	assert_bool(a.is_queued_for_deletion()).is_true()
	assert_int(m.p1.abilities.phone_frames).is_equal(0)
func test_five_hit_assist_is_blockable_and_does_not_knock_down_on_block() -> void:
	var m := _arena()
	m.p1.frozen = false
	m.p2.facing_right = false
	m.p2.input.right = true
	var a := SalahovAssist.new()
	a.attacker = m.p1
	a.target = m.p2
	m.add_child(a)
	for i in 84:
		a._physics_process(1.0/60)
	assert_int(m.p2.health).is_equal(1419)
	assert_int(m.p2.combo_count).is_equal(0)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Blockstun")
