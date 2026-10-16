extends Node2D

const ATLAS = preload("res://assets/fighters.png")
const ABILITY_ATLAS = preload("res://assets/ability_poses.png")
# Texture polygons isolate each hand-painted pose without resampling its pixels.
const OUTLINES = [
	[Vector2(0,0),Vector2(254,0),Vector2(254,480),Vector2(0,480)],
	[Vector2(254,0),Vector2(500,0),Vector2(500,480),Vector2(254,480)],
	[Vector2(500,0),Vector2(780,0),Vector2(780,480),Vector2(500,480)],
	[Vector2(780,0),Vector2(1094,0),Vector2(1094,205),Vector2(925,205),Vector2(925,480),Vector2(780,480)],
	[Vector2(1015,200),Vector2(1255,200),Vector2(1255,355),Vector2(1228,355),Vector2(1228,480),Vector2(1015,480)],
	[Vector2(1290,0),Vector2(1536,0),Vector2(1536,480),Vector2(1228,480),Vector2(1228,365),Vector2(1290,330)]
]
const ANCHOR_X = [128.0,377.0,617.0,862.0,1135.0,1377.0]
var t: float = 0.0

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var f = get_parent()
	var ability: FighterAbilities = f.abilities
	var growth := ability.size_multiplier() if ability != null else 1.0
	var state: String = str(f.state_machine.current_state.name) if f.state_machine.current_state != null else "Idle"
	var pose := 0
	var bob := sin(t*4.0)*0.8
	var lean := 0.0
	if state in ["Walk","Dash"]:
		pose = 1
		bob = -abs(sin(t*16.0))*2.0
		lean = sin(t*16.0)*0.015
	elif state in ["Crouch","Blockstun"]:
		pose = 4
		bob = 0.0
	elif state == "Attack" and f.current_move != null:
		var move_name: String = f.current_move.move_name.to_lower()
		pose = 3 if move_name.ends_with("k") else 2
		if f.current_move.is_special:
			pose = 5 if f.current_move.spawns_projectile else 3
		if f.state_machine.current_state.state_frame < f.current_move.startup/2:
			pose = 0
		bob = 0.0
	elif state == "Hitstun":
		lean = -0.15
	elif state == "Knockdown":
		lean = -1.35
		bob = -6.0
	# Soft contact shadow stays on the ground while the fighter jumps.
	draw_set_transform(Vector2(0,maxf(0.0,180.0-f.position.y)),0,Vector2(1,0.23))
	draw_circle(Vector2.ZERO,24.0*growth,Color(0,0,0,0.25))
	draw_set_transform(Vector2(0,bob),lean*f.facing(),Vector2(float(f.facing())*growth,growth))
	var row := 0 if f.character_id == "kaze" else 1
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in OUTLINES[pose]:
		var source: Vector2 = point + Vector2(0,row*494)
		points.append(Vector2((point.x-ANCHOR_X[pose])*0.24,(point.y-451.0)*0.24))
		uv.append(source / Vector2(1536.0,1024.0))
	var tint := Color.WHITE
	if ability != null:
		if ability.rage_frames > 0:
			tint = Color(1.0,0.35,0.3)
		if ability.freeze_frames > 0:
			tint = Color(0.25,1.0,0.3)
		if ability.energy_frames > 0:
			for i in range(4):
				draw_line(Vector2(-20-i*5,-28-i*15),Vector2(-30-i*6,-28-i*15),Color(0.4,0.95,1.0,0.55),1.0)
		if ability.rage_frames > 0:
			for i in range(6):
				var a := t*3.0+i
				draw_line(Vector2(sin(a)*25,-10-i*14),Vector2(sin(a)*28,-20-i*14),Color(1,0.2,0.1,0.5),1.5)
		if ability.cast_frames > 0:
			var slot := ability.cast_slot
			var outline := PackedVector2Array([Vector2(0,0),Vector2(495,0),Vector2(495,1024),Vector2(0,1024)])
			if slot == 1:
				outline = PackedVector2Array([Vector2(500,0),Vector2(975,0),Vector2(975,400),Vector2(944,400),Vector2(944,850),Vector2(975,850),Vector2(975,1024),Vector2(500,1024)])
			var drink_points := PackedVector2Array()
			var drink_uv := PackedVector2Array()
			for point in outline:
				drink_points.append(Vector2((point.x-(256.0+slot*512))*0.12,(point.y-930.0)*0.12))
				drink_uv.append(point/Vector2(1536,1024))
			draw_colored_polygon(drink_points,tint,drink_uv,ABILITY_ATLAS)
			draw_set_transform(Vector2.ZERO)
			return
	if state == "Hitstun":
		tint = Color(1.0,0.65,0.65)
	elif state == "Blockstun":
		tint = Color(0.6,0.95,1.0)
	if ability != null and ability.freeze_frames > 0:
		tint = Color(0.25,1.0,0.3)
	draw_colored_polygon(points,tint,uv,ATLAS)
	if ability != null and ability.freeze_frames > 0:
		draw_arc(Vector2(0,-48),47,0,TAU,40,Color(0.4,1.0,0.3,0.4),2)
		for i in range(5):
			draw_circle(Vector2(sin(i*2.3+t)*24,-15-i*17),2,Color(0.6,1,0.5,0.65))
	if ability != null and ability.pose_frames > 0 and ability.pose_kind == "mouth":
		draw_circle(Vector2(8,-83),2.2,Color("172f46"))
		draw_arc(Vector2(10,-83),7,-PI/2,PI/2,12,Color(0.6,0.9,1),1.5)
	draw_set_transform(Vector2.ZERO)
