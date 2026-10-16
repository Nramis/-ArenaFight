extends Node2D
var text := ""
var blocked := false
var age := 0.0
func _ready() -> void:
	add_to_group("ability_effect")
func _process(delta: float) -> void:
	age += delta
	if age > 0.65:
		queue_free()
	queue_redraw()
func _draw() -> void:
	var color := Color("9edee9") if blocked else Color("ffdaaa")
	color.a = minf(1,(0.65-age)*4)
	draw_string(ThemeDB.fallback_font,Vector2(-24,-age*24),text,HORIZONTAL_ALIGNMENT_CENTER,48,9,color)
	if age < 0.18:
		for i in 7:
			var direction := Vector2(cos(i*TAU/7),sin(i*TAU/7))
			draw_line(direction*(4+age*40),direction*(9+age*90),color,1.5)
