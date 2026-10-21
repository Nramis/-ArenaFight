class_name ExpansionEffect
extends Node2D

const ASSIST_DAMAGE := [145, 175, 155, 160, 170, 140, 165, 135, 150, 160, 170]
const ASSIST_NAMES := ["ПРОТЕИНОВЫЙ ТАРАН", "ВОДЯНОЙ КЛИНОК", "БУРГЕРНЫЙ ХУК", "ШПАГАТ С НЕБА", "СОЛНЕЧНЫЙ УДАР", "СОБАЧИЙ РЫВОК", "ЗОЛОТАЯ ОЧЕРЕДЬ", "ОБИДНЫЙ ПОДЗАТЫЛЬНИК", "ГРОЗОВАЯ ЛАДОНЬ", "ЛЕДЯНАЯ МЕЛЬНИЦА", "ЦЕПНОЙ АППЕРКОТ"]
const COLORS := [Color("c8fc68"), Color("7feaff"), Color("ffae53"), Color("ff7cda"), Color("ffe282"), Color("b4da82"), Color("f8d065"), Color("bd9cf6"), Color("a9b2ff"), Color("85f2e9"), Color("e2c18d")]
var kind := "cheese"
var attacker: Fighter
var target: Fighter
var variant := 0
var direction := 1
var age := 0
var struck := false
var power := 1.0
var vertical_speed := -90.0
var texture: Texture2D
var source := Rect2(0, 0, 384, 512)

func _ready() -> void:
    add_to_group("ability_effect")
    z_index = 4
    power = attacker.abilities.damage_multiplier()
    position = attacker.position + Vector2(direction * 23, -65)
    if kind == "assist":
        var id: String = Roster.IDS[variant]
        var path := "res://assets/motion/" + id + ".png"
        if not ResourceLoader.exists(path):
            path = "res://assets/rinat/rinat-base.png" if id == "rinat" else "res://assets/" + ("yusup" if id == "yusup" else "azat") + ".png"
        if ResourceLoader.exists(path):
            texture = load(path)
            if id == "rinat":
                source = Rect2(0, 0, texture.get_width() / 8.0, texture.get_height() / 4.0)
            elif id in ["yusup", "azat"]:
                source = Rect2(0, 0, texture.get_width() / 4.0, texture.get_height() / 4.0)
        position = Vector2(clampf(target.position.x - direction * 100, 38, 346), 180)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(attacker) or not is_instance_valid(target):
        queue_free()
        return
    if attacker.frozen:
        return
    age += 1
    if kind == "water":
        if attacker.abilities.expansion.water_frames == 0 or age > ExpansionAbilities.WATER_ACTIVE:
            queue_free()
            return
        position = attacker.position + Vector2(direction * 28, -73)
        var end := position + Vector2(direction * 320, 0)
        var rect := Rect2(Vector2(minf(position.x, end.x), position.y - 5), Vector2(320, 10))
        if not struck and rect.intersects(target.hurtbox_rect()):
            _hit(180, 125, false)
    elif kind == "cheese":
        vertical_speed += 300 * delta
        position += Vector2(direction * 285, vertical_speed) * delta
        rotation += direction * delta * 13
        if not struck and Rect2(position - Vector2(9, 9), Vector2(18, 18)).intersects(target.hurtbox_rect()):
            _hit(55, 85, false)
            queue_free()
        if position.y > 185 or age > 100 or position.x < -20 or position.x > 404:
            queue_free()
    else:
        if age > 30 and age <= 56:
            position.x = move_toward(position.x, target.position.x - direction * 44, 210 * delta)
        if age == 57:
            var region := Rect2(position + Vector2(-105, -114), Vector2(210, 124))
            if region.intersects(target.hurtbox_rect()):
                _hit(ASSIST_DAMAGE[variant], 250 if variant in [3, 6, 10] else 125, variant in [3, 6, 10])
                if struck and not target.last_hit_blocked:
                    if variant == 1:
                        target.abilities.slow_frames = maxi(90, target.abilities.slow_frames)
                        target.abilities.slow_strength = maxf(0.2, target.abilities.slow_strength)
                    elif variant == 9:
                        target.abilities.ignite(90, 0.6)
        if age > 100:
            queue_free()
    queue_redraw()

