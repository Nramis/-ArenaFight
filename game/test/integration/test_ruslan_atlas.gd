extends GdUnitTestSuite

func test_all_costume_outlines_match_their_original_pngs() -> void:
    for tier in ["prosperous", "struggling", "bankrupt"]:
        var data: Dictionary = RuslanAtlas.DATA[tier]
        assert_str(FileAccess.get_sha256("res://assets/ruslan/" + tier + ".png")).is_equal(data.sha256)
        assert_int(data.frames.size()).is_equal(48)

func test_every_pose_has_a_valid_polygon_inside_its_own_cell() -> void:
    for tier in ["prosperous", "struggling", "bankrupt"]:
        var data: Dictionary = RuslanAtlas.DATA[tier]
        for frame in data.frames:
            var polygon := PackedVector2Array()
            for pair in frame.outline:
                var point := Vector2(pair[0], pair[1])
                assert_float(point.x).is_greater_equal(0.5)
                assert_float(point.y).is_greater_equal(0.5)
                assert_float(point.x).is_less_equal(float(data.cell[0]) - 0.5)
                assert_float(point.y).is_less_equal(float(data.cell[1]) - 0.5)
                polygon.append(point)
            assert_int(Geometry2D.triangulate_polygon(polygon).size()).is_greater(0)

func test_walking_does_not_sample_previous_rows_shoes() -> void:
    for tier in ["prosperous", "struggling", "bankrupt"]:
        var data: Dictionary = RuslanAtlas.DATA[tier]
        for pose in range(8, 16):
            # Stray soles at the top edge of the old atlas caused the bug.
            for pair in data.frames[pose].outline:
                assert_float(float(pair[1])).is_greater(2.0)
