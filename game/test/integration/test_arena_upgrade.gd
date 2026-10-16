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

func test_heavy_launches_lies_down_and_wakes_with_short_protection() -> void:
	var m := _arena()
	m.p2.receive_hit(m.p1.moves["st.lp"],1)
	m.p2.receive_hit(m.p1.moves["st.mp"],1)
	m.p2.receive_hit(m.p1.moves["st.hk"],1)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Knockdown")
	assert_float(m.p2.vel.x).is_greater_equal(400.0)
	assert_float(m.p2.vel.y).is_less(0.0)
	var hp := m.p2.health
	m.p2.receive_hit(m.p1.moves["st.hk"],1)
	assert_int(m.p2.health).is_equal(hp)
	for i in 65:
		m.p2.state_machine.physics_update(1.0/60)
		m.p2._integrate(1.0/60)
		if m.p2.state_machine.current_state.name == "Idle":
			break
	assert_str(m.p2.state_machine.current_state.name).is_equal("Idle")
	assert_int(m.p2.invuln_frames).is_equal(Fighter.WAKEUP_PROTECTION)
	m.p2.receive_hit(m.p1.moves["st.lp"],1)
	assert_int(m.p2.health).is_equal(hp)
	m.p2.start_move(m.p2.moves["st.lp"])
	assert_int(m.p2.invuln_frames).is_equal(0)

func test_blocked_heavy_stays_standing_and_chip_does_not_build_combo() -> void:
	var m := _arena()
	m.p2.receive_block(m.p1.moves["st.hk"],1)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Blockstun")
	assert_int(m.p2.combo_count).is_equal(0)
	assert_float(m.p2.vel.y).is_equal(0.0)

func test_five_hit_route_has_no_reverse_loop_and_counts_scaled_damage() -> void:
	var m := _arena()
	m.p1.start_move(m.p1.moves["st.lp"])
	m.p2.receive_hit(m.p1.current_move,1)
	for button in ["lk","mp","mk","hp"]:
		m.p1.move_has_hit = true
		m.p1.attack_buffer = button
		m.p1.attack_buffer_frames = 12
		assert_bool(m.p1.try_chain_normal()).is_true()
		m.p2.receive_hit(m.p1.current_move,1)
	assert_int(m.p2.combo_count).is_equal(5)
	assert_int(m.p2.combo_damage).is_equal(180)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Knockdown")
	m.p1.move_has_hit = true
	m.p1.attack_buffer = "lp"
	m.p1.attack_buffer_frames = 12
	assert_bool(m.p1.try_chain_normal()).is_false()

func test_counter_interrupts_startup_and_extends_stun() -> void:
	var m := _arena()
	m.p2.start_move(m.p2.moves["st.hk"])
	m.p2.state_machine.force_state("Attack")
	m.p2.receive_hit(m.p1.moves["st.lp"],1)
	assert_bool(m.p2.last_counter_hit).is_true()
	assert_int(m.p2.hitstun_frames).is_equal(m.p1.moves["st.lp"].hitstun+4)

func test_jump_clears_grounded_body_and_can_land_on_other_side() -> void:
	var m := _arena()
	m.p1.position = Vector2(165,180)
	m.p2.position = Vector2(210,180)
	m.p1.launch_jump(1)
	var crossed := false
	for i in 40:
		m.p1.apply_gravity(1.0/60)
		m.p1._integrate(1.0/60)
		if StagePhysics.bodies_overlap_vertically(m.p1,m.p2):
			var sep := StagePhysics.separate(m.p1.position.x,m.p2.position.x,m.pushbox_min_sep)
			m.p1.position.x = sep[0]
			m.p2.position.x = sep[1]
		if m.p1.position.x > m.p2.position.x:
			crossed = true
	assert_bool(crossed).is_true()
	assert_bool(m.p1.on_ground).is_true()
	m.p1._update_facing()
	assert_int(m.p1.facing()).is_equal(-1)
	assert_bool(StagePhysics.bodies_overlap_vertically(m.p1,m.p2)).is_true()

func test_polina_crosses_to_far_side_even_at_wall() -> void:
	var m := _arena()
	m.p1.roster_id = "polina"
	for target_x in [220.0,344.0]:
		m.p1.abilities.reset()
		m.p1.position.x = 130
		m.p2.position.x = target_x
		m.p1.abilities.activate(0)
		for i in 24:
			m.p1.abilities.tick()
		assert_float(m.p1.position.x).is_greater(m.p2.position.x)
		assert_float(m.p1.position.x).is_less_equal(344.0)
		assert_float(m.p1.position.x-m.p2.position.x).is_equal(46.0)
		assert_int(m.p1.facing()).is_equal(-1)

func test_jump_regions_exclude_neighbouring_shoes() -> void:
	for id in ["nikita","ilgiz","bigboss","vladislav","ramis","mavrin"]:
		var rect: Rect2 = JumpAtlas.REGIONS[id]
		assert_float(rect.position.x).is_greater(450.0)
		assert_float(rect.end.x).is_less_equal(768.0)

func test_five_hit_route_connects_with_real_spacing_physics_and_buffer() -> void:
	var m := _arena()
	var a := FakeInput.new()
	var b := FakeInput.new()
	auto_free(a)
	auto_free(b)
	m.p1.input_source = a
	m.p2.input_source = b
	m.p1.position.x = 150
	m.p2.position.x = 200
	var route := ["lp","lk","mp","mk","hp"]
	var sent := 0
	for tick in 200:
		a.frame = InputFrame.new()
		if sent == 0 or (sent < route.size() and m.p1.move_has_hit and m.p1.current_move.move_name.to_lower().ends_with(route[sent-1])):
			a.frame.set(route[sent],true)
			sent += 1
		m._physics_process(1.0/60)
		m.p1._physics_process(1.0/60)
		m.p2._physics_process(1.0/60)
		if m.p2.combo_count == 5:
			break
	assert_int(sent).is_equal(5)
	assert_int(m.p2.combo_count).is_equal(5)
	assert_int(m.p2.combo_damage).is_equal(180)
	assert_str(m.p2.state_machine.current_state.name).is_equal("Knockdown")
