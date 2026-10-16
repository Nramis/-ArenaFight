# Integración Fase 3: bloqueo (chip+blockstun), reglas alto/bajo, throws y knockdown.
extends GdUnitTestSuite

const FIGHTER := preload("res://fighter/fighter.tscn")

func _spawn(x: float, faces_right: bool) -> Array:
	var f: Fighter = FIGHTER.instantiate()
	var fake := FakeInput.new()
	f.input_source = fake
	f.position = Vector2(x, f.ground_y)
	f.facing_right = faces_right
	auto_free(fake)
	add_child(f)
	auto_free(f)
	return [f, fake]

func _duo(ax: float, dx: float) -> Array:
	var a := _spawn(ax, true)
	var d := _spawn(dx, false)
	a[0].opponent = d[0]
	d[0].opponent = a[0]
	return [a[0], a[1], d[0], d[1]]

# --- Bloqueo ---

func test_standing_block_vs_mid_is_chip_and_blockstun() -> void:
	var t := _duo(100.0, 138.0)
	var atk: Fighter = t[0]
	var dfn: Fighter = t[2]
	t[1].frame.lp = true          # st.LP (mid)
	t[3].frame.right = true        # defensor mantiene atrás (de pie)
	var was_block := false
	for i in 16:
		await get_tree().physics_frame
		Combat.resolve(atk, dfn)
		if dfn.state_machine.current_state.name == "Blockstun":
			was_block = true
	assert_bool(was_block).is_true()
	assert_int(dfn.health).is_greater(dfn.max_health - 30)    # solo chip, no 30 completo
	assert_int(dfn.health).is_less(dfn.max_health - 0)

func test_standing_block_fails_vs_low() -> void:
	var t := _duo(100.0, 136.0)
	var atk: Fighter = t[0]
	var dfn: Fighter = t[2]
	atk.start_move(atk.moves["cr.lk"])     # low forzado
	atk.state_machine.transition_to("Attack")
	t[3].frame.right = true                 # defensor de pie (no abajo) -> NO cubre bajos
	for i in 14:
		await get_tree().physics_frame
		Combat.resolve(atk, dfn)
	assert_int(dfn.health).is_equal(dfn.max_health - 20)    # 1000 - 20 (cr.LK completo)

func test_crouch_block_stops_low() -> void:
	var t := _duo(100.0, 136.0)
	var atk: Fighter = t[0]
	var dfn: Fighter = t[2]
	atk.start_move(atk.moves["cr.lk"])
	atk.state_machine.transition_to("Attack")
	t[3].frame.right = true                 # atrás
	t[3].frame.down = true                  # + abajo -> bloqueo bajo
	var was_block := false
	for i in 14:
		await get_tree().physics_frame
		Combat.resolve(atk, dfn)
		if dfn.state_machine.current_state.name == "Blockstun":
			was_block = true
	assert_bool(was_block).is_true()
	assert_int(dfn.health).is_greater(dfn.max_health - 20)   # solo chip de 20

# --- Throws ---

func test_throw_knocks_down_and_damages() -> void:
	var t := _duo(100.0, 138.0)
	var atk: Fighter = t[0]
	var dfn: Fighter = t[2]
	t[1].frame.lp = true
	t[1].frame.lk = true          # LP+LK = agarre
	for i in 5:
		await get_tree().physics_frame
		Throws.resolve(atk, dfn, 60.0)
	assert_str(dfn.state_machine.current_state.name).is_equal("Knockdown")
	assert_int(dfn.health).is_equal(dfn.max_health - 120)     # 1000 - 120

func test_throw_tech_when_both_grab() -> void:
	var t := _duo(100.0, 138.0)
	var atk: Fighter = t[0]
	var dfn: Fighter = t[2]
	t[1].frame.lp = true
	t[1].frame.lk = true
	t[3].frame.lp = true
	t[3].frame.lk = true          # ambos agarran el mismo frame
	for i in 4:
		await get_tree().physics_frame
		Throws.resolve(atk, dfn, 60.0)
	assert_int(atk.health).is_equal(atk.max_health - 0)    # tech: sin daño
	assert_int(dfn.health).is_equal(dfn.max_health - 0)
	assert_str(dfn.state_machine.current_state.name).is_not_equal("Knockdown")

func test_sweep_causes_knockdown() -> void:
	var t := _duo(100.0, 136.0)
	var atk: Fighter = t[0]
	var dfn: Fighter = t[2]
	atk.start_move(atk.moves["cr.hk"])     # barrido
	atk.state_machine.transition_to("Attack")
	# defensor neutro (sin bloquear)
	for i in 16:
		await get_tree().physics_frame
		Combat.resolve(atk, dfn)
	assert_str(dfn.state_machine.current_state.name).is_equal("Knockdown")
	assert_int(dfn.health).is_equal(dfn.max_health - 90)     # 1000 - 90
