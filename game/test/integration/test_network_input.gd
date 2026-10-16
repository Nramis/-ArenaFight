extends GdUnitTestSuite
func after_test() -> void:
	NetSession.enabled = false
	NetSession.masks = [0,0]
	NetSession.edges = [0,0]
func test_shared_input_for_both_seats() -> void:
	NetSession.enabled = true
	NetSession.masks = [(1<<1)|(1<<4),(1<<0)|(1<<8)]
	var a := HumanInput.new()
	var b := HumanInput.new()
	b.player_prefix = "p2"
	auto_free(a)
	auto_free(b)
	assert_bool(a.poll().right).is_true()
	assert_bool(a.poll().lp).is_true()
	assert_bool(b.poll().left).is_true()
	assert_bool(b.poll().mk).is_true()
	assert_bool(b.poll().lp).is_false()
func test_special_and_flight_edges() -> void:
	NetSession.enabled = true
	NetSession.edges = [1<<10,(1<<12)|(1<<13)]
	assert_bool(NetSession.action_just_pressed("p1","special1")).is_true()
	assert_bool(NetSession.action_just_pressed("p1","special3")).is_false()
	assert_bool(NetSession.action_just_pressed("p2","special3")).is_true()
	assert_bool(NetSession.action_just_pressed("p2","fly")).is_true()
	NetSession.edges = [0,0]
	assert_bool(NetSession.action_just_pressed("p2","fly")).is_false()
func test_audio_randomness_separate() -> void:
	seed(12345)
	var expected := randi()
	seed(12345)
	var audio := Sfx.new()
	add_child(audio)
	auto_free(audio)
	audio.play_event("hit")
	audio.play_event("summon")
	assert_int(randi()).is_equal(expected)
