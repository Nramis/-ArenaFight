extends SceneTree

func _initialize() -> void:
	call_deferred("run_check")

func run_check() -> void:
	var config = root.get_node("GameConfig")
	var selection = load("res://ui/main_menu.tscn").instantiate()
	root.add_child(selection)
	current_scene = selection
	assert(selection.cards.size() == 9,"All nine cards are present")
	selection._set_slot(0)
	selection._select("polina")
	selection._set_slot(1)
	selection._select("bigboss")
	selection.mode.select(0)
	selection.difficulty.select(2)
	selection._start()
	for i in 3:
		await process_frame
	assert(current_scene.has_method("_reset_round"),"Selection starts the actual match")
	assert(current_scene.p1.roster_name() == "polina")
	assert(current_scene.p2.roster_name() == "bigboss")
	assert(current_scene.p2_is_cpu and current_scene.cpu_difficulty == "hard")
	Input.action_press("ui_cancel")
	for i in 3:
		await physics_frame
	Input.action_release("ui_cancel")
	for i in 2:
		await process_frame
	assert(current_scene.name == "FighterSelect","Escape returns to selection")
	assert(current_scene.selected == ["polina","bigboss"],"Selections persist")
	print("IN-GAME SELECTION FLOW PASSED")
	quit(0)
