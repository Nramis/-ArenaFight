extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")

func _arena() -> MatchManager:
	GameConfig.roster_enabled = true
	GameConfig.p1_character = "polina"
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

func _effect(m: MatchManager, kind: String) -> Node2D:
	for child in m.get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://fx/polina_effect.gd" and child.kind == kind:
			return child
	return null

func test_teleport_has_windup_disappearance_reappearance_then_one_strike() -> void:
	var m := _arena()
	assert_bool(m.p1.abilities.activate(0)).is_true()
	assert_bool(m.p1.visible).is_true()
	for i in 16:
		m.p1.abilities.tick()
	assert_bool(m.p1.visible).is_false()
	assert_bool(m.p1.is_invulnerable()).is_true()
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
	for i in 8:
		m.p1.abilities.tick()
	assert_bool(m.p1.visible).is_true()
	assert_bool(m.p1.is_invulnerable()).is_false()
	assert_float(absf(m.p1.position.x-m.p2.position.x)).is_equal(46.0)
	for i in 4:
		m.p1.abilities.tick()
	assert_int(m.p2.health).is_equal(m.p2.max_health - 105)
	for i in 22:
		m.p1.abilities.tick()
	assert_int(m.p2.health).is_equal(m.p2.max_health - 105)
	assert_bool(m.p1.abilities.activate(0)).is_false()

func test_teleport_windup_is_interruptible_and_reset_restores_visibility() -> void:
	var m := _arena()
	m.p1.abilities.activate(0)
	m.p1.receive_hit(MoveData.new(),-1)
	assert_int(m.p1.abilities.teleport_frames).is_equal(0)
	assert_bool(m.p1.visible).is_true()
	for i in 50:
		m.p1.abilities.tick()
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
	m.p1.abilities.reset()
	m.p1.state_machine.force_state("Idle")
	m.p1.abilities.activate(0)
	for i in 16:
		m.p1.abilities.tick()
	assert_bool(m.p1.visible).is_false()
	m._reset_round()
	assert_bool(m.p1.visible).is_true()
	assert_int(m.p1.abilities.teleport_frames).is_equal(0)

func test_rain_warns_before_drops_and_can_damage_only_opponent() -> void:
	var m := _arena()
	m.p1.abilities.activate(1)
	var effect := _effect(m,"rain")
	assert_object(effect).is_not_null()
	for i in 25:
		effect._physics_process(1.0/60)
	assert_int(effect.spawned).is_equal(0)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
	for i in 130:
		effect._physics_process(1.0/60)
	assert_int(effect.spawned).is_equal(12)
	assert_int(m.p2.health).is_less(m.p2.max_health - 0)
	assert_int(m.p1.health).is_equal(m.p1.max_health - 0)

func test_rain_is_dodgeable_and_respects_invulnerability() -> void:
	var m := _arena()
	m.p1.abilities.activate(1)
	var effect := _effect(m,"rain")
	m.p2.position.x = 40
	for i in 160:
		effect._physics_process(1.0/60)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
	m.p1.abilities.reset()
	m.p2.position.x = 254
	m.p2.abilities.fish_frames = 180
	m.p1.abilities.activate(1)
	var effects := get_tree().get_nodes_in_group("ability_effect")
	var second: Node2D = effects.back()
	for i in 160:
		second._physics_process(1.0/60)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)

func test_random_gesture_stuns_for_three_seconds_without_green_freeze() -> void:
	var m := _arena()
	m.p1.abilities.activate(2)
	assert_int(m.p1.abilities.gesture_variant).is_between(0,2)
	var effect := _effect(m,"gesture")
	for i in 17:
		effect._physics_process(1.0/60)
	assert_int(m.p2.abilities.stun_frames).is_equal(0)
	effect._physics_process(1.0/60)
	assert_int(m.p2.abilities.stun_frames).is_equal(180)
	assert_int(m.p2.abilities.freeze_frames).is_equal(0)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
	assert_bool(m.p2.abilities.locked()).is_true()
	for i in 180:
		m.p2.abilities.tick()
	assert_bool(m.p2.abilities.locked()).is_false()

func test_first_hit_breaks_stupor_and_far_gesture_misses() -> void:
	var m := _arena()
	m.p2.abilities.stun(180)
	m.p2.receive_hit(m.p1.moves["st.lp"],1)
	assert_int(m.p2.abilities.stun_frames).is_equal(0)
	m.p1.position.x = 40
	m.p2.position.x = 344
	m.p1.abilities.activate(2)
	var effect := _effect(m,"gesture")
	for i in 18:
		effect._physics_process(1.0/60)
	assert_int(m.p2.abilities.stun_frames).is_equal(0)
