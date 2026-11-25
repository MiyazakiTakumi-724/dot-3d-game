class_name Compass
extends RefCounted
## 方位の絵（2026-11-25 夜の2回目の直し）。丸の中に北を指す赤い針と「北」の字。
## 画面の右上（Hud）では、カメラを回すと一緒に回る。全体マップでは、いつも上が北。

const RADIUS := 8.0
const NORTH_COLOR := Color("e04a3a")
const SOUTH_COLOR := Color("d8dce8")

## canvas に、中心 c で、北の向き north（画面の向き。長さ1）の方位を描く。
static func draw_on(canvas: CanvasItem, c: Vector2, north: Vector2) -> void:
	var n := north.normalized()
	var side := n.orthogonal()
	canvas.draw_circle(c, RADIUS + 1.0, UiText.OUTLINE_COLOR)
	canvas.draw_circle(c, RADIUS, Color(0.07, 0.08, 0.11, 0.85))
	canvas.draw_colored_polygon(PackedVector2Array([c + n * (RADIUS - 1.0), c + side * 2.5, c - side * 2.5]), NORTH_COLOR)
	canvas.draw_colored_polygon(PackedVector2Array([c - n * (RADIUS - 2.0), c + side * 2.0, c - side * 2.0]), SOUTH_COLOR)
	var f := UiText.SMALL_FONT
	var at := c + n * (RADIUS + 6.0) + Vector2(-5, 4)
	canvas.draw_string_outline(f, at, "北", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, UiText.OUTLINE_COLOR)
	canvas.draw_string(f, at, "北", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffd0c8"))
