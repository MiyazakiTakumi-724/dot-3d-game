class_name StackCamera
extends Node2D
## sprite stacking 用のカメラ。ワールド座標（真上から見た平面）を画面座標に変える。
## Q / E で回す。

const SCREEN_CENTER := Vector2(160, 90)
const TURN_SPEED := PI / 2  # 1秒で90°

var angle: float = 0.0
var focus: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_Q):
		turn -= 1.0
	if Input.is_physical_key_pressed(KEY_E):
		turn += 1.0
	angle = wrapf(angle + turn * TURN_SPEED * delta, -PI, PI)

func world_to_screen(world: Vector2, height_px: float) -> Vector2:
	var p := (world - focus).rotated(-angle)
	return SCREEN_CENTER + p - Vector2(0, height_px)

## 画面上の向き（例：上キー = Vector2.UP）をワールドの向きに変える。
func screen_dir_to_world(dir: Vector2) -> Vector2:
	return dir.rotated(angle)

## 大きいほど手前（後から描く）。
func depth_key(world: Vector2) -> float:
	return (world - focus).rotated(-angle).y
