extends GutTest
## 大陸のエリアの地図を確かめる（tools/area_maps/gen.py で作った地図）。
## 仕掛けで閉じた所があるので、「仕掛けをすべて開けた地図」（open_maps）でも確かめる。
const Reach = preload("res://tests/helpers/reach.gd")

## 速さ60px/秒、1マス16px → 1秒で3.75マス
const CELLS_PER_SECOND := 60.0 / 16.0

var world: WorldMap
var rules := MovementRules.new()
var maps := {}
var open_maps := {}

func before_all():
	world = Continent.build()
	for id in world.ids():
		maps[id] = Continent.load_map(world.area(id))[0]
		var m: HeightMap = Continent.load_map(world.area(id))[0]
		for g in world.area(id).gimmicks:
			g.open(m)
		open_maps[id] = m

## エリアの中の出発点（たき火があればその南、なければ仕掛けで閉じていない出口）。
func _hub(id: String) -> Vector2i:
	var a := world.area(id)
	var info: Dictionary = Continent.load_map(a)[1]
	if info.has("checkpoint"):
		return info["checkpoint"] + Vector2i(0, 1)
	var m: HeightMap = maps[id]
	for ex in a.exits:
		var c := _mid(id, ex, 1)
		if Reach.reachable(m, rules, c).size() > 40:
			return c
	return _mid(id, a.exits[0], 1)

func _mid(area_id: String, ex: ExitDef, inward: int) -> Vector2i:
	var a := world.area(area_id)
	var cells := ex.cells(a.size())
	return cells[cells.size() / 2] - ex.outward() * inward

func _exit_to(area_id: String, target: String, gated: bool) -> ExitDef:
	for ex in world.area(area_id).exits:
		if ex.target == target and (ex.door_id != "") == gated:
			return ex
	return null

func test_continent_has_no_problems():
	assert_eq(world.problems(), [])

func test_all_areas():
	assert_eq(world.ids().size(), 52)  # 30 ＋ 寄り道（各地方3）・草原と廃城の隠しボス・塔の回廊（2026-11-25 夜）＋霧の谷6（2026-11-26）＋霧見の宿場（2026-11-27）
	for id in ["town", "rocks", "hills", "forest", "mt_5", "gr_5", "cs_5", "lv_5", "tw_4"]:
		assert_not_null(world.area(id), id)
	assert_null(world.area("camp"), "野営地は町に作り替えた")

## エリアはせまい（2026-11-25 の指示）。2026-11-26（3回目の直し）に、ランダムに少し広げた（gen.py の inflate_all）。
## いちばん大きくても 34×28 くらい
func test_areas_are_small():
	for id in world.ids():
		var s := world.area(id).size()
		assert_lte(s.x * s.y, 1000, "%s %s" % [id, s])

## 2026-11-26（3回目の直し）：町と休憩所のほかのエリアは、四角でない形（ふちが島の外になっている。gen.py の roughen）
func test_area_shapes_are_not_rectangles():
	for id in world.ids():
		var a := world.area(id)
		if id == "town" or Continent.load_map(a)[1].has("checkpoint"):
			continue
		var m: HeightMap = maps[id]
		var outside := 0
		for y in m.size.y:
			for x in m.size.x:
				if m.is_void(Vector2i(x, y)):
					outside += 1
		assert_gt(outside, m.size.x * m.size.y / 20, "%s 島の外 %d" % [id, outside])

func test_heights_within_0_to_8():
	for id in world.ids():
		var m: HeightMap = maps[id]
		for y in m.size.y:
			for x in m.size.x:
				assert_between(m.get_height(Vector2i(x, y)), 0, 8)

func test_flats_are_small_outside_camp():
	for id in world.ids():
		if world.area(id).open_flat:
			continue
		var m: HeightMap = maps[id]
		var found := false
		for y0 in m.size.y - 11:
			for x0 in m.size.x - 11:
				var h := m.get_height(Vector2i(x0, y0))
				var flat := true
				for y in range(y0, y0 + 12):
					for x in range(x0, x0 + 12):
						if m.get_height(Vector2i(x, y)) != h:
							flat = false
							break
					if not flat:
						break
				found = found or flat
		assert_false(found, id)

