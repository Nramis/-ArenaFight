extends Node2D

var f: Fighter
var banks: Dictionary = {}
var regions: Dictionary = {}
var clock := 0.0
var distance := 0.0
var previous_x := 0.0

func _ready() -> void:
    f = get_parent().get_parent()
    previous_x = f.position.x
    regions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/nikita-v2/regions.json"))
    for bank in ["movement", "attacks", "powers", "reactions"]:
        banks[bank] = load("res://assets/nikita-v2/" + bank + ".png")

func _process(delta: float) -> void:
    var dx := absf(f.position.x - previous_x)
    previous_x = f.position.x
    if not f.frozen and not f.abilities.conversation_locked() and f.hitstop_frames == 0:
        clock += delta
        if dx < 20:
            distance += dx
    queue_redraw()

func _draw() -> void:
    if f == null or f.abilities == null or f.state_machine.current_state == null or regions.is_empty():
        return
    var state := str(f.state_machine.current_state.name)
    var age := f.state_machine.current_state.state_frame
    var bank := "movement"
    var pose := int(clock * 7) % 8
    var lean := 0.0
    if f.abilities.expansion.water_frames > 0:
        bank = "powers"
        var elapsed := ExpansionAbilities.WATER_TOTAL - f.abilities.expansion.water_frames
        pose = mini(7, elapsed / 5) if elapsed < 36 else (11 + mini(2, (elapsed - 36) / 10) if elapsed < 66 else 14 + mini(1, (elapsed - 66) / 9))
    elif f.health <= 0:
        bank = "reactions"
        pose = 12
    elif state == "Attack" and f.current_move != null:
        bank = "attacks"
        var move := f.current_move
        var kick := move.move_name.to_lower().ends_with("k") or move.move_name == "Tatsu"
        var row := (3 if move.move_name.begins_with("cr.") or not f.on_ground else 2) if kick else (1 if move.damage >= 70 or move.move_name == "Shoryuken" else 0)
        var phase := 0
        if age < move.startup:
            phase = mini(2, int(age * 3.0 / maxi(1, move.startup)))
        elif age < move.startup + move.active:
            phase = 3 + mini(1, int((age - move.startup) * 2.0 / maxi(1, move.active)))
        else:
            phase = 5 + mini(2, int((age - move.startup - move.active) * 3.0 / maxi(1, move.recovery)))
        pose = row * 8 + phase
    elif f.abilities.pose_frames > 0 or f.abilities.rage_frames > 0:
        bank = "powers"
        pose = (16 if f.abilities.pose_kind == "blackflame" else 24) + int(clock * 10) % 8
    elif state in ["Walk", "Dash"]:
        pose = 8 + int(distance / 6) % 8
        lean = 0.06 if state == "Dash" else 0.0
    elif state in ["Jump", "JumpStartup"]:
        pose = 16 + clampi(int((f.vel.y + 660) / 180), 0, 7)
    elif state == "Crouch":
        pose = 26
    elif state == "Blockstun":
        bank = "reactions"
        pose = 16 + mini(7, age / 3)
    elif state == "Hitstun":
        bank = "reactions"
        pose = mini(7, age / 3)
        lean = -0.05
    elif state in ["Knockdown", "Thrown"]:
        bank = "reactions"
        pose = 8 + mini(7, age / 7)
    var growth := f.abilities.size_multiplier()
    draw_set_transform(Vector2(0, maxf(0, f.ground_y - f.position.y)), 0, Vector2(1, 0.22))
    draw_circle(Vector2.ZERO, 23 * growth, Color(0, 0, 0, 0.27))
    var squash := sin(f.landing_frames / 8.0 * PI) * 0.07 if f.landing_frames > 0 else 0.0
    draw_set_transform(Vector2.ZERO, lean * f.facing(), Vector2(f.facing() * growth * (1 + squash), growth * (1 - squash)))
    var data: Dictionary = regions[bank + ".png"]
    var frame: Dictionary = data.frames[clampi(pose, 0, 31)]
    var rect: Array = frame.rect
    var anchor: Array = frame.anchor
    # All banks share the same standing body scale; crouches never become giants.
    var unit := 112.0 / float(regions["movement.png"].height)
    var src := Rect2(rect[0], rect[1], rect[2], rect[3])
    var dest := Rect2(Vector2(float(rect[0]) - anchor[0], float(rect[1]) - anchor[1]) * unit, src.size * unit)
    var tint := Color(1, 0.65, 0.6) if state == "Hitstun" else Color.WHITE
    if f.abilities.rage_frames > 0:
        tint = Color(1, 0.48, 0.42)
    if f.abilities.freeze_frames > 0:
        tint = Color(0.35, 1, 0.5)
    if frame.has("polygon"):
        var points := PackedVector2Array()
        var uvs := PackedVector2Array()
        for pair in frame.polygon:
            var point := Vector2(pair[0], pair[1])
            points.append((point - Vector2(anchor[0], anchor[1])) * unit)
            uvs.append(point / Vector2(banks[bank].get_size()))
        draw_colored_polygon(points, tint, uvs, banks[bank])
    else:
        draw_texture_rect_region(banks[bank], dest, src, tint)
    draw_set_transform(Vector2.ZERO)
