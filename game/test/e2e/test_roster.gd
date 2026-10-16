extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")

func _match(first: String, second: String) -> MatchManager:
	GameConfig.roster_enabled = true
	GameConfig.p1_character = first
	GameConfig.p2_character = second
	GameConfig.p2_is_cpu = false
	var m: MatchManager = MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func after_test() -> void:
	GameConfig.roster_enabled = false
	GameConfig.p1_character = "rafael"
	GameConfig.p2_character = "nikita"
	Input.action_release("p1_up")

func test_any_roster_slot_preserves_identity() -> void:
	var m := _match("nikita","rafael")
	assert_str(m.p1.roster_name()).is_equal("nikita")
	assert_str(m.p2.roster_name()).is_equal("rafael")
	assert_bool(m.p1.abilities.activate(1)).is_true()
	assert_int(m.p1.abilities.rage_frames).is_greater(0)
	assert_bool(m.p2.abilities.activate(0)).is_true()
	assert_int(m.p2.abilities.cast_frames).is_greater(0)

func test_fish_immunity_lasts_exactly_three_seconds() -> void:
	var m := _match("vladislav","nikita")
	m.p1.abilities.activate(1)
	for i in 30:
		m.p1.abilities.tick()
	assert_bool(m.p1.is_invulnerable()).is_true()
	m.p1.receive_hit(MoveData.new(),-1)
	m.p1.get_thrown(-1)
	m.p1.abilities.freeze()
	assert_int(m.p1.health).is_equal(m.p1.max_health - 0)
	assert_int(m.p1.abilities.freeze_frames).is_equal(0)
	for i in 179:
		m.p1.abilities.tick()
	assert_bool(m.p1.is_invulnerable()).is_true()
	m.p1.abilities.tick()
	assert_bool(m.p1.is_invulnerable()).is_false()
	m.p1.receive_hit(MoveData.new(),-1)
	assert_int(m.p1.health).is_less(m.p1.max_health - 0)

func test_burger_wave_creates_five_projectiles() -> void:
	var m := _match("vladislav","mavrin")
	m.p1.abilities.activate(0)
	assert_int(get_tree().get_nodes_in_group("ability_effect").size()).is_equal(5)

func test_fat_mode_widens_hurtbox_and_halves_speed_then_expires() -> void:
	var m := _match("vladislav","mavrin")
	var width := m.p1.hurtbox_rect().size.x
	m.p1.abilities.activate(2)
	assert_float(m.p1.hurtbox_rect().size.x).is_equal_approx(width*1.65,0.01)
	assert_float(m.p1.walk_fwd_speed).is_equal(90.0)
	for i in 480:
		m.p1.abilities.tick()
	assert_float(m.p1.walk_fwd_speed).is_equal(180.0)
	assert_float(m.p1.hurtbox_rect().size.x).is_equal(width)

func test_words_stack_slow_with_cap_and_expiry() -> void:
	var m := _match("mavrin","vladislav")
	m.p2.abilities.add_slow()
	var first := m.p2.walk_fwd_speed
	m.p2.abilities.add_slow()
	assert_float(m.p2.walk_fwd_speed).is_less(first)
	for i in 10:
		m.p2.abilities.add_slow()
	assert_float(m.p2.abilities.slow_strength).is_equal_approx(0.72,0.01)
	for i in 150:
		m.p2.abilities.tick()
	assert_float(m.p2.walk_fwd_speed).is_equal(180.0)

func test_talking_emits_words_and_can_be_interrupted() -> void:
	var m := _match("mavrin","rafael")
	m.p1.abilities.activate(0)
	for i in 14:
		m.p1.abilities.tick()
	assert_int(get_tree().get_nodes_in_group("ability_effect").size()).is_equal(1)
	m.p1.receive_hit(MoveData.new(),-1)
	assert_int(m.p1.abilities.talking_frames).is_equal(0)

func test_split_kick_has_high_hitbox_and_real_damage() -> void:
	var m := _match("mavrin","vladislav")
	m.p1.position.x = 140
	m.p2.position.x = 195
	m.p1.abilities.activate(1)
	assert_str(m.p1.current_move.move_name).is_equal("SplitKick")
	m.p1.state_machine.current_state.state_frame = 9
	assert_bool(Combat.resolve(m.p1,m.p2)).is_true()
	assert_int(m.p2.health).is_equal(m.p2.max_health - 95)

func test_phone_call_windup_does_not_change_combat_stats_or_spawn_early() -> void:
	var m := _match("mavrin","vladislav")
	var speed := m.p1.walk_fwd_speed
	var health := m.p2.health
	m.p1.abilities.activate(2)
	assert_str(m.p1.abilities.pose_kind).is_equal("phone")
	assert_int(m.p2.health).is_equal(health)
	assert_float(m.p1.walk_fwd_speed).is_equal(speed)
	assert_float(m.p1.abilities.damage_multiplier()).is_equal(1.0)
	assert_int(get_tree().get_nodes_in_group("ability_effect").size()).is_equal(0)

func test_flight_moves_up_and_hit_cancels_it() -> void:
	var m := _match("mavrin","vladislav")
	m.p1.abilities.toggle_flight()
	var y := m.p1.position.y
	m.p1.input.up = true
	m.p1.abilities.process_flight(1.0/60.0)
	assert_float(m.p1.position.y).is_less(y)
	m.p1.receive_hit(MoveData.new(),-1)
	assert_bool(m.p1.abilities.flying).is_false()

func test_word_waves_hit_and_stack_slow_without_damage() -> void:
	var m := _match("mavrin","vladislav")
	m.p2.position.x = 200
	m.p1.abilities.activate(0)
	for i in 14:
		m.p1.abilities.tick()
	var first = get_tree().get_nodes_in_group("ability_effect").back()
	for i in 25:
		if not first.is_queued_for_deletion():
			first._physics_process(1.0/60.0)
	var slow := m.p2.abilities.slow_strength
	assert_float(slow).is_greater(0.0)
	for i in 14:
		m.p1.abilities.tick()
	var second = get_tree().get_nodes_in_group("ability_effect").back()
	for i in 25:
		if not second.is_queued_for_deletion():
			second._physics_process(1.0/60.0)
	assert_float(m.p2.abilities.slow_strength).is_greater(slow)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
