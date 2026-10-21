class_name FinisherScene
extends Node2D

const DURATION := 258
const TITLES := {
    "rafael": "ПРОТЕИНОВЫЙ ПЕРЕГРУЗ", "nikita": "СУЙТОН · ЛИНИЯ РАЗРЕЗА",
    "vladislav": "БУРГЕРНЫЙ ПРЕСС", "mavrin": "КЭТ · ПОСЛЕДНЯЯ ТРЕНИРОВКА",
    "ramis": "МАРИС · СОЛНЕЧНОЕ ЗАТМЕНИЕ", "ilgiz": "СТАЯ ВЫНОСИТ ПРИГОВОР",
    "bigboss": "АЛЕКСАНДРОВ · ЗОЛОТОЙ ЗАЛП", "azat": "ПОСЛЕДНЕЕ НЫТЬЁ",
    "polina": "ДОЖДЬ ПОСЛЕДНЕГО ДНЯ", "yusup": "А ЗАБЕЙ · ЛЕДЯНОЙ КРУГ",
    "rinat": "ИДИ СЮДА · ПОСЛЕДНИЙ ВДОХ"
}
var winner: Fighter
var loser: Fighter
var age := 0
var active := true
var winner_art: Texture2D
var loser_art: Texture2D
var winner_src: Rect2
var loser_src: Rect2
var direction := 1
var burst_done := false
var one_punch_finish := false
var victory_regions: Dictionary = {}

func _ready() -> void:
    z_index = 30
    direction = 1 if loser.position.x > winner.position.x else -1
    one_punch_finish = winner.abilities.expansion.one_punch_victory
    if one_punch_finish:
        victory_regions = JSON.parse_string(FileAccess.get_file_as_string(RamisShaveArt.VICTORY_METADATA))
    var w := _art(winner)
    winner_art = w[0]
    winner_src = w[1]
    var l := _art(loser)
    loser_art = l[0]
    loser_src = l[1]
    winner.visible = false
    loser.visible = false
    winner.emit_sound("summon")

func _art(f: Fighter) -> Array:
    var path := "res://assets/motion/" + f.roster_name() + ".png"
    var cols := 4
    var rows := 2
    if not ResourceLoader.exists(path):
        path = "res://assets/rinat/rinat-base.png" if f.roster_name() == "rinat" else "res://assets/" + f.roster_name() + ".png"
        cols = 8 if f.roster_name() == "rinat" else 4
        rows = 4
    if not ResourceLoader.exists(path):
        path = "res://assets/motion/nikita.png"
        cols = 4
        rows = 2
    var tex: Texture2D = load(path)
    return [tex, Rect2(0, 0, tex.get_width() / float(cols), tex.get_height() / float(rows))]

func _physics_process(_delta: float) -> void:
    age += 1
    if age == 115 and not burst_done and not one_punch_finish:
        burst_done = true
        loser.emit_blood(220, direction)
        loser.emit_blood(160, -direction)
        winner.emit_sound("combo_finish")
    if age >= DURATION:
        active = false
        winner.visible = true
        loser.visible = true
        set_physics_process(false)
        queue_redraw()
        return
    queue_redraw()

