extends GdUnitTestSuite

const MATCH = preload("res://match/match.tscn")

func _arena() -> MatchManager:
    GameConfig.roster_enabled = true
    GameConfig.p1_character = "ruslan"
    GameConfig.p2_character = "nikita"
    GameConfig.p2_is_cpu = false
    GameConfig.menu_open = false
    var arena: MatchManager = MATCH.instantiate()
    add_child(arena)
    auto_free(arena)
    arena.match_state.phase = MatchState.FIGHT
    arena.p1.frozen = false
    arena.p2.frozen = false
    return arena

func after_test() -> void:
    GameConfig.roster_enabled = false

func test_clothes_follow_health_and_healing_can_restore_them() -> void:
    var arena := _arena()
    var action := arena.p1.abilities.ruslan
    assert_int(action.wealth_tier()).is_equal(0)
    arena.p1.health = 900
    assert_int(action.wealth_tier()).is_equal(1)
    arena.p1.health = 450
    assert_int(action.wealth_tier()).is_equal(2)
    arena.p1.health = 1100
    assert_int(action.wealth_tier()).is_equal(0)

func test_three_clean_normals_heal_once_and_start_a_new_payout_next_combo() -> void:
    var arena := _arena()
    arena.p1.health = 900
    for key in ["st.lp", "st.mp", "st.hp"]:
        arena.p2.receive_hit(arena.p1.moves[key], 1)
    var healed := arena.p1.health
    assert_int(healed).is_greater(900)
    assert_int(arena.p1.abilities.ruslan.last_heal).is_less_equal(90)
    arena.p2.state_machine.force_state("Hitstun")
    arena.p2.receive_hit(arena.p1.moves["st.mk"], 1)
    assert_int(arena.p1.health).is_equal(healed)
    arena.p2.state_machine.force_state("Idle")
    for key in ["st.lp", "st.mp", "st.hp"]:
        arena.p2.receive_hit(arena.p1.moves[key], 1)
    assert_int(arena.p1.health).is_greater(healed)

func test_blocks_and_ability_damage_do_not_fund_lifesteal() -> void:
    var arena := _arena()
    arena.p1.health = 900
    for key in ["st.lp", "st.mp", "st.hp"]:
        arena.p2.receive_block(arena.p1.moves[key], 1)
    assert_int(arena.p1.health).is_equal(900)
    var rain := MoveData.new()
    rain.move_name = "RuslanMoneyRain"
    for i in 5:
        arena.p2.receive_hit(rain, 1)
    assert_int(arena.p1.health).is_equal(900)

func test_combo_history_changes_punch_kick_and_mixed_finishers() -> void:
    var arena := _arena()
    var action := arena.p1.abilities.ruslan
    for key in ["st.lp", "st.mp"]:
        arena.p2.receive_hit(arena.p1.moves[key], 1)
    var punch: MoveData = arena.p1.moves["st.hp"].duplicate()
    action.prepare_normal(punch)
    assert_str(action.combo_style).is_equal("КОЛЛЕКТОР")
    assert_int(punch.damage).is_greater(arena.p1.moves["st.hp"].damage)
    action.sequence = ["lk", "mk"]
    var kick: MoveData = arena.p1.moves["st.hk"].duplicate()
    action.prepare_normal(kick)
    assert_str(action.combo_style).is_equal("ПЕНАЛЬТИ")
    assert_float(kick.pushback).is_greater(arena.p1.moves["st.hk"].pushback)
    action.sequence = ["lp", "mk"]
    var mixed: MoveData = arena.p1.moves["st.hp"].duplicate()
    action.prepare_normal(mixed)
    assert_str(action.combo_style).is_equal("РЕФИНАНСИРОВАНИЕ")
    assert_int(mixed.hitstun).is_greater(arena.p1.moves["st.hp"].hitstun)

