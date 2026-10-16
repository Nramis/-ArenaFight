# Unit: fases de un ataque (startup/active/recovery/done). Move 4/3/7.
extends GdUnitTestSuite

func test_startup_frames() -> void:
	assert_int(MovePhase.phase_at(1, 4, 3, 7)).is_equal(MovePhase.STARTUP)
	assert_int(MovePhase.phase_at(3, 4, 3, 7)).is_equal(MovePhase.STARTUP)

func test_active_frames() -> void:
	assert_int(MovePhase.phase_at(4, 4, 3, 7)).is_equal(MovePhase.ACTIVE)   # primer activo = startup
	assert_int(MovePhase.phase_at(6, 4, 3, 7)).is_equal(MovePhase.ACTIVE)

func test_recovery_frames() -> void:
	assert_int(MovePhase.phase_at(7, 4, 3, 7)).is_equal(MovePhase.RECOVERY)
	assert_int(MovePhase.phase_at(13, 4, 3, 7)).is_equal(MovePhase.RECOVERY)

func test_done() -> void:
	assert_int(MovePhase.phase_at(14, 4, 3, 7)).is_equal(MovePhase.DONE)
