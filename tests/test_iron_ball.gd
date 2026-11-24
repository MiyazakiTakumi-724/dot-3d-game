extends GutTest

var map: HeightMap
var rules: MovementRules

func before_each():
	map = HeightMap.new(Vector2i(8, 8))
	rules = MovementRules.new()

func _player_at(cell: Vector2i, facing: Vector2) -> PlayerMover:
	var p := PlayerMover.new(map, rules)
	p.pos = HeightMap.cell_center(cell)
	p.height = map.get_height(cell)
	p.facing = facing
	return p

## 目の前のマスの中心（試作1と同じ落とし方）
func _front(p: PlayerMover) -> Vector2:
	return HeightMap.cell_center(p.front_cell())

func test_damage_table():
	assert_eq(IronBall.damage_for(0), 1)
	assert_eq(IronBall.damage_for(3), 4)

func test_drop_from_ledge_damage():
	map.set_height(Vector2i(1, 1), 3)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	watch_signals(b)
	assert_true(b.drop_at(p, map, _front(p)))
	b.update(1.0, p, map, rules)
	assert_signal_emitted_with_parameters(b, "landed", [HeightMap.cell_center(Vector2i(2, 1)), 4])
	assert_eq(b.state, IronBall.State.ON_GROUND)

func test_cannot_reuse_until_picked():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, _front(p))
	assert_false(b.drop_at(p, map, _front(p)))

func test_pick_up_returns_to_held():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, _front(p))
	b.update(1.0, p, map, rules)
	p.move(Vector2(16, 0))
	assert_true(b.try_pick_up(p))
	assert_eq(b.state, IronBall.State.HELD)

func test_cannot_pick_up_from_other_cell():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, _front(p))
	b.update(1.0, p, map, rules)
	assert_false(b.try_pick_up(p))

func test_drop_outside_map_keeps_ball():
	var p := _player_at(Vector2i(0, 0), Vector2.LEFT)
	var b := IronBall.new()
	assert_false(b.drop_at(p, map, _front(p)))
	assert_eq(b.state, IronBall.State.HELD)

func test_drop_into_wall_keeps_ball():
	map.set_wall(Vector2i(2, 1), true)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	assert_false(b.drop_at(p, map, _front(p)))

func test_drop_onto_higher_cell_uses_min_damage():
	map.set_height(Vector2i(2, 1), 1)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	watch_signals(b)
	b.drop_at(p, map, _front(p))
	b.update(1.0, p, map, rules)
	assert_signal_emitted_with_parameters(b, "landed", [HeightMap.cell_center(Vector2i(2, 1)), 1])
	assert_eq(b.height, 1)

func test_unreachable_ball_returns_to_player():
	map.set_height(Vector2i(2, 1), 2)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, _front(p))
	b.update(1.0, p, map, rules)  # 着地
	b.update(1.5, p, map, rules)  # 1秒以上届かない
	assert_eq(b.cell(), Vector2i(1, 1))
	assert_eq(b.height, 0)
	assert_eq(b.state, IronBall.State.ON_GROUND)

func test_reachable_ball_stays():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, _front(p))
	b.update(1.0, p, map, rules)
	b.update(1.5, p, map, rules)
	assert_eq(b.cell(), Vector2i(2, 1))

func test_strong_damage_table():
	assert_eq(IronBall.damage_for(0, true), 2)
	assert_eq(IronBall.damage_for(1, true), 3)
	assert_eq(IronBall.damage_for(-1, true), 2)

func test_switch_only_when_held():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	assert_true(b.set_strong(true))
	b.drop_at(p, map, _front(p))
	assert_false(b.set_strong(false))
	assert_true(b.strong)

func test_strong_ball_lands_with_strong_damage():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.set_strong(true)
	watch_signals(b)
	b.drop_at(p, map, _front(p))
	b.update(1.0, p, map, rules)
	assert_signal_emitted_with_parameters(b, "landed", [HeightMap.cell_center(Vector2i(2, 1)), 2])

func test_cannot_drop_into_pit():
	map.set_pit(Vector2i(2, 1), true)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	assert_false(b.drop_at(p, map, _front(p)))
	assert_eq(b.state, IronBall.State.HELD)

func test_can_drop_onto_grave():
	map.set_blocker(Vector2i(2, 1), HeightMap.Blocker.GRAVE)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	assert_true(b.drop_at(p, map, _front(p)))

func test_cannot_drop_onto_door():
	map.set_blocker(Vector2i(2, 1), HeightMap.Blocker.DOOR)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	assert_false(IronBall.new().drop_at(p, map, _front(p)))

func test_return_to_hand():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, _front(p))
	b.return_to_hand()
	assert_eq(b.state, IronBall.State.HELD)

func test_cannot_drop_into_water():
	map.set_water(Vector2i(2, 1), true)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	assert_false(IronBall.new().drop_at(p, map, _front(p)))

func test_cannot_drop_into_void():
	var m := HeightMap.new(Vector2i(4, 4))
	m.set_void(Vector2i(2, 1), true)
	assert_false(IronBall.can_drop_at(HeightMap.cell_center(Vector2i(2, 1)), m))

func test_reach_point_clamps_to_24px():
	assert_eq(IronBall.reach_point(Vector2.ZERO, Vector2(100, 0)), Vector2(24, 0))
	assert_eq(IronBall.reach_point(Vector2.ZERO, Vector2(10, 5)), Vector2(10, 5))

func test_drop_at_free_position_from_ledge():
	map.set_height(Vector2i(1, 1), 3)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	watch_signals(b)
	var target := p.pos + Vector2(13, 3)  # 隣のマス（高さ0）の、中心でない点
	assert_true(b.drop_at(p, map, target))
	b.update(1.0, p, map, rules)
	assert_signal_emitted_with_parameters(b, "landed", [target, 4])

func test_drop_at_far_cursor_lands_at_reach():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, p.pos + Vector2(200, 0))
	assert_eq(b.pos, p.pos + Vector2(24, 0))

func test_cannot_drop_on_water_point():
	map.set_water(Vector2i(2, 1), true)
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	assert_false(IronBall.new().drop_at(p, map, p.pos + Vector2(16, 0)))

func test_hits_needs_same_height_and_8px():
	assert_true(IronBall.hits(Vector2.ZERO, 1, Vector2(7, 0), 1))
	assert_false(IronBall.hits(Vector2.ZERO, 1, Vector2(9, 0), 1))
	assert_false(IronBall.hits(Vector2.ZERO, 1, Vector2(2, 0), 2))

func test_touches_cell_within_radius():
	# マス(2,1)は x 32〜48。点 x=26 は8px以内
	assert_true(IronBall.touches_cell(Vector2(26, 24), Vector2i(2, 1)))
	assert_false(IronBall.touches_cell(Vector2(20, 24), Vector2i(2, 1)))

func test_pick_up_within_6px():
	var p := _player_at(Vector2i(1, 1), Vector2.RIGHT)
	var b := IronBall.new()
	b.drop_at(p, map, p.pos + Vector2(10, 0))
	b.update(1.0, p, map, rules)
	assert_false(b.try_pick_up(p))
	p.pos += Vector2(5, 0)
	assert_true(b.try_pick_up(p))
