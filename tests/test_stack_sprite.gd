extends GutTest

func test_unit_in_back_half_of_cell_draws_after_its_tile():
	var cam: StackCamera = autofree(StackCamera.new())
	var tile: StackSprite = autofree(StackSprite.new())
	tile.camera = cam
	tile.world_pos = HeightMap.cell_center(Vector2i(2, 2))
	var unit: StackSprite = autofree(StackSprite.new())
	unit.camera = cam
	unit.sort_by_cell = true
	unit.draw_bias = 2
	unit.world_pos = Vector2(40, 33)  # (2,2) の奥側
	tile._process(0.0)
	unit._process(0.0)
	assert_gt(unit.z_index, tile.z_index)

func test_far_offscreen_sprite_is_hidden():
	var cam: StackCamera = autofree(StackCamera.new())
	var s: StackSprite = autofree(StackSprite.new())
	s.camera = cam
	s.world_pos = Vector2(600, 0)
	s.refresh()
	assert_false(s.visible)

func test_onscreen_sprite_is_visible_again():
	var cam: StackCamera = autofree(StackCamera.new())
	var s: StackSprite = autofree(StackSprite.new())
	s.camera = cam
	s.world_pos = Vector2(600, 0)
	s.refresh()
	cam.focus = Vector2(600, 0)
	s.refresh()
	assert_true(s.visible)

func test_hidden_sprite_stays_hidden_on_screen():
	var cam: StackCamera = autofree(StackCamera.new())
	var s: StackSprite = autofree(StackSprite.new())
	s.camera = cam
	s.force_hidden = true
	s.refresh()
	assert_false(s.visible)

## 動かない絵は、カメラを回したときだけ描き直す（動くものは always_redraw で毎回）
func test_static_sprite_redraws_only_on_turn():
	var cam: StackCamera = autofree(StackCamera.new())
	var s: StackSprite = autofree(StackSprite.new())
	s.camera = cam
	assert_true(s.needs_redraw())
	s._drawn_angle = cam.angle  # 描いた（_draw は描画中にしか呼べないので、記録だけまねる）
	assert_false(s.needs_redraw())
	cam.focus = Vector2(30, 0)
	assert_false(s.needs_redraw())
	cam.angle = 0.3
	assert_true(s.needs_redraw())
	s._drawn_angle = cam.angle
	s.always_redraw = true
	assert_true(s.needs_redraw())

## 動くものの描く順番：足元の円（半径 r）がかかるマスのうち、自分以下の高さのマスより後に描く。
## マスの手前のふちに立ったとき、手前のマスの地面がキャラにかぶらないように（ユーザーの指摘 2026-11-24）。
func _flat_map() -> HeightMap:
	return HeightMap.new(Vector2i(6, 6))

func test_sort_depth_center_of_cell_uses_own_cell():
	var cam: StackCamera = autofree(StackCamera.new())
	var m := _flat_map()
	var c := HeightMap.cell_center(Vector2i(2, 2))
	assert_almost_eq(StackSprite.sort_depth(cam, m, c, 0, 5.0), cam.depth_key(c), 0.001)

func test_sort_depth_near_front_edge_uses_front_cell():
	var cam: StackCamera = autofree(StackCamera.new())
	var m := _flat_map()
	var p := HeightMap.cell_center(Vector2i(2, 2)) + Vector2(0, 6)
	var front := HeightMap.cell_center(Vector2i(2, 3))
	assert_almost_eq(StackSprite.sort_depth(cam, m, p, 0, 5.0), cam.depth_key(front), 0.001)

func test_sort_depth_ignores_higher_front_cell():
	var cam: StackCamera = autofree(StackCamera.new())
	var m := _flat_map()
	m.set_height(Vector2i(2, 3), 1)
	var own := HeightMap.cell_center(Vector2i(2, 2))
	assert_almost_eq(StackSprite.sort_depth(cam, m, own + Vector2(0, 6), 0, 5.0), cam.depth_key(own), 0.001)

func test_sort_depth_ignores_wall_front_cell():
	var cam: StackCamera = autofree(StackCamera.new())
	var m := _flat_map()
	m.set_wall(Vector2i(2, 3), true)
	var own := HeightMap.cell_center(Vector2i(2, 2))
	assert_almost_eq(StackSprite.sort_depth(cam, m, own + Vector2(0, 6), 0, 5.0), cam.depth_key(own), 0.001)

func test_unit_at_front_edge_draws_after_front_tile():
	var cam: StackCamera = autofree(StackCamera.new())
	var m := _flat_map()
	var tile: StackSprite = autofree(StackSprite.new())
	tile.camera = cam
	tile.world_pos = HeightMap.cell_center(Vector2i(2, 3))
	var unit: StackSprite = autofree(StackSprite.new())
	unit.camera = cam
	unit.sort_by_cell = true
	unit.sort_map = m
	unit.draw_bias = 2
	unit.world_pos = HeightMap.cell_center(Vector2i(2, 2)) + Vector2(0, 7)
	tile.refresh()
	unit.refresh()
	assert_gt(unit.z_index, tile.z_index)
