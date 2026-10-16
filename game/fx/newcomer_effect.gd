extends Node2D

var kind := "dog"
var attacker: Fighter
var target: Fighter
var direction := 1
var variant := 0
var age := 0
var launched := false
var has_hit := false
var power := 1.0

func _ready() -> void:
	add_to_group("ability_effect")
	position = attacker.position
	power = attacker.abilities.damage_multiplier()
	visible = false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		queue_free()
		return
	if attacker.frozen:
		return
	age += 1
	var delay := variant * (7 if kind == "rifle_bullet" else 12)
	if age <= delay:
		return
	if not launched:
		launched = true
		if kind in ["bullet","rifle_bullet"]:
			attacker.emit_sound("pistol" if kind == "bullet" else "rifle")
		visible = true
		position = attacker.position + Vector2(direction*26,-68)*attacker.abilities.size_multiplier()
		if kind in ["dog","schoolkid"]:
			position = attacker.position + Vector2(-direction*(24+variant*5),0)
	if kind in ["dog","schoolkid"]:
		direction = 1 if target.position.x >= position.x else -1
		position.x += direction*(150 if kind == "dog" else 115)*delta
		position.y = 180
	else:
		position.x += direction*(190 if kind == "negative" else 460)*delta
	var collision := Rect2(position+Vector2(-12,-24),Vector2(24,24)) if kind in ["dog","schoolkid"] else Rect2(position-Vector2(10,6),Vector2(20,12))
	if not has_hit and not target.is_invulnerable() and collision.intersects(target.hurtbox_rect()):
		has_hit = true
		if kind == "negative":
			target.abilities.shrink()
		else:
			var move := MoveData.new()
			move.damage = int(round(({"bullet":65,"rifle_bullet":14,"dog":28,"schoolkid":18}[kind])*power))
			move.pushback = 65
			move.hitstun = 12
			if target.is_blocking(move):
				target.receive_block(move,direction)
			else:
				target.receive_hit(move,direction)
			attacker.get_parent()._on_hit(target)
		queue_free()
	if age > 240 or position.x < -50 or position.x > 434:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if kind in ["bullet","rifle_bullet"]:
		draw_line(Vector2(-direction*12,0),Vector2(direction*4,0),Color("ffda7d"),2)
		draw_circle(Vector2(direction*4,0),2,Color.WHITE)
	elif kind == "negative":
		draw_arc(Vector2.ZERO,14,-1.4,1.4,14,Color("b4b5f5"),2)
		draw_string(ThemeDB.fallback_font,Vector2(-25,-3),"НУ ТАКОЕ...",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ddd6ff"))
	elif kind == "dog":
		draw_set_transform(Vector2.ZERO,0,Vector2(direction,1))
		var fur := Color("b78b5f") if variant%2 == 0 else Color("e5d4b7")
		draw_rect(Rect2(-14,-17,24,11),fur)
		draw_circle(Vector2(11,-19),7,fur)
		draw_colored_polygon(PackedVector2Array([Vector2(7,-23),Vector2(9,-32),Vector2(14,-24)]),Color("70533e"))
		draw_line(Vector2(-13,-15),Vector2(-21,-24),fur,4)
		draw_circle(Vector2(14,-21),1.4,Color("22202c"))
		draw_circle(Vector2(18,-17),2,Color("22202c"))
		for i in 4:
			var x := -10+i*5
			draw_line(Vector2(x,-7),Vector2(x+sin(age*0.7+i)*5,-1),fur,3)
	else:
		# A playful crowd of backpack-wearing cartoon summons.
		draw_set_transform(Vector2.ZERO,0,Vector2(direction,1))
		var shirt: Color = [Color("78c6f0"),Color("efbc67"),Color("ad94ee"),Color("e98eab"),Color("83d4ac")][variant%5]
		var stride := sin(age*0.5)*4
		draw_rect(Rect2(-9,-25,7,13),Color("587ab4"))
		draw_rect(Rect2(-5,-27,12,16),shirt)
		draw_circle(Vector2(1,-33),7,Color("f2c6a4"))
		draw_arc(Vector2(1,-35),6,PI,TAU,12,Color("6d4c39"),3)
		draw_line(Vector2(-2,-11),Vector2(-4+stride,0),Color("35445b"),4)
		draw_line(Vector2(4,-11),Vector2(5-stride,0),Color("35445b"),4)
		draw_line(Vector2(5,-24),Vector2(12,-18-stride),Color("f2c6a4"),3)
		draw_set_transform(Vector2.ZERO)
		draw_string(ThemeDB.fallback_font,Vector2(-16,-46-absf(sin(age*0.1))*5),"тик ток",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("8ff3e5"))
