class_name WorldMapView
extends Control
## 全体マップ（M キー）。行ったことのあるエリアの長方形を、大陸の上の位置に並べて見せる。
## 今いるエリアは明るく縁取り、たき火のあるエリアには橙の点、墓石のあるエリアには白い印を付ける。
## 行ったことのないエリアは描かない（探検の楽しみを残す）。開いている間も世界は動く。
## 2026-11-25 夜（2回目の直し）に足したもの：
## - 右上に方位（マップの上が北）。画面の右上の方位（Hud）と同じ向き。
## - 自分のいる所（点滅する点）と、いま画面の上がどちらを向いているか（点から出る矢印）。
## - 出口（次のエリアへの道）を、エリアのふちの黄色い印で出す。行ったことのないとなりのエリアは、うすい枠と「？」で出す。
## - 門：閉じている門は赤い印（2本の柵）、開けた門は緑の印。
## 2026-11-26（3回目の直し）：エリアの形が四角でなくなったので、長方形でなく、エリアの本当の形（1マス1点の絵）で描く。
## 高い所ほど明るく、水は青、ふち（島の外のとなり）は暗くして形を見せる。

const BOX := Rect2(10, 14, 300, 142)  ## 地図を描く所（ゲームの座標）
const COLORS := {
	"grass": Color("5f9a42"), "town": Color("c9a66b"), "mountain": Color("9a9aa0"),
	"castle": Color("8a8478"), "lava": Color("8a3a2a"), "tower": Color("d8d4e8"), "mist": Color("4f6a5e"),
}
const PATH_COLOR := Color("ffe27a")
const GATE_CLOSED_COLOR := Color("e0402a")
const GATE_OPEN_COLOR := Color("7ae07a")
const UNKNOWN_COLOR := Color(0.75, 0.8, 0.95, 0.45)

var world: WorldMap
var run: RunState
var current_id := ""
## 今いるエリアの中の自分の位置（ワールドの px）と、カメラの角度（field.gd が毎フレーム入れる）
var player_pos := Vector2.ZERO
var view_angle := 0.0
var _fires := {}
## エリアの形の絵（id → ImageTexture）
var _shapes := {}
var _title: Label
var _legend: Label
var _blink := 0.0

func setup(w: WorldMap, r: RunState) -> void:
	world = w
	run = r
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(320, 180)
	for id in world.ids():
		var loaded = Continent.load_map(world.area(id))
		var info: Dictionary = loaded[1]
		if info.has("checkpoint"):
			_fires[id] = info["checkpoint"]
		_shapes[id] = shape_texture(loaded[0], COLORS.get(world.area(id).theme, Color.GRAY))
	_title = UiText.label()
	_title.position = Vector2(8, 1)
	add_child(_title)
	_legend = UiText.label()
	_legend.position = Vector2(8, 160)
	_legend.text = "黄：次への道　赤：閉じた門　緑：開けた門　橙：たき火"
	add_child(_legend)

func _process(delta: float) -> void:
	if visible:
		_blink += delta
		queue_redraw()

## 行ったことのないエリアのうち、行ったエリアの出口から道でつながっているもの（うすい枠で出す）。
func unvisited_neighbors() -> Array:
	var out: Array = []
	for id in run.visited_ids():
		for ex in world.area(id).exits:
			if not run.has_visited(ex.target) and not out.has(ex.target) and world.area(ex.target) != null:
				out.append(ex.target)
	return out

## 行ったエリアの出口の印。[{from, to, kind（path・gate_closed・gate_open）, door, edge, cells（大陸のマス）}]
func exit_marks() -> Array:
	var out: Array = []
	for id in run.visited_ids():
		var a := world.area(id)
		for ex in a.exits:
			var kind := "path"
			if ex.door_id != "":
				kind = "gate_open" if run.is_door_open(ex.door_id) else "gate_closed"
			var cells: Array = []
			for c in ex.cells(a.size()):
				cells.append(a.origin + c)
			out.append({"from": id, "to": ex.target, "kind": kind, "door": ex.door_id, "edge": ex.edge, "cells": cells})
	return out

## 行ったエリアと、そのとなりのまだ行っていないエリアがすべて入るように、大陸のマスから画面への倍率と位置を決める。
func layout() -> Dictionary:
	var bounds := Rect2i()
	var first := true
	for id in run.visited_ids() + unvisited_neighbors():
		var r := world.area(id).rect()
		bounds = r if first else bounds.merge(r)
		first = false
	if first:
		return {"scale": 1.0, "offset": Vector2.ZERO}
	var k := minf(BOX.size.x / bounds.size.x, BOX.size.y / bounds.size.y)
	k = minf(k, 1.2)
	var used := Vector2(bounds.size) * k
	var offset := BOX.position + (BOX.size - used) * 0.5 - Vector2(bounds.position) * k
	return {"scale": k, "offset": offset}

