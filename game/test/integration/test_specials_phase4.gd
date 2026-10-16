# Integración Fase 4: motions -> especiales, cancel, damage scaling, invuln del DP.
extends GdUnitTestSuite

const FIGHTER := preload("res://fighter/fighter.tscn")

func _spawn(x: float, faces_right: bool = true) -> Array:
	var f: Fighter = FIGHTER.instantiate()
	var fake := FakeInput.new()
	f.input_source = fake
	f.position = Vector2(x, f.ground_y)
	f.facing_right = faces_right
	auto_free(fake)
	add_child(f)
	auto_free(f)
	return [f, fake]

func _clear(fake: FakeInput) -> void:
	fake.frame.left = false; fake.frame.right = false
	fake.frame.up = false; fake.frame.down = false
	fake.frame.lp = false; fake.frame.mp = false; fake.frame.hp = false
	fake.frame.lk = false; fake.frame.mk = false; fake.frame.hk = false

func test_qcf_punch_starts_hadouken() -> void:
	var p := _spawn(100.0)
	var f: Fighter = p[0]
	var fake: FakeInput = p[1]
	# 236 + LP (mirando a la derecha, adelante = derecha). 2 frames por paso (lag de 1 frame).
	fake.frame.down = true
	for i in 2: await get_tree().physics_frame
	fake.frame.right = true                 # abajo-adelante (3)
	for i in 2: await get_tree().physics_frame
	fake.frame.down = false                  # adelante (6)
	for i in 2: await get_tree().physics_frame
	fake.frame.lp = true                     # golpe
	for i in 2: await get_tree().physics_frame
	assert_object(f.current_move).is_not_null()
	assert_bool(f.current_move.is_special).is_true()
	assert_bool(f.current_move.spawns_projectile).is_true()
	assert_str(f.state_machine.current_state.name).is_equal("Attack")

func test_dp_motion_starts_shoryuken() -> void:
	var p := _spawn(100.0)
	var f: Fighter = p[0]
	var fake: FakeInput = p[1]
	# 623 + LP (2 frames por paso)
	fake.frame.right = true                  # adelante (6)
	for i in 2: await get_tree().physics_frame
	fake.frame.right = false; fake.frame.down = true   # abajo (2)
	for i in 2: await get_tree().physics_frame
	fake.frame.right = true                  # abajo-adelante (3)
	for i in 2: await get_tree().physics_frame
	fake.frame.lp = true
	for i in 2: await get_tree().physics_frame
	assert_bool(f.current_move.is_special).is_true()
	assert_int(f.current_move.invuln_startup).is_greater(0)   # DP tiene invuln

func test_combo_damage_scaling() -> void:
	var p := _spawn(100.0)
	var d: Fighter = p[0]
	var lp: MoveData = MoveSet.default_normals()["st.lp"]   # 30
	var mp: MoveData = MoveSet.default_normals()["st.mp"]   # 60
	var hp: MoveData = MoveSet.default_normals()["st.hp"]   # 90
	d.receive_hit(lp, 1)    # combo 1: 100% -> 30  (970)
	d.receive_hit(mp, 1)    # combo 2: 100% -> 60  (910)
	d.receive_hit(hp, 1)    # combo 3:  80% -> 72  (838)
	assert_int(d.health).is_equal(d.max_health - 162)

func test_cancel_normal_into_special() -> void:
	var p := _spawn(100.0)
	var f: Fighter = p[0]
	var fake: FakeInput = p[1]
	# arrancar st.LP (cancelable, startup 4) y cancelarlo a Hadouken con 236+LP
	fake.frame.lp = true
	for i in 2: await get_tree().physics_frame          # st.LP (Attack)
	fake.frame.lp = false
	fake.frame.down = true                    # 2
	for i in 2: await get_tree().physics_frame
	fake.frame.right = true                   # abajo-adelante (3)
	for i in 2: await get_tree().physics_frame
	fake.frame.down = false                    # adelante (6)
	for i in 2: await get_tree().physics_frame
	fake.frame.lp = true                       # cancel
	for i in 2: await get_tree().physics_frame
	assert_bool(f.current_move.is_special).is_true()   # se canceló a especial

func test_dp_invuln_blocks_incoming_hit() -> void:
	var atk := _spawn(100.0, true)     # el que tiene invuln
	var dfn := _spawn(140.0, false)    # atacante
	var a: Fighter = atk[0]
	var d: Fighter = dfn[0]
	a.invuln_frames = 12               # simula invencibilidad activa (como un DP)
	d.start_move(d.moves["st.lp"])
	d.state_machine.transition_to("Attack")
	for i in 7:
		await get_tree().physics_frame
		Combat.resolve(d, a)
	assert_int(a.health).is_equal(a.max_health - 0)   # el invulnerable no recibió daño
