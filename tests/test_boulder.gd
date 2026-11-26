extends GutTest
## 転がる岩（2026-11-26 独自の開発1）。高い所の岩を押すと、低い所へ転がり落ちて速く・痛くなる。

func _map(w: int, h: int) -> HeightMap:
	return HeightMap.new(Vector2i(w, h))

func _roll(b: Boulder, max_steps := 240) -> Array:
	var events: Array = []
	for i in max_steps:
		var ev := b.update(1.0 / 60.0)
		if ev != "":
			events.append(ev)
		if b.state == Boulder.State.GONE:
			break
	return events

## 左の4列は4段、そのあと2段、右は0段の地面。いちばん右の列は壁。
func _stairs() -> HeightMap:
	var m := _map(12, 3)
	for y in 3:
		for x in 12:
			m.set_height(Vector2i(x, y), 4 if x < 4 else (2 if x < 7 else 0))
		m.set_wall(Vector2i(11, y), true)
	return m

func test_a_resting_boulder_blocks_its_cell():
	var m := _stairs()
	var b := Boulder.new(m, Vector2i(3, 1))
	assert_eq(b.state, Boulder.State.REST)
	assert_true(m.is_wall(Vector2i(3, 1)), "置いてある岩は通れない")
	assert_eq(m.get_blocker(Vector2i(3, 1)), HeightMap.Blocker.BOULDER)

func test_push_rolls_it_down_and_it_gets_stronger():
	var m := _stairs()
	var b := Boulder.new(m, Vector2i(3, 1))
	var d0 := b.damage()
	assert_true(b.push(Vector2(1, 0.2)))  # 斜めでも、いちばん近い向きへ
	assert_eq(b.dir, Vector2.RIGHT)
	assert_false(m.is_wall(Vector2i(3, 1)), "転がりだすと、元のマスは通れる")
	var events := _roll(b)
	assert_eq(events.count("drop"), 2, "2回落ちた")
	assert_eq(b.fallen, 4)
	assert_gt(b.damage(), d0, "落ちた段数ほど痛い")
	assert_gt(b.speed(), Boulder.SPEED, "落ちて速くなる")
	assert_eq(events.back(), "crash", "壁で砕ける")
	assert_eq(b.state, Boulder.State.GONE)

func test_cannot_push_into_a_wall_or_uphill():
	var m := _stairs()
	m.set_height(Vector2i(2, 1), 5)
	var b := Boulder.new(m, Vector2i(3, 1))
	assert_false(b.push(Vector2.LEFT), "高い所へは押せない")
	m.set_height(Vector2i(2, 1), 4)
	m.set_wall(Vector2i(2, 1), true)
	assert_false(b.push(Vector2.LEFT), "壁へも押せない")
	assert_eq(b.state, Boulder.State.REST)
	assert_true(m.is_wall(Vector2i(3, 1)))

func test_rolls_on_flat_ground_until_something_stops_it():
	var m := _map(8, 3)
	m.set_height(Vector2i(6, 1), 1)
	var b := Boulder.new(m, Vector2i(1, 1))
	assert_true(b.push(Vector2.RIGHT))
	var events := _roll(b)
	assert_eq(events, ["crash"], "1段でも高い所にぶつかると砕ける")
	assert_eq(b.fallen, 0)
	assert_eq(b.cell(), Vector2i(5, 1))

func test_falls_into_a_pit_and_is_gone():
	var m := _map(8, 3)
	m.set_pit(Vector2i(4, 1), true)
	var b := Boulder.new(m, Vector2i(1, 1))
	b.push(Vector2.RIGHT)
	var events := _roll(b)
	assert_eq(events.back(), "fall")
	assert_eq(b.state, Boulder.State.GONE)

func test_sinks_in_water():
	var m := _map(8, 3)
	m.set_water(Vector2i(4, 1), true)
	var b := Boulder.new(m, Vector2i(1, 1))
	b.push(Vector2.RIGHT)
	assert_eq(_roll(b).back(), "sink")

func test_hits_each_target_once_per_roll():
	var m := _map(8, 3)
	var b := Boulder.new(m, Vector2i(1, 1))
	b.push(Vector2.RIGHT)
	assert_true(b.can_hit("a"))
	assert_false(b.can_hit("a"), "同じ相手には1回だけ")
	assert_true(b.can_hit("b"))

func test_spots_are_high_cells_above_a_drop_with_room_to_push():
	var m := _stairs()
	var spots := Boulder.spots(m, {}, 5, 1)
	assert_gt(spots.size(), 0)
	for c in spots:
		var ok := false
		for d in Boulder.DIRS:
			var behind: Vector2i = c - d
			var front: Vector2i = c + d
			if m.get_height(front) <= m.get_height(c) - Boulder.MIN_DROP and not m.is_wall(front) \
					and m.get_height(behind) == m.get_height(c) and not m.is_wall(behind):
				ok = true
		assert_true(ok, "押す所と落ちる先がある %s" % c)

func test_spots_avoid_given_cells_and_keep_apart():
	var m := _stairs()
	var avoid := {}
	for y in 3:
		avoid[Vector2i(3, y)] = true
	var spots := Boulder.spots(m, avoid, 5, 1)
	for c in spots:
		assert_false(avoid.has(c))
		for o in spots:
			if o != c:
				assert_gt(maxi(absi(o.x - c.x), absi(o.y - c.y)), 2, "岩どうしは離す")

