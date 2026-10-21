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
    arena.set_physics_process(false)
    for f: Fighter in [arena.p1, arena.p2]:
        f.frozen = false
        f.input_source = null
        f.set_physics_process(false)
        f.invuln_frames = 0
    arena.p1.position = Vector2(150, 180)
    arena.p2.position = Vector2(200, 180)
    return arena

func after_test() -> void:
    GameConfig.roster_enabled = false
    NetSession.arena = null

func _offer(arena: MatchManager, button: String = "mk") -> ExpansionAbilities:
    var extra := arena.p1.abilities.expansion
    extra.activate_hold()
    extra.hold_counter_button = button
    extra.hold_frames = ExpansionAbilities.HOLD_DURATION - 90
    return extra

func _attack(arena: MatchManager, special: bool = false) -> void:
    var move := MoveData.new()
    move.move_name = "TestPunch"
    move.damage = 40
    move.is_special = special
    move.hitbox_offset = Vector2(35, -60)
    move.hitbox_size = Vector2(100, 100)
    arena.p1.start_move(move)
    arena.p1.state_machine.force_state("Attack")
    arena.p1.state_machine.current_state.state_frame = move.startup

func test_each_hold_rolls_once_with_half_chance_and_varied_buttons() -> void:
    var arena := _arena("mavrin", "polina")
    seed(41809)
    var extra := arena.p1.abilities.expansion
    var offered := 0
    var seen := {}
    for i in 500:
        assert_bool(extra.activate_hold()).is_true()
        if not extra.hold_counter_button.is_empty():
            offered += 1
            seen[extra.hold_counter_button] = true
        extra.release_hold()
    assert_int(offered).is_between(200, 300)
    assert_int(seen.size()).is_equal(6)

func test_correct_counter_hits_once_at_contact_then_releases_both() -> void:
    var arena := _arena("mavrin", "polina")
    var extra := _offer(arena)
    assert_bool(extra.attempt_counter("mk")).is_true()
    assert_bool(extra.attempt_counter("mk")).is_false()
    for i in 29:
        extra.tick()
    assert_int(arena.p1.health).is_equal(1500)
    extra.tick()
    assert_int(arena.p1.health).is_equal(1200)
    for i in 66:
        extra.tick()
    assert_int(arena.p1.health).is_equal(1200)
    assert_int(arena.p2.health).is_equal(1500)
    assert_bool(extra.interaction_locked()).is_false()
    assert_bool(arena.p2.abilities.locked()).is_false()
    assert_bool(arena.p2.on_ground).is_true()

func test_wrong_button_uses_only_attempt_without_damage() -> void:
    var arena := _arena("mavrin", "polina")
    var extra := _offer(arena)
    assert_bool(extra.attempt_counter("lp")).is_false()
    assert_bool(extra.attempt_counter("mk")).is_false()
    assert_int(extra.counter_frames).is_equal(0)
    assert_int(arena.p1.health).is_equal(1500)

func test_counter_ignores_early_late_and_unoffered_input() -> void:
    var arena := _arena("mavrin", "polina")
    var extra := _offer(arena)
    extra.hold_frames = ExpansionAbilities.HOLD_DURATION - 59
    assert_bool(extra.attempt_counter("mk")).is_false()
    assert_bool(extra.hold_counter_used).is_false()
    extra.hold_frames = 60
    assert_bool(extra.attempt_counter("mk")).is_false()
    extra.hold_frames = 200
    extra.hold_counter_button = ""
    assert_bool(extra.attempt_counter("mk")).is_false()

func test_polina_input_edge_starts_counter_during_input_lock() -> void:
    var arena := _arena("mavrin", "polina")
    var extra := _offer(arena)
    arena.p2.just_pressed = ["mk"]
    arena.p2.abilities.expansion.tick()
    assert_int(extra.counter_frames).is_equal(96)
    assert_bool(extra.activate_hold()).is_false()

func test_counter_can_knock_out_without_damaging_or_stranding_polina() -> void:
    var arena := _arena("mavrin", "polina")
    var extra := _offer(arena)
    arena.p1.health = 200
    extra.attempt_counter("mk")
    for i in 30:
        extra.tick()
    assert_int(arena.p1.health).is_equal(0)
    assert_int(arena.p2.health).is_equal(1500)
    assert_bool(arena.p2.abilities.locked()).is_false()
    assert_bool(arena.p2.on_ground).is_true()

func test_shaving_requires_two_seconds_and_starts_ten_second_cooldown() -> void:
    var arena := _arena("ramis")
    var extra := arena.p1.abilities.expansion
    assert_bool(extra.activate_auxiliary()).is_true()
    assert_int(extra.auxiliary_cd).is_equal(600)
    assert_bool(extra.locked()).is_true()
    for i in 119:
        extra.tick()
    assert_bool(extra.one_punch_ready).is_false()
    extra.tick()
    assert_bool(extra.one_punch_ready).is_true()
    assert_bool(extra.bald).is_true()
    assert_bool(extra.locked()).is_false()
    assert_int(extra.auxiliary_cd).is_equal(480)
    assert_bool(extra.activate_auxiliary()).is_false()

