extends Node2D
var fighter: Fighter
var clock := 0.0
func _ready() -> void:
	add_to_group("ability_effect")
	z_index = 16
func _process(delta: float) -> void:
	if not is_instance_valid(fighter) or fighter.abilities.stun_frames == 0:
		queue_free()
		return
	if not fighter.frozen:
		clock += delta
	position = fighter.position+Vector2(0,-111)*fighter.abilities.size_multiplier()
	queue_redraw()
func _draw() -> void:
	for i in 3:
		var p := Vector2(cos(clock*3+i*TAU/3)*17,sin(clock*3+i*TAU/3)*4)
		draw_line(p-Vector2(3,0),p+Vector2(3,0),Color("ffe7a0"),1.5)
		draw_line(p-Vector2(0,3),p+Vector2(0,3),Color("ffe7a0"),1.5)
