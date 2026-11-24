extends GutTest

func _cam() -> StackCamera:
	return autofree(StackCamera.new())

func test_focus_is_screen_center():
	var c := _cam()
	c.focus = Vector2(100, 100)
	assert_eq(c.world_to_screen(Vector2(100, 100), 0), Vector2(160, 90))

func test_height_moves_up_on_screen():
	var c := _cam()
	assert_eq(c.world_to_screen(Vector2.ZERO, 8).y, c.world_to_screen(Vector2.ZERO, 0).y - 8)

func test_rotation_90():
	var c := _cam()
	c.angle = PI / 2
	assert_almost_eq(c.world_to_screen(Vector2(10, 0), 0), Vector2(160, 80), Vector2(0.01, 0.01))

func test_screen_dir_roundtrip():
	var c := _cam()
	c.angle = 1.0
	var w := c.screen_dir_to_world(Vector2.UP)
	var d := (c.world_to_screen(w * 10, 0) - c.world_to_screen(Vector2.ZERO, 0)).normalized()
	assert_almost_eq(d, Vector2.UP, Vector2(0.01, 0.01))

func test_nearer_objects_have_larger_depth():
	var c := _cam()
	assert_gt(c.depth_key(Vector2(0, 50)), c.depth_key(Vector2(0, 10)))

func test_screen_to_world_roundtrip():
	var c := _cam()
	c.angle = 1.0
	c.focus = Vector2(40, 70)
	var w := Vector2(123, 45)
	var s := c.world_to_screen(w, 16)
	assert_almost_eq(c.screen_to_world(s, 16), w, Vector2(0.01, 0.01))

## 高い所に立つと、その高さが画面の真ん中に来る（高台でプレイヤーが画面の上に寄らない）
func test_focus_height_centers_high_ground():
	var c := _cam()
	c.focus = Vector2(100, 100)
	c.focus_height = 40.0
	assert_eq(c.world_to_screen(Vector2(100, 100), 40.0), Vector2(160, 90))
	var w := c.screen_to_world(c.world_to_screen(Vector2(130, 90), 16.0), 16.0)
	assert_almost_eq(w, Vector2(130, 90), Vector2(0.01, 0.01))

func test_follow_height_moves_smoothly():
	var c := _cam()
	c.follow(Vector2(10, 10), 40.0, 0.016)
	assert_gt(c.focus_height, 0.0)
	assert_lt(c.focus_height, 40.0)
	for i in 200:
		c.follow(Vector2(10, 10), 40.0, 0.016)
	assert_almost_eq(c.focus_height, 40.0, 0.5)
	assert_eq(c.focus, Vector2(10, 10))

func test_pick_ground_prefers_high_cell_under_cursor():
	var m := HeightMap.new(Vector2i(4, 4))
	m.set_height(Vector2i(1, 1), 2)
	var cam := _cam()
	cam.focus = HeightMap.cell_center(Vector2i(1, 1))
	var screen := cam.world_to_screen(HeightMap.cell_center(Vector2i(1, 1)), 16)
	assert_eq(HeightMap.world_to_cell(cam.pick_ground(screen, m, 8)), Vector2i(1, 1))

func test_pick_ground_falls_to_low_cell():
	var m := HeightMap.new(Vector2i(4, 4))
	var cam := _cam()
	cam.focus = HeightMap.cell_center(Vector2i(2, 2))
	var screen := cam.world_to_screen(HeightMap.cell_center(Vector2i(2, 2)), 0)
	assert_eq(cam.pick_ground(screen, m, 8), HeightMap.cell_center(Vector2i(2, 2)))

## 画面のゆれ：ゆれている間も、画面の点とワールドの点の行き来は合っている。時間がたつと止まる
func test_shake_fades_and_keeps_roundtrip():
	var c := _cam()
	c.shake(2.0)
	c._process(0.01)
	assert_lte(c.shake_offset.length(), 2.0 * sqrt(2.0) + 0.01)
	var w := Vector2(30, -12)
	assert_almost_eq(c.screen_to_world(c.world_to_screen(w, 8), 8), w, Vector2(0.01, 0.01))
	c._process(StackCamera.SHAKE_TIME)
	assert_eq(c.shake_offset, Vector2.ZERO)
