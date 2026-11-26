extends GutTest
## 幻の橋（2026-11-26 独自の開発1）。印の目が向く方を画面の上にして見たときだけ、橋が見えて歩ける。

## 左の3列は高さ4（行ける）、x=3,4 は高さ0の地面、x=5〜7 は高さ4（行けない台）。
func _gap_map() -> HeightMap:
	var m := HeightMap.new(Vector2i(8, 3))
	for y in 3:
		for x in 8:
			m.set_height(Vector2i(x, y), 4 if (x < 3 or x > 4) else 0)
	return m

func _reach() -> Dictionary:
	var r := {}
	for y in 3:
		for x in 5:
			r[Vector2i(x, y)] = true  # 台の上（x<3）と下の地面（x=3,4）。x>4 の台へは登れない
	return r

func test_find_bridges_the_gap_to_the_unreachable_ledge():
	var m := _gap_map()
	var b := PhantomBridge.find(m, _reach(), {}, 1)
	assert_not_null(b)
	assert_eq(b.dir, Vector2i.RIGHT)
	assert_eq(b.start.x, 2)
	assert_eq(b.goal.x, 5)
	assert_eq(b.cells.size(), 2)
	assert_eq(b.height, 4)

func test_no_bridge_when_the_other_side_is_reachable():
	var m := _gap_map()
	var r := _reach()
	for y in 3:
		for x in range(5, 8):
			r[Vector2i(x, y)] = true
	assert_null(PhantomBridge.find(m, r, {}, 1))

func test_no_bridge_over_pits_or_water():
	var m := _gap_map()
	for y in 3:
		m.set_pit(Vector2i(3, y), true)
	assert_null(PhantomBridge.find(m, _reach(), {}, 1), "下が奈落なら置かない")
	m = _gap_map()
	for y in 3:
		m.set_water(Vector2i(4, y), true)
	assert_null(PhantomBridge.find(m, _reach(), {}, 1), "下が水なら置かない")

func test_shows_only_from_its_view_angle():
	var m := _gap_map()
	var b := PhantomBridge.find(m, _reach(), {}, 1)
	# 右（+x）を画面の上にする角度
	var a := b.view_angle()
	assert_almost_eq(Vector2(0, -1).rotated(a).x, 1.0, 0.001)
	assert_true(b.shows(a))
	assert_true(b.shows(a + 0.3))
	assert_false(b.shows(a + PI / 2.0))
	assert_eq(b.alpha(a), 1.0)
	assert_eq(b.alpha(a + PI), 0.0)
	assert_between(b.alpha(a + (PhantomBridge.SHOW + PhantomBridge.HINT) / 2.0), 0.01, 0.99, "近いとうすく光る")

func test_update_makes_the_cells_walkable_and_back():
	var m := _gap_map()
	var b := PhantomBridge.find(m, _reach(), {}, 1)
	assert_true(b.update(m, b.view_angle(), Vector2i(0, 0), 0.1))
	assert_true(b.solid)
	for c in b.cells:
		assert_eq(m.get_height(c), 4, "橋の上は高い所と同じ高さ")
	assert_true(b.update(m, b.view_angle() + PI, Vector2i(0, 0), 0.1))
	for c in b.cells:
		assert_eq(m.get_height(c), 0, "消えると元の地面")

func test_standing_on_it_gives_a_little_grace():
	var m := _gap_map()
	var b := PhantomBridge.find(m, _reach(), {}, 1)
	b.update(m, b.view_angle(), Vector2i(0, 0), 0.1)
	var on: Vector2i = b.cells[0]
	assert_false(b.update(m, b.view_angle() + PI, on, 0.3), "乗っている間は少し待つ")
	assert_true(b.solid)
	assert_true(b.update(m, b.view_angle() + PI, on, 0.4))
	assert_false(b.solid)

func test_region_lists_the_far_side():
	var m := _gap_map()
	var room := PhantomBridge.region(m, Vector2i(5, 1), _reach())
	assert_eq(room.size(), 9)
