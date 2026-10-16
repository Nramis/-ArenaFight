# Unit: decisiones tácticas de la IA.
extends GdUnitTestSuite

func test_antiair_when_opponent_airborne_and_close() -> void:
	assert_str(AIBrain.decide(60.0, true, false, 0.5)).is_equal("antiair")

func test_approach_when_far() -> void:
	assert_str(AIBrain.decide(200.0, false, false, 0.9)).is_equal("approach")

func test_whiff_punish_when_opponent_recovering_at_mid() -> void:
	assert_str(AIBrain.decide(90.0, false, true, 0.9)).is_equal("attack")

func test_attack_when_close_low_roll() -> void:
	assert_str(AIBrain.decide(40.0, false, false, 0.1)).is_equal("attack")

func test_throw_when_close_mid_roll() -> void:
	assert_str(AIBrain.decide(40.0, false, false, 0.65)).is_equal("throw")
