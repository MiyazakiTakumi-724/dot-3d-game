class_name ShadowMap
extends RefCounted
## 地面に落ちる影（2026-11-26 の3回目の直し。添付の映像のように、木や崖の長い影を地面に落とす）。
## 日は西南西の空にあり、崖・木・岩・家などの影が東北東へ落ちる（地形の側面の明るさ SIDE_SHADE と同じ向きの光）。
## エリアごとに「物のてっぺんの高さ」の絵（RES×RES で1マス）を作り、地面の柱が上の面に影を描くときに、
## シェーダー（shadow.gdshader）がそこから日の方へたどって、影の線より高い物があれば影にする。
## 影はワールドに落ちるので、カメラを回しても地面と一緒に回る。

const RES := 8
## 日のある向き（ワールド、マス単位の水平の向き）。影はこの逆へ落ちる
const SUN := Vector2(-0.94, 0.34)
## 1段の高さの物の影の長さ（マス）
const CELLS_PER_LEVEL := 0.55
## 高さの絵の値は 高さ ÷ HEIGHT_RANGE（R8 に入るように）
const HEIGHT_RANGE := 16.0
## 物の高さ（段）と、マスの中で影を落とす丸の半径（マス）。SQUARE はマスいっぱいの四角い物
const OCCLUDERS := {
	"tree": [4.5, 0.42], "pine": [5.5, 0.34], "bush": [1.6, 0.42], "rock": [1.8, 0.45],
	"stonewall": [2.5, 0.5], "column": [4.0, 0.3], "house": [4.0, 0.5], "well": [1.5, 0.4], "npc": [2.2, 0.3],
}
const SQUARE := ["stonewall", "house"]
const SHADER := preload("res://scripts/render/shadow.gdshader")

## 影の色（青みのある暗さ。添付の映像の影に合わせた）
const SHADE_COLOR := Color(0.10, 0.07, 0.28, 0.42)

static var _white: ImageTexture

## そのワールドの点（マス単位）にある物のてっぺんの高さ（段）。島の外と奈落は影を落とさない。
static func occluder_height(map: HeightMap, deco: Dictionary, q: Vector2) -> float:
	var c := Vector2i(floori(q.x), floori(q.y))
	if not map.in_bounds(c) or map.is_void(c) or map.is_pit(c):
		return 0.0
	var h := float(map.get_height(c))
	var kind: String = deco.get(c, "")
	if OCCLUDERS.has(kind):
		var o: Array = OCCLUDERS[kind]
		if kind in SQUARE or (q - Vector2(c) - Vector2(0.5, 0.5)).length() <= o[1]:
			return h + o[0]
	return h

## エリアの、物のてっぺんの高さの絵（R8、RES×RES で1マス、値は 高さ ÷ HEIGHT_RANGE）。
## 地面はマスごとに四角く塗り（速い）、木や岩などは丸く塗る。
static func height_image(map: HeightMap, deco: Dictionary) -> Image:
	var img := Image.create(map.size.x * RES, map.size.y * RES, false, Image.FORMAT_R8)
	img.fill(Color(0, 0, 0))
	for y in map.size.y:
		for x in map.size.x:
			var c := Vector2i(x, y)
			if map.is_void(c) or map.is_pit(c):
				continue
			var h := float(map.get_height(c))
			img.fill_rect(Rect2i(x * RES, y * RES, RES, RES), Color(h / HEIGHT_RANGE, 0, 0))
			var kind: String = deco.get(c, "")
			if not OCCLUDERS.has(kind):
				continue
			var o: Array = OCCLUDERS[kind]
			var top := Color(minf(1.0, (h + o[0]) / HEIGHT_RANGE), 0, 0)
			if kind in SQUARE:
				img.fill_rect(Rect2i(x * RES, y * RES, RES, RES), top)
				continue
			for j in RES:
				for i in RES:
					if Vector2((i + 0.5) / RES - 0.5, (j + 0.5) / RES - 0.5).length() <= o[1]:
						img.set_pixel(x * RES + i, y * RES + j, top)
	return img

## エリアの地面の柱で使う材質（影のシェーダーと、そのエリアの高さの絵）。
static func material(map: HeightMap, deco: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("height_tex", ImageTexture.create_from_image(height_image(map, deco)))
	m.set_shader_parameter("area_cells", Vector2(map.size))
	m.set_shader_parameter("sun", SUN)
	m.set_shader_parameter("cells_per_level", CELLS_PER_LEVEL)
	m.set_shader_parameter("height_range", HEIGHT_RANGE)
	m.set_shader_parameter("shade_color", SHADE_COLOR)
	return m

## 柱の上の面に影を描くときに渡す色（シェーダーはこの色でマスと高さを知る。a=0.5 が目印）。
static func cell_code(cell: Vector2i, h: int) -> Color:
	return Color(cell.x / 255.0, cell.y / 255.0, h / HEIGHT_RANGE, 0.5)

## 1×1 の白い絵（影の面を描くのに使う）。
static func white() -> ImageTexture:
	if _white == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	return _white
