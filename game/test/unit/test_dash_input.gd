# Unit: detección de dash por doble toque (lógica pura).
extends GdUnitTestSuite

func test_double_tap_triggers_dash() -> void:
	var d := DashInput.new()
	assert_int(d.update(1)).is_equal(0)   # primer toque
	assert_int(d.update(0)).is_equal(0)   # neutro
	assert_int(d.update(1)).is_equal(1)   # segundo toque -> dash

func test_single_tap_no_dash() -> void:
	var d := DashInput.new()
	assert_int(d.update(1)).is_equal(0)

func test_holding_direction_no_dash() -> void:
	var d := DashInput.new()
	d.update(1)
	for i in 5:
		assert_int(d.update(1)).is_equal(0)   # mantener no es doble toque

func test_slow_second_tap_no_dash() -> void:
	var d := DashInput.new()
	d.update(1)                 # toque en frame 1
	for i in 13:
		d.update(0)             # 13 frames neutros (> ventana 12)
	assert_int(d.update(1)).is_equal(0)

func test_opposite_direction_no_dash() -> void:
	var d := DashInput.new()
	d.update(1)
	d.update(0)
	assert_int(d.update(-1)).is_equal(0)

func test_left_double_tap_triggers_left_dash() -> void:
	var d := DashInput.new()
	d.update(-1)
	d.update(0)
	assert_int(d.update(-1)).is_equal(-1)
