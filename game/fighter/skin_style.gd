class_name SkinStyle
extends Node2D

# Cosmetics only: never touch combat timers, inputs, collision or RNG.
const PALETTES := {
    "neon_champion": Color("7d4dff"), "water_shinobi": Color("168dd6"),
    "luchador": Color("b82952"), "disco_coach": Color("d93bcd"),
    "solar_knight": Color("ecb333"), "forest_ranger": Color("2f9264"),
    "cheese_baron": Color("e6ad36"), "catboy": Color("da68b5"),
    "storm_witch": Color("8063c9"), "polar_penguin": Color("48b4da"),
    "ice_ninja": Color("36bedb")
}
const ART_SCRIPTS := ["combat_art.gd", "locomotion_art.gd", "fighter_art.gd", "roster_art.gd", "polina_special_art.gd", "rinat_art.gd", "azat_art.gd", "yusupArt.gd", "nikita_art.gd", "cheese_art.gd", "ramis_shave_art.gd"]
const PALETTE_SHADER := preload("res://fighter/skin_palette.gdshader")
var f: Fighter
var clock := 0.0
var palette: ShaderMaterial

static func install(fighter: Fighter) -> void:
    if not PALETTES.has(fighter.skin_id):
        return
    var style := SkinStyle.new()
    style.name = "SkinStyle"
    fighter.add_child(style)

func _ready() -> void:
    f = get_parent()
    z_index = 3
    palette = ShaderMaterial.new()
    palette.shader = PALETTE_SHADER
    palette.set_shader_parameter("cloth_color", PALETTES[f.skin_id])
    # CombatArt creates its legacy/locomotion nodes deferred. Run after them.
    call_deferred("_apply_palette")

func _apply_palette() -> void:
    _visit_art(f)

func _visit_art(node: Node) -> void:
    var script = node.get_script()
    if node is CanvasItem and script != null and str(script.resource_path).get_file() in ART_SCRIPTS:
        node.material = palette
    for child in node.get_children():
        _visit_art(child)

func _process(delta: float) -> void:
    if f.abilities == null or f.state_machine.current_state == null:
        return
    if not f.frozen and f.hitstop_frames == 0 and not f.abilities.conversation_locked():
        clock += delta
    queue_redraw()

