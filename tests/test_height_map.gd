extends GutTest

func test_climb_one_level_ok():
	assert_true(MovementRules.new().can_step(0, 1))

func test_climb_two_levels_ng():
	assert_false(MovementRules.new().can_step(0, 2))

func test_drop_three_levels_ok():
	assert_true(MovementRules.new().can_step(3, 0))

func test_drop_four_levels_ng():
	assert_false(MovementRules.new().can_step(4, 0))

func test_rules_are_changeable():
	var r := MovementRules.new()
	r.max_climb = 2
	assert_true(r.can_step(0, 2))

func test_height_default_zero():
	assert_eq(HeightMap.new(Vector2i(4, 4)).get_height(Vector2i(1, 1)), 0)

func test_out_of_bounds():
	assert_false(HeightMap.new(Vector2i(4, 4)).in_bounds(Vector2i(4, 0)))

func test_world_to_cell():
	assert_eq(HeightMap.world_to_cell(Vector2(17, 31)), Vector2i(1, 1))
