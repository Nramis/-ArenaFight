extends GdUnitTestSuite

const MATCH = preload("res://match/match.tscn")

func _arena() -> MatchManager:
    GameConfig.roster_enabled = true
    GameConfig.p1_character = "yusup"
    GameConfig.p2_character = "nikita"
    GameConfig.p2_is_cpu = false
    GameConfig.menu_open = false
    var arena: MatchManager = MATCH.instantiate()
    add_child(arena)
    auto_free(arena)
    arena.match_state.phase = MatchState.FIGHT
    return arena

func after_test() -> void:
    GameConfig.roster_enabled = false
    for action in ["p1_right", "p2_left", "p1_special1", "p1_special2", "p1_special3"]:
        Input.action_release(action)

func test_yusup_is_selectable_and_has_three_cooldowns() -> void:
    var arena := _arena()
    assert_str(arena.p1.roster_name()).is_equal("yusup")
    assert_str(Roster.NAMES["yusup"]).is_equal("ЮСУП")
    assert_int(Roster.COOLDOWNS["yusup"].size()).is_equal(3)

func test_story_freezes_both_players_then_depletes_stamina_for_exactly_two_seconds() -> void:
    var arena := _arena()
    var owner := arena.p1
    var target := arena.p2
    assert_bool(owner.abilities.activate(0)).is_true()
    var owner_position := owner.position
    var target_position := target.position
    var round_time := arena.match_state.timer
    Input.action_press("p1_right")
    Input.action_press("p2_left")
    for frame in YusupAbilities.STORY_DURATION:
        assert_bool(owner.abilities.conversation_locked()).is_true()
        assert_bool(target.abilities.conversation_locked()).is_true()
        owner._physics_process(1.0 / 60.0)
        target._physics_process(1.0 / 60.0)
        if frame == 0:
            assert_str(owner.abilities.yusup.speech()).is_equal("там короче...")
        if frame == YusupAbilities.INTRO_FRAMES:
            assert_str(owner.abilities.yusup.speech()).is_equal("а забей")
        arena._physics_process(1.0 / 60.0)
    assert_vector(owner.position).is_equal(owner_position)
    assert_vector(target.position).is_equal(target_position)
    assert_int(arena.match_state.timer).is_equal(round_time)
    assert_bool(owner.abilities.conversation_locked()).is_false()
    assert_bool(target.abilities.conversation_locked()).is_false()
    assert_float(target.rhythm.stamina).is_equal(0.0)
    assert_int(target.rhythm.depleted_frames).is_equal(120)
    for frame in 120:
        target.rhythm.tick()
        assert_float(target.rhythm.stamina).is_equal(0.0)
    target.rhythm.tick()
    assert_float(target.rhythm.stamina).is_greater(0.0)

func test_cancelled_story_releases_opponent_without_depleting_stamina() -> void:
    var arena := _arena()
    arena.p1.abilities.activate(0)
    arena.p1.abilities.interrupt_cast()
    assert_bool(arena.p2.abilities.conversation_locked()).is_false()
    assert_float(arena.p2.rhythm.stamina).is_equal(100.0)

func test_remote_starts_three_seconds_of_heat_and_burning_after_its_windup() -> void:
    var arena := _arena()
    arena.p1.abilities.activate(1)
    for frame in 23:
        arena.p1.abilities.tick()
    assert_int(arena.p2.abilities.burn_frames).is_equal(0)
    arena.p1.abilities.tick()
    assert_int(arena.p1.abilities.yusup.heat_frames).is_equal(180)
    assert_int(arena.p2.abilities.burn_frames).is_equal(180)
    for frame in 180:
        arena.p2.abilities.tick()
        arena.p1.abilities.tick()
    assert_int(arena.p2.health).is_equal(arena.p2.max_health - 90)
    assert_int(arena.p2.abilities.burn_frames).is_equal(0)
    assert_int(arena.p1.abilities.yusup.heat_frames).is_equal(0)

func test_hitting_the_remote_windup_prevents_heat() -> void:
    var arena := _arena()
    arena.p1.abilities.activate(1)
    arena.p1.receive_hit(MoveData.new(), -1)
    for frame in 40:
        arena.p1.abilities.tick()
    assert_int(arena.p2.abilities.burn_frames).is_equal(0)
    assert_int(arena.p1.abilities.yusup.heat_frames).is_equal(0)

func test_swimmer_requires_contact_and_limits_repeated_hits() -> void:
    var arena := _arena()
    arena.p1.abilities.activate(2)
    arena.p1.abilities.tick()
    assert_int(arena.p2.health).is_equal(arena.p2.max_health)
    arena.p2.position.x = arena.p1.position.x + 50
    arena.p1.abilities.tick()
    var health_after_contact := arena.p2.health
    assert_int(health_after_contact).is_less(arena.p2.max_health)
    for frame in 17:
        arena.p1.abilities.tick()
    assert_int(arena.p2.health).is_equal(health_after_contact)
    arena.p1.abilities.tick()
    assert_int(arena.p2.health).is_less(health_after_contact)

func test_swimmer_expires_after_five_seconds_and_can_move_during_transformation() -> void:
    var arena := _arena()
    arena.p1.abilities.activate(2)
    assert_bool(arena.p1.abilities.locked()).is_false()
    assert_bool(arena.p1.abilities.activate(0)).is_false()
    for frame in 299:
        arena.p1.abilities.tick()
    assert_int(arena.p1.abilities.yusup.swim_frames).is_equal(1)
    arena.p1.abilities.tick()
    assert_int(arena.p1.abilities.yusup.swim_frames).is_equal(0)

func test_round_reset_clears_conversation_heat_swimsuit_and_exhaustion() -> void:
    var arena := _arena()
    arena.p1.abilities.activate(0)
    arena.p1.abilities.yusup.heat_frames = 180
    arena.p1.abilities.yusup.swim_frames = 300
    arena.p2.rhythm.deplete(120)
    arena._reset_round()
    assert_bool(arena.p2.abilities.conversation_locked()).is_false()
    assert_int(arena.p1.abilities.yusup.story_frames).is_equal(0)
    assert_int(arena.p1.abilities.yusup.heat_frames).is_equal(0)
    assert_int(arena.p1.abilities.yusup.swim_frames).is_equal(0)
    assert_int(arena.p2.rhythm.depleted_frames).is_equal(0)
    assert_float(arena.p2.rhythm.stamina).is_equal(100.0)

func test_sync_digest_includes_yusup_timers_and_stamina_lock() -> void:
    var arena := _arena()
    var previous := NetSession.arena
    NetSession.arena = arena
    var baseline := NetSession.state_digest()
    arena.p1.abilities.yusup.swim_hit_timer = 9
    assert_str(NetSession.state_digest()).is_not_equal(baseline)
    arena.p1.abilities.yusup.swim_hit_timer = 0
    arena.p2.rhythm.deplete(120)
    assert_str(NetSession.state_digest()).is_not_equal(baseline)
    NetSession.arena = previous
