extends GdUnitTestSuite

const MATCH = preload("res://match/match.tscn")

func _arena(id: String = "rinat") -> MatchManager:
    GameConfig.roster_enabled = true
    GameConfig.p1_character = id
    GameConfig.p2_character = "nikita"
    GameConfig.p1_skin = "default"
    GameConfig.p2_skin = "default"
    GameConfig.p2_is_cpu = false
    GameConfig.menu_open = false
    var arena: MatchManager = MATCH.instantiate()
    add_child(arena)
    auto_free(arena)
    arena.match_state.phase = MatchState.FIGHT
    return arena

func after_test() -> void:
    GameConfig.roster_enabled = false
    GameConfig.p1_skin = "default"
    GameConfig.p2_skin = "default"

func test_roster_and_skin_validation() -> void:
    assert_str(Roster.valid("rinat")).is_equal("rinat")
    assert_str(Skins.valid("rinat","scorpion")).is_equal("scorpion")
    assert_str(Skins.valid("vladislav","paquito")).is_equal("paquito")
    assert_str(Skins.valid("nikita","scorpion")).is_equal("default")
    assert_str(Skins.valid("rinat","paquito")).is_equal("default")

func test_chain_pulls_then_holds_for_one_second() -> void:
    var arena := _arena()
    var source := arena.p1
    var victim := arena.p2
    assert_bool(source.abilities.activate(0)).is_true()
    assert_int(source.abilities.cooldowns[0]).is_equal(480)
    for frame in RinatAbilities.CHAIN_WINDUP + RinatAbilities.CHAIN_FLIGHT:
        source.abilities.tick()
    assert_int(victim.abilities.rinat.bound_frames).is_equal(78)
    for frame in RinatAbilities.PULL_DURATION:
        victim.abilities.tick()
    assert_float(victim.position.x).is_equal(source.position.x + 48)
    assert_int(victim.abilities.rinat.bound_frames).is_equal(60)
    for frame in 59:
        victim.abilities.tick()
        assert_bool(victim.abilities.locked()).is_true()
    victim.abilities.tick()
    assert_bool(victim.abilities.locked()).is_false()

func test_block_prevents_chain_binding() -> void:
    var arena := _arena()
    arena.p2.input.right = true
    arena.p1.abilities.activate(0)
    for frame in 26:
        arena.p1.abilities.tick()
    assert_int(arena.p2.abilities.rinat.bound_frames).is_equal(0)
    assert_bool(arena.p2.last_hit_blocked).is_true()

func test_invulnerability_and_jumping_over_chain_avoid_binding() -> void:
    var arena := _arena()
    arena.p2.invuln_frames = 60
    arena.p1.abilities.rinat._catch_chain()
    assert_int(arena.p2.health).is_equal(1500)
    arena.p2.invuln_frames = 0
    arena.p2.position.y = 50
    arena.p1.abilities.rinat._catch_chain()
    assert_int(arena.p2.abilities.rinat.bound_frames).is_equal(0)

func test_drinking_can_be_interrupted_without_granting_master() -> void:
    var arena := _arena()
    arena.p1.abilities.activate(1)
    arena.p1.receive_hit(MoveData.new(),-1)
    for frame in 40:
        arena.p1.abilities.tick()
    assert_int(arena.p1.abilities.rinat.master_frames).is_equal(0)
    assert_int(arena.p1.abilities.cooldowns[1]).is_equal(1160)

func test_master_lasts_fifteen_seconds_then_twenty_second_cooldown() -> void:
    var arena := _arena()
    var a := arena.p1.abilities
    a.activate(1)
    for frame in 36:
        a.tick()
    assert_int(a.rinat.master_frames).is_equal(900)
    assert_bool(a.locked()).is_false()
    assert_float(a.damage_multiplier()).is_equal(1.25)
    for frame in 900:
        a.tick()
    assert_int(a.rinat.master_frames).is_equal(0)
    assert_int(a.cooldowns[1]).is_equal(1200)
    assert_float(a.damage_multiplier()).is_equal(1.0)
    for frame in 1200:
        a.tick()
    assert_int(a.cooldowns[1]).is_equal(0)

func test_singing_slows_opponent_but_does_not_lock_attack() -> void:
    var arena := _arena()
    var r := arena.p1.abilities.rinat
    r.master_frames = 500
    r.tear_timer = 100
    r.chant_timer = 1
    r.tick()
    assert_float(arena.p2.abilities.slow_strength).is_equal(0.30)
    assert_int(arena.p2.abilities.slow_frames).is_equal(90)
    assert_bool(arena.p1.abilities.locked()).is_false()
    arena.p1.just_pressed = ["lp"]
    assert_bool(arena.p1.try_start_attack("st")).is_true()
    assert_int(arena.p1.current_move.damage).is_equal(38)

