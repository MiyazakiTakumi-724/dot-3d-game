extends GutTest
## 武器で開く仕掛け（ひびの入った岩・的と橋・茨・つた）。

func _map() -> HeightMap:
	var m := HeightMap.new(Vector2i(8, 8))
	for y in 8:
		for x in 8:
			m.set_height(Vector2i(x, y), 1)
	return m

func _g(kind: Gimmick.Kind, cells: Array, trigger: Array = []) -> Gimmick:
	return Gimmick.make("g1", kind, cells, trigger if not trigger.is_empty() else cells)

func test_from_data_reads_kind_and_cells():
	var g := Gimmick.from_data(["mt_1:0", "TARGET", [Vector2i(3, 1), Vector2i(3, 2)], [Vector2i(5, 1)]])
	assert_eq(g.id, "mt_1:0")
	assert_eq(g.kind, Gimmick.Kind.TARGET)
	assert_eq(g.cells, [Vector2i(3, 1), Vector2i(3, 2)])
	assert_eq(g.trigger, [Vector2i(5, 1)])

func test_closed_crack_thorns_vines_block_the_cells():
	for k in [Gimmick.Kind.CRACK, Gimmick.Kind.THORNS, Gimmick.Kind.VINES]:
		var m := _map()
		var g := _g(k, [Vector2i(2, 2)])
		g.close(m)
		assert_true(m.is_wall(Vector2i(2, 2)), str(k))
		g.open(m)
		assert_false(m.is_wall(Vector2i(2, 2)), str(k))

func test_target_bridge_is_water_until_opened():
	var m := _map()
	var g := _g(Gimmick.Kind.TARGET, [Vector2i(3, 3), Vector2i(3, 4)], [Vector2i(6, 3)])
	g.close(m)
	assert_true(m.is_water(Vector2i(3, 3)))
	g.open(m)
	assert_false(m.is_water(Vector2i(3, 3)))
	assert_false(m.is_water(Vector2i(3, 4)))

func test_ball_can_be_dropped_on_a_crack_but_not_on_thorns():
	var m := _map()
	_g(Gimmick.Kind.CRACK, [Vector2i(2, 2)]).close(m)
	_g(Gimmick.Kind.THORNS, [Vector2i(4, 2)]).close(m)
	assert_true(IronBall.can_drop_at(HeightMap.cell_center(Vector2i(2, 2)), m, 2))
	assert_false(IronBall.can_drop_at(HeightMap.cell_center(Vector2i(4, 2)), m, 2))

func test_crack_breaks_only_when_dropped_from_above():
	var g := _g(Gimmick.Kind.CRACK, [Vector2i(2, 2)])
	var p := HeightMap.cell_center(Vector2i(2, 2))
	assert_true(g.by_ball(p, 1))
	assert_false(g.by_ball(p, 0))
	assert_false(g.by_ball(HeightMap.cell_center(Vector2i(5, 5)), 3))

func test_other_kinds_ignore_the_ball():
	var g := _g(Gimmick.Kind.THORNS, [Vector2i(2, 2)])
	assert_false(g.by_ball(HeightMap.cell_center(Vector2i(2, 2)), 2))

func test_target_opens_when_an_arrow_lands_on_it():
	var g := _g(Gimmick.Kind.TARGET, [Vector2i(3, 3)], [Vector2i(6, 3)])
	assert_true(g.by_arrow(HeightMap.cell_center(Vector2i(6, 3)) + Vector2(5, 0)))
	assert_false(g.by_arrow(HeightMap.cell_center(Vector2i(3, 3))))

func test_thorns_burn_from_fire_nearby():
	var g := _g(Gimmick.Kind.THORNS, [Vector2i(2, 2)])
	assert_true(g.by_fire(HeightMap.cell_center(Vector2i(2, 2)) + Vector2(10, 0), 8.0))
	assert_false(g.by_fire(HeightMap.cell_center(Vector2i(6, 6)), 8.0))
	assert_false(_g(Gimmick.Kind.VINES, [Vector2i(2, 2)]).by_fire(HeightMap.cell_center(Vector2i(2, 2)), 8.0))

func test_vines_are_cut_by_a_sword_facing_them():
	var m := _map()
	var g := _g(Gimmick.Kind.VINES, [Vector2i(3, 2)])
	var from := HeightMap.cell_center(Vector2i(2, 2))
	assert_true(g.by_sword(from, 1, Vector2.RIGHT, m))
	assert_false(g.by_sword(from, 1, Vector2.LEFT, m))
	assert_false(g.by_sword(from, 0, Vector2.RIGHT, m))  # 下からは届かない
