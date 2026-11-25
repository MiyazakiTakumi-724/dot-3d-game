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
	assert_eq(world.ids().size(), 31)
	for id in ["camp", "forest", "town", "mt_5", "gr_5", "cs_5", "lv_5", "tw_4"]:
		assert_not_null(world.area(id), id)

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

func test_shooters_only_in_forest():
	for id in world.ids():
		var weak := 0
		var melee := 0
		for e in world.area(id).enemies:
			if e[2] == EnemyKind.Kind.SHOOTER:
				assert_eq(id, "forest")
			elif e[2] == EnemyKind.Kind.WEAK:
				weak += 1
			else:
				melee += 1
		if id in ["rocks", "hills"]:
			assert_gt(weak, melee, id)

func test_one_strong_ball_in_forest_and_heals():
	var balls := 0
	var heals := 0
	for id in world.ids():
		for p in world.area(id).pickups:
			if p[1] == RunState.PickupKind.STRONG_BALL:
				balls += 1
				assert_eq(id, "forest")
			elif p[1] == RunState.PickupKind.HEAL:
				heals += 1
	assert_eq(balls, 1)
	assert_gt(heals, 1)

func _strong_ball() -> Vector2i:
	for p in world.area("forest").pickups:
		if p[1] == RunState.PickupKind.STRONG_BALL:
			return p[0]
	return Vector2i(-1, -1)

## たき火→丘陵→奥の森の強い鉄球まで、歩いて90秒以上
func test_route_to_strong_ball_is_long():
	var to_hills := _exit_to("camp", "hills", false)
	var from_camp := _exit_to("hills", "camp", false)
	var to_forest := _exit_to("hills", "forest", false)
	var from_hills := _exit_to("forest", "hills", false)
	var d1 := Reach.distance(maps["camp"], rules, Continent.START_CELL, _mid("camp", to_hills, 0))
	var d2 := Reach.distance(maps["hills"], rules, _mid("hills", from_camp, 1), _mid("hills", to_forest, 0))
	var d3 := Reach.distance(maps["forest"], rules, _mid("forest", from_hills, 1), _strong_ball())
	assert_gt(d1, 0)
	assert_gt(d2, 0)
	assert_gt(d3, 0)
	assert_gt((d1 + d2 + d3) / CELLS_PER_SECOND, 90.0)

## 門を開けた後は、強い鉄球のあたり→たき火が30秒以内
func test_gate_is_a_short_way_back():
	var gate := _exit_to("forest", "camp", true)
	var camp_gate := _exit_to("camp", "forest", true)
	assert_true(gate.opens_here)
	assert_false(camp_gate.opens_here)
	var r1 := Reach.distance(maps["forest"], rules, _strong_ball(), _mid("forest", gate, 0))
	var r2 := Reach.distance(maps["camp"], rules, _mid("camp", camp_gate, 1), Continent.START_CELL)
	assert_gt(r1, 0)
	assert_gt(r2, 0)
	assert_lt((r1 + r2) / CELLS_PER_SECOND, 30.0)

func test_camp_has_bonfire_and_no_enemies():
	var info: Dictionary = Continent.load_map(world.area("camp"))[1]
	assert_true(info.has("checkpoint"))
	assert_eq(world.area("camp").enemies.size(), 0)


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

## 野営地から出口をたどって行けるエリア。門と封印は開けられるものとする。
func _reachable_areas(use_all: bool) -> Dictionary:
	var seen := {"camp": true}
	var queue := [["camp", Continent.START_CELL]]
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
	for id in ["mt_5", "gr_5", "cs_5", "lv_5", "tw_2", "tw_3", "tw_4"]:
		assert_true(seen.has(id), id)
	assert_false(seen.has("mt_x"), "隠しボスは仕掛けの先")
	assert_false(seen.has("lv_x"), "隠しボスは仕掛けの先")

func test_every_area_reachable_with_all_gimmicks_open():
	assert_eq(_reachable_areas(true).size(), world.ids().size())

func test_regions_have_bonfire_boss_and_shortcut():
	var fires := {}
	var bosses := {}
	var gates := {}
	for id in world.ids():
		var a := world.area(id)
		var info: Dictionary = Continent.load_map(a)[1]
		if info.has("checkpoint"):
			fires[a.region] = fires.get(a.region, 0) + 1
		bosses[a.region] = bosses.get(a.region, 0) + a.bosses.size()
		for ex in a.exits:
			if ex.door_id != "" and ex.opens_here:
				gates[ex.door_id] = true
	for r in ["山岳", "草原", "廃城", "溶岩", "神秘の塔"]:
		assert_eq(fires.get(r, 0), 1, r)
		assert_gt(bosses.get(r, 0), 0, r)
	assert_eq(bosses["神秘の塔"], 4, "双子（2体）・番人・ブライト")
	for d in ["forest_gate", "mt_gate", "gr_gate", "cs_gate", "lv_gate", RunState.SEAL_DOOR]:
		assert_true(gates.has(d), d)

func test_town_has_bonfire_and_merchants():
	var info: Dictionary = Continent.load_map(world.area("town"))[1]
	assert_true(info.has("checkpoint"))
	assert_eq(info.get("merchants", []).size(), 2)

func test_bonfire_has_room_to_respawn():
	for id in world.ids():
		var info: Dictionary = Continent.load_map(world.area(id))[1]
		if info.has("checkpoint"):
			var m: HeightMap = maps[id]
			var c: Vector2i = info["checkpoint"] + Vector2i(0, 1)
			assert_false(m.is_wall(c) or m.is_water(c) or m.is_pit(c), id)

func test_all_four_gimmick_kinds_are_used():
	var kinds := {}
	for id in world.ids():
		for g in world.area(id).gimmicks:
			kinds[g.kind] = true
	assert_eq(kinds.size(), 4)

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

func test_no_regular_enemies_outside_the_start_region():
	for id in world.ids():
		var a := world.area(id)
		if a.region != "はじまりの地":
			assert_eq(a.enemies.size(), 0, id)