func test_damage_buff_is_sampled_at_attack_start() -> void:
    var arena := _arena()
    var move := MoveData.new()
    move.damage = 100
    arena.p1.abilities.rinat.master_frames = 1
    arena.p1.start_move(move)
    assert_int(arena.p1.current_move.damage).is_equal(125)
    arena.p1.abilities.rinat.tick()
    assert_int(arena.p1.current_move.damage).is_equal(125)
    assert_int(move.damage).is_equal(100)
    arena.p1.start_move(move)
    assert_int(arena.p1.current_move.damage).is_equal(100)

func test_random_shirt_tear_never_cancels_attacks() -> void:
    var arena := _arena()
    var r := arena.p1.abilities.rinat
    r.master_frames = 500
    r.tear_timer = 1
    r.chant_timer = 100
    r.tick()
    assert_bool(r.shirt_torn).is_true()
    assert_int(r.tear_frames).is_equal(36)
    assert_bool(arena.p1.abilities.locked()).is_false()

func test_smoke_has_small_periodic_damage_and_three_second_cooldown() -> void:
    var arena := _arena()
    var a := arena.p1.abilities
    a.activate(2)
    assert_int(a.cooldowns[2]).is_equal(180)
    for frame in 18:
        a.tick()
    assert_int(a.rinat.smoke_frames).is_equal(120)
    assert_int(arena.p2.health).is_equal(1500)
    for frame in 120:
        a.tick()
    assert_int(arena.p2.health).is_equal(1476)
    assert_int(a.rinat.smoke_frames).is_equal(0)
    assert_bool(a.activate(2)).is_false()
    for frame in 42:
        a.tick()
    assert_bool(a.activate(2)).is_true()

func test_smoke_cannot_damage_invulnerable_opponent() -> void:
    var arena := _arena()
    arena.p2.invuln_frames = 300
    arena.p1.abilities.rinat.smoke_frames = 120
    for frame in 120:
        arena.p1.abilities.rinat.tick()
    assert_int(arena.p2.health).is_equal(1500)

func test_crouch_plus_each_punch_starts_rinat_uppercut() -> void:
    var arena := _arena()
    for button in ["lp","mp","hp"]:
        arena.p1.rhythm.reset()
        arena.p1.input.down = true
        arena.p1.just_pressed = [button]
        assert_bool(arena.p1.try_start_attack("st")).is_true()
        assert_str(arena.p1.current_move.move_name).is_equal("RinatUppercut")
        assert_bool(arena.p1.current_move.causes_knockdown).is_true()
        arena.p2.reset_for_round(Vector2(180,180),false)
        arena.p2.receive_hit(arena.p1.current_move,1)
        assert_float(arena.p2.vel.y).is_less(0)
        assert_float(arena.p2.vel.x).is_greater(300)

func test_other_fighters_keep_original_crouch_attacks() -> void:
    var arena := _arena("vladislav")
    arena.p1.input.down = true
    arena.p1.just_pressed = ["hp"]
    assert_bool(arena.p1.try_start_attack("cr")).is_true()
    assert_str(arena.p1.current_move.move_name).is_equal("cr.HP")
    assert_bool(arena.p1.current_move.causes_knockdown).is_false()

func test_round_reset_clears_every_rinat_effect() -> void:
    var arena := _arena()
    arena.p1.abilities.rinat.master_frames = 500
    arena.p1.abilities.rinat.smoke_frames = 80
    arena.p1.abilities.rinat.shirt_torn = true
    arena.p2.abilities.rinat.bound_source = arena.p1
    arena.p2.abilities.rinat.bound_frames = 60
    arena._reset_round()
    assert_int(arena.p1.abilities.rinat.master_frames).is_equal(0)
    assert_int(arena.p1.abilities.rinat.smoke_frames).is_equal(0)
    assert_bool(arena.p1.abilities.rinat.shirt_torn).is_false()
    assert_bool(arena.p2.abilities.locked()).is_false()

func test_sync_digest_includes_binding_smoke_and_chant_timers() -> void:
    var arena := _arena()
    var previous := NetSession.arena
    NetSession.arena = arena
    var baseline := NetSession.state_digest()
    arena.p1.abilities.rinat.smoke_clock = 9
    assert_str(NetSession.state_digest()).is_not_equal(baseline)
    arena.p1.abilities.rinat.smoke_clock = 0
    arena.p1.abilities.rinat.chant_timer = 2
    assert_str(NetSession.state_digest()).is_not_equal(baseline)
    arena.p1.abilities.rinat.chant_timer = 0
    arena.p2.abilities.rinat.bound_frames = 1
    assert_str(NetSession.state_digest()).is_not_equal(baseline)
    NetSession.arena = previous
