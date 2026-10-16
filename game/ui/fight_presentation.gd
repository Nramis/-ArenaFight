extends CanvasLayer
var manager: MatchManager
var panel: Control
var title: Label
var subtitle: Label
var arena_label: Label
var rematch_button: Button
var select_button: Button
var _previous_phase := -1

func _ready() -> void:
	manager = get_parent()
	layer = 20
	panel = Control.new()
	panel.size = Vector2(384,216)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.position = Vector2(0,60)
	shade.size = Vector2(384,98)
	shade.color = Color(0.015,0.035,0.06,0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(shade)
	title = _label(Vector2(8,66),Vector2(368,33),25)
	subtitle = _label(Vector2(10,105),Vector2(364,31),11)
	arena_label = _label(Vector2(8,137),Vector2(368,14),8)
	rematch_button = _button("В ЛОББИ" if NetSession.enabled else "РЕВАНШ",Vector2(38,165))
	rematch_button.pressed.connect(manager.rematch)
	select_button = _button("ВЫБОР БОЙЦОВ",Vector2(202,165))
	select_button.pressed.connect(manager.open_selection)

func _process(_delta: float) -> void:
	var state := manager.match_state
	var phase := state.phase
	var opening_fight := phase == MatchState.FIGHT and state.phase_frame < 24
	panel.visible = phase != MatchState.FIGHT or opening_fight
	rematch_button.visible = phase == MatchState.MATCH_END
	select_button.visible = rematch_button.visible
	if phase != _previous_phase:
		if phase == MatchState.FIGHT:
			manager.play_fighter_sound("beam")
		_previous_phase = phase
	arena_label.text = Stages.NAMES[GameConfig.stage_id]
	if phase == MatchState.INTRO:
		var round_number := state.p1_rounds+state.p2_rounds+1
		title.text = "РАУНД "+str(round_number) if state.phase_frame > 55 else "ПРОТИВОСТОЯНИЕ"
		subtitle.text = Roster.NAMES[manager.p1.roster_name()]+"  VS  "+Roster.NAMES[manager.p2.roster_name()]
	elif opening_fight:
		title.text = "БОЙ!"
		subtitle.text = "Меняй удары · следи за выносливостью"
	elif phase == MatchState.ROUND_END:
		title.text = "ВРЕМЯ!" if state.timer <= 0 else "НОКАУТ!"
		subtitle.text = _winner_name()+" ЗАБИРАЕТ РАУНД" if state.last_winner != 0 else "НИЧЬЯ"
	elif phase == MatchState.MATCH_END:
		title.text = "ПОБЕДА!"
		subtitle.text = _winner_name()+"\n"+str(state.p1_rounds)+" : "+str(state.p2_rounds)
	var scale_in := 1.0+maxf(0,1-state.phase_frame/10.0)*0.15
	title.pivot_offset = title.size/2
	title.scale = Vector2.ONE*scale_in

func _winner_name() -> String:
	var winner := manager.match_state.match_winner() if manager.match_state.match_over() else manager.match_state.last_winner
	return Roster.NAMES[manager.p1.roster_name()] if winner == 1 else Roster.NAMES[manager.p2.roster_name()]

func _label(pos: Vector2,dimensions: Vector2,font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = dimensions
	label.add_theme_font_size_override("font_size",font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color",Color("e7f6ef"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return label

func _button(text: String,pos: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(144,32)
	button.add_theme_font_size_override("font_size",11)
	panel.add_child(button)
	return button
