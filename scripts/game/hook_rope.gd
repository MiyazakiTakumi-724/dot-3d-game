class_name HookRope
extends Node2D
## 鉤縄の縄（2026-11-26 独自の開発1）。主人公の手から、かけた所までを、ゲームの座標の1pxの線と爪で描く。
## 位置はワールドの点と高さで持ち、毎フレームカメラで画面の点に直す。

var camera: StackCamera
var from_world := Vector2.ZERO
var from_h := 0.0  ## px
var to_world := Vector2.ZERO
var to_h := 0.0  ## px
var time_left := 0.0

const ROPE := Color(0.78, 0.63, 0.38)
const CLAW := Color(0.78, 0.8, 0.86)

func show_rope(a: Vector2, a_h: float, b: Vector2, b_h: float, seconds: float) -> void:
	from_world = a
	from_h = a_h
	to_world = b
	to_h = b_h
	time_left = seconds
	z_index = 4000
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if time_left <= 0.0:
		visible = false
		return
	time_left -= delta
	queue_redraw()

func _draw() -> void:
	if camera == null or time_left <= 0.0:
		return
	var a := camera.world_to_screen(from_world, from_h)
	var b := camera.world_to_screen(to_world, to_h)
	var n := maxi(2, int(a.distance_to(b) / 2.0))
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		draw_rect(Rect2(p.floor(), Vector2.ONE), ROPE)
	draw_rect(Rect2(b.floor() - Vector2(1, 1), Vector2(3, 3)), CLAW)
