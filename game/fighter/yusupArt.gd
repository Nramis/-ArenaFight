extends Node2D

const ATLAS = preload("res://assets/yusup.png")
var fighter: Fighter
var clock := 0.0
var gait := 0.0

func _ready() -> void:
    fighter = get_parent().get_parent()

func _process(delta: float) -> void:
    if fighter.abilities != null and not fighter.frozen and not fighter.abilities.conversation_locked() and fighter.hitstop_frames == 0:
        clock += delta
        gait += absf(fighter.vel.x) * delta / 26.0
    queue_redraw()

func _draw() -> void:
    if fighter == null or fighter.abilities == null or fighter.state_machine.current_state == null:
        return
    var ability := fighter.abilities
    var action := ability.yusup
    var state := str(fighter.state_machine.current_state.name)
    var pose := 0
    var lean := 0.0
    var bob := sin(clock * 3.5) * 0.5
    if state in ["Walk", "Dash"]:
        pose = 1 + posmod(int(gait), 2)
        bob = -absf(sin(gait * PI))
    elif state in ["Jump", "JumpStartup"]:
        pose = 5
    elif state == "Crouch" or (state == "Blockstun" and fighter.input.down):
        pose = 6
        bob = 0
    elif state == "Attack" and fighter.current_move != null:
        pose = 4 if fighter.current_move.move_name.to_lower().ends_with("k") else 3
        if fighter.state_machine.current_state.state_frame < fighter.current_move.startup / 2:
            pose = 0
    if action.swim_frames > 0:
        pose = 12 + posmod(int((YusupAbilities.SWIM_DURATION - action.swim_frames) / 4), 4)
    if action.story_frames > 0:
        pose = 8 if action.story_frames > YusupAbilities.OUTRO_FRAMES else 9
        bob = 0
    elif ability.pose_frames > 0 and ability.pose_kind == "remote":
        pose = 10
    if state in ["Hitstun", "Knockdown", "Thrown"] or fighter.health <= 0:
        if action.swim_frames == 0:
            pose = 7
        lean = -1.25 if state in ["Knockdown", "Thrown"] or fighter.health <= 0 else -0.12
    var growth := ability.size_multiplier()
    var tint := Color.WHITE
    if ability.freeze_frames > 0:
        tint = Color(0.3, 1.0, 0.4)
    elif state == "Hitstun":
        tint = Color(1.0, 0.65, 0.6)
    elif state == "Blockstun":
        tint = Color(0.65, 0.9, 1.0)
    if fighter.invuln_frames > 0:
        tint.a = 0.8
    draw_set_transform(Vector2(0, maxf(0, fighter.ground_y - fighter.position.y)), 0, Vector2(1, 0.22))
    draw_circle(Vector2.ZERO, 22 * growth, Color(0, 0, 0, 0.25))
    draw_set_transform(Vector2(0, bob), lean * fighter.facing(), Vector2(fighter.facing() * growth, growth))
    _draw_pose(pose, tint)
    if action.swim_frames > 0:
        draw_arc(Vector2(0, -67), 36, clock * 15, clock * 15 + PI * 1.4, 20, Color(0.5, 0.85, 1.0, 0.65), 1.5)
    draw_set_transform(Vector2.ZERO)
    if action.story_frames > 0:
        var bubble := StyleBoxFlat.new()
        bubble.bg_color = Color("142332")
        bubble.border_color = Color("b1f5d6")
        bubble.set_border_width_all(1)
        bubble.set_corner_radius_all(4)
        draw_style_box(bubble, Rect2(-52, -139, 104, 22))
        draw_string(ThemeDB.fallback_font, Vector2(-48, -124), action.speech(), HORIZONTAL_ALIGNMENT_CENTER, 96, 10, Color("e5f5ef"))

func _draw_pose(pose: int, tint: Color) -> void:
    var cell := Vector2(ATLAS.get_size()) / 4.0
    var origin := Vector2(pose % 4, int(pose / 4)) * cell
    var source := Rect2(origin, cell)
    var unit := 110.0 / (cell.y * 0.97)
    if pose == 13:
        source.position.x -= 8
        source.size.x += 8
    if pose == 15:
        # The raised hand crosses into the row above. Isolate it without
        # sampling the preceding pose's feet or changing the source PNG.
        var outline := [Vector2(1060, 900), Vector2(1108, 900), Vector2(1108, 946), Vector2(1254, 946), Vector2(1254, 1254), Vector2(941, 1254), Vector2(941, 946), Vector2(1060, 946)]
        var points := PackedVector2Array()
        var uv := PackedVector2Array()
        for point: Vector2 in outline:
            points.append((point - origin - Vector2(cell.x / 2, cell.y * 0.99)) * unit)
            uv.append(point / Vector2(ATLAS.get_size()))
        draw_colored_polygon(points, tint, uv, ATLAS)
        return
    draw_texture_rect_region(ATLAS, Rect2((source.position - origin - Vector2(cell.x / 2, cell.y * 0.99)) * unit, source.size * unit), source, tint)
