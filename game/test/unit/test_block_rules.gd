# Unit: reglas de bloqueo por dirección/postura.
extends GdUnitTestSuite

func test_stand_block_stops_mid() -> void:
	assert_bool(BlockRules.can_block(true, false, false, false)).is_true()

func test_stand_block_fails_vs_low() -> void:
	assert_bool(BlockRules.can_block(true, false, true, false)).is_false()

func test_stand_block_stops_overhead() -> void:
	assert_bool(BlockRules.can_block(true, false, false, true)).is_true()

func test_crouch_block_stops_low() -> void:
	assert_bool(BlockRules.can_block(true, true, true, false)).is_true()

func test_crouch_block_fails_vs_overhead() -> void:
	assert_bool(BlockRules.can_block(true, true, false, true)).is_false()

func test_no_back_no_block() -> void:
	assert_bool(BlockRules.can_block(false, false, false, false)).is_false()
