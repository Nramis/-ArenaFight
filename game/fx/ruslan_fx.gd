extends Node2D

var fighter: Fighter
var blackout: ColorRect
var blackout_label: Label

func _ready() -> void:
    fighter = get_parent()
    top_level = true
    global_position = Vector2.ZERO
    z_index = 17
    var layer := CanvasLayer.new()
    layer.layer = 8
    add_child(layer)
    blackout = ColorRect.new()
    blackout.size = Vector2(384, 216)
    blackout.color = Color.BLACK
    blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(blackout)
    blackout_label = Label.new()
    blackout_label.position = Vector2(70, 86)
    blackout_label.size = Vector2(244, 32)
    blackout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    blackout_label.add_theme_font_size_override("font_size", 10)
    blackout_label.add_theme_color_override("font_color", Color("5e646b"))
    blackout_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(blackout_label)

func _process(_delta: float) -> void:
    if not is_instance_valid(fighter) or fighter.abilities == null:
        return
    var ability := fighter.abilities.ruslan
    blackout.visible = ability.dark_frames > 0 and not fighter.frozen
    blackout_label.visible = blackout.visible
    blackout_label.text = "ЧЁРНЫЙ ДЕНЬ · %.1f\nОриентируйся по звуку" % (ability.dark_frames / 60.0)
    queue_redraw()

func _draw() -> void:
    if fighter == null or fighter.abilities == null:
        return
    var ability := fighter.abilities.ruslan
    for coin in ability.coins:
        var opacity := minf(1, (54.0 - coin.age) / 15.0)
        var point := Vector2(coin.x, coin.y)
        var width := 0.35 + absf(sin(coin.age * 0.3)) * 0.65
        draw_set_transform(point, 0, Vector2(width, 1))
        draw_circle(Vector2.ZERO, 3.1, Color(1, 0.72, 0.14, opacity))
        draw_arc(Vector2.ZERO, 2, 0, TAU, 10, Color(0.56, 0.31, 0.04, opacity), 0.65)
    draw_set_transform(Vector2.ZERO)
    for shot in ability.shots:
        if shot.age < 0:
            continue
        var point := Vector2(shot.x, shot.y)
        draw_circle(point, 6.5, Color("d59b36"))
        for i in 9:
            var grain := Vector2(sin(i * 2.4 + shot.age * 0.2) * 5, cos(i * 3.1) * 4)
            draw_line(point + grain, point + grain + Vector2(2, -1), Color("ffe5a6"), 1)
        draw_circle(point + Vector2(1, -2), 1.8, Color("e57035"))
    if ability.pilaf_frames > 0:
        var pot := fighter.position + Vector2(fighter.facing() * 31, -7)
        draw_style_box(_box(Color("24343b"), Color("9aaba9")), Rect2(pot - Vector2(15, 10), Vector2(30, 17)))
        draw_ellipse_rice(pot + Vector2(0, -10))
        for i in 3:
            var steam := Vector2(pot.x - 8 + i * 8, pot.y - 18 - posmod(ability.simulation_frame + i * 8, 20))
            draw_arc(steam, 3, 0, PI, 7, Color(1, 1, 1, 0.5), 0.7)
    for drop in ability.drops:
        _banknote(Vector2(drop.x, drop.y), sin(drop.age * 0.12) * 0.4)
    if ability.rain_frames > 0 and ability.rain_spawned < 4:
        draw_arc(Vector2(ability.rain_center, 179), 45, PI, TAU, 24, Color("e3b74a"), 1.5)
        draw_string(ThemeDB.fallback_font, Vector2(ability.rain_center - 40, 158), "ДЕНЕЖНЫЙ ДОЖДЬ", HORIZONTAL_ALIGNMENT_CENTER, 80, 7, Color("ffe7a1"))
    if ability.dice_frames > 0 or ability.dice_reveal > 0:
        var point := fighter.position + Vector2(0, -132)
        var rolling := ability.dice_frames > 18
        var first := 1 + posmod(ability.simulation_frame / 3, 6) if rolling else ability.dice_a
        var second := 1 + posmod(ability.simulation_frame / 2 + 2, 6) if rolling else ability.dice_b
        _die(point + Vector2(-11, sin(ability.simulation_frame * 0.3) * 2 if rolling else 0), first)
        _die(point + Vector2(11, -sin(ability.simulation_frame * 0.3) * 2 if rolling else 0), second)

func draw_ellipse_rice(point: Vector2) -> void:
    draw_set_transform(point, 0, Vector2(1, 0.35))
    draw_circle(Vector2.ZERO, 14, Color("dfb55c"))
    draw_set_transform(Vector2.ZERO)
    for i in 9:
        draw_line(point + Vector2(-10 + i * 2.5, sin(i * 3) * 2), point + Vector2(-8 + i * 2.5, sin(i * 3) * 2), Color("ffe7af"), 0.8)

func _banknote(point: Vector2, angle: float) -> void:
    draw_set_transform(point, angle)
    draw_style_box(_box(Color("8dc58d"), Color("e0f5bb")), Rect2(-9, -4, 18, 8))
    draw_circle(Vector2.ZERO, 2.3, Color("397653"))
    draw_line(Vector2(-6, -2), Vector2(-6, 2), Color("397653"), 0.7)
    draw_set_transform(Vector2.ZERO)

func _die(point: Vector2, value: int) -> void:
    draw_style_box(_box(Color("fff4da"), Color("af8f50")), Rect2(point - Vector2(9, 9), Vector2(18, 18)))
    var positions: Array[Vector2] = []
    if value % 2 == 1:
        positions.append(Vector2.ZERO)
    if value >= 2:
        positions.append_array([Vector2(-4, -4), Vector2(4, 4)])
    if value >= 4:
        positions.append_array([Vector2(4, -4), Vector2(-4, 4)])
    if value == 6:
        positions.append_array([Vector2(-4, 0), Vector2(4, 0)])
    for pip in positions:
        draw_circle(point + pip, 1.4, Color("303d37"))

func _box(fill: Color, border: Color) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(1)
    box.set_corner_radius_all(3)
    return box
