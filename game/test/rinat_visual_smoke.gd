extends SceneTree

var output := ""

func _initialize() -> void:
    call_deferred("_run")

func _arena(skin: String):
    var config = root.get_node("GameConfig")
    config.roster_enabled = true
    config.menu_open = false
    config.p1_character = "rinat"
    config.p2_character = "vladislav"
    config.p1_skin = skin
    config.p2_skin = "paquito"
    config.p2_is_cpu = false
    var arena = load("res://match/match.tscn").instantiate()
    root.add_child(arena)
    arena.match_state.phase = MatchState.FIGHT
    arena.match_state.phase_frame = 120
    arena.set_physics_process(false)
    for f in [arena.p1, arena.p2]:
        f.set_physics_process(false)
        f.frozen = false
    return arena

func _capture(arena, label: String) -> void:
    await create_timer(0.25).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output+"/"+label+".png")
    print("Captured ",label)

func _run() -> void:
    if not OS.get_cmdline_user_args().is_empty():
        output = OS.get_cmdline_user_args()[0]
    else:
        output = ProjectSettings.globalize_path("user://rinat-visual")
    DirAccess.make_dir_recursive_absolute(output)
    root.size = Vector2i(1152,648)
    var arena = _arena("default")
    await _capture(arena,"01-default-and-paquito")
    arena.p1.abilities.rinat.master_frames = 600
    arena.p1.abilities.rinat.shirt_torn = true
    arena.p1.abilities.rinat.chant_frames = 80
    await _capture(arena,"02-master")
    arena.p1.abilities.rinat.chant_frames = 0
    arena.p1.abilities.rinat.smoke_frames = 75
    await _capture(arena,"03-smoke")
    arena.p1.abilities.rinat.smoke_frames = 0
    arena.p1.abilities.rinat.master_frames = 0
    arena.p1.abilities.rinat.shirt_torn = false
    arena.p1.input.down = true
    arena.p1.just_pressed = ["hp"]
    arena.p1.try_start_attack("cr")
    arena.p1.state_machine.force_state("Attack")
    arena.p1.state_machine.current_state.state_frame = 12
    await _capture(arena,"04-uppercut")
    arena.queue_free()
    await process_frame
    arena = _arena("scorpion")
    arena.p1.abilities.pose_kind = "rinat_chain"
    arena.p1.abilities.pose_frames = 15
    arena.p2.abilities.rinat.bound_source = arena.p1
    arena.p2.abilities.rinat.bound_frames = 60
    await _capture(arena,"05-scorpion-chain")
    arena.p1.abilities.pose_frames = 0
    arena.p1.abilities.rinat.master_frames = 400
    arena.p1.abilities.rinat.shirt_torn = true
    await _capture(arena,"06-scorpion-master")
    arena.queue_free()
    await process_frame
    await process_frame
    quit()
