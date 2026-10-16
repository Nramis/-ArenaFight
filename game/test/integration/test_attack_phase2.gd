# Integración Fase 2: ciclo de un ataque y resolución de golpe entre dos fighters.
extends GdUnitTestSuite

const FIGHTER := preload("res://fighter/fighter.tscn")

func _spawn(x: float) -> Array:
	var f: Fighter = FIGHTER.instantiate()
	var fake := FakeInput.new()
	f.input_source = fake
	f.position = Vector2(x, f.ground_y)
	auto_free(fake)
	add_child(f)
	auto_free(f)
	return [f, fake]

func test_attack_runs_and_returns_to_idle() -> void:
	var p := _spawn(100.0)
	var f: Fighter = p[0]
	var fake: FakeInput = p[1]
	fake.frame.lp = true
	var was_attack := false
	for i in 22:
		await get_tree().physics_frame
		if f.state_machine.current_state.name == "Attack":
			was_attack = true
	assert_bool(was_attack).is_true()                                   # pasó por Attack
	assert_str(f.state_machine.current_state.name).is_equal("Idle")      # y volvió a Idle

func test_hit_applies_damage_hitstun_and_hitstop() -> void:
	var a := _spawn(100.0)
	var d := _spawn(150.0)
	var atk: Fighter = a[0]
	var dfn: Fighter = d[0]
	atk.opponent = dfn
	dfn.opponent = atk
	a[1].frame.lp = true    # el atacante lanza st.LP

	var was_hitstun := false
	var saw_hitstop := false
	for i in 16:
		await get_tree().physics_frame
		Combat.resolve(atk, dfn)
		Combat.resolve(dfn, atk)
		if dfn.state_machine.current_state.name == "Hitstun":
			was_hitstun = true
		if dfn.hitstop_frames > 0 or atk.hitstop_frames > 0:
			saw_hitstop = true

	assert_int(dfn.health).is_equal(dfn.max_health - 30)     # 1000 - 30 (st.LP), un solo golpe
	assert_bool(was_hitstun).is_true()
	assert_bool(saw_hitstop).is_true()

func test_attack_out_of_range_does_not_hit() -> void:
	var a := _spawn(100.0)
	var d := _spawn(300.0)   # lejos, fuera de rango del jab
	var atk: Fighter = a[0]
	var dfn: Fighter = d[0]
	atk.opponent = dfn
	dfn.opponent = atk
	a[1].frame.lp = true
	for i in 16:
		await get_tree().physics_frame
		Combat.resolve(atk, dfn)
	assert_int(dfn.health).is_equal(dfn.max_health - 0)    # no llegó
