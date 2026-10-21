extends SceneTree

var output := "/tmp/arena-hero-visual"

func _initialize() -> void:
    call_deferred("_run")

func _arena(second: bool = false):
    var config = root.get_node("GameConfig")
    config.roster_enabled = true
    config.menu_open = false
    config.p1_character = "polina" if second else "ramis"
    config.p2_character = "ramis" if second else "polina"
    config.p1_skin = "default"
    config.p2_skin = "default"
    config.p2_is_cpu = false
    var arena = load("res://match/match.tscn").instantiate()
    root.add_child(arena)
    arena.match_state.phase = MatchState.FIGHT
    arena.match_state.phase_frame = 200
    arena.set_physics_process(false)
    for f in [arena.p1,arena.p2]:
        f.set_physics_process(false)
        f.frozen = false
        f.input_source = null
    arena.p1.position.x = 125
    arena.p2.position.x = 245
    return arena

func _capture(label: String) -> void:
    await create_timer(.25).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output+"/"+label+".png")
    print("Captured ",label)

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(output)
    root.size = Vector2i(1152,648)
    var arena = _arena()
    var extra = arena.p1.abilities.expansion
    extra.activate_auxiliary()
    for remaining in [80,45,27,9]:
        extra.shave_frames = remaining
        await _capture("transform-%02d"%remaining)
    extra.shave_frames = 1
    extra.tick()
    await _capture("hero-ready")
    var hero = extra.hero
    hero.begin(arena.p2)
    for age in [18,54,84,105,114,124,140,180,204]:
        while hero.age < age:
            hero.tick()
        await _capture("ultimate-%03d"%age)
    arena._physics_process(1.0/60)
    await _capture("victory-crater")
    arena._reset_round()
    arena.match_state.phase = MatchState.FIGHT
    arena.match_state.phase_frame = 200
    for f in [arena.p1,arena.p2]:
        f.frozen = false
    await _capture("reset-clean-ground")
    arena.queue_free()
    await process_frame
    await process_frame
    arena = _arena(true)
    var mirrored = arena.p2.abilities.expansion.hero
    mirrored.begin(arena.p1)
    for age in [80,130,204]:
        while mirrored.age < age:
            mirrored.tick()
        await _capture("mirrored-%03d"%age)
    arena.queue_free()
    await process_frame
    quit()
