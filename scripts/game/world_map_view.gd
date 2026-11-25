class_name WorldMapView
extends Control
## 全体マップ（M キー）。行ったことのあるエリアの長方形を、大陸の上の位置に並べて見せる。
## 今いるエリアは明るく縁取り、たき火のあるエリアには橙の点、墓石のあるエリアには白い印を付ける。
## 行ったことのないエリアは描かない（探検の楽しみを残す）。開いている間も世界は動く。

const BOX := Rect2(10, 12, 300, 146)  ## 地図を描く所（ゲームの座標）
const COLORS := {
	"grass": Color("5f9a42"), "town": Color("c9a66b"), "mountain": Color("9a9aa0"),
	"castle": Color("8a8478"), "lava": Color("8a3a2a"), "tower": Color("d8d4e8"),
}

var world: WorldMap
var run: RunState
var current_id := ""
var _fires := {}
var _title: Label

func setup(w: WorldMap, r: RunState) -> void:
	world = w
	run = r
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(320, 180)
	for id in world.ids():
		var info: Dictionary = Continent.load_map(world.area(id))[1]
		if info.has("checkpoint"):
			_fires[id] = info["checkpoint"]
	_title = UiText.label()
	_title.position = Vector2(8, 160)
	add_child(_title)

## 行ったエリアがすべて入るように、大陸のマスから画面への倍率と位置を決める。
func layout() -> Dictionary:
	var bounds := Rect2i()
	var first := true
	for id in run.visited_ids():
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

func area_rect(id: String, lay: Dictionary) -> Rect2:
	var r := world.area(id).rect()
	var k: float = lay["scale"]
	return Rect2(Vector2(r.position) * k + lay["offset"], Vector2(r.size) * k)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.08, 0.96))
	var lay := layout()
	for id in run.visited_ids():
		var a := world.area(id)
		var r := area_rect(id, lay)
		draw_rect(r, COLORS.get(a.theme, Color.GRAY))
		draw_rect(r, Color(0, 0, 0, 0.6), false, 1.0)
		if _fires.has(id):
			var p := r.position + (Vector2(_fires[id]) + Vector2(0.5, 0.5)) * float(lay["scale"])
			draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color("ff9a3c"))
		if run.grave != null and run.grave.area_id == id:
			var gp := r.position + (Vector2(run.grave.cell) + Vector2(0.5, 0.5)) * float(lay["scale"])
			draw_rect(Rect2(gp - Vector2(1.5, 1.5), Vector2(3, 3)), Color("f4f1ff"))
	if current_id != "" and run.has_visited(current_id):
		var cr := area_rect(current_id, lay)
		draw_rect(cr.grow(1.0), Color("ffe27a"), false, 1.0)
	var a := world.area(current_id)
	if a != null and _title != null:
		_title.text = "M：閉じる　いま：%s・%s　橙：たき火　白：墓石" % [a.region, a.title]
