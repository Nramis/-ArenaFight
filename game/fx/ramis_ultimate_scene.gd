class_name RamisUltimateScene
extends Node2D

const FONT = preload("res://assets/fonts/Manrope.ttf")
var attacker: Fighter
var victim: Fighter
var victim_texture: Texture2D
var victim_region := Rect2()
var portrait: Texture2D
var crater_texture: Texture2D

func _ready() -> void:
    add_to_group("ability_effect")
    z_index = 12
    portrait = load("res://assets/ramis-hero/portrait.png")
    if ResourceLoader.exists("res://assets/ramis-hero/crater.png"):
        crater_texture = load("res://assets/ramis-hero/crater.png")
    var path := "res://assets/motion/" + victim.roster_name() + ".png"
    var columns := 4
    var rows := 2
    var index := 6
    if not ResourceLoader.exists(path):
        path = "res://assets/rinat/rinat-base.png" if victim.roster_name() == "rinat" else "res://assets/" + victim.roster_name() + ".png"
        columns = 8 if victim.roster_name() == "rinat" else 4
        rows = 4
        index = 0
    victim_texture = load(path)
    if victim_texture != null:
        var cell := Vector2(victim_texture.get_size()) / Vector2(columns, rows)
        victim_region = Rect2(Vector2((index % columns) * cell.x, (index / columns) * cell.y), cell)

