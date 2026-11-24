extends GutTest

func _drag(cam: StackCamera, dx: float, mask: int) -> void:
	var e := InputEventMouseMotion.new()
	e.relative = Vector2(dx, 0)
	e.button_mask = mask
	cam._unhandled_input(e)

## 左クリックはアイテムを使うボタンなので、左ドラッグではカメラを回さない
func test_left_drag_does_not_rotate():
	var c: StackCamera = autofree(StackCamera.new())
	_drag(c, 50, MOUSE_BUTTON_MASK_LEFT)
	assert_eq(c.angle, 0.0)

## 右ドラッグで回す。動いた量は本当の画面（640×360）のpxなので、ゲームの座標のpxに直して回す
func test_drag_right_button_also_rotates():
	var c: StackCamera = autofree(StackCamera.new())
	_drag(c, -20, MOUSE_BUTTON_MASK_RIGHT)
	assert_almost_eq(c.angle, -20.0 / StackCamera.PIXEL_SCALE * StackCamera.MOUSE_SENSITIVITY, 0.0001)

func test_move_without_button_does_nothing():
	var c: StackCamera = autofree(StackCamera.new())
	_drag(c, 50, 0)
	assert_eq(c.angle, 0.0)
