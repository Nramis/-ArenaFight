class_name SalahovAssist
extends Node2D

const ATLAS = preload("res://assets/salahov.png")
const FONT = preload("res://assets/fonts/Manrope.ttf")
const HIT_FRAMES = [28,42,56,70,84]
const DAMAGE = [80,80,100,100,180]
var attacker: Fighter
var target: Fighter
var age := 0
var strikes := 0
var direction := 1
var power := 1.0

func _ready() -> void:
	add_to_group("ability_effect")
	z_index = 12
	direction = attacker.facing()
	position = Vector2(clampf(target.position.x-direction*76,attacker.wall_left,attacker.wall_right),attacker.ground_y)
	power = attacker.abilities.damage_multiplier()
	attacker.emit_sound("summon")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		queue_free()
		return
	if attacker.frozen:
		return
	age += 1
	direction = 1 if target.position.x >= position.x else -1
	if age < 24:
		position.x = move_toward(position.x,target.position.x-direction*48,110*delta)
	position.x = clampf(position.x,attacker.wall_left,attacker.wall_right)
	if age in HIT_FRAMES:
		var index := HIT_FRAMES.find(age)
		strikes += 1
		attacker.emit_sound("swing_heavy")
		var reach := Rect2(position+Vector2(direction*34-36,-93),Vector2(72,85))
		if not target.is_invulnerable() and reach.intersects(target.hurtbox_rect()):
			var move := MoveData.new()
			move.move_name = "Salahov"
			move.damage = int(round(DAMAGE[index]*power))
			move.hitstun = 20
			move.hitstop = 5
			move.pushback = 420 if index == 4 else 25
			move.combo_finisher = index == 4
			if target.is_blocking(move):
				target.receive_block(move,direction)
			else:
				target.receive_hit(move,direction)
			target.set_hitstop(move.hitstop)
			attacker.get_parent()._on_hit(target)
	if age >= 114:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if age < 12:
		draw_arc(Vector2.ZERO,32+age,0,TAU,32,Color("d6fc63"),2)
		draw_string(FONT,Vector2(-65,-120),"САЛАХОВ НА СВЯЗИ!",HORIZONTAL_ALIGNMENT_CENTER,130,8,Color("d6fc63"))
	var pose := 0
	if age >= 12 and age < 24:
		pose = 1+int(age/4)%2
	elif age >= 24 and age < 94:
		var index := clampi(int((age-24)/14),0,4)
		pose = [3,4,5,3,6][index] if age >= HIT_FRAMES[index]-3 and age <= HIT_FRAMES[index]+5 else 0
	elif age >= 94:
		pose = 7
	var fade := minf(1,age/12.0)*(1.0-clampf((age-100)/14.0,0,1))
	draw_set_transform(Vector2.ZERO,0,Vector2(direction,1))
	var source: Rect2 = SalahovAtlas.REGIONS[pose]
	var column := pose%4
	var anchor := float(column*384+192)
	var baseline := float(SalahovAtlas.BASELINES[pose])
	if pose == 6:
		var outline := PackedVector2Array([Vector2(768,500),Vector2(1152,500),Vector2(1152,570),Vector2(1215,570),Vector2(1215,700),Vector2(1152,700),Vector2(1152,1024),Vector2(768,1024)])
		var points := PackedVector2Array()
		var uv := PackedVector2Array()
		for p in outline:
			points.append(Vector2(p.x-anchor,p.y-baseline)*0.235)
			uv.append(p/ATLAS.get_size())
		draw_colored_polygon(points,Color(1,1,1,fade),uv,ATLAS)
	else:
		draw_texture_rect_region(ATLAS,Rect2(Vector2(source.position.x-anchor,source.position.y-baseline)*0.235,source.size*0.235),source,Color(1,1,1,fade))
	draw_set_transform(Vector2.ZERO)
