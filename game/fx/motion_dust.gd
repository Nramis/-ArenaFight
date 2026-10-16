extends Node2D
var age := 0.0
func _ready() -> void:
	add_to_group("ability_effect")
func _process(delta: float) -> void:
	age += delta
	if age > 0.3:
		queue_free()
	queue_redraw()
func _draw() -> void:
	for i in 6:
		var side := -1.0 if i%2 == 0 else 1.0
		var point := Vector2(side*(6+i*2+age*35),-sin(age*7)*(2+i))
		draw_circle(point,1+i*0.2,Color(0.7,0.8,0.85,(1-age/0.3)*0.35))
