extends GdUnitTestSuite

const MATCH = preload("res://match/match.tscn")

func _match() -> MatchManager:
	GameConfig.p2_is_cpu = false
	var m: MatchManager = MATCH.instantiate()
	add_child(m)
	auto_free(m)
	m.match_state.phase = MatchState.FIGHT
	return m

func after_test() -> void:
	for action in ["p1_right", "p1_special1", "p2_special1"]:
		Input.action_release(action)

func test_energy_requires_drinking_and_expires() -> void:
	var m := _match()
	assert_bool(m.p1.abilities.activate(0)).is_true()
	assert_int(m.p1.abilities.energy_frames).is_equal(0)
	for i in 36:
		m.p1.abilities.tick()
	assert_float(m.p1.walk_fwd_speed).is_equal_approx(297.0,0.01)
	for i in FighterAbilities.ENERGY_DURATION:
		m.p1.abilities.tick()
	assert_float(m.p1.walk_fwd_speed).is_equal_approx(180.0,0.01)

func test_protein_changes_reach_and_damage_without_mutating_shared_move() -> void:
	var m := _match()
	var original: MoveData = m.p1.moves["st.lp"]
	var damage := original.damage
	var old_size := m.p1.hurtbox_rect().size
	m.p1.abilities.activate(1)
	for i in 36:
		m.p1.abilities.tick()
	m.p1.start_move(original)
	assert_int(m.p1.current_move.damage).is_equal(int(round(damage*1.6)))
	assert_int(original.damage).is_equal(damage)
	assert_vector(m.p1.hurtbox_rect().size).is_equal(old_size*1.4)
	assert_vector(m.p1.current_move.hitbox_size).is_equal(original.hitbox_size*1.4)

func test_getting_hit_interrupts_drink() -> void:
	var m := _match()
	m.p1.abilities.activate(1)
	m.p1.receive_hit(MoveData.new(),-1)
	for i in 40:
		m.p1.abilities.tick()
	assert_int(m.p1.abilities.protein_frames).is_equal(0)
	assert_int(m.p1.abilities.cast_frames).is_equal(0)

func test_freeze_stops_movement_and_expires() -> void:
	var m := _match()
	m.p1.abilities.freeze()
	var x := m.p1.position.x
	Input.action_press("p1_right")
	m.p1._physics_process(1.0/60.0)
	assert_float(m.p1.position.x).is_equal(x)
	assert_bool(m.p1.abilities.status_text().begins_with("В ЛОВУШКЕ")).is_true()
	for i in FighterAbilities.FREEZE_DURATION:
		m.p1.abilities.tick()
	m.p1._physics_process(1.0/60.0)
	m.p1._physics_process(1.0/60.0)
	assert_float(m.p1.position.x).is_greater(x)

func test_trap_lands_waits_and_freezes_only_opponent() -> void:
	var m := _match()
	m.p2.position.x = 254
	m.p1.position.x = 149
	assert_bool(m.p2.abilities.activate(0)).is_true()
	var effect = get_tree().get_nodes_in_group("ability_effect").back()
	for i in 26:
		effect._physics_process(1.0/60.0)
	assert_int(m.p1.abilities.freeze_frames).is_equal(FighterAbilities.FREEZE_DURATION)
	assert_int(m.p2.abilities.freeze_frames).is_equal(0)
	assert_bool(effect.is_queued_for_deletion()).is_true()

func test_trap_expires_if_no_one_steps_in_it() -> void:
	var m := _match()
	m.p1.position.x = 40
	m.p2.abilities.activate(0)
	var effect = get_tree().get_nodes_in_group("ability_effect").back()
	for i in 326:
		effect._physics_process(1.0/60.0)
	assert_bool(effect.is_queued_for_deletion()).is_true()
	assert_int(m.p1.abilities.freeze_frames).is_equal(0)

func test_rage_increases_speed_and_damage_then_resets() -> void:
	var m := _match()
	m.p2.abilities.activate(1)
	assert_float(m.p2.abilities.damage_multiplier()).is_equal(1.5)
	assert_float(m.p2.walk_fwd_speed).is_equal_approx(262.5,0.01)
	for i in FighterAbilities.RAGE_DURATION:
		m.p2.abilities.tick()
	assert_float(m.p2.abilities.damage_multiplier()).is_equal(1.0)
	assert_float(m.p2.walk_fwd_speed).is_equal_approx(210.0,0.01)

func test_mouth_wave_origin_and_knockback() -> void:
	var m := _match()
	m.p1.position.x = 130
	m.p2.position.x = 190
	m.p1.abilities.activate(2)
	var effect = get_tree().get_nodes_in_group("ability_effect").back()
	assert_float(effect.position.y).is_equal(94.0)
	for i in 8:
		if not effect.is_queued_for_deletion():
			effect._physics_process(1.0/60.0)
	assert_int(m.p2.health).is_less(m.p2.max_health - 0)
	assert_float(m.p2.vel.x).is_equal(520.0)

func test_black_flame_has_warning_ignites_and_can_be_jumped() -> void:
	var m := _match()
	m.p2.abilities.activate(2)
	var effect = get_tree().get_nodes_in_group("ability_effect").back()
	for i in 29:
		effect._physics_process(1.0/60)
	assert_int(m.p1.health).is_equal(m.p1.max_health - 0)
	effect._physics_process(1.0/60)
	assert_int(m.p1.health).is_equal(m.p1.max_health - 45)
	assert_int(m.p1.abilities.burn_frames).is_equal(180)
	for i in 180:
		m.p1.abilities.tick()
	assert_int(m.p1.health).is_equal(m.p1.max_health - 75)
	m._reset_round()
	m.p2.abilities.activate(2)
	var missed = get_tree().get_nodes_in_group("ability_effect").back()
	m.p1.position.y = 80
	for i in 30:
		missed._physics_process(1.0/60)
	assert_int(m.p1.health).is_equal(m.p1.max_health - 0)
	assert_int(m.p1.abilities.burn_frames).is_equal(0)

func test_cooldowns_and_round_reset() -> void:
	var m := _match()
	assert_bool(m.p1.abilities.activate(0)).is_true()
	assert_bool(m.p1.abilities.activate(0)).is_false()
	m.p1.abilities.freeze()
	m.p1.reset_for_round(Vector2(130,180),true)
	assert_int(m.p1.abilities.freeze_frames).is_equal(0)
	assert_int(m.p1.abilities.cooldowns[0]).is_equal(0)
	assert_bool(m.p1.abilities.activate(0)).is_true()
