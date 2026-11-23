extends GutTest

func _drag(cam: StackCamera, dx: float, mask: int) -> void:
	var e := InputEventMouseMotion.new()
	e.relative = Vector2(dx, 0)
	e.button_mask = mask
	cam._unhandled_input(e)

func test_drag_with_button_held_rotates():
	var c: StackCamera = autofree(StackCamera.new())
	_drag(c, 50, MOUSE_BUTTON_MASK_LEFT)
	assert_almost_eq(c.angle, 50 * StackCamera.MOUSE_SENSITIVITY, 0.0001)

func test_drag_right_button_also_rotates():
	var c: StackCamera = autofree(StackCamera.new())
	_drag(c, -20, MOUSE_BUTTON_MASK_RIGHT)
	assert_almost_eq(c.angle, -20 * StackCamera.MOUSE_SENSITIVITY, 0.0001)

func test_move_without_button_does_nothing():
	var c: StackCamera = autofree(StackCamera.new())
	_drag(c, 50, 0)
	assert_eq(c.angle, 0.0)
