extends GdUnitTestSuite

func test_all_sprite_outlines_are_triangulable_and_inside_their_original_atlas() -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rinat/regions.json"))
    assert_int(data.size()).is_equal(5)
    for key in data:
        var bank: Dictionary = data[key]
        assert_int(bank.frames.size()).is_equal(32)
        assert_float(float(bank.height)).is_greater(100)
        for frame in bank.frames:
            var polygon := PackedVector2Array()
            for p in frame.polygon:
                assert_float(float(p[0])).is_between(0,float(bank.size[0]))
                assert_float(float(p[1])).is_between(0,float(bank.size[1]))
                polygon.append(Vector2(p[0],p[1]))
            assert_int(Geometry2D.triangulate_polygon(polygon).size()).is_greater(0)

func test_each_skin_has_the_same_gameplay_stats_as_its_default() -> void:
    GameConfig.roster_enabled = true
    GameConfig.p1_character = "rinat"
    GameConfig.p2_character = "vladislav"
    GameConfig.p1_skin = "scorpion"
    GameConfig.p2_skin = "paquito"
    GameConfig.p2_is_cpu = false
    var arena: MatchManager = preload("res://match/match.tscn").instantiate()
    add_child(arena)
    auto_free(arena)
    assert_str(arena.p1.skin_id).is_equal("scorpion")
    assert_str(arena.p2.skin_id).is_equal("paquito")
    assert_int(arena.p1.max_health).is_equal(1500)
    assert_int(arena.p2.max_health).is_equal(1500)
    assert_int(arena.p1.moves["st.hp"].damage).is_equal(arena.p2.moves["st.hp"].damage)
    GameConfig.p1_skin = "default"
    GameConfig.p2_skin = "default"
    GameConfig.roster_enabled = false