func _hit(damage: int, push: float, knockdown: bool) -> void:
    if target.is_invulnerable() or target.health <= 0:
        return
    struck = true
    var move := MoveData.new()
    move.move_name = "WaterJet" if kind == "water" else ("Cheese" if kind == "cheese" else ASSIST_NAMES[variant])
    move.damage = int(round(damage * power))
    move.hitstun = 24 if kind == "water" else 18
    move.blockstun = 12
    move.pushback = push
    move.causes_knockdown = knockdown
    move.hits_low = kind == "assist" and variant == 3
    move.hits_overhead = kind == "assist" and variant in [2, 7, 10]
    if target.is_blocking(move):
        target.receive_block(move, direction)
    else:
        target.receive_hit(move, direction)
    attacker.get_parent()._on_hit(target)

func _draw() -> void:
    if kind == "water":
        var envelope := minf(1, age / 5.0) * minf(1, (ExpansionAbilities.WATER_ACTIVE - age) / 6.0)
        var end := Vector2(direction * 320, 0)
        draw_line(Vector2.ZERO, end, Color(0.2, 0.75, 1, envelope * 0.24), 12)
        draw_line(Vector2.ZERO, end, Color(0.3, 0.85, 1, envelope), 3)
        draw_line(Vector2.ZERO, end, Color(0.9, 1, 1, envelope), 1)
        for i in 22:
            var x := fmod(i * 17 + age * 13, 320)
            draw_line(Vector2(direction * x, sin(i + age * 0.7) * 4), Vector2(direction * (x - 6), 0), Color(0.7, 0.96, 1, envelope * 0.8), 1)
    elif kind == "cheese":
        draw_rect(Rect2(-8, -5, 16, 10), Color("fff0b1"))
        draw_rect(Rect2(-7, -4, 14, 8), Color("caa345"), false, 1)
        draw_rect(Rect2(-3, -5, 6, 10), Color("6b3421"))
        draw_line(Vector2(-6, -3), Vector2(-4, 2), Color.WHITE, 1)
    else:
        var tint: Color = COLORS[variant]
        var fade := minf(1, age / 15.0) * minf(1, (100 - age) / 20.0)
        if age < 30:
            draw_arc(Vector2(0, -2), 23, 0, TAU, 32, Color(tint, fade), 2)
        if texture != null:
            var lean := -0.12 if age < 50 else 0.2
            var offset := sin(clampf((age - 40) / 20.0, 0, 1) * PI) * 15
            draw_set_transform(Vector2(offset * direction, -sin(age / 100.0 * PI) * (25 if variant == 3 else 4)), lean * direction, Vector2(direction, 1))
            var frame := source
            if source.size.x == 384 and age >= 45:
                frame.position.x = (3 if variant % 2 == 0 else 0) * 384
                if variant % 2 == 1:
                    frame.position.y = 512
            draw_texture_rect_region(texture, Rect2(-39, -108, 78, 108), frame, Color(1, 1, 1, fade))
            draw_set_transform(Vector2.ZERO)
        if age >= 45 and age < 76:
            var extent := clampf((age - 45) / 12.0, 0, 1) * 83
            if variant in [1, 4, 6]:
                for i in (6 if variant == 6 else 1):
                    draw_line(Vector2(direction * 20, -75 + i * 3), Vector2(direction * extent, -75 + i * 3), Color(tint, fade), 2)
            elif variant in [3, 8, 9, 10]:
                draw_arc(Vector2(direction * 24, -55), extent * 0.7, -1.3, 1.3, 30, Color(tint, fade), 3)
            else:
                draw_circle(Vector2(direction * extent, -65), 10, Color(tint, fade * 0.8))
        draw_string(ThemeDB.fallback_font, Vector2(-75, -123), Roster.NAMES[Roster.IDS[variant]], HORIZONTAL_ALIGNMENT_LEFT, 150, 8, Color(tint, fade))

func digest() -> Array:
    return [kind, attacker.team, age, struck, variant, direction, power, roundi(position.x * 1000), roundi(position.y * 1000), roundi(vertical_speed * 1000)]