func test_clean_hit_interrupts_shave_and_keeps_cooldown() -> void:
    var arena := _arena("ramis")
    var extra := arena.p1.abilities.expansion
    extra.activate_auxiliary()
    for i in 45:
        extra.tick()
    var hit := MoveData.new()
    hit.damage = 60
    arena.p1.receive_hit(hit, -1)
    assert_int(extra.shave_frames).is_equal(0)
    assert_int(extra.auxiliary_cd).is_equal(555)
    assert_bool(extra.bald).is_false()
    for i in 120:
        extra.tick()
    assert_bool(extra.one_punch_ready).is_false()
    assert_int(arena.p1.health).is_equal(1440)

func test_freeze_also_interrupts_shaving() -> void:
    var arena := _arena("ramis")
    var extra := arena.p1.abilities.expansion
    extra.activate_auxiliary()
    arena.p1.abilities.freeze()
    assert_int(extra.shave_frames).is_equal(0)
    assert_bool(extra.one_punch_ready).is_false()

func test_empowered_melee_knocks_out_guarding_full_health_target() -> void:
    var arena := _arena("ramis")
    var extra := arena.p1.abilities.expansion
    extra.bald = true
    extra.one_punch_ready = true
    arena.p2.input.right = true
    _attack(arena)
    assert_bool(arena.p2.is_blocking(arena.p1.current_move)).is_true()
    assert_bool(Combat.resolve(arena.p1, arena.p2)).is_false()
    assert_int(arena.p2.health).is_equal(1500)
    for i in RamisUltimate.IMPACT:
        extra.hero.tick()
    assert_int(arena.p2.health).is_equal(0)
    assert_bool(extra.one_punch_ready).is_false()
    assert_bool(extra.bald).is_true()
    assert_bool(extra.one_punch_victory).is_true()
    assert_bool(Combat.resolve(arena.p1, arena.p2)).is_false()

func test_whiff_does_not_spend_empowerment() -> void:
    var arena := _arena("ramis")
    arena.p1.abilities.expansion.one_punch_ready = true
    arena.p2.position.x = 340
    _attack(arena)
    assert_bool(Combat.resolve(arena.p1, arena.p2)).is_false()
    assert_bool(arena.p1.abilities.expansion.one_punch_ready).is_true()

func test_special_melee_preserves_empowerment() -> void:
    var arena := _arena("ramis")
    arena.p1.abilities.expansion.one_punch_ready = true
    _attack(arena, true)
    assert_bool(Combat.resolve(arena.p1, arena.p2)).is_true()
    assert_int(arena.p2.health).is_equal(1460)
    assert_bool(arena.p1.abilities.expansion.one_punch_ready).is_true()

func test_hit_after_completed_shave_preserves_baldness_and_charge() -> void:
    var arena := _arena("ramis")
    var extra := arena.p1.abilities.expansion
    extra.bald = true
    extra.one_punch_ready = true
    arena.p1.receive_hit(MoveData.new(), -1)
    assert_bool(extra.one_punch_ready).is_true()
    assert_bool(extra.bald).is_true()

func test_round_reset_clears_new_state_and_counter_links() -> void:
    var arena := _arena("mavrin", "polina")
    var extra := _offer(arena)
    extra.attempt_counter("mk")
    extra.bald = true
    extra.one_punch_ready = true
    extra.shave_frames = 50
    arena.p1.reset_for_round(Vector2(100, 180), true)
    assert_int(extra.counter_frames).is_equal(0)
    assert_int(extra.shave_frames).is_equal(0)
    assert_bool(extra.bald).is_false()
    assert_bool(extra.one_punch_ready).is_false()
    assert_bool(arena.p2.abilities.locked()).is_false()

func test_new_state_changes_lockstep_digest() -> void:
    var arena := _arena("ramis")
    NetSession.arena = arena
    var before := NetSession.state_digest()
    arena.p1.abilities.expansion.bald = true
    assert_str(NetSession.state_digest()).is_not_equal(before)
    before = NetSession.state_digest()
    arena.p1.abilities.expansion.one_punch_ready = true
    assert_str(NetSession.state_digest()).is_not_equal(before)

func test_one_punch_victory_gets_time_to_turn_to_camera_and_its_own_final_scene() -> void:
    var arena := _arena("ramis")
    var extra := arena.p1.abilities.expansion
    extra.bald = true
    extra.one_punch_ready = true
    _attack(arena)
    Combat.resolve(arena.p1, arena.p2)
    for i in RamisUltimate.TOTAL:
        extra.hero.tick()
    arena.match_state.last_winner = 1
    arena.match_state.p1_rounds = 1
    arena._start_finisher()
    assert_object(arena.finisher).is_null()
    assert_int(arena.match_state.round_end_duration).is_equal(150)
    arena.match_state.p1_rounds = 2
    arena._start_finisher()
    assert_object(arena.finisher).is_null()
    assert_bool(extra.hero.crater_active).is_true()
