# Unit: damage scaling de combos.
extends GdUnitTestSuite

func test_first_two_hits_full() -> void:
	assert_int(DamageCalculator.scaled_damage(100, 0)).is_equal(100)
	assert_int(DamageCalculator.scaled_damage(100, 1)).is_equal(100)

func test_third_hit_80() -> void:
	assert_int(DamageCalculator.scaled_damage(100, 2)).is_equal(80)

func test_scaling_curve() -> void:
	assert_int(DamageCalculator.scaled_damage(100, 3)).is_equal(60)
	assert_int(DamageCalculator.scaled_damage(100, 4)).is_equal(40)
	assert_int(DamageCalculator.scaled_damage(100, 5)).is_equal(20)
	assert_int(DamageCalculator.scaled_damage(100, 9)).is_equal(20)   # piso
