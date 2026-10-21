extends Node2D

const FONT = preload("res://assets/fonts/Manrope.ttf")
var f: Fighter
var clock := 0.0

func _ready() -> void:
    f = get_parent()
    z_index = 7

func _process(delta: float) -> void:
    if not f.frozen and not f.abilities.conversation_locked():
        clock += delta
    queue_redraw()

func _draw() -> void:
    if f.abilities == null or f.frozen:
        return
    var a := f.abilities.expansion
    if a.water_frames > 0:
        var elapsed := ExpansionAbilities.WATER_TOTAL - a.water_frames
        if elapsed < ExpansionAbilities.WATER_WINDUP:
            draw_arc(Vector2(0, -66), 16 + sin(clock * 13) * 2, clock * 8, clock * 8 + 4.2, 32, Color(0.4, 0.9, 1, 0.8), 1)
            for i in 6:
                draw_circle(Vector2(sin(clock * 5 + i) * 22, -55 - i * 5), 1, Color("c7faff"))
        _caption("СУЙТОН · ПЕЧАТИ" if elapsed < 36 else "РЕЖУЩАЯ СТРУЯ", Color("9fedff"))
    if a.cheese_mode:
        # Tray/accessories are still rendered when the fighter is stunned.
        draw_set_transform(Vector2.ZERO, 0, Vector2(f.facing(), 1) * f.abilities.size_multiplier())
        if not ResourceLoader.exists("res://assets/cheese/bigboss-cheese.png"):
            draw_rect(Rect2(-10, -52, 37, 20), Color("9e7936"))
            for i in a.cheese_remaining:
                var p := Vector2(-7 + (i % 4) * 8, -50 + int(i / 4) * 5)
                draw_rect(Rect2(p, Vector2(7, 4)), Color("f9dfa2"))
                draw_line(p + Vector2(3, 0), p + Vector2(3, 4), Color("543025"), 2)
        draw_set_transform(Vector2.ZERO)
        _caption("СЫРКИ %d/12 · УДАР = БРОСОК" % a.cheese_remaining, Color("ffdfa1"))
    if a.shave_frames > 0:
        var progress := 1.0 - a.shave_frames / float(ExpansionAbilities.SHAVE_DURATION)
        _speech("БРИТЬЁ · %.1f с · СБЕЙ УДАРОМ!" % (a.shave_frames / 60.0), Color("ffdc79"), 51 - f.position.y)
        draw_rect(Rect2(-30, -10, 60, 3), Color("263549"))
        draw_rect(Rect2(-30, -10, 60 * progress, 3), Color("ffdc79"))
    elif a.one_punch_ready:
        _caption("ОДИН УДАР!", Color("ffdc79"))
    if a.hold_frames > 0 and a.counter_frames == 0:
        var age := ExpansionAbilities.HOLD_DURATION - a.hold_frames
        if age < 100:
            _speech("Эххх, Полинаа!", Color("fff0a8"), -68)
        else:
            _speech("Идите в жопу со своими\nупражнениями, Игорь Анатольевич!", Color("f3c7ff"), -68)
    if is_instance_valid(a.hold_source):
        var holder := a.hold_source.abilities.expansion
        if holder.counter_available():
            var left := (holder.hold_frames - ExpansionAbilities.COUNTER_CLOSE_REMAINING) / 60.0
            _speech("ЖМИ " + holder.counter_button_label() + " · КОЛЕНОМ · %.1f с · 1 ПОПЫТКА" % left, Color("8cffe0"), 51 - f.position.y)
    if a.counter_frames > 0:
        _caption("КОНТРАТАКА ПОЛИНЫ!", Color("ffbd8b"))
    if f.roster_name() == "mavrin" and f.abilities.pose_frames > 0 and f.abilities.pose_kind == "ket":
        _caption("КЭТ!", Color("fff0a8"))

func _caption(text: String, color: Color) -> void:
    _speech(text, color, 51 - f.position.y)

func _speech(text: String, color: Color, y: float) -> void:
    var lines := text.split("\n")
    var width := 0.0
    for line in lines:
        width = maxf(width, FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)
    width = minf(350, width + 14)
    var x := clampf(f.position.x - width / 2, 6, 378 - width) - f.position.x
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.025, 0.035, 0.055, 0.94)
    box.border_color = Color(color, 0.5)
    box.set_border_width_all(1)
    box.set_corner_radius_all(4)
    draw_style_box(box, Rect2(x, maxf(y, 51 - f.position.y), width, 6 + lines.size() * 10))
    for i in lines.size():
        draw_string(FONT, Vector2(x + 7, maxf(y, 51 - f.position.y) + 11 + i * 10), lines[i], HORIZONTAL_ALIGNMENT_LEFT, width - 14, 8, color)
