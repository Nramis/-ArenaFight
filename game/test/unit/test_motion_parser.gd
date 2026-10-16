# Unit: detección de motions numpad.
extends GdUnitTestSuite

# history con índice 0 = más reciente. Para 236 el jugador hizo 2,3,6 -> historial [6,3,2,...]
func test_qcf_detected() -> void:
	assert_bool(MotionParser.matches([6, 3, 2, 5, 5], [2, 3, 6], 12)).is_true()

func test_dp_detected() -> void:
	assert_bool(MotionParser.matches([3, 2, 6, 5], [6, 2, 3], 12)).is_true()

func test_qcb_detected() -> void:
	assert_bool(MotionParser.matches([4, 1, 2, 5], [2, 1, 4], 12)).is_true()

func test_incomplete_motion_fails() -> void:
	assert_bool(MotionParser.matches([6, 5, 5, 5], [2, 3, 6], 12)).is_false()

func test_gap_too_large_fails() -> void:
	# 2 y 6 muy separados (más que la ventana), sin 3
	var hist := [6, 5, 5, 5, 5, 2]
	assert_bool(MotionParser.matches(hist, [2, 3, 6], 2)).is_false()

func test_to_numpad_forward_down() -> void:
	assert_int(MotionParser.to_numpad(1, -1)).is_equal(3)   # abajo-adelante
	assert_int(MotionParser.to_numpad(1, 0)).is_equal(6)    # adelante
	assert_int(MotionParser.to_numpad(-1, 1)).is_equal(7)   # arriba-atrás
