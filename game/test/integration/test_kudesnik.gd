extends GdUnitTestSuite

const MATCH = preload("res://match/match.tscn")

func _arena(first: String, second: String = "nikita") -> MatchManager:
    GameConfig.roster_enabled = true
    GameConfig.p1_character = first
    GameConfig.p2_character = second
    GameConfig.p1_skin = "default"
    GameConfig.p2_skin = "default"
    GameConfig.p2_is_cpu = false
    GameConfig.menu_open = false
    var arena: MatchManager = MATCH.instantiate()
    add_child(arena)
    auto_free(arena)
    arena.match_state.phase = MatchState.FIGHT
    for f: Fighter in [arena.p1, arena.p2]:
        f.frozen = false
        f.input_source = null
        f.set_physics_process(false)
        f.invuln_frames = 0
    arena.set_physics_process(false)
    return arena

func after_test() -> void:
    GameConfig.roster_enabled = false
    GameConfig.p1_skin = "default"
    GameConfig.p2_skin = "default"

func test_water_cast_has_exact_fifteen_second_cooldown_and_can_be_interrupted() -> void:
    var arena := _arena("nikita")
    var extra := arena.p1.abilities.expansion
    assert_bool(extra.activate_auxiliary()).is_true()
    assert_int(extra.auxiliary_cd).is_equal(900)
    assert_bool(extra.activate_auxiliary()).is_false()
    for i in 15:
        arena.p1.abilities.tick()
    var move := MoveData.new()
    move.damage = 35
    arena.p1.receive_hit(move, -1)
    assert_int(extra.water_frames).is_equal(0)
    assert_int(extra.auxiliary_cd).is_equal(885)

func test_water_stream_hits_once_and_respects_block() -> void:
    var arena := _arena("nikita", "rafael")
    arena.p1.position = Vector2(70, 180)
    arena.p2.position = Vector2(250, 180)
    arena.p1.abilities.expansion.activate_auxiliary()
    for i in ExpansionAbilities.WATER_WINDUP:
        arena.p1.abilities.tick()
    var effect: ExpansionEffect
    for node in get_tree().get_nodes_in_group("ability_effect"):
        if node is ExpansionEffect and node.attacker == arena.p1:
            effect = node
    assert_object(effect).is_not_null()
    effect.set_physics_process(false)
    for i in 10:
        effect._physics_process(1.0 / 60)
    assert_int(arena.p2.health).is_equal(1320)
    arena.p2.reset_for_round(Vector2(250, 180), false)
    arena.p2.frozen = false
    arena.p2.input.right = true
    effect.struck = false
    effect._physics_process(1.0 / 60)
    assert_bool(arena.p2.last_hit_blocked).is_true()
    assert_int(arena.p2.health).is_equal(1473)

func test_cheese_ammunition_survives_toggling_and_normals_stay_disabled() -> void:
    var arena := _arena("bigboss")
    var extra := arena.p1.abilities.expansion
    assert_bool(extra.activate_auxiliary()).is_true()
    assert_bool(extra.throw_cheese()).is_true()
    assert_int(extra.cheese_remaining).is_equal(11)
    arena.p1.just_pressed = ["hp"]
    assert_bool(arena.p1.try_start_attack("st")).is_false()
    assert_bool(arena.p1.abilities.activate(1)).is_false()
    assert_bool(extra.activate_auxiliary()).is_true()
    assert_bool(extra.cheese_mode).is_false()
    assert_bool(extra.activate_auxiliary()).is_true()
    assert_int(extra.cheese_remaining).is_equal(11)
    for i in 11:
        extra.cheese_recovery = 0
        assert_bool(extra.throw_cheese()).is_true()
    assert_int(extra.cheese_remaining).is_equal(0)
    assert_bool(extra.throw_cheese()).is_false()
    assert_bool(extra.activate_auxiliary()).is_true()
    assert_bool(extra.activate_auxiliary()).is_false()
    arena.p1.reset_for_round(Vector2(100, 180), true)
    assert_int(extra.cheese_remaining).is_equal(12)
    assert_bool(extra.cheese_used).is_false()

