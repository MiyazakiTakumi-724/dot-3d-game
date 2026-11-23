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
