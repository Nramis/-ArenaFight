extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")

func _match() -> MatchManager:
	GameConfig.roster_enabled = true
	GameConfig.p1_character = "ilgiz"
	GameConfig.p2_character = "bigboss"
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

func test_away_lasts_six_seconds_prevents_damage_and_actions() -> void:
	var m := _match()
	assert_bool(m.p1.abilities.activate(1)).is_true()
	assert_bool(m.p1.visible).is_false()
	assert_bool(m.p1.is_invulnerable()).is_true()
	assert_bool(m.p1.abilities.activate(0)).is_false()
	var move := MoveData.new()
	move.damage = 100
	m.p1.receive_hit(move,-1)
	assert_int(m.p1.health).is_equal(m.p1.max_health - 0)
	for i in 359:
		m.p1.abilities.tick()
	assert_bool(m.p1.visible).is_false()
	m.p1.abilities.tick()
	assert_bool(m.p1.visible).is_true()
	assert_bool(m.p1.is_invulnerable()).is_false()

func test_shrink_scales_hurtbox_damage_and_expires() -> void:
	var m := _match()
	var height := m.p2.hurtbox_rect().size.y
	m.p2.abilities.shrink()
	assert_float(m.p2.hurtbox_rect().size.y).is_equal_approx(height*0.65,0.01)
	assert_float(m.p2.abilities.damage_multiplier()).is_equal(0.6)
	for i in 359:
		m.p2.abilities.tick()
	assert_int(m.p2.abilities.shrink_frames).is_equal(1)
	m.p2.abilities.tick()
	assert_float(m.p2.hurtbox_rect().size.y).is_equal(height)
	assert_float(m.p2.abilities.damage_multiplier()).is_equal(1.0)

func test_negative_wave_applies_shrink_on_contact() -> void:
	var m := _match()
	m.p1.abilities.activate(2)
	var wave = get_tree().get_nodes_in_group("ability_effect").back()
	for i in 80:
		if not wave.is_queued_for_deletion():
			wave._physics_process(1.0/60.0)
	assert_int(m.p2.abilities.shrink_frames).is_equal(360)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)

func test_boss_is_shorter_and_pistol_hits_only_once() -> void:
	var m := _match()
	assert_float(m.p2.hurtbox_rect().size.y).is_less(m.p1.hurtbox_rect().size.y)
	m.p2.abilities.activate(0)
	var bullet = get_tree().get_nodes_in_group("ability_effect").back()
	for i in 60:
		if not bullet.is_queued_for_deletion():
			bullet._physics_process(1.0/60.0)
	assert_int(m.p1.health).is_equal(m.p1.max_health - 65)

func test_dogs_spawn_three_and_attack() -> void:
	var m := _match()
	m.p1.abilities.activate(0)
	var squad = get_tree().get_nodes_in_group("ability_effect")
	assert_int(squad.size()).is_equal(3)
	for e in squad:
		for i in 130:
			if not e.is_queued_for_deletion():
				e._physics_process(1.0/60.0)
	assert_int(m.p2.health).is_less(m.p2.max_health - 0)

func test_rifle_burst_and_crowd_counts_and_round_cleanup() -> void:
	var m := _match()
	m.p2.abilities.activate(1)
	assert_int(get_tree().get_nodes_in_group("ability_effect").size()).is_equal(6)
	m._reset_round()
	await get_tree().process_frame
	m.p2.frozen = false
	m.p2.abilities.activate(2)
	var crowd = get_tree().get_nodes_in_group("ability_effect")
	assert_int(crowd.size()).is_equal(5)
	assert_str(crowd[0].kind).is_equal("schoolkid")
	m.p1.abilities.shrink()
	m._reset_round()
	assert_int(m.p1.abilities.shrink_frames).is_equal(0)
	assert_bool(m.p1.visible).is_true()

func test_invulnerability_protects_from_negative_wave() -> void:
	var m := _match()
	m.p2.abilities.fish_frames = 180
	m.p2.abilities.shrink()
	assert_int(m.p2.abilities.shrink_frames).is_equal(0)
