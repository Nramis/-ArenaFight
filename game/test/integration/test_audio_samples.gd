extends GdUnitTestSuite
var sound: Sfx

func before_test() -> void:
	GameConfig.set_audio(true,0.8)
	sound = Sfx.new()
	add_child(sound)
	auto_free(sound)

func after_test() -> void:
	GameConfig.set_audio(true,0.8)

func test_all_effects_are_real_loadable_audio_samples() -> void:
	assert_int(sound.bank.size()).is_greater_equal(16)
	for event: String in sound.bank:
		for stream: AudioStream in sound.bank[event]:
			assert_object(stream).is_not_null()
			assert_float(stream.get_length()).is_greater(0.0)
	assert_int(sound.voices.size()).is_equal(10)

func test_hit_block_and_swing_use_different_samples() -> void:
	sound.play_hit(false,30)
	assert_bool(sound.voices[0].stream in sound.bank["hit"]).is_true()
	sound.play_hit(true,15)
	assert_bool(sound.voices[1].stream in sound.bank["block"]).is_true()
	sound.play_event("swing")
	assert_bool(sound.voices[2].stream in sound.bank["swing"]).is_true()

func test_mute_and_volume_apply_without_restarting_scene() -> void:
	GameConfig.set_audio(false,0.4)
	var bus := AudioServer.get_bus_index("ArenaSFX")
	assert_bool(AudioServer.is_bus_mute(bus)).is_true()
	sound.play_hit()
	assert_object(sound.voices[0].stream).is_null()
	GameConfig.set_audio(true,0.4)
	assert_bool(AudioServer.is_bus_mute(bus)).is_false()
	assert_float(AudioServer.get_bus_volume_db(bus)).is_equal_approx(linear_to_db(0.4),0.01)
	sound.play_hit()
	assert_object(sound.voices[0].stream).is_not_null()

func test_repeated_steps_are_limited_without_cutting_hit() -> void:
	for i in 20:
		sound.play_event("step")
	sound.play_hit()
	assert_bool(sound.voices[0].stream in sound.bank["step"]).is_true()
	assert_bool(sound.voices[1].stream in sound.bank["hit"]).is_true()
	assert_object(sound.voices[2].stream).is_null()
