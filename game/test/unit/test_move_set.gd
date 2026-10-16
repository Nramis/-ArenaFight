# Unit: el set de normales (datos).
extends GdUnitTestSuite

func test_has_18_normals() -> void:
	assert_int(MoveSet.default_normals().size()).is_equal(18)

func test_st_lp_values() -> void:
	var m: MoveData = MoveSet.default_normals()["st.lp"]
	assert_int(m.damage).is_equal(30)
	assert_int(m.total()).is_equal(14)   # 4 + 3 + 7

func test_cr_mk_is_low() -> void:
	assert_bool(MoveSet.default_normals()["cr.mk"].hits_low).is_true()

func test_jump_hp_is_overhead() -> void:
	assert_bool(MoveSet.default_normals()["j.hp"].hits_overhead).is_true()