func _draw() -> void:
    if f == null or f.abilities == null or f.state_machine.current_state == null or f.health <= 0:
        return
    if PolinaHoldArt.handles(f) or RamisShaveArt.handles(f):
        return
    var state := str(f.state_machine.current_state.name)
    if state in ["Knockdown", "Throw", "Thrown"] or f.abilities.maris_frames > 0:
        return
    var crouch := state == "Crouch" or (state == "Blockstun" and f.input.down) or (state == "Attack" and f.current_move != null and f.current_move.move_name.begins_with("cr."))
    var head_y := -79.0 if crouch else -108.0
    if f.roster_name() == "yusup":
        head_y += 9
    elif f.roster_name() == "bigboss":
        head_y += 3
    var bob := sin(clock * 3.5) * 0.45
    if state in ["Walk", "Dash"]:
        bob = -absf(sin(clock * 10)) * 1.1
    var lean := -0.08 if state == "Hitstun" else 0.0
    var growth := f.abilities.size_multiplier()
    draw_set_transform(Vector2(0, bob), lean * f.facing(), Vector2(f.facing() * growth, growth))
    var center := Vector2(0, head_y)
    if f.roster_name() == "nikita" and f.abilities.expansion.water_frames > 18 and f.abilities.expansion.water_frames <= 48:
        center += Vector2(16, 20)
    var dark := Color("152237")
    var accent: Color = PALETTES[f.skin_id]
    match f.skin_id:
        "neon_champion":
            _band(center + Vector2(0, 6), Color("1c1a33"), Color("91faff"))
            draw_rect(Rect2(center + Vector2(-13, 9), Vector2(11, 6)), Color("38ffce"))
            draw_rect(Rect2(center + Vector2(1, 9), Vector2(11, 6)), Color("ff49d8"))
            draw_line(center + Vector2(-2, 11), center + Vector2(1, 11), dark, 2)
            _ribbon(center, Color("ff49d8"))
        "water_shinobi":
            _band(center + Vector2(0, 5), accent, Color("d6edff"))
            draw_arc(center + Vector2(0, 5), 2.4, 0.2, TAU - 0.2, 12, Color("268cc9"), 1)
            _ribbon(center, Color("78d9ff"))
        "luchador":
            _band(center + Vector2(0, 5), accent, Color("ffda5c"))
            _star(center + Vector2(0, 5), 4.0, Color("ffda5c"))
            draw_line(center + Vector2(-13, 5), center + Vector2(-17, 18), accent, 3)
            draw_line(center + Vector2(13, 5), center + Vector2(17, 18), accent, 3)
        "disco_coach":
            _band(center + Vector2(0, 4), accent, Color("ffc9fb"))
            _star(center + Vector2(-7, 11), 6, Color("ffdf68"))
            _star(center + Vector2(6, 11), 6, Color("ffdf68"))
            draw_line(center + Vector2(-2, 11), center + Vector2(1, 11), Color("fff2ba"), 2)
        "solar_knight":
            _crown(center, Color("fbd653"))
            draw_arc(center + Vector2(0, -10), 12, PI, TAU, 16, Color("fff0a0"), 1.5)
            for i in range(5):
                var ray := Vector2.from_angle(PI + i * PI / 4)
                draw_line(center + Vector2(0, -10) + ray * 15, center + Vector2(0, -10) + ray * 18, Color("ffda5e"), 1.5)
        "forest_ranger":
            _polygon([center + Vector2(-17, 4), center + Vector2(-2, -12), center + Vector2(16, 4)], Color("154e38"), accent)
            draw_line(center + Vector2(-19, 5), center + Vector2(20, 5), Color("e9ca79"), 3)
            draw_line(center + Vector2(8, 0), center + Vector2(14, -15), Color("e9ca79"), 2)
            draw_line(center + Vector2(12, -9), center + Vector2(18, -12), Color("e9ca79"), 2)
        "cheese_baron":
            _crown(center, Color("f9cd55"))
            for point in [Vector2(-7, 0), Vector2(4, -2), Vector2(8, 4)]:
                draw_circle(center + point, 1.8, Color("c88922"))
            _star(center + Vector2(0, -8), 4, Color("fff6b0"))
        "catboy":
            for sign_value in [-1, 1]:
                var ear := center + Vector2(sign_value * 10, 0)
                _polygon([ear + Vector2(-5, 4), ear + Vector2(-sign_value * 2, -12), ear + Vector2(6, 4)], dark, Color("df8dc8"))
                draw_line(ear + Vector2(0, -6), ear + Vector2(2, 1), Color("ffd4ef"), 2)
            _band(center + Vector2(0, 5), Color("704584"), Color("ffb4e5"))
        "storm_witch":
            _polygon([center + Vector2(-15, 3), center + Vector2(-6, -26), center + Vector2(5, -20), center + Vector2(12, 3)], dark, Color("654698"))
            draw_line(center + Vector2(-21, 5), center + Vector2(22, 5), dark, 6)
            draw_line(center + Vector2(-20, 4), center + Vector2(21, 4), accent, 3)
            _star(center + Vector2(0, -7), 4, Color("b5f2ff"))
        "polar_penguin":
            draw_arc(center + Vector2(0, 4), 13, PI, TAU, 18, dark, 7)
            draw_arc(center + Vector2(0, 4), 11, PI, TAU, 18, Color("cbf2ff"), 5)
            draw_circle(center + Vector2(0, -12), 4, Color("e8faff"))
            _polygon([center + Vector2(9, 4), center + Vector2(20, 8), center + Vector2(9, 10)], Color("b37b2c"), Color("ffb94c"))
            draw_line(Vector2(-10, head_y + 29), Vector2(10, head_y + 29), accent, 5)
            draw_line(Vector2(-8, head_y + 29), Vector2(-15, head_y + 44), accent, 4)
        "ice_ninja":
            _band(center + Vector2(0, 5), Color("166b95"), Color("b4f4ff"))
            _polygon([center + Vector2(0, -9), center + Vector2(4, 2), center + Vector2(0, 7), center + Vector2(-4, 2)], Color("247ea0"), Color("bdfaff"))
            _ribbon(center, Color("88e6ff"))
    draw_set_transform(Vector2.ZERO)

func _band(center: Vector2, cloth: Color, plate: Color) -> void:
    draw_rect(Rect2(center - Vector2(14, 4), Vector2(28, 8)), Color("152237"))
    draw_rect(Rect2(center - Vector2(13, 3), Vector2(26, 6)), cloth)
    draw_rect(Rect2(center - Vector2(6, 3), Vector2(12, 6)), plate)

func _ribbon(center: Vector2, color: Color) -> void:
    var flutter := sin(clock * 9) * 2
    draw_polyline(PackedVector2Array([center + Vector2(-13, 5), center + Vector2(-22, 8 + flutter), center + Vector2(-30, 5)]), color, 3, true)
    draw_polyline(PackedVector2Array([center + Vector2(-13, 6), center + Vector2(-20, 14 - flutter), center + Vector2(-26, 13)]), color.darkened(0.2), 2, true)

func _crown(center: Vector2, color: Color) -> void:
    _polygon([center + Vector2(-13, 5), center + Vector2(-15, -7), center + Vector2(-7, -2), center + Vector2(0, -12), center + Vector2(7, -2), center + Vector2(15, -7), center + Vector2(13, 5)], Color("73582b"), color)
    draw_line(center + Vector2(-13, 4), center + Vector2(13, 4), Color("fff1b3"), 2)

func _polygon(points: Array, outline: Color, fill: Color) -> void:
    var vertices := PackedVector2Array(points)
    draw_colored_polygon(vertices, fill)
    vertices.append(vertices[0])
    draw_polyline(vertices, outline, 1.2, true)

func _star(center: Vector2, radius: float, color: Color) -> void:
    var vertices := PackedVector2Array()
    for i in range(10):
        vertices.append(center + Vector2.from_angle(-PI / 2 + i * PI / 5) * (radius if i % 2 == 0 else radius * 0.43))
    draw_colored_polygon(vertices, color)