func test_every_exit_reachable_both_ways():
	for id in world.ids():
		var a := world.area(id)
		var m: HeightMap = open_maps[id]
		var hub := _hub(id)
		var fwd := Reach.reachable(m, rules, hub)
		var back := Reach.reachable(m, rules, hub, true)
		for ex in a.exits:
			for c in ex.cells(a.size()):
				assert_true(fwd.has(c) and back.has(c), "%s %s" % [id, c])

func test_enemies_and_pickups_reachable():
	for id in world.ids():
		var a := world.area(id)
		var m: HeightMap = open_maps[id]
		var fwd := Reach.reachable(m, rules, _hub(id))
		for e in a.enemies:
			assert_true(fwd.has(e[0]), "%s enemy %s" % [id, e[0]])
		for p in a.pickups:
			assert_true(fwd.has(p[0]), "%s pickup %s" % [id, p[0]])

func test_no_pocket_without_exit():
	for id in world.ids():
		for m: HeightMap in [maps[id], open_maps[id]]:
			var hub := _hub(id)
			var back := Reach.reachable(m, rules, hub, true)
			for c in Reach.reachable(m, rules, hub):
				assert_true(back.has(c), "%s pocket %s" % [id, c])

func test_no_enemy_near_entries():
	for id in world.ids():
		var safe := world.area(id).entry_safe_cells()
		for e in world.area(id).enemies:
			assert_false(safe.has(e[0]), "%s %s" % [id, e[0]])

## 町とたき火のある休憩所のほかのすべてのエリアに敵がいる（ボスの間はボスだけ）。種類は地方ごと、レベルは地方のレベル
func test_enemies_everywhere_but_town():
	for id in world.ids():
		var a := world.area(id)
		if id == "town" or Continent.load_map(a)[1].has("checkpoint"):
			assert_eq(a.enemies.size(), 0, id)
			continue
		if not a.bosses.is_empty():
			continue
		assert_gt(a.enemies.size(), 0, id)
		for e in a.enemies:
			assert_eq(e[3], Loot.region_level(a.region), id)

func test_many_enemy_kinds():
	var kinds := {}
	for id in world.ids():
		for e in world.area(id).enemies:
			kinds[e[2]] = true
	assert_eq(kinds.size(), EnemyKind.Kind.size())

## 拾いものはすべて品物の id。装備は宝箱だけのものがなく、ランク5は落ちていない
func test_pickups_are_known_items_and_no_chest_only_gear():
	var potions := 0
	for id in world.ids():
		for p in world.area(id).pickups:
			assert_true(ItemCatalog.known(p[1]), "%s %s" % [id, p[1]])
			if p[1] == "potion":
				potions += 1
			if ItemCatalog.exists(p[1]):
				assert_lt(ItemCatalog.rank(p[1]), 5, p[1])
				var other := ItemCatalog.sources(p[1]).filter(func(s): return s != "chest")
				assert_gt(other.size(), 0, p[1])
	assert_gt(potions, 1)

func _heavy_ball() -> Vector2i:
	for p in world.area("forest").pickups:
		if p[1] == "ball_heavy":
			return p[0]
	return Vector2i(-1, -1)

## 門を開けた後は、奥の森の台地（重い鉄球）のあたり→町のたき火が30秒以内
func test_gate_is_a_short_way_back():
	var gate := _exit_to("forest", "town", true)
	var town_gate := _exit_to("town", "forest", true)
	assert_true(gate.opens_here)
	assert_false(town_gate.opens_here)
	var r1 := Reach.distance(maps["forest"], rules, _heavy_ball(), _mid("forest", gate, 0))
	var r2 := Reach.distance(maps["town"], rules, _mid("town", town_gate, 1), Continent.START_CELL)
	assert_gt(r1, 0)
	assert_gt(r2, 0)
	assert_lt((r1 + r2) / CELLS_PER_SECOND, 30.0)

func test_town_has_bonfire_shops_and_no_enemies():
	var a := world.area("town")
	var info: Dictionary = Continent.load_map(a)[1]
	assert_true(info.has("checkpoint"))
	assert_eq(a.enemies.size(), 0)
	var shops := a.merchants.map(func(m): return m[1])
	assert_eq(shops, ["tool", "weapon", "smith"])
	assert_eq(info.get("merchants", []).size(), 3)

## 旅の商人は4つの地方と霧の谷の休憩所に1人ずつ
func test_travelling_merchants():
	var shops := {}
	for id in world.ids():
		for m in world.area(id).merchants:
			assert_true(Shop.NAMES.has(m[1]), m[1])
			shops[m[1]] = id
	for r in ["山岳", "草原", "廃城", "溶岩", "霧の谷"]:
		assert_true(shops.has(r), r)
		assert_eq(world.area(shops[r]).region, r)