## 1マス幅の高い道（y=1、高さ3）。y=0 は低い地面、y=2 は x0 のくぼみのほかは壁。
func _ridge(x0: int, wide: bool) -> HeightMap:
	var m := _map(9, 3)
	for x in 9:
		m.set_height(Vector2i(x, 0), 0)
		m.set_height(Vector2i(x, 1), 3)
		m.set_height(Vector2i(x, 2), 3)
		m.set_wall(Vector2i(x, 2), not wide and x != x0)
	return m

func test_spots_never_cut_a_narrow_path():
	for x0 in range(1, 8):
		var m := _ridge(x0, false)
		assert_false(Boulder.spots(m, {}, 9, x0).has(Vector2i(x0, 1)), "細い道の途中には置かない（%d）" % x0)

func test_spots_on_a_wide_ridge_are_fine():
	var m := _ridge(4, true)
	assert_gt(Boulder.spots(m, {}, 9, 3).size(), 0)

func test_spots_are_the_same_for_the_same_seed():
	var m := _stairs()
	assert_eq(Boulder.spots(m, {}, 2, 7), Boulder.spots(m, {}, 2, 7))

# ---------------------------------------------------------------- 画面の中で（field）

## 左の4列は4段の台地、その右は低い地面。主人公は台地の上、岩は台地のふち（3,1）、敵は下（7,1）。
func _field_with_boulder():
	var f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)
	var m := HeightMap.new(Vector2i(12, 3))
	for x in 4:
		for y in 3:
			m.set_height(Vector2i(x, y), 4)
	f.map = m
	f.player.mover.map = m
	f.player.mover.place(Vector2i(2, 1))
	f.player.mover.facing = Vector2.RIGHT
	for e in f.enemies:
		e.queue_free()
	f.enemies.clear()
	for r in f.boulders:
		r[1].queue_free()
	f.boulders.clear()
	var b: Boulder = f.add_boulder(Vector2i(3, 1))
	var e := Enemy.new()
	e.setup(m, Vector2i(7, 1), Vector2.UP, f.player, f.camera, EnemyKind.Kind.MELEE, Enemy.SHOOT_INTERVAL, 1)
	add_child_autofree(e)
	f._wire_enemy(e)
	f.enemies.append(e)
	e.set_process(false)
	return [f, b, e]

func _run_field(f, seconds: float) -> void:
	for i in int(seconds * 60.0):
		f._step_boulders(1.0 / 60.0)

func test_f_pushes_the_boulder_off_the_ledge_onto_an_enemy():
	var fbe = _field_with_boulder()
	var f = fbe[0]
	var b: Boulder = fbe[1]
	var e: Enemy = fbe[2]
	assert_eq(f.boulder_here(), b)
	var hp0 := e.walker.hp
	assert_true(f.try_push_boulder())
	assert_true(b.rolling())
	_run_field(f, 1.0)
	assert_eq(b.fallen, 4)
	assert_eq(e.walker.hp, hp0 - b.damage_to(e.walker.max_hp), "落ちた岩は痛い")
	assert_true(e.walker.knocking() or e.walker.pos.x > HeightMap.cell_center(Vector2i(7, 1)).x, "岩に押される")

func test_sword_pushes_the_boulder():
	var fbe = _field_with_boulder()
	var f = fbe[0]
	var b: Boulder = fbe[1]
	f.run.inventory.equipment.gain("sword_1")
	f.hotbar.select_slot(2, f.run.inventory.equipment)
	assert_true(f.swing_sword())
	assert_true(b.rolling(), "剣で押せる")

func test_cannot_push_from_below():
	var fbe = _field_with_boulder()
	var f = fbe[0]
	f.player.mover.place(Vector2i(4, 1))  # 台地の下
	assert_null(f.boulder_here(), "下からは押せない")

func test_rolling_boulder_breaks_a_cracked_rock():
	var fbe = _field_with_boulder()
	var f = fbe[0]
	var b: Boulder = fbe[1]
	var g := Gimmick.make("test_crack_boulder", Gimmick.Kind.CRACK, [Vector2i(9, 1)], [Vector2i(9, 1)])
	g.close(f.map)
	f.area.gimmicks.append(g)
	f.try_push_boulder()
	_run_field(f, 2.0)
	assert_true(f.run.is_gimmick_open("test_crack_boulder"), "ひびの岩を砕く")
	assert_eq(b.state, Boulder.State.GONE)
	f.area.gimmicks.erase(g)

func test_some_areas_have_boulders_and_town_has_none():
	var f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)
	assert_eq(f.boulders.size(), 0, "町には置かない")
	var total := 0
	for id in ["rocks", "mt_1", "mt_3", "gr_1", "cs_1"]:
		f.enter_area(id, Vector2i(1, 1))
		total += f.boulders.size()
		for r in f.boulders:
			assert_true(f.map.is_wall(r[0].cell()), "置いた岩はマスをふさぐ")
	assert_gt(total, 0, "高い所のあるエリアには岩がある")
