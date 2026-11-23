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
