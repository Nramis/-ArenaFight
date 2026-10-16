class_name HUD
extends CanvasLayer

## HUD simple: dos barras de vida que leen la salud de cada fighter (presentación pura).
## Sustituible por un HUD con sprites/arte más adelante sin tocar la lógica.

const BAR_W := 154.0

@onready var p1_fill: ColorRect = $P1Fill
@onready var p2_fill: ColorRect = $P2Fill
@onready var timer_label: Label = $Timer
@onready var msg_label: Label = $Message
@onready var p1_pips: Label = $P1Pips
@onready var p2_pips: Label = $P2Pips

var p1: Fighter
var p2: Fighter

func set_timer(seconds: int) -> void:
	if timer_label != null:
		timer_label.text = str(seconds)

func set_rounds(a: int, b: int) -> void:
	if p1_pips != null:
		p1_pips.text = "●".repeat(a)
	if p2_pips != null:
		p2_pips.text = "●".repeat(b)

func set_message(text: String) -> void:
	if msg_label != null:
		msg_label.text = text

func setup(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b
	$P1Name.text = Roster.NAMES[p1.roster_name()]
	$P2Name.text = Roster.NAMES[p2.roster_name()]

func _process(_delta: float) -> void:
	if p1 != null and p2 != null:
		_update_combo(combo_p1,p2)
		_update_combo(combo_p2,p1)
		health_p1.text = str(p1.health)+" / "+str(p1.max_health)
		health_p2.text = str(p2.health)+" / "+str(p2.max_health)
		for pair in [[p1,trail_p1],[p2,trail_p2]]:
			var target := BAR_W*clampf(float(pair[0].health)/pair[0].max_health,0,1)
			var bar: ColorRect = pair[1]
			bar.size.x = target if target >= bar.size.x else move_toward(bar.size.x,target,_delta*65)
		trail_p2.position.x = 220+(BAR_W-trail_p2.size.x)

	if p1 != null and p1.abilities != null and status_p1 != null:
		status_p1.text = p1.rhythm.warning if p1.rhythm.warning_frames > 0 else p1.abilities.status_text()
		cooldown_p1.text = p1.abilities.cooldown_text()
		if p1.abilities.energy_frames > 0:
			status_p1.text = "ЭНЕРГИЯ · БЕЗ РАСХОДА"
	if p2 != null and p2.abilities != null and status_p2 != null:
		status_p2.text = p2.rhythm.warning if p2.rhythm.warning_frames > 0 else p2.abilities.status_text()
		cooldown_p2.text = p2.abilities.cooldown_text()
		if p2.abilities.energy_frames > 0:
			status_p2.text = "ЭНЕРГИЯ · БЕЗ РАСХОДА"
	if p1 != null:
		stamina_p1.size.x = BAR_W*p1.rhythm.stamina/100.0
		p1_fill.color = Color("ff6877") if p1.health < p1.max_health*0.25 else Color("d6fc63")
		stamina_p1.color = Color("d6fc63") if p1.abilities.energy_frames > 0 else Color("8fc5e7")
		p1_fill.size.x = BAR_W * clampf(float(p1.health) / float(p1.max_health), 0.0, 1.0)
	if p2 != null:
		stamina_p2.size.x = BAR_W*p2.rhythm.stamina/100.0
		p2_fill.color = Color("ff6877") if p2.health < p2.max_health*0.25 else Color("ffbd88")
		stamina_p2.color = Color("d6fc63") if p2.abilities.energy_frames > 0 else Color("8fc5e7")
		var w := BAR_W * clampf(float(p2.health) / float(p2.max_health), 0.0, 1.0)
		p2_fill.size.x = w
		p2_fill.position.x = 220.0 + (BAR_W - w)   # la barra de P2 drena hacia el centro

var stamina_p1: ColorRect
var stamina_p2: ColorRect
var status_p1: Label
var status_p2: Label
var cooldown_p1: Label
var cooldown_p2: Label

var combo_p1: Label
var combo_p2: Label
var health_p1: Label
var health_p2: Label
var trail_p1: ColorRect
var trail_p2: ColorRect

func _update_combo(label: Label, victim: Fighter) -> void:
	label.visible = victim.combo_display_frames > 0 and victim.combo_count >= 2
	label.text = "%d СЕРИЯ · %d УРОН" % [victim.combo_count,victim.combo_damage]
	label.modulate.a = minf(1.0,victim.combo_display_frames/20.0)

func _health_trail(pos: Vector2, behind: Node) -> ColorRect:
	var bar := ColorRect.new()
	bar.position = pos
	bar.size = Vector2(BAR_W,12)
	bar.color = Color("ffcf8a")
	add_child(bar)
	move_child(bar,behind.get_index())
	return bar

const UI_FONT = preload("res://assets/fonts/Manrope.ttf")
func _ready() -> void:
	var frame := Node2D.new()
	frame.set_script(preload("res://ui/hud_frame.gd"))
	add_child(frame)
	move_child(frame,0)
	for child in get_children():
		if child is Label:
			child.add_theme_font_override("font",UI_FONT)
	timer_label.position = Vector2(174,7)
	timer_label.size = Vector2(36,24)
	timer_label.add_theme_font_size_override("font_size",16)
	trail_p1 = _health_trail(Vector2(12,8),p1_fill)
	trail_p2 = _health_trail(Vector2(220,8),p2_fill)
	p1_fill.color = Color("d6fc63")
	p2_fill.color = Color("ffbd88")
	health_p1 = _ability_label(Vector2(15,8),false,Color("141d0a"),7)
	health_p2 = _ability_label(Vector2(203,8),true,Color("332116"),7)
	combo_p1 = _ability_label(Vector2(12,56),false,Color("9bf4de"),10)
	combo_p2 = _ability_label(Vector2(204,56),true,Color("ffcc99"),10)
	stamina_p1 = _stamina_bar(Vector2(12,35))
	stamina_p2 = _stamina_bar(Vector2(220,35))
	status_p1 = _ability_label(Vector2(12,40),false,Color(0.7,0.95,0.9),7)
	status_p2 = _ability_label(Vector2(204,40),true,Color(1,0.65,0.5),7)
	cooldown_p1 = _ability_label(Vector2(12,201),false,Color(0.8,0.9,0.9),7)
	cooldown_p2 = _ability_label(Vector2(204,201),true,Color(0.9,0.8,0.75),7)

func _ability_label(pos: Vector2, right: bool, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = Vector2(168,12)
	label.add_theme_font_override("font",UI_FONT)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	add_child(label)
	return label

func _stamina_bar(pos: Vector2) -> ColorRect:
	var bg := ColorRect.new()
	bg.position = pos
	bg.size = Vector2(BAR_W,3)
	bg.color = Color(0.1,0.2,0.25,0.9)
	add_child(bg)
	var fill := ColorRect.new()
	fill.position = pos
	fill.size = Vector2(BAR_W,3)
	fill.color = Color("8fc5e7")
	add_child(fill)
	return fill
