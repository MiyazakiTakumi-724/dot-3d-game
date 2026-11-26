extends GutTest
## 町の人が歩きまわる（2026-11-27）。家（home）のまわりの歩いてよいマスだけを、1マスずつ歩いて、ときどき立ち止まる。

func _area(home: Vector2i, r: int) -> Dictionary:
	var a := {}
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			a[home + Vector2i(dx, dy)] = true
	return a

func _free(_c: Vector2i) -> bool:
	return true

func test_starts_at_home_and_waits_first() -> void:
	var w := Wanderer.make(Vector2i(5, 5), _area(Vector2i(5, 5), 2), 1)
	assert_eq(w.cell, Vector2i(5, 5))
	assert_eq(w.pos, HeightMap.cell_center(Vector2i(5, 5)))
	assert_false(w.moving)
	w.update(0.1, _free)
	assert_false(w.moving, "はじめは少し立っている")

func test_walks_one_cell_at_a_time_inside_its_area() -> void:
	var home := Vector2i(5, 5)
	var area := _area(home, 2)
	var w := Wanderer.make(home, area, 7)
	var moved := false
	for i in 2000:
		w.update(0.05, _free)
		assert_true(area.has(w.cell), "歩いてよいマスの中だけ")
		if w.moving:
			moved = true
			assert_eq((w.cell - w.from_cell).abs().x + (w.cell - w.from_cell).abs().y, 1, "となりのマスへ1つずつ")
	assert_true(moved, "そのうち歩きだす")

func test_occupied_lists_both_cells_while_walking() -> void:
	var w := Wanderer.make(Vector2i(5, 5), _area(Vector2i(5, 5), 2), 3)
	while not w.moving:
		w.update(0.05, _free)
	var occ := w.occupied()
	assert_eq(occ.size(), 2)
	assert_has(occ, w.cell)
	assert_has(occ, w.from_cell)
	while w.moving:
		w.update(0.05, _free)
	assert_eq(w.occupied(), [w.cell] as Array[Vector2i])

func test_never_steps_into_a_cell_that_is_not_free() -> void:
	var home := Vector2i(5, 5)
	var w := Wanderer.make(home, _area(home, 2), 11)
	var no_east := func(c: Vector2i) -> bool: return c.x <= home.x
	for i in 2000:
		w.update(0.05, no_east)
		assert_lte(w.cell.x, home.x, "ふさがったマスへは行かない")

func test_stays_put_when_boxed_in() -> void:
	var w := Wanderer.make(Vector2i(5, 5), {Vector2i(5, 5): true}, 5)
	for i in 400:
		w.update(0.05, _free)
	assert_eq(w.cell, Vector2i(5, 5))
	assert_false(w.moving)

func test_hold_stops_new_steps() -> void:
	var w := Wanderer.make(Vector2i(5, 5), _area(Vector2i(5, 5), 2), 9)
	w.hold(Wanderer.TALK_PAUSE)
	var c := w.cell
	for i in int(Wanderer.TALK_PAUSE / 0.05) - 2:
		w.update(0.05, _free)
		assert_eq(w.cell, c, "話したあとは少し立ち止まる")

func test_walk_speed_and_bob() -> void:
	var w := Wanderer.make(Vector2i(5, 5), _area(Vector2i(5, 5), 2), 2)
	while not w.moving:
		w.update(0.05, _free)
	var p0 := w.pos
	w.update(0.1, _free)
	assert_almost_eq(w.pos.distance_to(p0), Wanderer.SPEED * 0.1, 0.01)
	var lifts := {}
	for i in 12:
		w.update(0.05, _free)
		lifts[w.lift()] = true
	assert_true(lifts.has(0.0) and lifts.has(Wanderer.BOB), "歩くと少しはねる")
	while w.moving:
		w.update(0.05, _free)
	assert_eq(w.lift(), 0.0)

func test_same_seed_same_walk() -> void:
	var a := Wanderer.make(Vector2i(5, 5), _area(Vector2i(5, 5), 3), 42)
	var b := Wanderer.make(Vector2i(5, 5), _area(Vector2i(5, 5), 3), 42)
	for i in 600:
		a.update(0.05, _free)
		b.update(0.05, _free)
	assert_eq(a.cell, b.cell)
	assert_eq(a.pos, b.pos)

func test_facing_follows_the_step() -> void:
	var w := Wanderer.make(Vector2i(5, 5), _area(Vector2i(5, 5), 2), 4)
	while not w.moving:
		w.update(0.05, _free)
	assert_eq(w.facing, Vector2(w.cell - w.from_cell))
