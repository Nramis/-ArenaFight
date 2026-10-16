extends SceneTree
func _initialize() -> void:
	call_deferred("check_roster")
func check_roster() -> void:
	var config = root.get_node("GameConfig")
	config.roster_enabled = true
	config.p2_is_cpu = false
	var ids = ["rafael","nikita","vladislav","mavrin","ramis","ilgiz","bigboss"]
	for id in ids:
		config.p1_character = id
		config.p2_character = id
		var arena = load("res://match/match.tscn").instantiate()
		root.add_child(arena)
		arena.match_state.phase = 1
		for i in 3:
			await process_frame
		for f in [arena.p1,arena.p2]:
			var art = null
			for child in f.get_children():
				if child.get_script() != null and child.get_script().resource_path == "res://fighter/combat_art.gd":
					art = child
			assert(art != null and art.texture != null and art.transition_texture != null and art.posture_texture != null,"Motion atlas loads for "+id)
			assert(art.legacy.get_parent() == f,"Special animations keep the fighter owner")
		for slot in 3:
			arena._reset_round()
			arena.p1.frozen = false
			assert(arena.p1.abilities.activate(slot),"Ability activates for "+id)
			for i in 2:
				await process_frame
		arena.queue_free()
		await process_frame
	print("ALL TWENTY-ONE MOTION ATLASES AND 21 ABILITIES LOADED")
	quit(0)