func test_blackout_has_windup_and_exactly_240_active_frames() -> void:
    var arena := _arena()
    var action := arena.p1.abilities.ruslan
    assert_bool(arena.p1.abilities.activate(1)).is_true()
    for frame in 35:
        arena.p1.abilities.tick()
    assert_int(action.dark_frames).is_equal(0)
    arena.p1.abilities.tick()
    assert_int(action.dark_frames).is_equal(240)
    for frame in 239:
        arena.p1.abilities.tick()
    assert_int(action.dark_frames).is_equal(1)
    arena.p1.abilities.tick()
    assert_int(action.dark_frames).is_equal(0)

func test_interrupting_startup_prevents_blackout_pilaf_and_dice() -> void:
    var arena := _arena()
    for slot in 3:
        arena.p1.reset_for_round(Vector2(130, 180), true)
        arena.p1.abilities.activate(slot)
        arena.p1.receive_hit(arena.p2.moves["st.lp"], -1)
        var health_after_hit := arena.p1.health
        for frame in 70:
            arena.p1.abilities.tick()
        assert_int(arena.p1.abilities.ruslan.dark_frames).is_equal(0)
        assert_array(arena.p1.abilities.ruslan.shots).is_empty()
        assert_int(arena.p1.abilities.ruslan.rain_frames).is_equal(0)
        assert_int(arena.p1.health).is_equal(health_after_hit)

func test_all_36_dice_outcomes_have_six_wins_and_thirty_losses() -> void:
    var arena := _arena()
    var action := arena.p1.abilities.ruslan
    var wins := 0
    for first in range(1, 7):
        for second in range(1, 7):
            action.reset()
            arena.p1.health = arena.p1.max_health
            action.dice_a = first
            action.dice_b = second
            action.resolve_dice()
            if first == second:
                wins += 1
                assert_int(action.rain_frames).is_equal(168)
                assert_int(arena.p1.health).is_equal(arena.p1.max_health)
            else:
                assert_int(action.rain_frames).is_equal(0)
                assert_int(arena.p1.health).is_equal(arena.p1.max_health - 150)
    assert_int(wins).is_equal(6)

func test_losing_dice_can_knock_out_owner() -> void:
    var arena := _arena()
    arena.p1.health = 100
    var action := arena.p1.abilities.ruslan
    action.dice_a = 1
    action.dice_b = 2
    action.resolve_dice()
    assert_int(arena.p1.health).is_equal(0)

func test_pilaf_requires_windup_travels_and_can_miss() -> void:
    var arena := _arena()
    var action := arena.p1.abilities.ruslan
    arena.p1.abilities.activate(0)
    for frame in 29:
        arena.p1.abilities.tick()
    assert_array(action.shots).is_empty()
    arena.p1.abilities.tick()
    assert_int(action.shots.size()).is_equal(3)
    for frame in 110:
        arena.p1.abilities.tick()
    assert_int(arena.p2.health).is_less(arena.p2.max_health)
    assert_array(action.shots).is_empty()

func test_damage_drops_coins_and_round_reset_clears_finance_state() -> void:
    var arena := _arena()
    arena.p1.receive_hit(arena.p2.moves["st.mp"], -1)
    var action := arena.p1.abilities.ruslan
    assert_array(action.coins).is_not_empty()
    action.dark_frames = 200
    action.rain_frames = 168
    action.dice_a = 5
    action.sequence = ["lp", "mp"]
    arena._reset_round()
    assert_int(action.dark_frames).is_equal(0)
    assert_int(action.rain_frames).is_equal(0)
    assert_int(action.dice_a).is_equal(0)
    assert_array(action.coins).is_empty()
    assert_array(action.sequence).is_empty()
    assert_int(action.wealth_tier()).is_equal(0)

func test_finance_simulation_is_in_network_digest() -> void:
    var arena := _arena()
    NetSession.arena = arena
    var before := NetSession.state_digest()
    arena.p1.abilities.ruslan.dark_frames = 240
    assert_str(NetSession.state_digest()).is_not_equal(before)
    NetSession.arena = null
