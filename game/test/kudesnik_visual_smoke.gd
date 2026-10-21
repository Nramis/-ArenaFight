extends SceneTree

var output := "/tmp/arena-visual"

func _initialize() -> void:
    call_deferred("_run")

func _arena(first: String, second: String, first_skin: String = "default", second_skin: String = "default"):
    var config = root.get_node("GameConfig")
    config.roster_enabled = true
    config.menu_open = false
    config.p1_character = first
    config.p2_character = second
    config.p1_skin = first_skin
    config.p2_skin = second_skin
    config.p2_is_cpu = false
    var arena = load("res://match/match.tscn").instantiate()
    root.add_child(arena)
    arena.match_state.phase = MatchState.FIGHT
    arena.match_state.phase_frame = 200
    arena.set_physics_process(false)
    for f in [arena.p1, arena.p2]:
        f.set_physics_process(false)
        f.frozen = false
    return arena

func _capture(label: String) -> void:
    await create_timer(0.3).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output + "/" + label + ".png")
    print("Captured ", label)

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(output)
    root.size = Vector2i(1152, 648)
    if "counter-shave" in OS.get_cmdline_user_args():
        var pair = _arena("mavrin", "polina")
        pair.p1.position.x = 130
        pair.p2.position.x = 185
        var extra = pair.p1.abilities.expansion
        extra.activate_hold()
        extra.hold_frames = 270
        extra.hold_counter_button = "mk"
        await _capture("counter-01-prompt")
        extra.attempt_counter("mk")
        for age in [12, 30, 55, 90]:
            extra.counter_frames = 96 - age
            await _capture("counter-%02d-pose" % age)
        pair.p1.position.x = 245
        pair.p1.facing_right = false
        pair.p2.position.x = 190
        extra.counter_frames = 66
        await _capture("counter-mirrored")
        pair.queue_free()
        await process_frame
        await process_frame
        var hero = _arena("ramis", "nikita")
        hero.p1.position.x = 115
        hero.p2.position.x = 265
        var shave = hero.p1.abilities.expansion
        shave.activate_auxiliary()
        for remaining in [110, 60, 10]:
            shave.shave_frames = remaining
            await _capture("shave-%03d" % remaining)
        shave.shave_frames = 1
        shave.tick()
        await _capture("shave-ready")
        shave.one_punch_ready = false
        shave.one_punch_victory = true
        hero.match_state.phase = MatchState.ROUND_END
        hero.p2.health = 0
        hero.p2.state_machine.force_state("Knockdown")
        for age in [10, 28, 60, 100]:
            hero.match_state.phase_frame = age
            await _capture("victory-%03d" % age)
        hero.match_state.last_winner = 1
        hero.match_state.p1_rounds = 2
        hero._start_finisher()
        hero.finisher.set_physics_process(false)
        hero.finisher.age = 110
        await _capture("victory-final-scene")
        hero.queue_free()
        await process_frame
        quit()
        return
    if "hold" in OS.get_cmdline_user_args():
        var hold_arena = _arena("mavrin", "polina")
        hold_arena.p1.position.x = 140
        hold_arena.p2.position.x = 195
        hold_arena.p1.abilities.expansion.activate_hold()
        for pair in [[370, "hold-01-start"], [320, "hold-02-lift"], [200, "hold-03-shake"], [20, "hold-04-lower"]]:
            hold_arena.p1.abilities.expansion.hold_frames = pair[0]
            await _capture(pair[1])
        hold_arena.p1.position.x = 245
        hold_arena.p1.facing_right = false
        hold_arena.p2.position.x = 190
        hold_arena.p1.abilities.expansion.hold_frames = 190
        await _capture("hold-05-mirrored")
        hold_arena.queue_free()
        await process_frame
        await process_frame
        quit()
        return
    var arena = _arena("nikita", "bigboss", "water_shinobi", "cheese_baron")
    arena.p1.position.x = 90
    arena.p2.position.x = 275
    arena.p2.abilities.expansion.activate_auxiliary()
    arena.p2.abilities.expansion.cheese_pose = 0
    await _capture("01-nikita-and-cheese")
    arena.p1.abilities.expansion.activate_auxiliary()
    arena.p1.abilities.expansion.water_frames = 64
    await _capture("02-hand-seals")
    arena.p1.abilities.expansion.water_frames = 48
    arena.p1.abilities.expansion._effect("water")
    await _capture("03-water-stream")
    arena.queue_free()
    await process_frame
    arena = _arena("mavrin", "polina", "disco_coach", "storm_witch")
    arena.p1.position.x = 140
    arena.p2.position.x = 195
    arena.p1.abilities.expansion.activate_hold()
    arena.p1.abilities.expansion.hold_frames = 260
    arena.p2.position.y = 145
    await _capture("04-polina-hold")
    arena.queue_free()
    await process_frame
    arena = _arena("rinat", "nikita", "ice_ninja", "default")
    arena.p1.abilities.rinat._catch_chain()
    await _capture("05-chain-bind")
    arena.p1.abilities.rinat.release_binding()
    arena.match_state.last_winner = 1
    arena.match_state.p1_rounds = 2
    arena.p2.health = 0
    arena._start_finisher()
    arena.finisher.set_physics_process(false)
    arena.finisher.age = 120
    await _capture("06-fatality")
    arena.queue_free()
    await process_frame
    quit()
