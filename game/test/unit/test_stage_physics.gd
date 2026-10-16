# Unit: paredes (clamp) y separación de pushboxes (lógica pura).
extends GdUnitTestSuite

func test_clamp_within_bounds() -> void:
	assert_float(StagePhysics.clamp_wall(100.0, 40.0, 344.0)).is_equal(100.0)

func test_clamp_left_wall() -> void:
	assert_float(StagePhysics.clamp_wall(10.0, 40.0, 344.0)).is_equal(40.0)

func test_clamp_right_wall() -> void:
	assert_float(StagePhysics.clamp_wall(400.0, 40.0, 344.0)).is_equal(344.0)

func test_separate_overlapping_pushboxes() -> void:
	var r := StagePhysics.separate(100.0, 120.0, 44.0)   # dist 20 < 44
	assert_float(r[1] - r[0]).is_equal_approx(44.0, 0.001)
	# empuje simétrico respecto al centro (110)
	assert_float((r[0] + r[1]) / 2.0).is_equal_approx(110.0, 0.001)

func test_separate_apart_unchanged() -> void:
	var r := StagePhysics.separate(100.0, 200.0, 44.0)
	assert_float(r[0]).is_equal(100.0)
	assert_float(r[1]).is_equal(200.0)
