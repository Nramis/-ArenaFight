class_name PolinaHoldArt
extends Node2D

const TEXTURE = preload("res://assets/grapples/mavrin-polina-hold.png")
const COUNTER_TEXTURE = preload("res://assets/grapples/polina-counter.png")
const COUNTER_METADATA := "res://assets/grapples/polina-counter.json"
const METADATA := "res://assets/grapples/mavrin-polina-hold.json"
const HOLD_POSES := [4, 6, 5, 7, 8, 9, 6, 7]
var f: Fighter
var regions: Dictionary = {}
var counter_regions: Dictionary = {}

static func handles(fighter: Fighter) -> bool:
    if fighter == null or fighter.abilities == null:
        return false
    var hold := fighter.abilities.expansion
    return hold.hold_frames > 0 or (is_instance_valid(hold.hold_source) and hold.hold_source.abilities.expansion.hold_frames > 0)

static func pose_at(remaining: int) -> int:
    var age := ExpansionAbilities.HOLD_DURATION - remaining
    if age < 48:
        return clampi(age / 12, 0, 3)
    if remaining <= 36:
        return 10 if remaining > 18 else 11
    return HOLD_POSES[int((age - 48) / 8) % HOLD_POSES.size()]

func _ready() -> void:
    f = get_parent().get_parent()
    regions = JSON.parse_string(FileAccess.get_file_as_string(METADATA))
    counter_regions = JSON.parse_string(FileAccess.get_file_as_string(COUNTER_METADATA))
    # Each figure keeps its own clothing palette in the joint sprite.
    var palette := ShaderMaterial.new()
    palette.shader = preload("res://fighter/hold_palette.gdshader")
    palette.set_shader_parameter("mavrin_enabled", SkinStyle.PALETTES.has(f.skin_id))
    palette.set_shader_parameter("mavrin_color", SkinStyle.PALETTES.get(f.skin_id, Color.WHITE))
    var other_skin := GameConfig.p2_skin if f.name == "Player1" else GameConfig.p1_skin
    palette.set_shader_parameter("polina_enabled", SkinStyle.PALETTES.has(other_skin))
    palette.set_shader_parameter("polina_color", SkinStyle.PALETTES.get(other_skin, Color.WHITE))
    material = palette

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    if f == null or f.abilities == null or f.abilities.expansion.hold_frames <= 0 or regions.is_empty():
        return
    var counter: int = f.abilities.expansion.counter_frames
    var bank := counter_regions if counter > 0 else regions
    var atlas: Texture2D = COUNTER_TEXTURE if counter > 0 else TEXTURE
    var index := clampi((ExpansionAbilities.COUNTER_DURATION - counter) / 6, 0, 15) if counter > 0 else pose_at(f.abilities.expansion.hold_frames)
    var frame: Dictionary = bank.frames[index]
    var anchor: Array = frame.anchor
    # The artist packed the last rows more tightly. Normalize their standing height.
    var reference_height: float = [317.0, 301.0, 263.0, 204.0][index / 4] if counter > 0 else float(regions.height)
    var unit := 112.0 / reference_height
    var growth := f.abilities.size_multiplier()
    draw_set_transform(Vector2.ZERO, 0, Vector2(1, .22))
    draw_circle(Vector2.ZERO, 23, Color(0, 0, 0, .27))
    draw_circle(Vector2(f.facing() * 47, 0), 17, Color(0, 0, 0, .18))
    draw_set_transform(Vector2.ZERO, 0, Vector2(f.facing() * growth, growth))
    for polygon in frame.polygons:
        var points := PackedVector2Array()
        var uvs := PackedVector2Array()
        for pair in polygon:
            var point := Vector2(pair[0], pair[1])
            points.append((point - Vector2(anchor[0], anchor[1])) * unit)
            uvs.append(point / Vector2(atlas.get_size()))
        draw_colored_polygon(points, Color.WHITE, uvs, atlas)
    draw_set_transform(Vector2.ZERO)
