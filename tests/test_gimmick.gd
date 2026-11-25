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

# ---- 2026-11-26（3回目の直し）：仕掛けの種類を増やした

func test_new_kinds_from_data():
	var g := Gimmick.from_data(["cs_1:1", "CRYSTAL", [Vector2i(3, 4), Vector2i(3, 3)], [Vector2i(5, 4)], [2, 3]])
	assert_eq(g.kind, Gimmick.Kind.CRYSTAL)
	assert_eq(g.heights, [2, 3])
	assert_eq(Gimmick.from_data(["x:0", "PLATE", [Vector2i(1, 1)], [Vector2i(2, 2)]]).heights, [])

## 押し板：鉄球を板の上に置く（落とす高さは問わない）と、鉄格子が上がる
func test_plate_opens_bars_when_the_ball_rests_on_it():
	var m := _map()
	var g := _g(Gimmick.Kind.PLATE, [Vector2i(2, 2)], [Vector2i(5, 5)])
	g.close(m)
	assert_true(m.is_wall(Vector2i(2, 2)), "鉄格子")
	assert_eq(m.get_blocker(Vector2i(2, 2)), HeightMap.Blocker.BARS)
	assert_false(m.is_wall(Vector2i(5, 5)), "板の上は歩ける")
	assert_true(g.by_ball(HeightMap.cell_center(Vector2i(5, 5)), 0))
	assert_false(g.by_ball(HeightMap.cell_center(Vector2i(5, 5)) + Vector2(12, 0), 0), "板の外")
	assert_false(g.by_ball(HeightMap.cell_center(Vector2i(2, 2)), 2), "鉄格子に落としても開かない")
	g.open(m)
	assert_false(m.is_wall(Vector2i(2, 2)))

## レバー：となりに立って F で引く（高さの差は1段まで）
func test_lever_is_pulled_from_next_to_it():
	var m := _map()
	m.set_height(Vector2i(6, 1), 3)
	var g := _g(Gimmick.Kind.LEVER, [Vector2i(2, 2)], [Vector2i(5, 1)])
	g.close(m)
	assert_eq(m.get_blocker(Vector2i(2, 2)), HeightMap.Blocker.BARS)
	assert_true(g.by_hand(Vector2i(5, 2), m))
	assert_true(g.by_hand(Vector2i(4, 1), m))
	assert_false(g.by_hand(Vector2i(5, 3), m), "2マス離れている")
	assert_false(g.by_hand(Vector2i(6, 1), m), "高い所からは届かない")
	assert_false(_g(Gimmick.Kind.VINES, [Vector2i(5, 1)]).by_hand(Vector2i(5, 2), m))

## 魔法の水晶：魔法を当てると、足場（cells）が heights の高さまでせり上がる
func test_crystal_raises_steps_when_hit_by_magic():
	var m := _map()
	var g := Gimmick.make("g1", Gimmick.Kind.CRYSTAL, [Vector2i(3, 3), Vector2i(3, 2)], [Vector2i(6, 6)], [2, 3])
	g.close(m)
	assert_eq(m.get_height(Vector2i(3, 3)), 1, "閉じている間は低いまま")
	assert_false(m.is_wall(Vector2i(3, 3)))
	assert_true(g.by_magic(HeightMap.cell_center(Vector2i(6, 6)) + Vector2(8, 0), 4.0))
	assert_false(g.by_magic(HeightMap.cell_center(Vector2i(1, 1)), 4.0))
	assert_false(g.by_fire(HeightMap.cell_center(Vector2i(6, 6)), 4.0), "炎で茨を燃やすのとは別")
	g.open(m)
	assert_eq(m.get_height(Vector2i(3, 3)), 2)
	assert_eq(m.get_height(Vector2i(3, 2)), 3)
	g.open(m)
	assert_eq(m.get_height(Vector2i(3, 2)), 3, "2回開けても同じ高さ")

## もろい壁：爆弾でだけ崩れる（鉄球や剣では崩れない）
func test_brittle_wall_breaks_only_with_a_bomb():
	var m := _map()
	var g := _g(Gimmick.Kind.BRITTLE, [Vector2i(2, 2)])
	g.close(m)
	assert_eq(m.get_blocker(Vector2i(2, 2)), HeightMap.Blocker.BRITTLE)
	assert_true(g.by_bomb(HeightMap.cell_center(Vector2i(2, 2)) + Vector2(20, 0), 20.0))
	assert_false(g.by_bomb(HeightMap.cell_center(Vector2i(6, 6)), 20.0))
	assert_false(g.by_ball(HeightMap.cell_center(Vector2i(2, 2)), 3))
	assert_false(g.by_sword(HeightMap.cell_center(Vector2i(1, 2)), 1, Vector2.RIGHT, m))
	assert_false(_g(Gimmick.Kind.CRACK, [Vector2i(2, 2)]).by_bomb(HeightMap.cell_center(Vector2i(2, 2)), 20.0), "ひびの岩は今までどおり鉄球（爆弾は field が鉄球として扱う）")