func _process(_delta: float) -> void:
    if not is_instance_valid(attacker) or not is_instance_valid(victim):
        queue_free()
        return
    var hero := attacker.abilities.expansion.hero
    if hero.age < 0:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    if not is_instance_valid(attacker) or not is_instance_valid(victim):
        return
    var hero := attacker.abilities.expansion.hero
    var age := hero.age
    if age < 0:
        return
    if hero.active():
        var dim := .34 if age < RamisUltimate.SLAM else .16
        draw_rect(Rect2(0, 51, 384, 165), Color(.02, .025, .05, dim))
    # Draw the opponent above the hole before impact; afterward bury the lower
    # half behind the broken rim. The actual fighter remains hidden, not deleted.
    if victim_texture != null:
        var pos := victim.position
        var rotation_value := 0.0
        if age >= RamisUltimate.SLAM and age < RamisUltimate.IMPACT:
            rotation_value = clampf((age - RamisUltimate.SLAM) / 18.0, 0, 1) * 1.15 * hero.direction
        elif age >= RamisUltimate.IMPACT:
            pos = hero.impact + Vector2(0, 15)
            rotation_value = 1.48 * hero.direction
        if age >= RamisUltimate.IMPACT + 12:
            # Only the head and upper torso remain above the broken ground.
            var upper := Rect2(victim_region.position, Vector2(victim_region.size.x, victim_region.size.y * .55))
            draw_set_transform(hero.impact + Vector2(0,15), 0, Vector2(-hero.direction,1))
            draw_texture_rect_region(victim_texture, Rect2(-18,-49,36,27), upper, Color(1,.88,.8))
        else:
            var shrink := 1.0
            if age >= RamisUltimate.IMPACT:
                var bury := smoothstep(0, 1, clampf((age-RamisUltimate.IMPACT)/12.0, 0, 1))
                shrink = lerpf(1.0,.45,bury)
                rotation_value = 1.48 * hero.direction * (1-bury)
                pos = hero.impact + Vector2(0,15)
            draw_set_transform(pos, rotation_value, Vector2(-hero.direction, 1)*shrink)
            draw_texture_rect_region(victim_texture, Rect2(-40, -109, 80, 109), victim_region, Color(1, .88, .8))
        draw_set_transform(Vector2.ZERO)
    if hero.crater_active:
        _crater(hero)
    if hero.active():
        var pose := RamisHeroAtlas.attack_pose(age)
        RamisHeroAtlas.draw_pose(self, pose[0], pose[1], attacker.position, hero.direction)
        _speed_and_impact(hero)
        if age < 58:
            _cut_in(age)
        if age >= 58 and age < RamisUltimate.SLAM:
            draw_rect(Rect2(76, 52, 232, 15), Color(.03, .025, .035, .88))
            draw_string(FONT, Vector2(106, 63), "СЕРЬЁЗНЫЙ УДАР", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffe899"))

func _cut_in(age: int) -> void:
    var enter := smoothstep(0, 1, clampf(age / 9.0, 0, 1))
    var leave := smoothstep(0, 1, clampf((age - 43) / 15.0, 0, 1))
    var x := -155 * (1 - enter) - 160 * leave
    draw_colored_polygon(PackedVector2Array([Vector2(x-5, 71),Vector2(x+142, 60),Vector2(x+129, 171),Vector2(x-5, 183)]), Color("120f18ed"))
    draw_colored_polygon(PackedVector2Array([Vector2(x-5, 77),Vector2(x+135, 66),Vector2(x+123, 165),Vector2(x-5, 177)]), Color("b47a18ed"))
    if portrait != null:
        draw_texture_rect(portrait, Rect2(x-13, 65, 159, 113), false)
    for i in 7:
        var y := 78 + i * 14
        draw_line(Vector2(x+2, y), Vector2(x+123, y-9), Color(1, .86, .36, .17), 1)
    draw_line(Vector2(x-3, 73), Vector2(x+140, 62), Color("fff1a2"), 2)
    draw_line(Vector2(x-3, 181), Vector2(x+130, 169), Color("fff1a2"), 2)
    draw_string(FONT, Vector2(x+5, 165), "РАМИС · ОДИН УДАР", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)

func _speed_and_impact(hero: RamisUltimate) -> void:
    var age := hero.age
    if age >= RamisUltimate.DRIVE and age < RamisUltimate.IMPACT:
        for i in 14:
            var y := 71 + i * 8
            var x := fmod(age * 19 + i * 37, 380)
            draw_line(Vector2(x, y), Vector2(x - hero.direction * (22 + i % 4 * 9), y+2), Color(1, .89, .55, .28), 1)
        draw_arc(attacker.position + Vector2(hero.direction * 20, -56), 42, -.9, .9, 26, Color(1, .86, .3, .55), 2)
    var elapsed := age - RamisUltimate.IMPACT
    if elapsed >= 0 and elapsed < 9:
        draw_rect(Rect2(0, 51, 384, 165), Color(1, .97, .85, .62 * (1 - elapsed / 9.0)))
    if elapsed >= 0 and elapsed < 38:
        var t := elapsed / 38.0
        draw_set_transform(hero.impact + Vector2(0,-2), 0, Vector2(1,.28))
        draw_arc(Vector2.ZERO, 12 + t * 146, 0, TAU, 64, Color(1,.9,.6,1-t), 3)
        draw_arc(Vector2.ZERO, 8 + t * 109, 0, TAU, 64, Color(.91,.96,1,(1-t)*.7), 1.5)
        draw_set_transform(Vector2.ZERO)
    if elapsed >= 0 and elapsed < 70:
        for i in 18:
            var vx := (i % 2 * 2 - 1) * (28 + (i * 19 % 90))
            var time := elapsed / 60.0
            var pos := hero.impact + Vector2(vx * time, -(55+i*7%95)*time + 105*time*time)
            var size := 2.0 + i % 4
            var rock := PackedVector2Array([pos+Vector2(-size,-size*.6),pos+Vector2(size,-size),pos+Vector2(size*.7,size),pos+Vector2(-size*.7,size*.6)])
            draw_colored_polygon(rock, Color(.44,.48,.52,1-elapsed/80.0))
        for i in 8:
            var time := elapsed/70.0
            var pos := hero.impact + Vector2((i-3.5)*(7+time*15),-time*22)
            draw_circle(pos, 6+time*12, Color(.74,.69,.58,(1-time)*.13))

func _crater(hero: RamisUltimate) -> void:
    var center := hero.impact + Vector2(0, 3)
    if crater_texture != null:
        draw_texture_rect(crater_texture, Rect2(center+Vector2(-77,-16),Vector2(154,39)), false)
        return
    # Fixed irregular geometry keeps the visual stable during network stalls.
    for i in 13:
        var angle := i * TAU / 13.0
        var ray := Vector2(cos(angle), sin(angle)*.22)
        var a := center + ray * (30 + i%3*4)
        var b := center + ray * (67 + i*11%21)
        var c := b + Vector2((i%2*2-1)*8, (i%3-1)*4)
        draw_polyline(PackedVector2Array([a,b,c]), Color("11161ee6"), 1.4)
    var rim := PackedVector2Array()
    var hole := PackedVector2Array()
    for i in 28:
        var angle := i * TAU / 28.0
        rim.append(center + Vector2(cos(angle)*(53+i%3*3), sin(angle)*(10+i%2*2)))
        hole.append(center + Vector2(cos(angle)*43, sin(angle)*8))
    draw_colored_polygon(rim, Color("616975"))
    draw_colored_polygon(hole, Color("10141d"))
    for i in 14:
        var angle := i * TAU / 14
        var pos := center + Vector2(cos(angle)*50,sin(angle)*11)
        draw_line(pos, pos+Vector2(5+i%3, -2-i%2), Color("a7acb1"), 2)
