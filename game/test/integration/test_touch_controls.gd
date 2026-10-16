extends GdUnitTestSuite
const MATCH = preload("res://match/match.tscn")
var match_node: MatchManager
var pad: Node2D

func before_test() -> void:
	GameConfig.p2_is_cpu = false
	match_node = MATCH.instantiate()
	add_child(match_node)
	auto_free(match_node)
	pad = match_node.get_node("TouchLayer/TouchControls")

func _touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	pad._input(event)

func _enable() -> void:
	pad.enabled = true
	pad.visible = true

func test_desktop_keeps_keyboard_bindings_and_no_overlay() -> void:
	assert_bool(pad.enabled).is_false()
	var event := InputEventKey.new()
	event.physical_keycode = KEY_D
	assert_bool(InputMap.action_has_event("p1_right",event)).is_true()
	Input.action_press("p1_right")
	var human := HumanInput.new()
	auto_free(human)
	assert_bool(human.poll().right).is_true()
	pad.release_all()
	assert_bool(human.poll().right).is_true()
	Input.action_release("p1_right")

func test_touch_is_ignored_on_desktop() -> void:
	_touch(0,Vector2(70,166),true)
	assert_bool(Input.is_action_pressed("p1_right")).is_false()

func test_multitouch_move_and_punch_are_independent() -> void:
	_enable()
	_touch(0,Vector2(70,166),true)
	_touch(1,Vector2(280,148),true)
	var human := HumanInput.new()
	auto_free(human)
	assert_bool(human.poll().right).is_true()
	assert_bool(human.poll().lp).is_true()
	_touch(1,Vector2.ZERO,false)
	assert_bool(human.poll().lp).is_false()
	assert_bool(human.poll().right).is_true()
	_touch(0,Vector2.ZERO,false)
	assert_bool(human.poll().right).is_false()

func test_drag_changes_direction_and_jump_without_sticking() -> void:
	_enable()
	_touch(3,Vector2(70,166),true)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = Vector2(25,145)
	pad._input(drag)
	assert_bool(Input.is_action_pressed("p1_right")).is_false()
	assert_bool(Input.is_action_pressed("p1_left")).is_true()
	assert_bool(Input.is_action_pressed("p1_up")).is_true()
	_touch(3,Vector2.ZERO,false)
	assert_bool(Input.is_action_pressed("p1_left")).is_false()
	assert_bool(Input.is_action_pressed("p1_up")).is_false()

func test_special_buttons_map_to_existing_actions_and_focus_loss_releases() -> void:
	_enable()
	_touch(1,Vector2(280,111),true)
	_touch(2,Vector2(313,111),true)
	_touch(3,Vector2(346,111),true)
	for i in 3:
		assert_bool(Input.is_action_pressed("p1_special"+str(i+1))).is_true()
	pad._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	for i in 3:
		assert_bool(Input.is_action_pressed("p1_special"+str(i+1))).is_false()
	assert_int(pad.stick_finger).is_equal(-1)

func test_scene_exit_releases_touch_actions() -> void:
	_enable()
	_touch(0,Vector2(70,166),true)
	pad._exit_tree()
	assert_bool(Input.is_action_pressed("p1_right")).is_false()

func test_second_finger_on_same_button_does_not_release_first() -> void:
	_enable()
	_touch(1,Vector2(280,148),true)
	_touch(2,Vector2(280,148),true)
	_touch(1,Vector2.ZERO,false)
	assert_bool(Input.is_action_pressed("p1_lp")).is_true()
	_touch(2,Vector2.ZERO,false)
	assert_bool(Input.is_action_pressed("p1_lp")).is_false()
