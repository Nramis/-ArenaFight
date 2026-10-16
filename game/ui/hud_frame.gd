extends Node2D
# Code-native chrome, kept outside simulation and collision.
func _draw() -> void:
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("101722e8")
	plate.border_color = Color("485264")
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(4)
	for x in [8.0,216.0]:
		draw_style_box(plate,Rect2(x,4,162,46))
	var clock := StyleBoxFlat.new()
	clock.bg_color = Color("202a33")
	clock.border_color = Color("d6fc63")
	clock.set_border_width_all(1)
	clock.set_corner_radius_all(5)
	draw_style_box(clock,Rect2(174,5,36,28))
	for x in [12.0,220.0]:
		for i in 5:
			draw_line(Vector2(x+i*30.8,8),Vector2(x+i*30.8,20),Color(0,0,0,0.16),0.5)
