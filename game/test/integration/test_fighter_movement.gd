# Test de INTEGRACIÓN: el Fighter completo (escena + StateMachine + input) se mueve
# y transiciona de estado correctamente al recibir input. Prueba varios nodos juntos.
# Requiere gdUnit4.
extends GdUnitTestSuite

const FIGHTER := preload("res://fighter/fighter.tscn")

# Crea un Fighter con una fuente de input falsa ya inyectada, y lo añade al árbol.
func _make_fighter() -> Array:
	var fighter: Fighter = FIGHTER.instantiate()
	var fake := FakeInput.new()
	fighter.input_source = fake        # inyectado ANTES de _ready → se respeta
	auto_free(fake)                    # evita orphan node al terminar el test
	add_child(fighter)
	auto_free(fighter)
	return [fighter, fake]

func test_fighter_starts_in_idle() -> void:
	var pair := _make_fighter()
	var fighter: Fighter = pair[0]
	await get_tree().physics_frame
	assert_str(fighter.state_machine.current_state.name).is_equal("Idle")

func test_fighter_walks_right_on_right_input() -> void:
	var pair := _make_fighter()
	var fighter: Fighter = pair[0]
	var fake: FakeInput = pair[1]
	var start_x := fighter.position.x

	fake.frame.right = true
	for i in 10:
		await get_tree().physics_frame

	assert_float(fighter.position.x).is_greater(start_x)
	assert_str(fighter.state_machine.current_state.name).is_equal("Walk")

func test_fighter_walks_left_on_left_input() -> void:
	var pair := _make_fighter()
	var fighter: Fighter = pair[0]
	var fake: FakeInput = pair[1]
	var start_x := fighter.position.x

	fake.frame.left = true
	for i in 10:
		await get_tree().physics_frame

	assert_float(fighter.position.x).is_less(start_x)

func test_fighter_returns_to_idle_when_input_released() -> void:
	var pair := _make_fighter()
	var fighter: Fighter = pair[0]
	var fake: FakeInput = pair[1]

	fake.frame.right = true
	for i in 5:
		await get_tree().physics_frame
	assert_str(fighter.state_machine.current_state.name).is_equal("Walk")

	fake.frame.right = false           # soltar
	for i in 5:
		await get_tree().physics_frame
	assert_str(fighter.state_machine.current_state.name).is_equal("Idle")

func test_fighter_does_not_move_when_neutral() -> void:
	var pair := _make_fighter()
	var fighter: Fighter = pair[0]
	var start_x := fighter.position.x
	for i in 10:
		await get_tree().physics_frame
	assert_float(fighter.position.x).is_equal(start_x)