## エリアの形の絵（1マス1点）。島の外は透明。
static func shape_texture(m: HeightMap, base: Color) -> ImageTexture:
	var img := Image.create(m.size.x, m.size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in m.size.y:
		for x in m.size.x:
			var c := Vector2i(x, y)
			if m.is_void(c):
				continue
			var col := base
			if m.is_water(c):
				col = Color("3f6fb0")
			elif m.is_pit(c):
				col = Color("1a1420")
			else:
				var h := m.get_height(c)
				col = base.darkened(0.25).lightened(minf(0.45, h * 0.06))
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if m.is_void(c + d):
					edge = true
			if edge:
				col = col.darkened(0.45)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

## エリアの形の絵（テスト用）
func shape_of(id: String) -> ImageTexture:
	return _shapes.get(id)

func area_rect(id: String, lay: Dictionary) -> Rect2:
	var r := world.area(id).rect()
	var k: float = lay["scale"]
	return Rect2(Vector2(r.position) * k + lay["offset"], Vector2(r.size) * k)

## 大陸のマス（小数も可）を画面の点に。
func _to_screen(cell: Vector2, lay: Dictionary) -> Vector2:
	return cell * float(lay["scale"]) + lay["offset"]

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.08, 0.96))
	var lay := layout()
	var k: float = lay["scale"]
	# まだ行っていないとなりのエリア（うすい枠と「？」）
	for id in unvisited_neighbors():
		var r := area_rect(id, lay)
		draw_rect(r, Color(UNKNOWN_COLOR, 0.12))
		draw_rect(r, UNKNOWN_COLOR, false, 1.0)
		var f := UiText.SMALL_FONT
		draw_string(f, r.get_center() + Vector2(-3, 4), "？", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UNKNOWN_COLOR)
	for id in run.visited_ids():
		var a := world.area(id)
		var r := area_rect(id, lay)
		if _shapes.has(id):
			draw_texture_rect(_shapes[id], r, false)
		else:
			draw_rect(r, COLORS.get(a.theme, Color.GRAY))
		if _fires.has(id):
			var p := r.position + (Vector2(_fires[id]) + Vector2(0.5, 0.5)) * k
			draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color("ff9a3c"))
		if run.grave != null and run.grave.area_id == id:
			var gp := r.position + (Vector2(run.grave.cell) + Vector2(0.5, 0.5)) * k
			draw_rect(Rect2(gp - Vector2(1.5, 1.5), Vector2(3, 3)), Color("f4f1ff"))
	if current_id != "" and run.has_visited(current_id):
		var cr := area_rect(current_id, lay)
		draw_rect(cr.grow(1.0), Color("ffe27a"), false, 1.0)
	for m in exit_marks():
		_draw_exit(m, lay)
	_draw_player(lay)
	_draw_compass(Vector2(BOX.end.x - 10, BOX.position.y + 12))
	var a := world.area(current_id)
	if a != null and _title != null:
		_title.text = "M：閉じる　いま：%s・%s" % [a.region, a.title]

## 出口の印：エリアのふちに、外へ向かう太い線（道は黄色、門は赤か緑）。門には柵の印も付ける。
func _draw_exit(m: Dictionary, lay: Dictionary) -> void:
	var cells: Array = m["cells"]
	if cells.is_empty():
		return
	var out := Vector2(ExitDef.dir(m["edge"]))
	var c0: Vector2 = Vector2(cells[0]) + Vector2(0.5, 0.5)
	var c1: Vector2 = Vector2(cells[cells.size() - 1]) + Vector2(0.5, 0.5)
	var a := _to_screen(c0 + out * 0.5, lay)
	var b := _to_screen(c1 + out * 0.5, lay)
	var side := out.orthogonal().abs() * 0.5 * float(lay["scale"])
	a -= side
	b += side
	var color := PATH_COLOR
	match m["kind"]:
		"gate_closed":
			color = GATE_CLOSED_COLOR
		"gate_open":
			color = GATE_OPEN_COLOR
	var rect := Rect2(a, Vector2.ZERO).expand(b).grow(1.0)
	draw_rect(rect, Color(0, 0, 0, 0.8))
	draw_rect(rect.grow(-0.5), color)
	if m["kind"] != "path":
		# 門の印：出口の真ん中に、小さな柵（2本の棒）の箱
		var mid := (a + b) * 0.5
		var box := Rect2(mid - Vector2(3, 3), Vector2(6, 6))
		draw_rect(box.grow(1.0), Color(0, 0, 0, 0.9))
		draw_rect(box, color.darkened(0.35))
		if m["kind"] == "gate_closed":
			draw_line(box.position + Vector2(2, 0.5), box.position + Vector2(2, 5.5), color.lightened(0.5), 1.0)
			draw_line(box.position + Vector2(4, 0.5), box.position + Vector2(4, 5.5), color.lightened(0.5), 1.0)
		else:
			draw_rect(Rect2(box.position + Vector2(1.5, 1.5), Vector2(3, 3)), color.lightened(0.5), false, 1.0)

## 自分のいる所（点滅する白い点）と、画面の上の向き（点から出る矢印。画面の上へ歩くとこの向きへ進む）
func _draw_player(lay: Dictionary) -> void:
	var a := world.area(current_id)
	if a == null or not run.has_visited(current_id):
		return
	var cell := Vector2(a.origin) + player_pos / float(HeightMap.CELL_PX)
	var p := _to_screen(cell, lay)
	var up := Vector2.UP.rotated(view_angle)
	draw_line(p, p + up * 7.0, Color(1, 1, 1, 0.85), 1.0)
	var tip := p + up * 8.0
	draw_colored_polygon(PackedVector2Array([tip + up * 2.0, tip + up.orthogonal() * 2.0, tip - up.orthogonal() * 2.0]), Color(1, 1, 1, 0.85))
	var on := int(_blink * 3.0) % 2 == 0
	draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(0, 0, 0, 0.9))
	draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color.WHITE if on else Color("ffe27a"))

## 方位（マップの上が北）
func _draw_compass(c: Vector2) -> void:
	Compass.draw_on(self, c, Vector2.UP)
