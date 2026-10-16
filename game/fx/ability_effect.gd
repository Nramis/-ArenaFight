extends Node2D

const SUMMON_ATLAS = preload("res://assets/ability_poses.png")
var kind := "wave"
var attacker: Fighter
var target: Fighter
var direction := 1
var age := 0
var has_hit := false
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var damage_scale := 1.0

func _ready() -> void:
	add_to_group("ability_effect")
	damage_scale = attacker.abilities.damage_multiplier()
	if kind == "wave":
		position = attacker.position + Vector2(direction * 10.0, -86.0) * attacker.abilities.size_multiplier()
	elif kind == "trap":
		origin = attacker.position + Vector2(direction * 20.0, -65.0)
		destination = Vector2(clampf(attacker.position.x + direction * 105.0,40.0,344.0),170.0)
		position = origin
	else:
		position = Vector2(clampf(target.position.x - direction * 38.0,30.0,354.0),180.0)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		queue_free()
		return
	if attacker.frozen:
		return
	age += 1
	if kind == "wave":
		position.x += direction * 310.0 * delta
		var radius := 14.0 + minf(age * 0.5, 18.0)
		if not has_hit and Rect2(position-Vector2(10,radius),Vector2(20,radius*2)).intersects(target.hurtbox_rect()):
			has_hit = true
			deal_damage(65,520.0)
			queue_free()
		elif age > 80 or position.x < -40 or position.x > 424:
			queue_free()
	elif kind == "trap":
		if age <= 25:
			var u := age / 25.0
			position = origin.lerp(destination,u) + Vector2(0,-sin(u*PI)*25.0)
		# Thrown sphere becomes a persistent proximity trap when it lands.
		if age > 25 and not has_hit and Rect2(position-Vector2(15,18),Vector2(30,36)).intersects(target.hurtbox_rect()) and not target.is_invulnerable():
			has_hit = true
			target.abilities.freeze()
			queue_free()
		elif age > 325:
			queue_free()
	else:
		if age == 14 and not has_hit:
			has_hit = true
			var hit_area := Rect2(position + Vector2(-42,-76),Vector2(84,76))
			if hit_area.intersects(target.hurtbox_rect()):
				deal_damage(105,280.0)
		if age > 40:
			queue_free()
	queue_redraw()

func deal_damage(base_damage: int, push: float) -> void:
	if target.is_invulnerable():
		return
	var move := MoveData.new()
	move.damage = int(round(base_damage * damage_scale))
	move.pushback = push
	move.hitstun = 27
	move.blockstun = 14
	move.is_special = true
	if target.is_blocking(move):
		target.receive_block(move,direction)
	else:
		target.receive_hit(move,direction)
	var manager = attacker.get_parent()
	if manager.has_method("_on_hit"):
		manager._on_hit(target)

func _draw() -> void:
	if kind == "wave":
		var radius := 14.0 + minf(age * 0.5,18.0)
		for i in range(3):
			draw_arc(Vector2(-direction*i*7,0),radius-i*3,-PI/2 if direction>0 else PI/2,PI/2 if direction>0 else PI*1.5,24,Color(0.65,0.9,1.0,0.9-i*0.23),2.0)
	elif kind == "trap":
		var pulse := 1.0 + sin(age*0.15)*0.12
		draw_circle(Vector2.ZERO,17*pulse,Color(0.2,1,0.25,0.15))
		draw_circle(Vector2.ZERO,10*pulse,Color(0.2,0.9,0.3,0.7))
		draw_arc(Vector2.ZERO,12*pulse,0,TAU,32,Color(0.7,1,0.6,0.9),1.5)
		draw_circle(Vector2(-3,-3),3,Color(0.9,1,0.8,0.8))
		if age > 25:
			draw_arc(Vector2(0,6),19,0,TAU,32,Color(0.4,1,0.4,0.45),1)
	else:
		var opacity := minf(age / 5.0, minf((41-age)/10.0,1.0))
		if age < 10:
			draw_circle(Vector2(0,-35),35-age*2,Color(0.7,1,0.5,0.25))
		draw_set_transform(Vector2(direction*(age-14)*0.5,0),0,Vector2(float(direction),1))
		draw_texture_rect_region(SUMMON_ATLAS,Rect2(-45,-94,90,98),Rect2(945,225,591,625),Color(1,1,1,opacity))
