class_name ComboCameo
extends Node2D

const FACE = preload("res://assets/toasty-face.png")
const FONT = preload("res://assets/fonts/Manrope.ttf")
const DURATION := 1.55
const COOLDOWN := 3.0
var arena: MatchManager
var age := DURATION
var cooldown := 0.0
var pending: Dictionary = {}
var appearances := 0

func _ready() -> void:
	position = Vector2(192,306)
	visible = false

func notify_hit(victim: Fighter) -> void:
	if victim.last_hit_blocked:
		return
	if victim.combo_count < 3:
		pending.erase(victim)
		return
	pending[victim] = victim.combo_count
	if victim.state_machine.current_state.name == "Knockdown":
		show_cameo()
		pending.erase(victim)

func _physics_process(_delta: float) -> void:
	for victim: Fighter in pending.keys():
		if not is_instance_valid(victim) or victim.combo_count < 3 or victim.combo_display_frames == 0:
			pending.erase(victim)
			continue
		if victim.state_machine.current_state.name not in ["Hitstun","Attack"] or arena.match_state.phase != MatchState.FIGHT:
			show_cameo()
			pending.erase(victim)

func show_cameo() -> bool:
	if cooldown > 0:
		return false
	age = 0.0
	cooldown = COOLDOWN
	appearances += 1
	visible = true
	if arena != null and arena.sfx != null:
		arena.sfx.play_event("toasty")
	return true

func reset() -> void:
	pending.clear()
	age = DURATION
	cooldown = 0.0
	visible = false

func _process(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	if age >= DURATION:
		return
	age += delta
	visible = age < DURATION
	var slide := smoothstep(0.0,0.18,age)*(1.0-smoothstep(1.15,DURATION,age))
	position = Vector2(192,216+90*(1-slide))
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(FACE,Rect2(-39,-77,78,78),false)
	draw_string(FONT,Vector2(-51,-77),"ТВИСТИИ!",HORIZONTAL_ALIGNMENT_CENTER,104,10,Color.BLACK)
	draw_string(FONT,Vector2(-52,-78),"ТВИСТИИ!",HORIZONTAL_ALIGNMENT_CENTER,104,10,Color("d6fc63"))
