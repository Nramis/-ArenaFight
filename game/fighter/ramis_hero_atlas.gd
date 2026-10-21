class_name RamisHeroAtlas
extends RefCounted

static var banks: Dictionary = {}
static var textures: Dictionary = {}

static func bank(name: String) -> Dictionary:
    if not banks.has(name):
        var path := "res://assets/ramis-hero/" + name + ".json"
        banks[name] = JSON.parse_string(FileAccess.get_file_as_string(path))
    return banks[name]

static func texture(name: String) -> Texture2D:
    if not textures.has(name):
        textures[name] = load("res://assets/ramis-hero/" + name + ".png")
    return textures[name]

static func draw_pose(canvas: Node2D, name: String, index: int, origin: Vector2, direction: int = 1, scale_value: float = 1.0, rotation_value: float = 0.0, tint: Color = Color.WHITE) -> void:
    var data := bank(name)
    var atlas := texture(name)
    if data.is_empty() or atlas == null:
        return
    index = clampi(index, 0, data.frames.size()-1)
    var frame: Dictionary = data.frames[index]
    var anchor: Array = frame.anchor
    var unit := 112.0 / float(data.get("reference_heights", [data.height, data.height, data.height, data.height])[index/4])
    canvas.draw_set_transform(origin, rotation_value * direction, Vector2(direction, 1) * scale_value)
    for polygon in frame.polygons:
        var points := PackedVector2Array()
        var uvs := PackedVector2Array()
        for pair in polygon:
            var point := Vector2(pair[0], pair[1])
            points.append((point - Vector2(anchor[0], anchor[1])) * unit)
            uvs.append(point / Vector2(atlas.get_size()))
        canvas.draw_colored_polygon(points, tint, uvs, atlas)
    canvas.draw_set_transform(Vector2.ZERO)

static func attack_pose(age: int) -> Array:
    if age < RamisUltimate.DRIVE:
        return ["windup", clampi(age / 4, 0, 15)]
    if age < RamisUltimate.SLAM:
        return ["drive", clampi((age - RamisUltimate.DRIVE) / 2, 0, 15)]
    if age < 132:
        return ["slam", clampi((age - RamisUltimate.SLAM) / 3, 0, 11)]
    if age < 148:
        return ["victory", clampi((age - 132) / 4, 0, 3)]
    if age < 160:
        return ["slam", 12 + clampi((age - 148) / 3, 0, 3)]
    return ["victory", 4 + clampi((age - 160) / 4, 0, 11)]
