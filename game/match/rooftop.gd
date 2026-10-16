extends Node2D
var backdrop: Texture2D

func _ready() -> void:
	if GameConfig.stage_id != "rooftop":
		backdrop = load("res://assets/arenas/"+GameConfig.stage_id+".png")


func _draw() -> void:
	if backdrop != null:
		draw_texture_rect(backdrop,Rect2(0,0,384,216),false)
		# Clear text overlays are rendered by the game instead of baked into art.
		if GameConfig.stage_id == "taneko":
			draw_string(ThemeDB.fallback_font,Vector2(133,108),"ТАНЕКО",HORIZONTAL_ALIGNMENT_CENTER,71,15,Color("183234"))
		else:
			draw_string(ThemeDB.fallback_font,Vector2(306,56),"ТАТНЕФТЬ",HORIZONTAL_ALIGNMENT_CENTER,52,9,Color("174d39"))
		draw_rect(Rect2(0,180,384,36),Color(0.03,0.06,0.09,0.17))
		draw_line(Vector2(0,180),Vector2(384,180),Color(0.8,0.9,0.9,0.3),0.7)
		return
	draw_rect(Rect2(-100,-100,600,400), Color("101828"))
	for i in range(20):
		var x := float(i * 29 - 60)
		var h := float(30 + (i * 37) % 65)
		draw_rect(Rect2(x,155-h,25,h),Color("1a2940"))
		for col in range(3):
			for row in range(2, int(h/8)):
				if (col+row+i)%3 != 0:
					draw_rect(Rect2(x+4+col*7,155-h+row*7,2,3),Color("3d5970") if i%3 else Color("927b50"))
	draw_circle(Vector2(295,52),14,Color("c3d6d4"))
	draw_circle(Vector2(300,48),13,Color("101828"))
	draw_rect(Rect2(-60,148,510,32),Color("243448"))
	for i in range(23):
		draw_line(Vector2(i*20-40,151),Vector2(i*20-40,178),Color("344459"),1)
	draw_rect(Rect2(-60,146,510,3),Color("41667a"))
	draw_rect(Rect2(-60,180,510,90),Color("182635"))
	for i in range(17):
		draw_line(Vector2(192+(i-8)*18,180),Vector2(192+(i-8)*32,250),Color("2a3c4c"),0.5)
	for y in [185,195,210,234]:
		draw_line(Vector2(-50,y),Vector2(440,y),Color("2a3c4c"),0.5)
	draw_line(Vector2(-40,179),Vector2(430,179),Color("7b949e"),1)
	# Rooftop access room, windows and light strips.
	draw_rect(Rect2(4,88,60,59),Color("293c4f"))
	draw_rect(Rect2(13,99,24,47),Color("111c2a"))
	draw_rect(Rect2(41,100,14,18),Color("72a1a2"))
	draw_line(Vector2(5,88),Vector2(63,88),Color("85e0de"),2)
	draw_rect(Rect2(321,115,55,30),Color("304253"))
	for i in range(6):
		draw_line(Vector2(327,120+i*4),Vector2(369,120+i*4),Color("172636"),1)
	draw_line(Vector2(337,112),Vector2(366,112),Color("e9a472"),2)
