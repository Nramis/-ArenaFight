extends Node2D

const ATLAS = preload("res://assets/azat.png")
const BASELINES = [492, 490, 488, 490, 483, 481, 482, 482]
var f: Fighter
var clock := 0.0
var gait := 0.0

func _ready() -> void:
	f = get_parent().get_parent()

func _process(delta: float) -> void:
	if not f.frozen and f.hitstop_frames == 0 and f.abilities.freeze_frames == 0:
		clock += delta
		gait += absf(f.vel.x)*delta/28.0
	queue_redraw()

func _draw() -> void:
	if f == null or f.abilities == null or f.state_machine.current_state == null:
		return
	if LocomotionArt.handles(f):
		return
	var state := str(f.state_machine.current_state.name)
	var pose := 0
	var lean := 0.0
	var bob := sin(clock*3)*0.7
	var a := f.abilities
	if state in ["Walk","Dash"]:
		pose = 1+posmod(int(gait),2)
		bob = -absf(sin(gait*PI))*0.9
		lean = sin(gait*PI)*0.01
	elif state in ["Crouch","JumpStartup"] or (state == "Blockstun" and f.input.down):
		pose = 3
		bob = 0
	if a.pose_frames > 0:
		pose = {"whine":4,"complain":5,"plead":6}.get(a.pose_kind,4)
		lean = sin(clock*15)*0.025
	if state in ["Hitstun","Knockdown"] or f.health <= 0:
		pose = 7
		lean = -1.3 if state == "Knockdown" or f.health <= 0 else -0.08
	if state == "Jump":
		lean = clampf(f.vel.x/1600.0,-0.09,0.09)*f.facing()
	var growth := a.size_multiplier()
	var tint := Color(0.3,1,0.4) if a.freeze_frames > 0 else (Color(1,0.65,0.6) if state == "Hitstun" else Color.WHITE)
	if f.invuln_frames > 0 and state in ["Idle","Walk","Crouch"]:
		tint = Color(0.65,0.95,1,0.8)
	draw_set_transform(Vector2(0,maxf(0,180-f.position.y)),0,Vector2(1,0.22))
	draw_circle(Vector2.ZERO,22*growth,Color(0,0,0,0.25))
	draw_set_transform(Vector2(0,bob),lean*f.facing(),Vector2(f.facing()*growth,growth))
	var cell := Vector2(ATLAS.get_width()/4.0,ATLAS.get_height()/2.0)
	var source := Rect2(Vector2(pose%4,int(pose/4))*cell,cell)
	draw_texture_rect_region(ATLAS,Rect2(Vector2(-cell.x/2,-BASELINES[pose])*0.235,cell*0.235),source,tint)
	draw_set_transform(Vector2.ZERO)
	if a.pose_frames > 0 and state not in ["Hitstun","Knockdown"] and f.health > 0:
		var width := 100.0
		# A small local speech bubble; never a projectile or gameplay hitbox.
		draw_style_box(_bubble(),Rect2(-width/2,-136,width,20))
		draw_string(ThemeDB.fallback_font,Vector2(-width/2,-123),a.effect_name,HORIZONTAL_ALIGNMENT_CENTER,width,8,Color("b8d7ef"))
		for i in 2:
			var y := fmod(clock*22+i*8,16)
			draw_circle(Vector2(f.facing()*9+i*3,-86+y),1.2,Color(0.4,0.7,1,0.7))

func _bubble() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.035,0.07,0.12,0.9)
	box.border_color = Color("7196b3")
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	return box
