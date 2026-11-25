extends GutTest
## 影と光（2026-11-26 の3回目の直し）：地面に落ちる木や崖の影の高さの絵と、地方ごとの暗さ・明かり・舞うもの。

func _flat(n: int, h: int) -> HeightMap:
	var m := HeightMap.new(Vector2i(n, n))
	for y in n:
		for x in n:
			m.set_height(Vector2i(x, y), h)
	return m

func test_height_image_has_ground_and_round_tree_tops():
	var m := _flat(4, 1)
	m.set_void(Vector2i(0, 0), true)
	var deco := {Vector2i(2, 2): "tree"}
	var img := ShadowMap.height_image(m, deco)
	var R := ShadowMap.RES
	assert_eq(img.get_size(), Vector2i(4 * R, 4 * R))
	assert_almost_eq(img.get_pixel(R + 1, R + 1).r * ShadowMap.HEIGHT_RANGE, 1.0, 0.1, "地面の高さ")
	assert_almost_eq(img.get_pixel(1, 1).r, 0.0, 0.01, "島の外は影を落とさない")
	var center := img.get_pixel(2 * R + R / 2, 2 * R + R / 2).r * ShadowMap.HEIGHT_RANGE
	assert_almost_eq(center, 1.0 + ShadowMap.OCCLUDERS["tree"][0], 0.1, "木のてっぺん")
	var corner := img.get_pixel(2 * R, 2 * R).r * ShadowMap.HEIGHT_RANGE
	assert_almost_eq(corner, 1.0, 0.1, "木は丸く影を落とす（マスの角は地面）")

func test_occluder_height_matches_image():
	var m := _flat(4, 2)
	var deco := {Vector2i(1, 1): "house"}
	assert_almost_eq(ShadowMap.occluder_height(m, deco, Vector2(1.05, 1.05)), 2.0 + ShadowMap.OCCLUDERS["house"][0], 0.01)
	assert_almost_eq(ShadowMap.occluder_height(m, deco, Vector2(3.5, 3.5)), 2.0, 0.01)

## 影は日の逆（東より）へ落ちる
func test_shadow_falls_away_from_the_sun():
	assert_lt(ShadowMap.SUN.x, 0.0, "日は西の空")

func test_cell_code_carries_cell_and_height():
	var c := ShadowMap.cell_code(Vector2i(12, 30), 5)
	assert_eq(roundi(c.r * 255.0), 12)
	assert_eq(roundi(c.g * 255.0), 30)
	assert_almost_eq(c.b * ShadowMap.HEIGHT_RANGE, 5.0, 0.01)
	assert_eq(c.a, 0.5)

## 溶岩・廃城・塔は暗く、ほかの地方は暗くしない（雲の影はある）
func test_dark_regions():
	for t in ["lava", "castle", "tower"]:
		assert_lt(float(Atmosphere.config(t)["ambient"]), 1.0, t)
	for t in ["grass", "town", "mountain"]:
		assert_eq(float(Atmosphere.config(t)["ambient"]), 1.0, t)
		assert_gt(float(Atmosphere.config(t)["clouds"]), 0.0, t)
	assert_eq(Atmosphere.config("lava")["particles"], "embers")
	assert_eq(Atmosphere.config("mountain")["particles"], "snow")
