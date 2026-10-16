extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")

func _match() -> MatchManager:
	GameConfig.p2_is_cpu = false
	var m: MatchManager = MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func test_acceleration_is_smooth_and_reaches_same_top_speed() -> void:
	var m := _match()
	m.p1.walk(1)
	assert_float(m.p1.vel.x).is_greater(0.0)
	assert_float(m.p1.vel.x).is_less(m.p1.walk_fwd_speed)
	for i in 8:
		m.p1.walk(1)
	assert_float(m.p1.vel.x).is_equal(m.p1.walk_fwd_speed)

func test_buffered_tap_is_consumed_once() -> void:
	var m := _match()
	m.p1.input.lp = true
	m.p1._update_button_edges()
	m.p1.input.lp = false
	m.p1._update_button_edges()
	assert_bool(m.p1.try_start_attack("st")).is_true()
	assert_str(m.p1.current_move.move_name).is_equal("st.LP")
	assert_bool(m.p1.try_start_attack("st")).is_false()

func test_confirmed_light_can_chain_to_medium_but_not_reverse_or_whiff() -> void:
	var m := _match()
	m.p1.start_move(m.p1.moves["st.lp"])
	m.p1.attack_buffer = "mp"
	m.p1.attack_buffer_frames = 6
	assert_bool(m.p1.try_chain_normal()).is_false()
	m.p1.move_has_hit = true
	assert_bool(m.p1.try_chain_normal()).is_true()
	assert_str(m.p1.current_move.move_name).is_equal("st.MP")
	m.p1.move_has_hit = true
	m.p1.attack_buffer = "lp"
	m.p1.attack_buffer_frames = 6
	assert_bool(m.p1.try_chain_normal()).is_false()

func test_air_steering_is_bounded_and_cannot_teleport() -> void:
	var m := _match()
	m.p1.launch_jump(0)
	m.p1.input.right = true
	m.p1.steer_air(1.0/60)
	assert_float(m.p1.vel.x).is_greater(0.0)
	assert_float(m.p1.vel.x).is_less(m.p1.jump_h_speed)
	for i in 100:
		m.p1.steer_air(1.0/60)
	assert_float(m.p1.vel.x).is_equal(m.p1.jump_h_speed)

func test_landing_and_reset_clear_buffer_and_input_edges() -> void:
	var m := _match()
	m.p1.position.y = 179
	m.p1.on_ground = false
	m.p1.vel.y = 120
	m.p1._integrate(1.0/60)
	assert_int(m.p1.landing_frames).is_equal(8)
	m.p1.attack_buffer = "hp"
	m.p1.attack_buffer_frames = 8
	m._reset_round()
	assert_str(m.p1.attack_buffer).is_equal("")
	assert_int(m.p1.landing_frames).is_equal(0)

func test_block_feedback_is_distinct_from_hit() -> void:
	var m := _match()
	var move := MoveData.new()
	move.damage = 100
	m.p2.receive_block(move,1)
	assert_bool(m.p2.last_hit_blocked).is_true()
	assert_int(m.p2.last_damage).is_equal(15)
	m.p2.receive_hit(move,1)
	assert_bool(m.p2.last_hit_blocked).is_false()
	assert_int(m.p2.last_damage).is_equal(100)
