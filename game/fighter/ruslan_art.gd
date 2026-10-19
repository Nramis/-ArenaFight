extends Node2D

const ATLASES = [preload("res://assets/ruslan/prosperous.png"), preload("res://assets/ruslan/struggling.png"), preload("res://assets/ruslan/bankrupt.png")]
var fighter: Fighter
var clock := 0.0
var gait := 0.0
var lean := 0.0
var atlas_frames: Array = []

func _ready() -> void:
    fighter = get_parent().get_parent()
    for tier in ["prosperous", "struggling", "bankrupt"]:
        var data: Dictionary = RuslanAtlas.DATA[tier]
        var cell := Vector2(data.cell[0], data.cell[1])
        var anchor := Vector2(data.anchor[0], data.anchor[1])
        var frames: Array = []
        var texture_size := Vector2(ATLASES[atlas_frames.size()].get_size())
        for pose in 48:
            var points := PackedVector2Array()
            var uv := PackedVector2Array()
            var origin := Vector2(pose % 8, int(pose / 8)) * cell
            for pair in data.frames[pose].outline:
                var pixel := Vector2(pair[0], pair[1])
                points.append((pixel - anchor) * float(data.scale))
                uv.append((origin + pixel) / texture_size)
            frames.append({"points": points, "uv": uv})
        atlas_frames.append(frames)

func _process(delta: float) -> void:
    if fighter.abilities == null:
        return
    if not fighter.frozen and not fighter.abilities.conversation_locked() and fighter.hitstop_frames == 0:
        clock += delta
        gait += absf(fighter.vel.x) * delta / 13.0
    queue_redraw()

func _draw() -> void:
    if fighter == null or fighter.abilities == null or fighter.state_machine.current_state == null:
        return
    var state := str(fighter.state_machine.current_state.name)
    var ability := fighter.abilities.ruslan
    var pose := posmod(int(clock * 10), 8)
    var bob := sin(clock * 3.2) * 0.4
    var rotation_amount := 0.0
    var stretch := Vector2.ONE
    if state in ["Walk", "Dash"]:
        pose = 8 + posmod(int(gait), 8)
        bob = -absf(sin(gait * PI / 4)) * 1.1
        rotation_amount = (0.10 if state == "Dash" else 0.025) * signf(fighter.vel.x * fighter.facing())
    elif state in ["Jump", "JumpStartup"]:
        pose = 34
        stretch = Vector2(0.98, 1.02)
    elif state == "Crouch":
        pose = 32
    elif state == "Blockstun":
        pose = 32 if fighter.input.down else 33
        rotation_amount = -0.04
    elif state == "Attack" and fighter.current_move != null:
        var move := fighter.current_move
        var button := move.move_name.to_lower().get_slice(".", 1)
        var buttons := ["lp", "mp", "hp", "lk", "mk", "hk"]
        var index := buttons.find(button)
        var frame := fighter.state_machine.current_state.state_frame
        var active := frame >= move.startup and frame < move.startup + move.active
        if index >= 0:
            var base := (16 + index * 2) if index < 3 else (24 + (index - 3) * 2)
            if button == "hp" and ability.combo_style == "КОЛЛЕКТОР":
                base = 22
            elif move.move_name.begins_with("cr.") and button == "hk":
                base = 30
            pose = base + (1 if active else 0)
            if frame > move.startup + move.active:
                pose = base if frame < move.total() - 4 else 0
            rotation_amount = 0.035 if active else -0.025
            if fighter.is_crouching_pose():
                stretch.y = 0.78
        else:
            pose = 35 if not fighter.on_ground else 23
    if ability.pilaf_frames > 0:
        pose = 40 if ability.pilaf_frames > 24 else 41 + posmod(int(ability.pilaf_frames / 4), 2)
    elif fighter.abilities.pose_frames > 0 and fighter.abilities.pose_kind == "pilaf":
        pose = 43
    elif ability.dice_frames > 0:
        pose = 44 if ability.dice_frames > 22 else 45
    elif ability.rain_frames > 138:
        pose = 46
    elif ability.dark_cast > 0:
        pose = 47
    if state in ["Hitstun", "Thrown", "Knockdown"] or fighter.health <= 0:
        pose = 36 if state == "Hitstun" else 37
        rotation_amount = -0.16 if state == "Hitstun" else -0.9
        if fighter.health <= 0:
            stretch = Vector2(1, 0.84)
    elif fighter.frozen and fighter.opponent != null and fighter.opponent.health <= 0:
        pose = 39
    elif state == "Idle" and ability.wealth_tier() == 2 and posmod(int(clock), 7) == 0:
        pose = 38
    var tint := Color.WHITE
    if ability.dark_cast > 0 and ability.dark_cast <= 18:
        tint = Color(0.015, 0.015, 0.025)
    elif state == "Hitstun":
        tint = Color(1, 0.65, 0.56)
    elif fighter.abilities.freeze_frames > 0:
        tint = Color(0.4, 0.95, 0.6)
    if fighter.invuln_frames > 0:
        tint.a = 0.72 + sin(clock * 30) * 0.2
    var growth := fighter.abilities.size_multiplier()
    draw_set_transform(Vector2(0, maxf(0, fighter.ground_y - fighter.position.y)), 0, Vector2(1, 0.22))
    draw_circle(Vector2.ZERO, 22 * growth, Color(0, 0, 0, 0.25))
    draw_set_transform(Vector2(0, bob), rotation_amount * fighter.facing(), Vector2(fighter.facing() * growth, growth) * stretch)
    var texture: Texture2D = ATLASES[ability.wealth_tier()]
    var frame: Dictionary = atlas_frames[ability.wealth_tier()][pose]
    draw_colored_polygon(frame.points, tint, frame.uv, texture)
    draw_set_transform(Vector2.ZERO)
