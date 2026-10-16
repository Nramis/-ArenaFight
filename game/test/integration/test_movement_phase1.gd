# Integración Fase 1: agacharse, saltar (arco completo) y dash, con el Fighter real
# y una fuente de input falsa. Requiere gdUnit4.
extends GdUnitTestSuite

const FIGHTER := preload("res://fighter/fighter.tscn")

func _make() -> Array:
	var f: Fighter = FIGHTER.instantiate()
	var fake := FakeInput.new()
	f.input_source = fake
	f.position = Vector2(100.0, f.ground_y)   # colocarlo sobre el suelo
	auto_free(fake)
	add_child(f)
	auto_free(f)
	return [f, fake]

func test_crouch_on_down_and_stand_on_release() -> void:
	var p := _make()
	var f: Fighter = p[0]
	var fake: FakeInput = p[1]
	fake.frame.down = true
	for i in 3:
		await get_tree().physics_frame
	assert_str(f.state_machine.current_state.name).is_equal("Crouch")
	fake.frame.down = false
	for i in 3:
		await get_tree().physics_frame
	assert_str(f.state_machine.current_state.name).is_equal("Idle")

func test_jump_leaves_ground_rises_and_lands() -> void:
	var p := _make()
	var f: Fighter = p[0]
	var fake: FakeInput = p[1]
	var min_y := f.position.y
	fake.frame.up = true
	for i in 3:                        # mantener up unos frames para disparar el salto
		await get_tree().physics_frame
	fake.frame.up = false              # soltar para que no re-salte
	var left_ground := false
	for i in 70:
		await get_tree().physics_frame
		if not f.on_ground:
			left_ground = true
		min_y = minf(min_y, f.position.y)
	assert_bool(left_ground).is_true()             # despegó
	assert_float(min_y).is_less(f.ground_y)         # subió (y menor = más arriba)
	assert_bool(f.on_ground).is_true()              # y aterrizó
	assert_str(f.state_machine.current_state.name).is_equal("Idle")

func test_double_tap_right_dashes_forward() -> void:
	var p := _make()
	var f: Fighter = p[0]
	var fake: FakeInput = p[1]
	var start_x := f.position.x
	# doble toque derecha con neutro claro entre ambos (2 frames cada tramo)
	fake.frame.right = true
	for i in 2:
		await get_tree().physics_frame
	fake.frame.right = false
	for i in 2:
		await get_tree().physics_frame
	fake.frame.right = true
	for i in 2:
		await get_tree().physics_frame
	assert_str(f.state_machine.current_state.name).is_equal("Dash")
	fake.frame.right = false
	for i in 22:
		await get_tree().physics_frame
	assert_float(f.position.x).is_greater(start_x + 50.0)
	assert_str(f.state_machine.current_state.name).is_equal("Idle")
