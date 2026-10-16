# Test unitario de InputFrame (lógica pura, sin escena).
# Requiere gdUnit4 instalado en res://addons/ (ver README). Sintaxis gdUnit4.
extends GdUnitTestSuite

func test_horizontal_neutral_is_zero() -> void:
	var f := InputFrame.new()
	assert_int(f.horizontal()).is_equal(0)

func test_horizontal_right_is_positive() -> void:
	var f := InputFrame.new()
	f.right = true
	assert_int(f.horizontal()).is_equal(1)

func test_horizontal_left_is_negative() -> void:
	var f := InputFrame.new()
	f.left = true
	assert_int(f.horizontal()).is_equal(-1)

func test_horizontal_both_pressed_cancels_to_zero() -> void:
	var f := InputFrame.new()
	f.left = true
	f.right = true
	assert_int(f.horizontal()).is_equal(0)

func test_vertical_down_is_positive() -> void:
	var f := InputFrame.new()
	f.down = true
	assert_int(f.vertical()).is_equal(1)
