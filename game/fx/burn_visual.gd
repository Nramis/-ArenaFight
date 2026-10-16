extends Node2D
var fighter: Fighter
var clock := 0.0
func _ready() -> void:
	add_to_group("ability_effect")
	z_index = 16
func _process(delta: float) -> void:
	if not is_instance_valid(fighter) or fighter.abilities.burn_frames <= 0:
		queue_free()
		return
	position = fighter.position
	visible = fighter.visible
	if not fighter.frozen:
		clock += delta
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(fighter):
		return
	var growth := fighter.abilities.size_multiplier()
	draw_set_transform(Vector2.ZERO,0,Vector2(growth,growth))
	for i in 7:
		var point := Vector2(-19+i*6,-8-fmod(clock*28+i*13,69))
		draw_line(point,point+Vector2(sin(clock*8+i)*3,-10),Color(0.5,0.12,0.7,0.8),4)
		draw_line(point,point+Vector2(0,-7),Color("130e1e"),2)
