extends GutTest
## 弓と矢（design.md 7章、17.4）。溜めるほど強く遠くへ。矢はカーソルの所へ山なりに飛び、壁を越える。

func _flat(w := 20, h := 5) -> HeightMap:
	return HeightMap.new(Vector2i(w, h))

func test_charge_rate_grows_linearly_to_one():
	var b := Bow.new()
	assert_eq(b.release(), 0.0)  # 溜めていなければ撃たない
	b.start()
	assert_almost_eq(b.rate(), 0.3, 0.001)
	b.update(0.5)
	assert_almost_eq(b.rate(), 0.65, 0.001)
	b.update(1.0)
	assert_almost_eq(b.rate(), 1.0, 0.001)
	assert_almost_eq(b.release(), 1.0, 0.001)
	assert_false(b.charging)

func test_range_grows_with_charge_and_height():
	assert_almost_eq(Bow.max_range(1.0, 0), Bow.BASE_RANGE, 0.01)
	assert_lt(Bow.max_range(0.3, 0), Bow.max_range(1.0, 0))
	assert_gt(Bow.max_range(1.0, 2), Bow.max_range(1.0, 0))
	assert_lt(Bow.max_range(1.0, -2), Bow.max_range(1.0, 0))

func test_landing_at_target_when_in_range():
	var m := _flat()
	var from := HeightMap.cell_center(Vector2i(1, 2))
	var target := from + Vector2(60, 0)
	assert_eq(Bow.landing(from, 0, target, 1.0, m), target)

func test_short_charge_falls_short():
	var m := _flat()
	var from := HeightMap.cell_center(Vector2i(1, 2))
	var target := from + Vector2(100, 0)
	var p := Bow.landing(from, 0, target, 0.3, m)
	assert_lt(p.distance_to(from), 100.0)
	assert_almost_eq(p.distance_to(from), Bow.max_range(0.3, 0), 2.1)

func test_higher_ground_reaches_farther():
	var m := _flat(30)
	for y in 5:
		m.set_height(Vector2i(1, y), 3)
	var from := HeightMap.cell_center(Vector2i(1, 2))
	var target := from + Vector2(Bow.BASE_RANGE + 30, 0)
	assert_eq(Bow.landing(from, 3, target, 1.0, m), target)
	assert_ne(Bow.landing(from, 0, target, 1.0, m), target)

func test_arrow_flies_over_walls_in_an_arc():
	var a := Arrow.new()
	a.launch(Vector2(0, 0), 0.0, Vector2(80, 0), 0.0)
	assert_false(a.update(a.duration * 0.5))
	assert_almost_eq(a.pos().x, 40.0, 0.01)
	assert_gt(a.height_px(), 8.0)  # 山なり
	assert_true(a.update(a.duration))
	assert_eq(a.pos(), Vector2(80, 0))

func test_arrow_hits_only_same_height_near_landing():
	assert_true(Arrow.hits(Vector2(10, 10), 2, Vector2(14, 10), 2))
	assert_false(Arrow.hits(Vector2(10, 10), 2, Vector2(14, 10), 1))
	assert_false(Arrow.hits(Vector2(10, 10), 2, Vector2(30, 10), 2))

func test_poison_arrow_needs_skill():
	assert_true(Arrow.usable(Arrow.Kind.NORMAL, 0))
	assert_false(Arrow.usable(Arrow.Kind.POISON, 0))
	assert_true(Arrow.usable(Arrow.Kind.POISON, 1))