func test_polina_hold_does_no_damage_and_has_no_cooldown() -> void:
    var arena := _arena("mavrin", "polina")
    arena.p1.position.x = 150
    arena.p2.position.x = 205
    var extra := arena.p1.abilities.expansion
    assert_bool(extra.activate_hold()).is_true()
    for i in ExpansionAbilities.HOLD_DURATION:
        extra.tick()
        arena.p2.abilities.expansion.tick()
    assert_int(arena.p1.health).is_equal(1500)
    assert_int(arena.p2.health).is_equal(1500)
    assert_bool(extra.interaction_locked()).is_false()
    assert_bool(extra.activate_hold()).is_true()
    extra.reset()
    assert_bool(arena.p2.abilities.expansion.interaction_locked()).is_false()

func test_hold_is_available_only_to_mavrin_against_polina_in_range() -> void:
    var arena := _arena("mavrin", "rinat")
    assert_bool(arena.p1.abilities.expansion.activate_hold()).is_false()
    arena.p2.roster_id = "polina"
    arena.p2.position.x = 340
    assert_bool(arena.p1.abilities.expansion.activate_hold()).is_false()

func test_chain_stuns_without_automatic_pull_and_attack_pulls_for_two_seconds() -> void:
    var arena := _arena("rinat")
    arena.p1.position.x = 70
    arena.p2.position.x = 285
    arena.p1.abilities.rinat._catch_chain()
    assert_int(arena.p2.abilities.rinat.bound_frames).is_equal(120)
    arena.p2.abilities.tick()
    assert_float(arena.p2.position.x).is_equal(285.0)
    arena.p1.input.lp = true
    for i in 119:
        arena.p1.abilities.tick()
        arena.p2.abilities.tick()
    assert_float(arena.p2.position.x).is_equal(118.0)
    assert_bool(arena.p2.abilities.locked()).is_false()

func test_auxiliary_and_inventory_state_affect_network_digest() -> void:
    var arena := _arena("bigboss")
    NetSession.arena = arena
    var before := NetSession.state_digest()
    arena.p1.abilities.expansion.cheese_remaining -= 1
    assert_str(NetSession.state_digest()).is_not_equal(before)
    NetSession.arena = null

func test_unique_finisher_only_starts_after_decisive_knockout() -> void:
    var arena := _arena("nikita")
    arena.match_state.last_winner = 1
    arena.match_state.p1_rounds = 1
    arena.p2.health = 0
    arena._start_finisher()
    assert_object(arena.finisher).is_null()
    arena.match_state.p1_rounds = 2
    arena._start_finisher()
    assert_object(arena.finisher).is_not_null()
    assert_int(arena.match_state.round_end_duration).is_greater(240)
    assert_int(FinisherScene.TITLES.size()).is_equal(Roster.IDS.size())

func test_all_eleven_ket_assists_have_a_single_distinct_strike() -> void:
    var arena := _arena("mavrin", "nikita")
    assert_int(ExpansionEffect.ASSIST_NAMES.size()).is_equal(Roster.IDS.size())
    for variant in Roster.IDS.size():
        arena.p2.reset_for_round(Vector2(230, 180), false)
        arena.p2.frozen = false
        arena.p1.abilities.expansion._effect("assist", variant)
        var helper: ExpansionEffect
        for node in get_tree().get_nodes_in_group("ability_effect"):
            if node is ExpansionEffect and node.variant == variant and node.age == 0:
                helper = node
        assert_object(helper).is_not_null()
        helper.set_physics_process(false)
        for frame in 65:
            helper._physics_process(1.0 / 60)
        assert_bool(helper.struck).is_true()
        assert_int(arena.p2.health).is_less(1500)
        assert_int(arena.p2.health).is_greater(1200)
        helper.queue_free()

func test_projectiles_pause_after_knockout_during_finisher() -> void:
    var arena := _arena("nikita", "rafael")
    var projectile = load("res://projectile/projectile.tscn").instantiate()
    projectile.team = arena.p1.team
    projectile.owner_facing = 1
    projectile.move = MoveData.new()
    projectile.move.damage = 100
    projectile.velocity_x = 180
    arena.add_child(projectile)
    projectile.position = arena.p2.hurtbox_rect().get_center()
    var start: Vector2 = projectile.position
    arena.p1.frozen = true
    arena.p2.frozen = true
    arena._process_projectiles(1.0 / 60)
    assert_int(arena.p2.health).is_equal(1500)
    assert_vector(projectile.position).is_equal(start)
