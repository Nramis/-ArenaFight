extends Node2D
var attacker: Fighter
var target: Fighter
var age := 0
var power := 1.0
var impact_done := false

func _ready() -> void:
	add_to_group("ability_effect")
	z_index = 15
	position = Vector2(clampf(target.position.x,40,344),180)
	power = attacker.abilities.damage_multiplier()

func zone_rect() -> Rect2:
	return Rect2(position+Vector2(-38,-65),Vector2(76,65))

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		queue_free()
		return
	if attacker.frozen:
		return
	age += 1
	if age >= 30 and (age-30)%60 == 0 and zone_rect().intersects(target.hurtbox_rect()) and not target.is_invulnerable():
		if not impact_done:
			impact_done = true
			var move := MoveData.new()
			move.damage = int(round(45*power))
			move.hitstun = 10
			move.pushback = 60
			if target.is_blocking(move):
				target.receive_block(move,attacker.facing())
			else:
				target.receive_hit(move,attacker.facing())
			attacker.get_parent()._on_hit(target)
		target.abilities.ignite(180,power)
	if age >= 270:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if age < 30:
		var eye := attacker.position-position+Vector2(attacker.facing()*11,-94)*attacker.abilities.size_multiplier()
		for x in [-2,2]:
			draw_circle(eye+Vector2(x,0),4,Color(0.7,0.03,0.2,0.3))
			draw_circle(eye+Vector2(x,0),1.5,Color("ff3959"))
		draw_arc(Vector2(0,-2),34,0,TAU,32,Color(0.7,0.3,1,0.65),1)
		draw_string(ThemeDB.fallback_font,Vector2(-24,-5),"ВЗГЛЯД",HORIZONTAL_ALIGNMENT_CENTER,48,7,Color("cf99ff"))
		return
	var fade := minf(1.0,(270-age)/25.0)
	for i in 9:
		var x := -35+i*8
		var height := 23+sin(age*0.23+i*2)*10+(i%3)*8
		var points := PackedVector2Array([Vector2(x-6,0),Vector2(x-8,-height*0.45),Vector2(x-1,-height),Vector2(x+3,-height*0.5),Vector2(x+7,-height*0.72),Vector2(x+6,0)])
		draw_colored_polygon(points,Color(0.34,0.07,0.5,fade))
		draw_line(Vector2(x,0),Vector2(x-1,-height*0.68),Color(0.025,0.01,0.04,fade),5)