# ---- 大陸の全体（2026-11-25）

## 出口から入ったとき、そのエリアで歩いて行ける出口（CRACK の仕掛けだけは開けてよい。鉄球は最初から持っている）。
func _exits_from(id: String, cell: Vector2i, use_all: bool) -> Array[ExitDef]:
	var a := world.area(id)
	var m: HeightMap = open_maps[id] if use_all else Continent.load_map(a)[0]
	if not use_all:
		for g in a.gimmicks:
			if g.kind == Gimmick.Kind.CRACK:
				g.open(m)
	var fwd := Reach.reachable(m, rules, cell)
	var out: Array[ExitDef] = []
	for ex in a.exits:
		for c in ex.cells(a.size()):
			if fwd.has(c):
				out.append(ex)
				break
	return out

## 町から出口をたどって行けるエリア。門と封印は開けられるものとする。
func _reachable_areas(use_all: bool) -> Dictionary:
	var seen := {"town": true}
	var queue := [["town", Continent.START_CELL]]
	while not queue.is_empty():
		var cur = queue.pop_front()
		for ex in _exits_from(cur[0], cur[1], use_all):
			if seen.has(ex.target):
				continue
			seen[ex.target] = true
			var c: Vector2i = ex.cells(world.area(cur[0]).size())[0]
			queue.append([ex.target, world.arrival(cur[0], ex, c)["cell"]])
	return seen

## 本道：武器の仕掛け（弓・炎・剣）を開けなくても、すべての地方のボスの間まで行ける（好きな順で回れるので）
func test_main_path_reaches_every_boss_without_weapon_gimmicks():
	var seen := _reachable_areas(false)
	for id in ["mt_5", "gr_5", "cs_5", "lv_5", "tw_2", "tw_3", "tw_4", "mv_5"]:
		assert_true(seen.has(id), id)
	for id in ["mt_x", "lv_x", "gr_x", "cs_x"]:
		assert_false(seen.has(id), "隠しボスは仕掛けの先 " + id)
	for id in ["mt_6", "mt_7", "mt_8", "gr_6", "gr_7", "gr_8", "cs_6", "cs_7", "cs_8", "lv_6", "lv_7", "lv_8"]:
		assert_true(seen.has(id), "寄り道のエリアは仕掛けなしで行ける " + id)

func test_every_area_reachable_with_all_gimmicks_open():
	assert_eq(_reachable_areas(true).size(), world.ids().size())

func test_regions_have_bonfire_boss_and_shortcut():
	var fires := {}
	var bosses := {}
	var gates := {}
	for id in world.ids():
		var a := world.area(id)
		var info: Dictionary = Continent.load_map(a)[1]
		if info.has("checkpoint") and a.theme != "town":  # 町（はじまりの町・霧見の宿場）のたき火は数えない
			fires[a.region] = fires.get(a.region, 0) + 1
		bosses[a.region] = bosses.get(a.region, 0) + a.bosses.size()
		for ex in a.exits:
			if ex.door_id != "" and ex.opens_here:
				gates[ex.door_id] = true
	for r in ["山岳", "草原", "廃城", "溶岩", "神秘の塔", "霧の谷"]:
		assert_eq(fires.get(r, 0), 1, r)
		assert_gt(bosses.get(r, 0), 0, r)
	assert_eq(bosses["神秘の塔"], 4, "双子（2体）・番人・ブライト")
	for d in ["forest_gate", "mt_gate", "gr_gate", "cs_gate", "lv_gate", "mv_gate", RunState.SEAL_DOOR, Story.MIST_DOOR, Story.KEEP_DOOR]:
		assert_true(gates.has(d), d)
	for d in RunState.BOSS_DOORS:
		assert_true(gates.has(d), d)

## 4つの地方には、地方の印が3つずつ（寄り道のエリアに1つずつ、仕掛けの奥ではない）。隠しボスは1エリアに1体
func test_three_seals_per_region_and_one_hidden_boss_each():
	var seals := {}
	var hidden := {}
	for id in world.ids():
		var a := world.area(id)
		var reach := Reach.reachable(maps[id], rules, _hub(id))
		for p in a.pickups:
			if ItemCatalog.is_key(p[1]):
				seals[p[1]] = seals.get(p[1], 0) + 1
				assert_true(reach.has(p[0]), "%s %s" % [id, p[0]])
		if id.ends_with("_x"):
			assert_eq(a.bosses.size(), 1, id)
			hidden[a.region] = true
	for seal in RunState.BOSS_DOORS.values():
		assert_eq(seals.get(seal, 0), RunState.SEALS_PER_DOOR, seal)
	assert_eq(hidden.size(), 4)

