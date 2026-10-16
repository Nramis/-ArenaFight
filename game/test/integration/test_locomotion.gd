extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")

func _arena() -> MatchManager:
	GameConfig.roster_enabled = true
	GameConfig.p1_character = "ramis"
	GameConfig.p2_character = "nikita"
	GameConfig.p2_is_cpu = false
	GameConfig.menu_open = false
	var m: MatchManager = MATCH.instantiate()
	add_child(m)
	auto_free(m)
	return m

func after_test() -> void:
	GameConfig.roster_enabled = false
	GameConfig.p1_character = "rafael"

func test_maris_uses_locomotion_instead_of_frozen_special_pose() -> void:
	var m := _arena()
	assert_bool(m.p1.abilities.activate(0)).is_true()
	for i in 20:
		m.p1.abilities.tick()
	assert_bool(LocomotionArt.handles(m.p1)).is_true()
	m.p1.state_machine.force_state("Walk")
	assert_bool(LocomotionArt.handles(m.p1)).is_true()
	m.p1.receive_hit(MoveData.new(),1)
	assert_bool(LocomotionArt.handles(m.p1)).is_false()

func test_every_fighter_has_eight_complete_frames_and_1500_health() -> void:
	var m := _arena()
	for id in ["rafael","nikita","vladislav","mavrin","ramis","ilgiz","bigboss","azat","polina"]:
		m.p1.roster_id = id
		m.p1.reset_for_round(Vector2(130,180),true)
		assert_int(m.p1.health).is_equal(1500)
		var data: Dictionary = LocomotionAtlas.DATA[id]
		assert_int(data.regions.size()).is_equal(8)
		var atlas: Texture2D = LocomotionArt.BANKS[data.bank]
		for rect: Rect2 in data.regions:
			assert_float(rect.size.y).is_greater(100.0)
			assert_bool(Rect2(Vector2.ZERO,atlas.get_size()).encloses(rect)).is_true()

func test_reverse_walk_cycle_wraps_and_round_reset_heals_to_new_maximum() -> void:
	assert_int(LocomotionAtlas.frame_at(-13.5)).is_equal(7)
	assert_int(LocomotionAtlas.frame_at(108.0)).is_equal(0)
	var m := _arena()
	m.p1.health = 10
	m._reset_round()
	assert_int(m.p1.health).is_equal(1500)
	assert_int(m.p2.health).is_equal(1500)
