# Unit: diferenciación de los 2 shotos.
extends GdUnitTestSuite

func test_homura_walks_faster_than_kaze() -> void:
	assert_float(Characters.stats("homura")["walk_fwd_speed"]).is_greater(Characters.stats("kaze")["walk_fwd_speed"])

func test_kaze_hadouken_recovers_faster() -> void:
	var kaze: MoveData = Characters.specials_for("kaze")["hadouken.l"]
	var homura: MoveData = Characters.specials_for("homura")["hadouken.l"]
	assert_int(kaze.recovery).is_less(homura.recovery)   # mejor fireball de Kaze

func test_homura_dp_hits_harder() -> void:
	var kaze: MoveData = Characters.specials_for("kaze")["dp.l"]
	var homura: MoveData = Characters.specials_for("homura")["dp.l"]
	assert_int(homura.damage).is_greater(kaze.damage)
