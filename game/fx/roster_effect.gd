extends Node2D

var kind := "burger"
var attacker: Fighter
var target: Fighter
var direction := 1
var variant := 0
var age := 0
var origin := Vector2.ZERO
var has_hit := false
var power := 1.0

func _ready() -> void:
	add_to_group("ability_effect")
	origin = attacker.position + Vector2(direction*18,-84 if kind == "word" else -65)
	if kind == "sunbeam":
		origin = attacker.position + Vector2(direction*15,-88)*attacker.abilities.size_multiplier()
	elif kind == "critter":
		origin = attacker.position + Vector2(-direction*22,-7)
	position = origin
	power = attacker.abilities.damage_multiplier()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		queue_free()
		return
	if attacker.frozen:
		return
	age += 1
	if kind == "sunbeam":
		if age == 18 and not has_hit:
			has_hit = true
			var dx := (target.position.x-position.x)*direction
			var ray_y := position.y + dx/340.0*15.0
			if dx >= 0 and dx <= 340 and target.hurtbox_rect().has_point(Vector2(target.position.x,ray_y)):
				_hit_target(105,230)
		if age > 40:
			queue_free()
		queue_redraw()
		return
	if kind == "critter":
		visible = age >= variant*8
		if not visible:
			return
		direction = 1 if target.position.x >= position.x else -1
		position.x += direction*125*delta
		position.y = 173.0-absf(sin(age*0.35))*3
		if not has_hit and Rect2(position-Vector2(9,8),Vector2(18,16)).intersects(target.hurtbox_rect()) and not target.is_invulnerable():
			has_hit = true
			_hit_target(18,65)
			queue_free()
		if age > 240:
			queue_free()
		queue_redraw()
		return
	if kind == "burger" and age < variant*5:
		visible = false
		return
	visible = true
	position.x += direction*(210.0 if kind == "burger" else 175.0)*delta
	position.y = origin.y + sin(age*0.1)*3 + (variant-2)*10 if kind == "burger" else origin.y + sin(age*0.08)*5
	if not has_hit and Rect2(position-Vector2(13,10),Vector2(26,20)).intersects(target.hurtbox_rect()) and not target.is_invulnerable():
		has_hit = true
		if kind == "word":
			target.abilities.add_slow()
		else:
			var move := MoveData.new()
			move.damage = int(round(22*power))
			move.pushback = 100
			move.hitstun = 12
			if target.is_blocking(move):
				target.receive_block(move,direction)
			else:
				target.receive_hit(move,direction)
			attacker.get_parent()._on_hit(target)
		queue_free()
	elif age > 140 or position.x < -40 or position.x > 424:
		queue_free()
	queue_redraw()

func _hit_target(damage: int, push: float) -> void:
	if target.is_invulnerable():
		return
	var move := MoveData.new()
	move.damage = int(round(damage*power))
	move.pushback = push
	move.hitstun = 20
	if target.is_blocking(move):
		target.receive_block(move,direction)
	else:
		target.receive_hit(move,direction)
	attacker.get_parent()._on_hit(target)

func _draw() -> void:
	if kind == "sunbeam":
		var strength := 0.35 if age < 16 else minf(1.0,(41-age)/15.0)
		var gold := Color(1,0.88,0.4,strength)
		draw_line(Vector2(-direction*45,-180),Vector2.ZERO,gold,3)
		draw_circle(Vector2.ZERO,5+sin(age*0.6)*2,Color(1,1,0.8,strength))
		for i in 4:
			var ray := Vector2(cos(i*PI/2.0+0.4),sin(i*PI/2.0+0.4))*12
			draw_line(-ray,ray,gold,1.5)
		if age >= 16:
			draw_line(Vector2.ZERO,Vector2(direction*340,15),gold,6)
			draw_line(Vector2.ZERO,Vector2(direction*340,15),Color(1,1,0.95,strength),2)
	elif kind == "critter":
		var bounce := sin(age*0.45)*3
		draw_circle(Vector2.ZERO,7,Color("b7334b"))
		draw_circle(Vector2(-2,-3),5,Color("ed6070"))
		for side in [-1,1]:
			draw_line(Vector2(side*3,4),Vector2(side*7,9+side*bounce),Color("e6a3a4"),2)
			draw_circle(Vector2(direction*2+side*2,-2),1.7,Color.WHITE)
			draw_circle(Vector2(direction*3+side*2,-2),0.8,Color("29141f"))
	elif kind == "burger":
		draw_arc(Vector2(0,0),8,PI,TAU,20,Color("e8b45f"),4)
		draw_rect(Rect2(-9,-1,18,3),Color("81b954"))
		draw_rect(Rect2(-8,2,16,3),Color("63372b"))
		draw_rect(Rect2(-8,5,16,3),Color("e9b468"))
		for x in [-4,0,4]:
			draw_circle(Vector2(x,-5),0.7,Color("fff1ba"))
	else:
		var words := ["СОБСТВЕННО", "ОБСУДИМ", "СОГЛАСУЕМ", "ПОЯСНЮ"]
		draw_arc(Vector2.ZERO,14,-PI/2 if direction>0 else PI/2,PI/2 if direction>0 else PI*1.5,20,Color(0.7,0.7,1,0.6),1)
		draw_string(ThemeDB.fallback_font,Vector2(-15,2),words[int(age/16)%4],HORIZONTAL_ALIGNMENT_CENTER,40,7,Color("d8ccff"))
