extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var net = root.get_node("NetSession")
	root.get_node("GameConfig").p2_is_cpu = false
	net.enabled = true
	net.set_physics_process(true)
	var m = load("res://match/match.tscn").instantiate()
	root.add_child(m)
	current_scene = m
	net.started = true
	for i in 12:
		await physics_frame
		await process_frame
	assert(net.buffer.frame == 6)
	var f = m.match_state.phase_frame
	for i in 4:
		await physics_frame
		await process_frame
	assert(m.match_state.phase_frame == f)
	for i in range(6,20):
		net.buffer.receive(i,0)
	for i in 4:
		await physics_frame
		await process_frame
	assert(m.match_state.phase_frame > f)
	net.enabled = false
	paused = false
	print("NETWORK PAUSE AND RESUME PASSED")
	quit(0)
