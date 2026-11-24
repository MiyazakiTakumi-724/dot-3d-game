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

## 2層の地図：高さの層（. は島の外）と、物の層
func test_parse_layers():
	var heights := [".122", "0011"]
	var objects := [".T~=", "C_BG"]
	var m := HeightMap.new(Vector2i(4, 2))
	var info := Terrain.parse_layers(heights, objects, m)
	assert_true(m.is_void(Vector2i(0, 0)))
	assert_eq(m.get_height(Vector2i(1, 0)), 1)
	assert_true(m.is_wall(Vector2i(1, 0)))
	assert_true(m.is_water(Vector2i(2, 0)))
	assert_eq(m.get_height(Vector2i(2, 0)), 2)
	assert_false(m.is_wall(Vector2i(3, 0)))
	assert_eq(info["checkpoint"], Vector2i(0, 1))
	assert_true(m.is_pit(Vector2i(1, 1)))
	assert_true(m.is_wall(Vector2i(2, 1)))
	assert_eq(info["goal"], Vector2i(3, 1))
	assert_eq(m.get_height(Vector2i(3, 1)), 1)  # ゴールも高さの層の高さになる
	assert_eq(info["deco"], {Vector2i(1, 0): "tree", Vector2i(3, 0): "bridge", Vector2i(2, 1): "bush"})

func test_parse_layers_other_objects():
	var m := HeightMap.new(Vector2i(4, 1))
	var info := Terrain.parse_layers(["0000"], ["PRFD"], m)
	assert_true(m.is_wall(Vector2i(0, 0)))
	assert_true(m.is_wall(Vector2i(1, 0)))
	assert_false(m.is_wall(Vector2i(2, 0)))  # 花は歩ける
	assert_eq(info["doors"], [Vector2i(3, 0)])
	assert_eq(info["deco"], {Vector2i(0, 0): "pine", Vector2i(1, 0): "rock", Vector2i(2, 0): "flower"})

func _flat(h: int) -> HeightMap:
	var m := HeightMap.new(Vector2i(5, 5))
	for y in 5:
		for x in 5:
			m.set_height(Vector2i(x, y), h)
	return m

## 周りが同じ高さなら、上の面だけ描く（側面は見えない）
func test_column_bottom_flat_is_top_only():
	assert_eq(Terrain.column_bottom(_flat(2), Vector2i(2, 2)), 2)

## 隣（斜めも）が低いと、その高さまで側面を描く
func test_column_bottom_next_to_lower():
	var m := _flat(3)
	m.set_height(Vector2i(3, 3), 1)
	assert_eq(Terrain.column_bottom(m, Vector2i(2, 2)), 1)

## 島のふちでは、断面が0より下へ伸びる
func test_column_bottom_at_island_edge_goes_down():
	var m := _flat(2)
	m.set_void(Vector2i(2, 1), true)
	var b := Terrain.column_bottom(m, Vector2i(2, 2))
	assert_lt(b, 0)
	assert_eq(b, -Terrain.foundation_levels(Vector2i(2, 2)))

## 隣が水なら、水面が低い分だけ岸を描く
func test_column_bottom_next_to_water():
	var m := _flat(2)
	m.set_water(Vector2i(2, 3), true)
	assert_eq(Terrain.column_bottom(m, Vector2i(2, 2)), 1)

## 奈落の隣は、裂け目の底まで描く
func test_column_bottom_next_to_pit():
	var m := _flat(1)
	m.set_pit(Vector2i(2, 3), true)
	assert_lt(Terrain.column_bottom(m, Vector2i(2, 2)), 0)

func test_lower_sides_bits():
	var m := HeightMap.new(Vector2i(3, 3))
	m.set_height(Vector2i(1, 1), 2)
	m.set_height(Vector2i(1, 0), 2)
	assert_eq(Terrain.lower_sides(m, Vector2i(1, 1)), 2 | 4 | 8)

func test_lower_sides_counts_map_edge():
	var m := HeightMap.new(Vector2i(3, 3))
	assert_eq(Terrain.lower_sides(m, Vector2i(0, 1)), 8)

func test_top_color_brighter_when_higher():
	assert_gt(Terrain.top_color(5).v, Terrain.top_color(1).v)
	assert_gt(Terrain.top_color(8).v, Terrain.top_color(7).v)

func test_edge_highlight_on_lower_side():
	var plain := Terrain.ground_model(2, 3, 0, false, -1, 0)
	var lit := Terrain.ground_model(2, 3, 0, false, -1, 2)
	var top := (2 - -1) * StackSprite.LEVEL_PX  # 上の面の輪切り
	assert_gt(lit.get_voxel(Vector3i(15, 8, top)).v, plain.get_voxel(Vector3i(15, 8, top)).v)
	assert_eq(lit.get_voxel(Vector3i(0, 8, top)), plain.get_voxel(Vector3i(0, 8, top)))

func test_side_has_level_bands():
	# 1段ごとに暗い帯が入る：高さの境目の輪切りは、その1つ上より暗い
	var m := Terrain.ground_model(4, 4, 2, false, 0, 0)
	assert_lt(m.get_voxel(Vector3i(0, 0, 8)).v, m.get_voxel(Vector3i(0, 0, 9)).v)

func test_arrow_model_points_north():
	var a := Terrain.arrow_model()
	assert_ne(a.get_voxel(Vector3i(a.size.x / 2, 0, 0)).a, 0.0)
	assert_eq(a.get_voxel(Vector3i(0, 0, 0)).a, 0.0)
