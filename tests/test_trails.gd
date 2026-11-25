extends GutTest
## 地面の道（Trails）：出口とたき火などの真ん中を、歩けるマスでつなぐ。

func _flat(size: Vector2i) -> HeightMap:
	var m := HeightMap.new(size)
	for y in size.y:
		for x in size.x:
			m.set_height(Vector2i(x, y), 1)
	return m

func _exit(e: ExitDef.Edge, a: int, b: int) -> ExitDef:
	var ex := ExitDef.new()
	ex.edge = e
	ex.from = a
	ex.to = b
	return ex

func test_trail_joins_two_exits() -> void:
	var m := _flat(Vector2i(12, 10))
	var exits: Array[ExitDef] = [_exit(ExitDef.Edge.WEST, 4, 6), _exit(ExitDef.Edge.EAST, 4, 6)]
	var cells := Trails.cells(m, exits, Vector2i(-1, -1))
	assert_true(cells.has(Vector2i(0, 5)), "西の出口の真ん中から")
	assert_true(cells.has(Vector2i(11, 5)), "東の出口の真ん中まで")
	# つながっている（4方向で）
	var seen := {Vector2i(0, 5): true}
	var todo: Array[Vector2i] = [Vector2i(0, 5)]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if cells.has(n) and not seen.has(n):
				seen[n] = true
				todo.append(n)
	assert_true(seen.has(Vector2i(11, 5)))

func test_trail_avoids_walls_and_water() -> void:
	var m := _flat(Vector2i(12, 10))
	for y in range(0, 8):
		m.set_wall(Vector2i(6, y), true)
	m.set_water(Vector2i(6, 8), true)
	var exits: Array[ExitDef] = [_exit(ExitDef.Edge.WEST, 4, 6), _exit(ExitDef.Edge.EAST, 4, 6)]
	var cells := Trails.cells(m, exits, Vector2i(-1, -1))
	for c in cells:
		assert_false(m.is_wall(c), "壁の上に道はない %s" % c)
		assert_false(m.is_water(c), "水の上に道はない %s" % c)
	assert_true(cells.has(Vector2i(6, 9)), "壁と水をよけて下を回る")

func test_trail_goes_to_the_hub() -> void:
	var m := _flat(Vector2i(14, 14))
	var exits: Array[ExitDef] = [_exit(ExitDef.Edge.NORTH, 6, 7)]
	var cells := Trails.cells(m, exits, Vector2i(7, 11))
	assert_true(cells.has(Vector2i(7, 11)) or cells.has(Vector2i(7, 10)), "たき火のそばまで道が来る")

func test_trail_is_always_the_same() -> void:
	var m := _flat(Vector2i(16, 12))
	var exits: Array[ExitDef] = [_exit(ExitDef.Edge.NORTH, 3, 4), _exit(ExitDef.Edge.SOUTH, 10, 12)]
	var a := Trails.cells(m, exits, Vector2i(-1, -1))
	var b := Trails.cells(m, exits, Vector2i(-1, -1))
	assert_eq(a.keys().size(), b.keys().size())
	for c in a:
		assert_true(b.has(c))
