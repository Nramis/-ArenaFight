extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")

func _match() -> MatchManager:
	GameConfig.roster_enabled = true
	GameConfig.p1_character = "ramis"
	GameConfig.p2_character = "vladislav"
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

func test_maris_transformation_changes_speed_hurtbox_and_expires() -> void:
	var m := _match()
	var speed := m.p1.walk_fwd_speed
	var height := m.p1.hurtbox_rect().size.y
	assert_bool(m.p1.abilities.activate(0)).is_true()
	assert_float(m.p1.walk_fwd_speed).is_equal_approx(speed*1.8,0.01)
	assert_float(m.p1.hurtbox_rect().size.y).is_less(height)
	assert_float(m.p1.abilities.damage_multiplier()).is_equal(1.25)
	for i in 360:
		m.p1.abilities.tick()
	assert_float(m.p1.walk_fwd_speed).is_equal(speed)
	assert_float(m.p1.hurtbox_rect().size.y).is_equal(height)

func test_sunbeam_waits_for_reflection_and_hits_once() -> void:
	var m := _match()
	m.p1.abilities.activate(1)
	var effect = get_tree().get_nodes_in_group("ability_effect").back()
	for i in 17:
		effect._physics_process(1.0/60.0)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
	effect._physics_process(1.0/60.0)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 105)
	for i in 10:
		effect._physics_process(1.0/60.0)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 105)

func test_fish_protects_against_sunbeam() -> void:
	var m := _match()
	m.p2.abilities.fish_frames = 180
	m.p1.abilities.activate(1)
	var effect = get_tree().get_nodes_in_group("ability_effect").back()
	for i in 18:
		effect._physics_process(1.0/60.0)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)

func test_critter_squad_spawns_behind_and_chases_target() -> void:
	var m := _match()
	m.p1.abilities.activate(2)
	var squad = get_tree().get_nodes_in_group("ability_effect")
	assert_int(squad.size()).is_equal(4)
	assert_float(squad[0].position.x).is_less(m.p1.position.x)
	var x: float = squad[0].position.x
	for i in 5:
		squad[0]._physics_process(1.0/60.0)
	assert_float(squad[0].position.x).is_greater(x)
	for i in 100:
		if not squad[0].is_queued_for_deletion():
			squad[0]._physics_process(1.0/60.0)
	assert_int(m.p2.health).is_less(m.p2.max_health - 0)

func test_airborne_target_can_avoid_critters() -> void:
	var m := _match()
	m.p2.position.y = 100
	m.p1.abilities.activate(2)
	var effect = get_tree().get_nodes_in_group("ability_effect")[0]
	for i in 130:
		effect._physics_process(1.0/60.0)
	assert_int(m.p2.health).is_equal(m.p2.max_health - 0)
