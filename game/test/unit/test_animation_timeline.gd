extends GdUnitTestSuite

func test_walk_uses_passing_frames_between_strides() -> void:
	var poses: Array[int] = []
	for step in 8:
		poses.append(AnimationTimeline.walk_pose(step))
	assert_array(poses).is_equal([1,8,2,9,1,8,2,9])

func test_punch_has_windup_strike_retraction_and_guard() -> void:
	assert_int(AnimationTimeline.attack_pose(0,9,4,18,false)).is_equal(10)
	assert_int(AnimationTimeline.attack_pose(9,9,4,18,false)).is_equal(3)
	assert_int(AnimationTimeline.attack_pose(19,9,4,18,false)).is_equal(11)
	assert_int(AnimationTimeline.attack_pose(30,9,4,18,false)).is_equal(0)

func test_kick_uses_chamber_and_retraction() -> void:
	assert_int(AnimationTimeline.attack_pose(0,7,4,14,true)).is_equal(12)
	assert_int(AnimationTimeline.attack_pose(7,7,4,14,true)).is_equal(4)
	assert_int(AnimationTimeline.attack_pose(16,7,4,14,true)).is_equal(13)

func test_knockdown_reacts_lies_down_and_gets_up() -> void:
	assert_int(AnimationTimeline.knockdown_pose(1,39)).is_equal(6)
	assert_int(AnimationTimeline.knockdown_pose(10,30)).is_equal(14)
	assert_int(AnimationTimeline.knockdown_pose(32,8)).is_equal(15)
