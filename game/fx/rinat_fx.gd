extends Node2D

# Reads simulation state only. No gameplay/random-number draws in rendering.
const FONT = preload("res://assets/fonts/Manrope.ttf")
var f: Fighter
var clock := 0.0
var puff: GradientTexture2D

func _ready() -> void:
    f = get_parent()
    z_index = 3
    puff = GradientTexture2D.new()
    puff.width = 64
    puff.height = 64
    puff.fill = GradientTexture2D.FILL_RADIAL
    puff.fill_from = Vector2(0.5,0.5)
    puff.fill_to = Vector2(1,0.5)
    var gradient := Gradient.new()
    gradient.offsets = PackedFloat32Array([0,0.35,0.65,1])
    gradient.colors = PackedColorArray([Color(1,1,1,0.3),Color(1,1,1,0.21),Color(0.95,0.98,1,0.08),Color(1,1,1,0)])
    puff.gradient = gradient

func _process(delta: float) -> void:
    if not f.frozen and not f.abilities.conversation_locked():
        clock += delta
    queue_redraw()

func _draw() -> void:
    if f.abilities == null or f.frozen:
        return
    var r := f.abilities.rinat
    var origin := Vector2(f.facing() * 22, -72)
    var target := f.opponent
    if r.chain_frames > 0 and r.chain_frames <= RinatAbilities.CHAIN_FLIGHT and is_instance_valid(target):
        var endpoint := target.position - f.position + Vector2(0, -58)
        var progress := 1.0 - r.chain_frames / float(RinatAbilities.CHAIN_FLIGHT)
        _chain(origin, origin.lerp(endpoint, progress), true)
    if is_instance_valid(target) and target.abilities.rinat.bound_source == f and target.abilities.rinat.bound_frames > 0:
        _chain(origin, target.position - f.position + Vector2(0, -56), false)
    if r.bound_frames > 0:
        for i in 3:
            var y := -42.0 - i * 13.0
            draw_arc(Vector2(0, y), 24, -0.15, PI + 0.2, 18, Color("b9c5cf"), 2)
            for j in 7:
                draw_arc(Vector2(-22+j*7, y+sin(j*0.8)*2), 3.5, 0, TAU, 8, Color("75899b"), 1)
    if r.chain_frames > 0 or (is_instance_valid(target) and target.abilities.rinat.bound_source == f and target.abilities.rinat.bound_frames > 0):
        _caption("Ты Орлов? Иди сюда!", Color("ffe4a5"))
    elif r.chant_frames > 0:
        _caption(RinatAbilities.CHANTS[r.chant_variant], Color("d9f478"))
    elif r.drink_frames > 0:
        _caption("ЭЛИКСИР → ПЬЯНЫЙ МАСТЕР", Color("9cebbd"))
    if r.master_frames > 0:
        for i in 4:
            var p := Vector2(sin(clock*1.5+i*1.7)*28, -fmod(clock*17+i*23, 95))
            draw_circle(p, 1.5, Color(0.8, 1, 0.4, 0.45))
        if r.tear_frames > 0:
            for i in 6:
                var progress := 1.0-r.tear_frames/36.0
                var p := Vector2((i-2.5)*progress*12, -72+progress*40)
                draw_colored_polygon(PackedVector2Array([p,p+Vector2(4,5),p+Vector2(-2,8)]), Color(1,0.85,0.4,1-progress))
    if r.smoke_frames > 0:
        var age := RinatAbilities.SMOKE_DURATION-r.smoke_frames
        var envelope := minf(1,age/15.0)*minf(1,r.smoke_frames/24.0)
        # The translucent cloud leaves the opponent and touch controls legible.
        for i in 36:
            var x := 30.0+fmod(i*29.1+age*0.7,324.0)
            var y := 55.0+fmod(i*19.3+age*0.12,120.0)
            var radius := 38.0+sin(i*1.8)*10.0
            draw_texture_rect(puff,Rect2(Vector2(x-radius,y-radius)-f.position,Vector2.ONE*radius*2),false,Color(1,1,1,envelope*0.75))
        var plume := Vector2(f.facing()*25,-82)
        for i in 7:
            var travel := fmod(clock*50+i*11,100.0)
            draw_circle(plume+Vector2(f.facing()*travel,-travel*0.22),5+travel*0.09,Color(1,1,1,0.12*envelope))

func _chain(from: Vector2, to: Vector2, spear: bool) -> void:
    var delta := to-from
    var count := maxi(1,int(delta.length()/7))
    for i in count:
        var p := from.lerp(to,float(i)/count)
        var sag := sin(float(i)/count*PI)*4
        draw_set_transform(p+Vector2(0,sag),delta.angle(),Vector2.ONE)
        draw_arc(Vector2.ZERO,3.5,0,TAU,8,Color("536779"),2)
        draw_arc(Vector2(0,-0.6),3.5,0,PI,6,Color("e6edf1"),0.7)
    draw_set_transform(Vector2.ZERO)
    if spear:
        var d := delta.normalized()
        var n := Vector2(-d.y,d.x)
        draw_colored_polygon(PackedVector2Array([to+d*8,to-d*5+n*4,to-d*2,to-d*5-n*4]),Color("ffe0a1"))

func _caption(text: String, color: Color) -> void:
    var width := minf(290,FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x+12)
    var x := clampf(f.position.x-width/2,8,376-width)-f.position.x
    var y := -118.0 if f.team == 0 else -102.0
    draw_style_box(_bubble(),Rect2(Vector2(x,y),Vector2(width,15)))
    draw_string(FONT,Vector2(x+6,y+10),text,HORIZONTAL_ALIGNMENT_LEFT,width-12,8,color)

func _bubble() -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.02,0.04,0.06,0.88)
    box.set_corner_radius_all(3)
    return box
