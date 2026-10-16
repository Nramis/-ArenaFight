# Integración Fase 5: los personajes aplican sus stats (Homura se mueve más que Kaze).
extends GdUnitTestSuite

const FIGHTER := preload("res://fighter/fighter.tscn")

func _spawn(cid: String) -> Array:
	var f: Fighter = FIGHTER.instantiate()
	var fake := FakeInput.new()
	f.input_source = fake
	f.character_id = cid                       # antes de add_child -> _ready lo aplica
	f.position = Vector2(100.0, f.ground_y)
	f.facing_right = true
	auto_free(fake)
	add_child(f)
	auto_free(f)
	return [f, fake]

func test_homura_moves_farther_than_kaze_same_input() -> void:
	var k := _spawn("kaze")
	var h := _spawn("homura")
	k[1].frame.right = true
	h[1].frame.right = true
	for i in 20:
		await get_tree().physics_frame
	var kaze_dist: float = k[0].position.x - 100.0
	var homura_dist: float = h[0].position.x - 100.0
	assert_float(homura_dist).is_greater(kaze_dist)
