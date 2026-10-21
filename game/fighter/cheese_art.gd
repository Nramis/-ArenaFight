extends Node2D

var f: Fighter
var texture: Texture2D
var regions: Dictionary = {}
var distance := 0.0
var previous_x := 0.0

func _ready() -> void:
    f = get_parent().get_parent()
    previous_x = f.position.x
    texture = load("res://assets/cheese/bigboss-cheese.png")
    var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/nikita-v2/regions.json"))
    regions = all.get("bigboss-cheese.png", {})

func _process(_delta: float) -> void:
    var dx := absf(f.position.x - previous_x)
    previous_x = f.position.x
    if not f.frozen and dx < 20:
        distance += dx
    queue_redraw()

func _draw() -> void:
    if f.abilities == null or not f.abilities.expansion.cheese_mode or regions.is_empty():
        return
    var extra := f.abilities.expansion
    var state := str(f.state_machine.current_state.name)
    var pose := 4
    var lean := 0.0
    if extra.cheese_recovery > 0:
        pose = 8 + mini(7, (26 - extra.cheese_recovery) / 3)
    elif state in ["Walk", "Dash"]:
        pose = 16 + int(distance / 9) % 4
    elif state in ["Crouch", "Blockstun"]:
        pose = 21
    elif extra.cheese_pose > 0:
        pose = mini(7, (30 - extra.cheese_pose) / 4)
    if state in ["Hitstun", "Knockdown"]:
        lean = -0.12 if state == "Hitstun" else -1.3
    var growth := f.abilities.size_multiplier()
    draw_set_transform(Vector2(0, maxf(0, f.ground_y - f.position.y)), 0, Vector2(1, 0.22))
    draw_circle(Vector2.ZERO, 25 * growth, Color(0, 0, 0, 0.25))
    draw_set_transform(Vector2.ZERO, lean * f.facing(), Vector2(f.facing() * growth, growth))
    var frame: Dictionary = regions.frames[pose]
    var r: Array = frame.rect
    var anchor: Array = frame.anchor
    var unit := 112.0 / float(regions.height)
    var src := Rect2(r[0], r[1], r[2], r[3])
    var dest := Rect2(Vector2(r[0] - anchor[0], r[1] - anchor[1]) * unit, src.size * unit)
    var tint := Color(1, 0.65, 0.6) if state == "Hitstun" else Color.WHITE
    if frame.has("polygon"):
        var points := PackedVector2Array()
        var uvs := PackedVector2Array()
        for pair in frame.polygon:
            var point := Vector2(pair[0], pair[1])
            points.append((point - Vector2(anchor[0], anchor[1])) * unit)
            uvs.append(point / Vector2(texture.get_size()))
        draw_colored_polygon(points, tint, uvs, texture)
    else:
        draw_texture_rect_region(texture, dest, src, tint)
    draw_set_transform(Vector2.ZERO)
