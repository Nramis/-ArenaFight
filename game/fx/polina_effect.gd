extends Node2D
var kind := "rain"
var attacker: Fighter
var target: Fighter
var variant := 0
var age := 0
var center_x := 192.0
var power := 1.0
var drops: Array[Dictionary] = []
var spawned := 0
const OFFSETS = [0,-38,38,-16,16,-55,55,0,-28,28,-46,46]

func _ready() -> void:
	add_to_group("ability_effect")
	z_index = 15
	center_x = clampf(target.position.x,66,318)
	power = attacker.abilities.damage_multiplier()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		queue_free()
		return
	if attacker.frozen:
		return
	age += 1
	# Interrupt the preparation before the shower or gesture happens.
	if age < (26 if kind == "rain" else 18) and attacker.abilities.pose_frames == 0:
		queue_free()
		return
	if kind == "rain":
		_tick_rain(delta)
	else:
		if age == 18 and attacker.abilities.pose_kind == "random_gesture" and attacker.abilities.pose_frames > 0:
			var distance := target.position-attacker.position
			if absf(distance.x) <= 145 and absf(distance.y) <= 90 and not target.is_invulnerable():
				target.abilities.stun(180)
		if age > 65:
			queue_free()
	queue_redraw()

func _tick_rain(delta: float) -> void:
	if age >= 26 and spawned < OFFSETS.size() and (age-26)%8 == 0:
		drops.append({"x":center_x+OFFSETS[spawned],"y":-24.0,"kind":spawned%2,"hit":false,"speed":220.0+(spawned%3)*18})
		spawned += 1
	for drop in drops:
		if drop.hit:
			continue
		drop.y += drop.speed*delta
		var rect := Rect2(float(drop.x)-5,float(drop.y)-9,10,18)
		if not target.is_invulnerable() and rect.intersects(target.hurtbox_rect()):
			drop.hit = true
			var move := MoveData.new()
			move.damage = int(round(14*power))
			move.hitstun = 4
			move.pushback = 20
			move.hits_overhead = true
			var direction := 1 if target.position.x >= attacker.position.x else -1
			if target.is_blocking(move):
				target.receive_block(move,direction)
			else:
				target.receive_hit(move,direction)
			attacker.get_parent()._on_hit(target)
		elif drop.y > 183:
			drop.hit = true
	if age > 200:
		queue_free()

func _draw() -> void:
	if kind == "rain":
		if age < 26:
			draw_arc(Vector2(center_x,178),56,0,TAU,40,Color(0.8,0.85,1,0.6),1.5)
			draw_string(ThemeDB.fallback_font,Vector2(center_x-38,165),"ОСАДКИ",HORIZONTAL_ALIGNMENT_CENTER,76,8,Color("d6dbf7"))
		for i in 5:
			draw_circle(Vector2(center_x-42+i*21,3+sin(i*2)*3),14,Color(0.3,0.35,0.5,0.7))
		for drop in drops:
			if drop.hit:
				continue
			draw_set_transform(Vector2(drop.x,drop.y),0.22*sin(age*0.06+drop.x))
			if drop.kind == 0:
				draw_rect(Rect2(-2,-9,4,18),Color("f6f1e4"))
				draw_rect(Rect2(-2,3,4,6),Color("c59259"))
				draw_line(Vector2(-2,-9),Vector2(2,-9),Color("fb7f52"),2)
			else:
				draw_rect(Rect2(-4,-7,8,14),Color("a7bce4"))
				draw_rect(Rect2(-2,-11,4,4),Color("263348"))
				draw_circle(Vector2(0,3),1.5,Color("adffe6"))
			draw_set_transform(Vector2.ZERO)
	else:
		var p := attacker.position+Vector2(attacker.facing()*37,-113)
		var text: String = ["♥","?!","ХА!"][variant]
		draw_circle(p,15,Color(0.3,0.17,0.4,0.8))
		draw_string(ThemeDB.fallback_font,p+Vector2(-18,5),text,HORIZONTAL_ALIGNMENT_CENTER,36,16,Color("f0b6d9"))