func _draw() -> void:
    if not active or winner_art == null:
        return
    if one_punch_finish:
        _draw_one_punch()
        return
    var id := winner.roster_name()
    var envelope := minf(1, age / 24.0) * minf(1, (DURATION - age) / 24.0)
    draw_rect(Rect2(0, 0, 384, 216), Color(0.015, 0.02, 0.035, 0.82 * envelope))
    var wx := 105.0 if direction > 0 else 279.0
    var lx := 260.0 if direction > 0 else 124.0
    var progress := clampf((age - 70) / 60.0, 0, 1)
    var after := clampf((age - 115) / 60.0, 0, 1)
    var victim_scale := 1.0 - after * 0.2
    var victim_y := 180.0
    var victim_rotation := after * 1.45 * direction
    if id in ["mavrin", "ramis", "rinat"]:
        victim_y -= sin(progress * PI) * 52
    if id == "vladislav":
        victim_scale = 1.0 - progress * 0.75
        victim_rotation = 0
    if id == "azat":
        victim_y -= absf(sin(progress * 10)) * 15
    draw_set_transform(Vector2(lx + after * direction * 28, victim_y), victim_rotation, Vector2(-direction * victim_scale, victim_scale))
    draw_texture_rect_region(loser_art, Rect2(-37, -108, 74, 108), loser_src, Color(1, 0.65, 0.65, 1 - after * 0.3))
    draw_set_transform(Vector2(wx, 180), -sin(progress * PI) * direction * 0.12, Vector2(direction, 1))
    draw_texture_rect_region(winner_art, Rect2(-40, -112, 80, 112), winner_src)
    draw_set_transform(Vector2.ZERO)
    if age >= 40 and age < 205:
        match id:
            "nikita":
                for i in 3:
                    draw_line(Vector2(wx + direction * 23, 95 + i * 2), Vector2(lerpf(wx, lx + direction * 65, progress), 95 + i * 2), Color(0.55, 0.94, 1, envelope), 2 if i == 1 else 1)
                for i in 18:
                    var p := Vector2(lx + sin(i * 3.4 + age * 0.1) * 44, 64 + fmod(i * 13.0 + age, 110))
                    draw_circle(p, 1.5, Color(0.65, 0.96, 1, envelope))
            "rinat":
                for i in 24:
                    var p := Vector2(wx + direction * 16, 119).lerp(Vector2(lx, victim_y - 55), i / 24.0)
                    draw_arc(p, 3, 0, TAU, 8, Color("d1e0ea"), 1.6)
                for i in 20:
                    draw_circle(Vector2(lx + sin(i * 2.4 + age * 0.04) * 44, 180 - fmod(i * 11 + age * 0.8, 110.0)), 12, Color(0.9, 0.94, 1, 0.065 * envelope))
            "bigboss":
                for i in 12:
                    var t := clampf(progress * 2 - i * 0.06, 0, 1)
                    var p := Vector2(wx, 115).lerp(Vector2(lx + sin(i) * 22, 110 + cos(i) * 25), t)
                    draw_rect(Rect2(p - Vector2(6, 4), Vector2(12, 8)), Color("e4be60"))
                    draw_rect(Rect2(p - Vector2(2, 4), Vector2(4, 8)), Color("542b23"))
            "vladislav":
                var y := lerpf(20, 154, progress)
                draw_style_box(_box(Color("d59b43")), Rect2(lx - 55, y - 14, 110, 28))
                draw_rect(Rect2(lx - 52, y - 5, 104, 7), Color("6e321f"))
                draw_line(Vector2(lx - 48, y - 9), Vector2(lx + 48, y - 9), Color("a2d855"), 4)
            "mavrin":
                for i in 4:
                    var x := lx + (i - 1.5) * 25
                    draw_line(Vector2(x, 160), Vector2(lx, victim_y - 50), Color(1, 0.6, 0.9, envelope), 3)
                    draw_circle(Vector2(x, 80), 9, Color("efc3a5"))
                    draw_line(Vector2(x, 91), Vector2(x, 125), Color("9172bb"), 10)
                draw_string(ThemeDB.fallback_font, Vector2(lx - 28, 63), "КЭТ!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff098"))
            "ramis":
                draw_circle(Vector2(lx, 65), 22 + progress * 15, Color(1, 0.85, 0.3, envelope * 0.75))
                draw_line(Vector2(lx, 70), Vector2(lx, 180), Color(1, 0.88, 0.4, envelope * 0.5), 16 * progress)
                for i in 10:
                    var angle := i * TAU / 10 + age * 0.02
                    draw_line(Vector2(lx, 65) + Vector2.from_angle(angle) * 27, Vector2(lx, 65) + Vector2.from_angle(angle) * 55, Color("ffe08a"), 2)
            "ilgiz":
                for i in 5:
                    var x := lerpf(wx - direction * (30 + i * 12), lx + (i - 2) * 12, progress)
                    draw_rect(Rect2(x - 13, 158 + (i % 2) * 6, 26, 12), Color("a7784f"))
                    draw_circle(Vector2(x + direction * 14, 157 + (i % 2) * 6), 7, Color("cfa875"))
                    draw_line(Vector2(x - 7, 171), Vector2(x - 10, 180), Color("7f573d"), 3)
                    draw_line(Vector2(x + 7, 171), Vector2(x + 10, 180), Color("7f573d"), 3)
            "polina":
                for i in 30:
                    var p := Vector2(lx - 66 + fmod(i * 23.7, 132), fmod(age * 3 + i * 17, 170.0))
                    draw_line(p, p + Vector2(2, 11), Color("f9ecd0"), 1.8)
                    draw_circle(p + Vector2(2, 11), 1.3, Color("ff8c5c"))
            "yusup":
                draw_arc(Vector2(lx, 124), 50 * progress, age * 0.08, age * 0.08 + TAU - 0.5, 50, Color("b0faff"), 3)
                for i in 8:
                    var p := Vector2(lx, 124) + Vector2.from_angle(i * TAU / 8 + age * 0.07) * (35 * progress)
                    draw_line(p, p + Vector2(5, -9), Color("e1ffff"), 2)
            "azat":
                for i in 4:
                    draw_arc(Vector2(wx, 92), int(age * 1.5 + i * 24) % 190, -0.8 if direction > 0 else PI - 0.8, 0.8 if direction > 0 else PI + 0.8, 30, Color(0.8, 0.65, 1, envelope * 0.7), 2)
                draw_string(ThemeDB.fallback_font, Vector2(90, 62), "НУ ПОЧЕМУ Я-А-А?!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e1caff"))
            _:
                draw_circle(Vector2(wx, 125), 28 + progress * 30, Color(0.7, 1, 0.3, 0.28 * envelope))
                for i in 7:
                    draw_line(Vector2(wx + direction * 18, 125), Vector2(lx, 80 + i * 13), Color(0.8, 1, 0.4, envelope), 2)
    draw_rect(Rect2(0, 52, 384, 28), Color(0.02, 0.02, 0.03, 0.95))
    var font := ThemeDB.fallback_font
    var title: String = TITLES[id]
    var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
    draw_string(font, Vector2((384 - width) / 2, 70), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e8fa9b"))
    if age > 145:
        draw_string(font, Vector2(126, 204), "ФАТАЛИТИ", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("ff4960"))

func _box(color: Color) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    box.set_corner_radius_all(12)
    return box

func _draw_one_punch() -> void:
    draw_rect(Rect2(0, 0, 384, 216), Color(0.015, 0.02, 0.035, .68))
    var wx := 120.0 if direction > 0 else 264.0
    var lx := 270.0 if direction > 0 else 114.0
    var fall := clampf(age / 30.0, 0, 1)
    draw_set_transform(Vector2(lx, 180), fall * 1.45 * direction, Vector2(-direction, 1))
    draw_texture_rect_region(loser_art, Rect2(-37, -108, 74, 108), loser_src, Color(1, .8, .8))
    draw_set_transform(Vector2.ZERO)
    RamisShaveArt.draw_victory(self, victory_regions, age, Vector2(wx, 180), direction)
    draw_rect(Rect2(0, 51, 384, 15), Color(.02, .02, .03, .95))
    draw_string(ThemeDB.fallback_font, Vector2(88, 62), "ОДИН УДАР · ЛЫСЫЙ ГЕРОЙ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffe08a"))
    if age > 70:
        draw_string(ThemeDB.fallback_font, Vector2(142, 204), "ПОБЕДА", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("e8fa9b"))
