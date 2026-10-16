# Unit: flujo de match (rounds, timer, KO, best-of-3).
extends GdUnitTestSuite

func test_intro_transitions_to_fight() -> void:
	var m := MatchState.new()
	m.phase_frame = MatchState.INTRO_FRAMES - 1
	var ev := m.tick(1000, 1000)
	assert_str(ev).is_equal("fight")
	assert_int(m.phase).is_equal(MatchState.FIGHT)

func test_ko_ends_round_and_awards_winner() -> void:
	var m := MatchState.new()
	m.phase = MatchState.FIGHT
	var ev := m.tick(1000, 0)      # P2 sin vida -> gana P1
	assert_str(ev).is_equal("round_end")
	assert_int(m.p1_rounds).is_equal(1)

func test_timeout_awards_higher_health() -> void:
	var m := MatchState.new()
	m.phase = MatchState.FIGHT
	m.timer = 1
	var ev := m.tick(500, 300)     # se agota el tiempo -> gana quien tiene más vida
	assert_str(ev).is_equal("round_end")
	assert_int(m.p1_rounds).is_equal(1)

func test_two_round_wins_end_match() -> void:
	var m := MatchState.new()
	m.p1_rounds = 2
	m.phase = MatchState.ROUND_END
	m.phase_frame = MatchState.ROUND_END_FRAMES
	var ev := m.tick(1000, 0)
	assert_str(ev).is_equal("match_end")
	assert_bool(m.match_over()).is_true()
	assert_int(m.match_winner()).is_equal(1)

func test_one_round_win_continues_match() -> void:
	var m := MatchState.new()
	m.p1_rounds = 1
	m.phase = MatchState.ROUND_END
	m.phase_frame = MatchState.ROUND_END_FRAMES
	var ev := m.tick(1000, 0)
	assert_str(ev).is_equal("next_round")
	assert_bool(m.match_over()).is_false()

func test_timer_seconds_starts_at_99() -> void:
	assert_int(MatchState.new().timer_seconds()).is_equal(99)