## 2026-11-25 夜（2回目の直し）：たき火のある休憩所はせまい（歩ける所はたき火の広場と出口への道だけ）。敵はいない
func test_bonfire_areas_are_small_and_safe():
	var n := 0
	for id in world.ids():
		var a := world.area(id)
		if a.theme == "town" or not Continent.load_map(a)[1].has("checkpoint"):
			continue
		n += 1
		assert_eq(a.enemies.size(), 0, id)
		var m: HeightMap = maps[id]
		var walk := 0
		for y in m.size.y:
			for x in m.size.x:
				var c := Vector2i(x, y)
				if not m.is_wall(c) and not m.is_water(c) and not m.is_pit(c):
					walk += 1
		assert_lte(walk, 185, "%s 歩けるマス %d" % [id, walk])  # 2026-11-26 にエリアを広げたので、出口への道が少し長い。霧の谷の村跡は広場が広い
		assert_lte(walk * 2, m.size.x * m.size.y, "%s 半分より多く歩ける" % id)
	assert_eq(n, 6, "4つの地方と神秘の塔と霧の谷の休憩所")

func test_bonfire_has_room_to_respawn():
	for id in world.ids():
		var info: Dictionary = Continent.load_map(world.area(id))[1]
		if info.has("checkpoint"):
			var m: HeightMap = maps[id]
			var c: Vector2i = info["checkpoint"] + Vector2i(0, 1)
			assert_false(m.is_wall(c) or m.is_water(c) or m.is_pit(c), id)

## 2026-11-26（3回目の直し）：仕掛けは8種類（押し板・レバー・魔法の水晶・もろい壁を足した）。どれも2か所以上
func test_all_gimmick_kinds_are_used():
	var kinds := {}
	for id in world.ids():
		for g in world.area(id).gimmicks:
			kinds[g.kind] = kinds.get(g.kind, 0) + 1
	assert_eq(kinds.size(), Gimmick.Kind.size())
	for k in kinds:
		assert_gte(kinds[k], 2, Gimmick.Kind.keys()[k])

## 仕掛けの宝は、閉じている間は取れず、開けると取れる
func test_gimmick_rewards_locked_until_opened():
	var locked := 0
	for id in world.ids():
		var a := world.area(id)
		var closed := Reach.reachable(maps[id], rules, _hub(id))
		var opened := Reach.reachable(open_maps[id], rules, _hub(id))
		for p in a.pickups:
			if not closed.has(p[0]):
				locked += 1
				assert_true(opened.has(p[0]), "%s %s" % [id, p[0]])
	assert_gt(locked, 8)

## 霧の谷（2026-11-26）：沼の小道の南の霧の門の先。村跡（たき火）に村のお守りがあり、闇の砦の門の鍵になる
func test_mist_valley():
	var mv := []
	for id in world.ids():
		if world.area(id).region == "霧の谷":
			mv.append(id)
			assert_eq(world.area(id).theme, "mist", id)
	assert_eq(mv.size(), 6)
	assert_not_null(_exit_to("gr_6", "mv_1", true), "沼の小道から霧の門")
	assert_eq(_exit_to("gr_6", "mv_1", true).door_id, Story.MIST_DOOR)
	assert_eq(_exit_to("mv_4", "mv_5", true).door_id, Story.KEEP_DOOR)
	var keep := false
	var reach := Reach.reachable(maps["mv_2"], rules, _hub("mv_2"))
	for p in world.area("mv_2").pickups:
		if p[1] == Story.KEEPSAKE:
			keep = true
			assert_true(reach.has(p[0]), "お守りはたき火から取りに行ける")
	assert_true(keep)
	assert_eq(world.area("mv_5").bosses[0][1], Story.DARK_KING)
	for k in [EnemyKind.Kind.WOLF, EnemyKind.Kind.DARK_KNIGHT]:
		var found := false
		for id in mv:
			for e in world.area(id).enemies:
				found = found or e[2] == k
		assert_true(found, EnemyKind.name_of(k))
