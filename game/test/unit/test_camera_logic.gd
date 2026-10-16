# Unit: cálculo de cámara (centro + zoom acotado).
extends GdUnitTestSuite

func test_center_is_midpoint() -> void:
	var c := CameraLogic.compute(100.0, 200.0, 384.0, 0.85, 1.6, 90.0)
	assert_float(c[0]).is_equal(150.0)

func test_zoom_clamped_to_max_when_close() -> void:
	# needed = 10 + 180 = 190; 384/190 ~= 2.02 -> clamp a max 1.6
	var c := CameraLogic.compute(100.0, 110.0, 384.0, 0.85, 1.6, 90.0)
	assert_float(c[1]).is_equal(1.6)

func test_zoom_clamped_to_min_when_far() -> void:
	# needed = 384 + 180 = 564; 384/564 ~= 0.68 -> clamp a min 0.85
	var c := CameraLogic.compute(0.0, 384.0, 384.0, 0.85, 1.6, 90.0)
	assert_float(c[1]).is_equal(0.85)
