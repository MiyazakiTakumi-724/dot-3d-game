extends GutTest
const Reach = preload("res://tests/helpers/reach.gd")

var area
var rules := MovementRules.new()

func before_each():
	area = load("res://scenes/area_02.tscn").instantiate()
	add_child_autofree(area)

## 速さ60px/秒、1マス16px → 1分で225マス
func test_back_of_area_is_over_a_minute_away():
	var d := Reach.distance(area.map, rules, area.checkpoint, area.goal)
	assert_gt(d, 225)

func test_everything_reachable_with_doors_closed():
	for p in area.PICKUPS:
		assert_gt(Reach.distance(area.map, rules, area.PLAYER_START, p[0]), 0, str(p[0]))
	for c in area.DOOR_OPEN_FROM:
		assert_gt(Reach.distance(area.map, rules, area.PLAYER_START, c), 0, str(c))
	for e in area.ENEMIES:
		assert_gt(Reach.distance(area.map, rules, area.PLAYER_START, e[0]), 0, str(e[0]))

func test_door_open_from_is_next_to_its_door():
	assert_eq(area.DOOR_OPEN_FROM.size(), area.doors.size())
	for i in area.doors.size():
		var diff: Vector2i = area.DOOR_OPEN_FROM[i] - area.doors[i]
		assert_eq(absi(diff.x) + absi(diff.y), 1)

func test_open_door_is_a_short_way_back():
	for i in area.doors.size():
		area.map.set_blocker(area.doors[i], HeightMap.Blocker.NONE)
		var d := Reach.distance(area.map, rules, area.DOOR_OPEN_FROM[i], area.checkpoint)
		assert_between(d, 1, 40)

func test_door_far_side_is_far_while_closed():
	for c in area.DOOR_OPEN_FROM:
		assert_gt(Reach.distance(area.map, rules, area.checkpoint, c), 100)

func test_no_enemy_near_checkpoint():
	for e in area.ENEMIES:
		var c: Vector2i = e[0]
		assert_gt(maxi(absi(c.x - area.checkpoint.x), absi(c.y - area.checkpoint.y)), 8)

func test_one_strong_ball():
	var n := 0
	for p in area.PICKUPS:
		if p[1] == RunState.PickupKind.STRONG_BALL:
			n += 1
	assert_eq(n, 1)

func test_at_least_two_heals():
	var n := 0
	for p in area.PICKUPS:
		if p[1] == RunState.PickupKind.HEAL:
			n += 1
	assert_gt(n, 1)

func test_has_pits():
	var pits := 0
	for y in area.map.size.y:
		for x in area.map.size.x:
			if area.map.is_pit(Vector2i(x, y)):
				pits += 1
	assert_gt(pits, 0)

func test_start_area_is_walkable():
	for dx in [1, 2, 3]:
		var c := Vector2i(area.PLAYER_START.x + dx, area.PLAYER_START.y)
		assert_false(area.map.is_wall(c))
		assert_eq(area.map.get_height(c), 0)
