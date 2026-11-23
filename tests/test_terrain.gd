extends GutTest

func test_parse_symbols():
	var layout := ["C1_", "#DG"]
	var m := HeightMap.new(Vector2i(3, 2))
	var info := Terrain.parse(layout, m)
	assert_eq(info["checkpoint"], Vector2i(0, 0))
	assert_eq(info["goal"], Vector2i(2, 1))
	assert_eq(info["doors"], [Vector2i(1, 1)])
	assert_eq(m.get_height(Vector2i(1, 0)), 1)
	assert_true(m.is_pit(Vector2i(2, 0)))
	assert_true(m.is_wall(Vector2i(0, 1)))
	assert_eq(m.get_blocker(Vector2i(1, 1)), HeightMap.Blocker.DOOR)

func test_parse_without_markers():
	var m := HeightMap.new(Vector2i(2, 1))
	var info := Terrain.parse(["01"], m)
	assert_false(info.has("checkpoint"))
	assert_false(info.has("goal"))
	assert_eq(info["doors"], [])

func test_parse_outdoor_symbols():
	var m := HeightMap.new(Vector2i(4, 1))
	var info := Terrain.parse(["RT~="], m)
	assert_true(m.is_wall(Vector2i(0, 0)))
	assert_true(m.is_wall(Vector2i(1, 0)))
	assert_true(m.is_water(Vector2i(2, 0)))
	assert_false(m.is_wall(Vector2i(3, 0)))
	assert_false(m.is_water(Vector2i(3, 0)))
	assert_eq(m.get_height(Vector2i(3, 0)), 0)
	assert_eq(info["deco"], {Vector2i(0, 0): "rock", Vector2i(1, 0): "tree", Vector2i(3, 0): "bridge"})
