extends GdUnitTestSuite
func test_initial_frames_then_wait() -> void:
	var b := LockstepBuffer.new()
	b.reset(3)
	for i in 3:
		assert_array(b.advance()).is_equal([0,0])
	assert_bool(b.ready()).is_false()
	assert_array(b.advance()).is_empty()
	assert_int(b.frame).is_equal(3)
func test_packets_consumed_in_order() -> void:
	var b := LockstepBuffer.new()
	b.reset(3)
	for i in 3:
		b.queue_local(5+i)
		b.advance()
	b.receive(5,100)
	b.receive(3,12)
	assert_array(b.advance()).is_equal([5,12])
	assert_bool(b.ready()).is_false()
	b.receive(4,17)
	assert_array(b.advance()).is_equal([6,17])
	assert_array(b.advance()).is_equal([7,100])
func test_duplicates_and_bounds() -> void:
	var b := LockstepBuffer.new()
	b.reset(6)
	assert_bool(b.receive(6,10)).is_true()
	assert_bool(b.receive(6,11)).is_false()
	assert_bool(b.receive(500,10)).is_false()
	assert_bool(b.receive(-1,10)).is_false()
	assert_bool(b.receive(8,99999)).is_false()
	assert_int(b.remote_inputs.size()).is_equal(7)
func test_local_sample_once() -> void:
	var b := LockstepBuffer.new()
	b.reset(6)
	assert_int(b.queue_local(42)).is_equal(6)
	assert_int(b.queue_local(9)).is_equal(-1)
	assert_int(b.local_inputs[6]).is_equal(42)
