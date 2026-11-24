extends GutTest
## 大陸の4エリアの地図を確かめる（tools/area_maps/gen.py で作った地図）。
const Reach = preload("res://tests/helpers/reach.gd")

## 速さ60px/秒、1マス16px → 1秒で3.75マス
const CELLS_PER_SECOND := 60.0 / 16.0

var world: WorldMap
var rules := MovementRules.new()
var maps := {}

func before_all():
	world = Continent.build()
	for id in world.ids():
		maps[id] = Continent.load_map(world.area(id))[0]

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

func test_four_areas():
	assert_eq_deep(world.ids().size(), 4)
	assert_not_null(world.area("camp"))
	assert_not_null(world.area("forest"))

func test_heights_within_0_to_8():
	for id in world.ids():
		var m: HeightMap = maps[id]
		for y in m.size.y:
			for x in m.size.x:
				assert_between(m.get_height(Vector2i(x, y)), 0, 8)

func test_flats_are_small_outside_camp():
	for id in world.ids():
		if id == "camp":
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
		var m: HeightMap = maps[id]
		var hub := _mid(id, a.exits[0], 1)
		var fwd := Reach.reachable(m, rules, hub)
		var back := Reach.reachable(m, rules, hub, true)
		for ex in a.exits:
			for c in ex.cells(a.size()):
				assert_true(fwd.has(c) and back.has(c), "%s %s" % [id, c])

func test_enemies_and_pickups_reachable():
	for id in world.ids():
		var a := world.area(id)
		var m: HeightMap = maps[id]
		var fwd := Reach.reachable(m, rules, _mid(id, a.exits[0], 1))
		for e in a.enemies:
			assert_true(fwd.has(e[0]), "%s enemy %s" % [id, e[0]])
		for p in a.pickups:
			assert_true(fwd.has(p[0]), "%s pickup %s" % [id, p[0]])

func test_no_pocket_without_exit():
	for id in world.ids():
		var a := world.area(id)
		var m: HeightMap = maps[id]
		var hub := _mid(id, a.exits[0], 1)
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
