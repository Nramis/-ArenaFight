extends GdUnitTestSuite

const MATCH = preload("res://match/match.tscn")

func _arena(ramis_second: bool = false, opponent: String = "polina") -> MatchManager:
    GameConfig.roster_enabled = true
    GameConfig.p1_character = opponent if ramis_second else "ramis"
    GameConfig.p2_character = "ramis" if ramis_second else opponent
    GameConfig.p1_skin = "default"
    GameConfig.p2_skin = "default"
    GameConfig.p2_is_cpu = false
    GameConfig.menu_open = false
    var arena: MatchManager = MATCH.instantiate()
    add_child(arena)
    auto_free(arena)
    arena.set_physics_process(false)
    arena.match_state.phase = MatchState.FIGHT
    for f: Fighter in [arena.p1,arena.p2]:
        f.set_physics_process(false)
        f.frozen = false
        f.input_source = null
        f.invuln_frames = 0
    arena.p1.position = Vector2(150,180)
    arena.p2.position = Vector2(200,180)
    return arena

func after_test() -> void:
    GameConfig.roster_enabled = false
    NetSession.arena = null

func test_cinematic_locks_both_fighters_and_kills_only_at_contact() -> void:
    var arena := _arena()
    var hero := arena.p1.abilities.expansion.hero
    assert_bool(hero.begin(arena.p2)).is_true()
    assert_bool(arena.p1.abilities.locked()).is_true()
    assert_bool(arena.p2.abilities.locked()).is_true()
    assert_bool(arena.p2.visible).is_false()
    for i in RamisUltimate.IMPACT-1:
        hero.tick()
    assert_int(arena.p2.health).is_equal(1500)
    assert_bool(hero.crater_active).is_false()
    hero.tick()
    assert_int(arena.p2.health).is_equal(0)
    assert_bool(hero.crater_active).is_true()
    assert_bool(hero.struck).is_true()
    assert_int(arena.p2.last_damage).is_equal(1500)
    for i in RamisUltimate.TOTAL-RamisUltimate.IMPACT:
        hero.tick()
    assert_bool(hero.active()).is_false()
    assert_bool(arena.p1.abilities.locked()).is_false()
    assert_bool(hero.crater_active).is_true()
    assert_int(arena.p1.health).is_equal(1500)

func test_round_clock_and_ko_wait_until_burial_finishes() -> void:
    var arena := _arena()
    var hero := arena.p1.abilities.expansion.hero
    hero.begin(arena.p2)
    var timer := arena.match_state.timer
    for i in RamisUltimate.IMPACT:
        hero.tick()
    arena._physics_process(1.0/60)
    assert_int(arena.match_state.phase).is_equal(MatchState.FIGHT)
    assert_int(arena.match_state.timer).is_equal(timer)
    for i in RamisUltimate.TOTAL-RamisUltimate.IMPACT:
        hero.tick()
    arena._physics_process(1.0/60)
    assert_int(arena.match_state.phase).is_equal(MatchState.ROUND_END)
    assert_int(arena.match_state.last_winner).is_equal(1)
    assert_int(arena.match_state.round_end_duration).is_equal(150)

func test_second_player_mirrors_slam_and_stays_inside_arena() -> void:
    var arena := _arena(true)
    arena.p1.position.x = 42
    arena.p2.position.x = 90
    var hero := arena.p2.abilities.expansion.hero
    hero.begin(arena.p1)
    assert_int(hero.direction).is_equal(-1)
    for i in RamisUltimate.TOTAL:
        hero.tick()
        assert_float(arena.p2.position.x).is_between(40.0,344.0)
    assert_int(arena.p1.health).is_equal(0)
    assert_int(arena.p2.health).is_equal(1500)
    assert_float(hero.impact.x).is_equal(105.0)

func test_reset_removes_crater_and_restores_hidden_opponent() -> void:
    var arena := _arena()
    var hero := arena.p1.abilities.expansion.hero
    hero.begin(arena.p2)
    for i in RamisUltimate.TOTAL:
        hero.tick()
    arena._reset_round()
    assert_bool(hero.crater_active).is_false()
    assert_int(hero.age).is_equal(-1)
    assert_bool(arena.p2.visible).is_true()
    assert_bool(arena.p1.abilities.expansion.bald).is_false()
    assert_int(arena.p2.health).is_equal(1500)
    assert_object(arena.p2.abilities.expansion.hero.source).is_null()

func test_cancel_mid_animation_restores_target_without_damage() -> void:
    var arena := _arena()
    var hero := arena.p1.abilities.expansion.hero
    hero.begin(arena.p2)
    for i in 50:
        hero.tick()
    hero.cancel()
    assert_bool(arena.p2.visible).is_true()
    assert_bool(arena.p2.abilities.locked()).is_false()
    assert_bool(hero.crater_active).is_false()
    assert_int(arena.p2.health).is_equal(1500)

func test_cinematic_state_is_in_network_digest() -> void:
    var arena := _arena()
    NetSession.arena = arena
    var before := NetSession.state_digest()
    arena.p1.abilities.expansion.hero.begin(arena.p2)
    assert_str(NetSession.state_digest()).is_not_equal(before)
    before = NetSession.state_digest()
    arena.p1.abilities.expansion.hero.tick()
    assert_str(NetSession.state_digest()).is_not_equal(before)

func test_each_costume_bank_has_sixteen_real_poses_and_all_attack_poses_play() -> void:
    for name in ["transform","motion","windup","drive","slam","victory"]:
        var bank := RamisHeroAtlas.bank(name)
        assert_int(bank.frames.size()).is_equal(16)
        assert_object(RamisHeroAtlas.texture(name)).is_not_null()
        for frame: Dictionary in bank.frames:
            assert_bool(frame.polygons.is_empty()).is_false()
    var played := {}
    for age in RamisUltimate.TOTAL:
        var pose := RamisHeroAtlas.attack_pose(age)
        played[str(pose[0])+str(pose[1])] = true
    # All 48 anticipation/drive/slam poses, then 15 recovery poses before KO.
    assert_int(played.size()).is_equal(63)

func test_dead_opponent_does_not_start_cinematic() -> void:
    var arena := _arena()
    arena.p2.health = 0
    assert_bool(arena.p1.abilities.expansion.hero.begin(arena.p2)).is_false()
    assert_bool(arena.p1.abilities.expansion.hero.active()).is_false()

func test_all_eleven_opponents_have_cinematic_art_and_can_be_buried() -> void:
    for id: String in Roster.IDS:
        var arena := _arena(false,id)
        var hero := arena.p1.abilities.expansion.hero
        assert_bool(hero.begin(arena.p2)).is_true()
        var art: RamisUltimateScene
        for node in get_tree().get_nodes_in_group("ability_effect"):
            if node is RamisUltimateScene and node.attacker == arena.p1:
                art = node
        assert_object(art).is_not_null()
        assert_object(art.victim_texture).is_not_null()
        assert_object(art.portrait).is_not_null()
        assert_object(art.crater_texture).is_not_null()
        for i in RamisUltimate.TOTAL:
            hero.tick()
        assert_int(arena.p2.health).is_equal(0)
        assert_bool(hero.crater_active).is_true()
        arena._reset_round()
