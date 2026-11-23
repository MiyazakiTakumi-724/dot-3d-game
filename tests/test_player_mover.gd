extends GutTest

var map: HeightMap

func before_each():
	map = HeightMap.new(Vector2i(8, 8))
	map.set_height(Vector2i(2, 0), 1)
	map.set_height(Vector2i(3, 0), 3)

func _mover_at(cell: Vector2i) -> PlayerMover:
	var m := PlayerMover.new(map, MovementRules.new())
	m.pos = Vector2(cell) * 16 + Vector2(8, 8)
	m.height = map.get_height(cell)
	return m

func test_auto_climb_one():
	var m := _mover_at(Vector2i(1, 0))
	m.move(Vector2(16, 0))
	assert_eq(m.height, 1)

func test_blocked_by_two():
	var m := _mover_at(Vector2i(2, 0))
	m.move(Vector2(16, 0))
	assert_eq(HeightMap.world_to_cell(m.pos), Vector2i(2, 0))

func test_drop_three():
	var m := _mover_at(Vector2i(3, 0))
	m.move(Vector2(0, 16))
	assert_eq(m.height, 0)

func test_blocked_by_wall():
	map.set_wall(Vector2i(1, 1), true)
	var m := _mover_at(Vector2i(1, 0))
	m.move(Vector2(0, 16))
	assert_eq(HeightMap.world_to_cell(m.pos), Vector2i(1, 0))

func test_cannot_leave_map():
	var m := _mover_at(Vector2i(0, 0))
	m.move(Vector2(-16, 0))
	assert_eq(HeightMap.world_to_cell(m.pos), Vector2i(0, 0))

func test_front_cell():
	var m := _mover_at(Vector2i(1, 1))
	m.move(Vector2(1, 0))
	assert_eq(m.front_cell(), Vector2i(2, 1))

func test_input_is_relative_to_camera():
	var c: StackCamera = autofree(StackCamera.new())
	c.angle = PI / 2
	assert_almost_eq(c.screen_dir_to_world(Vector2.UP), Vector2(1, 0), Vector2(0.01, 0.01))

func test_front_cell_with_diagonal_facing_from_cell_edge():
	var m := _mover_at(Vector2i(1, 1))
	m.pos = Vector2(17, 24)
	m.facing = Vector2(0.88, 0.48).normalized()
	assert_eq(m.front_cell(), Vector2i(2, 1))

func test_walking_into_pit_falls():
	map.set_pit(Vector2i(2, 1), true)
	var p := PlayerMover.new(map, MovementRules.new())
	p.place(Vector2i(1, 1))
	for i in 20:
		p.move(Vector2(2, 0))
	assert_true(p.fell)
	assert_eq(p.cell(), Vector2i(2, 1))

func test_last_safe_cell_skips_pit():
	map.set_pit(Vector2i(3, 1), true)
	var p := PlayerMover.new(map, MovementRules.new())
	p.place(Vector2i(1, 1))
	for i in 40:
		p.move(Vector2(2, 0))
	assert_true(p.fell)
	assert_eq(p.last_safe_cell, Vector2i(2, 1))

func test_no_move_after_fall():
	map.set_pit(Vector2i(2, 1), true)
	var p := PlayerMover.new(map, MovementRules.new())
	p.place(Vector2i(1, 1))
	for i in 20:
		p.move(Vector2(2, 0))
	var before := p.pos
	p.move(Vector2(0, 5))
	assert_eq(p.pos, before)

func test_place_resets_fall():
	map.set_height(Vector2i(5, 5), 2)
	var p := PlayerMover.new(map, MovementRules.new())
	p.fell = true
	p.place(Vector2i(5, 5))
	assert_false(p.fell)
	assert_eq(p.height, 2)
	assert_eq(p.last_safe_cell, Vector2i(5, 5))
	assert_eq(p.pos, HeightMap.cell_center(Vector2i(5, 5)))

func test_cannot_walk_into_water():
	map.set_water(Vector2i(2, 1), true)
	var p := PlayerMover.new(map, MovementRules.new())
	p.place(Vector2i(1, 1))
	for i in 20:
		p.move(Vector2(2, 0))
	assert_eq(p.cell(), Vector2i(1, 1))
