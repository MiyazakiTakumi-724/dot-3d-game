class_name Terrain
extends RefCounted
## 文字の地図から高さマップを作り、地形を輪切りの絵で並べる。ステージ同士で共有する。
##
## 1層の地図（parse、試作1）：数字＝高さ、# ＝レンガの壁、R ＝岩、T ＝木、~ ＝水、= ＝橋、_ ＝奈落、
## C ＝チェックポイント、D ＝扉（門）、G ＝ゴール（R・T・=・C・D・G は高さ0）。
## 2層の地図（parse_layers、箱庭）：高さの層は . ＝島の外、数字＝高さ。物の層は . ＝なし、T ＝丸い木、
## P ＝とがった木、B ＝茂み、R ＝岩、F ＝花、~ ＝水、= ＝橋、_ ＝奈落、C/D/G。物はそのマスの高さに置く。
## 木・茂み・岩は壁と同じく移動も弾も止める。水は入れないが弾は通る。花は飾りで歩ける。
##
## 描き方：各マスを「柱」として描く。柱の上は地面の面、下は隣の一番低い床まで（column_bottom）。
## 隣が低くないマスは上の面だけになるので、描く枚数が少なくて済む。島のふちの柱は0より下へ伸びて、
## 浮いた島の断面（土と岩）になる。水の柱の側面は滝として描く。

const WALL_COLOR := Color("8a8f99")
## 草の上面の色（高さ0〜5）。高い所ほど少し明るい。
const GRASS_COLORS := [Color("6fb944"), Color("7cc24c"), Color("88ca55"), Color("95d161"), Color("a3d86c"), Color("b0de78")]
const DIRT_COLORS := [Color("a0703f"), Color("8f6136")]
const DEEP_COLORS := [Color("7a5236"), Color("6a4630"), Color("5a3c2c")]
const STONE_COLOR := Color("85807a")
const WATER_COLOR := Color("4fc3c9")
const FALL_COLORS := [Color("5fcbd6"), Color("8fe0ea"), Color("4ab4cf"), Color("d4f4f6"), Color("6fd2dc")]
const FOAM_COLOR := Color("dff7f7")
## 背景（島の外）のグラデーション
const SKY_TOP := Color("1f2438")
const SKY_BOTTOM := Color("0b0d16")
const SEA_COLOR := SKY_BOTTOM  ## 互換用（背景の色）

## 島のふちの断面の深さ（段）。マスごとに FOUNDATION_MIN〜+2 の間で変える。
const FOUNDATION_MIN := 3
## 島のふちから落ちる滝は、断面よりさらにこの段数だけ下まで描く
const FALL_EXTRA_LEVELS := 3
## 水面は地面より少し低い（px）
const WATER_DROP_PX := 2

## 1層の地図を map に書き込み、チェックポイント・ゴール・扉の場所を返す。見つからないものは入れない（doors は常に入る）。
static func parse(layout: Array, map: HeightMap) -> Dictionary:
	var info := {"doors": [], "deco": {}}
	for y in layout.size():
		for x in layout[y].length():
			var cell := Vector2i(x, y)
			var ch: String = layout[y][x]
			if ch == "#":
				map.set_wall(cell, true)
			elif ch.is_valid_int():
				map.set_height(cell, int(ch))
			else:
				_put_object(ch, cell, map, info)
	return info

## 2層の地図（高さの層と物の層）を map に書き込む。返すものは parse と同じ。
static func parse_layers(heights: Array, objects: Array, map: HeightMap) -> Dictionary:
	var info := {"doors": [], "deco": {}}
	for y in heights.size():
		for x in heights[y].length():
			var cell := Vector2i(x, y)
			var hc: String = heights[y][x]
			if hc == ".":
				map.set_void(cell, true)
				continue
			if not hc.is_valid_int():
				push_error("高さの層に知らない記号 '%s' がある：%s" % [hc, cell])
			map.set_height(cell, int(hc))
			var oc: String = objects[y][x] if y < objects.size() and x < objects[y].length() else "."
			_put_object(oc, cell, map, info)
	return info

static func _put_object(ch: String, cell: Vector2i, map: HeightMap, info: Dictionary) -> void:
	match ch:
		"R":
			map.set_wall(cell, true)
			info["deco"][cell] = "rock"
		"T":
			map.set_wall(cell, true)
			info["deco"][cell] = "tree"
		"P":
			map.set_wall(cell, true)
			info["deco"][cell] = "pine"
		"B":
			map.set_wall(cell, true)
			info["deco"][cell] = "bush"
		"F":
			info["deco"][cell] = "flower"
		"~":
			map.set_water(cell, true)
		"=":
			info["deco"][cell] = "bridge"
		"_":
			map.set_pit(cell, true)
		"C":
			info["checkpoint"] = cell
		"G":
			info["goal"] = cell
		"D":
			map.set_blocker(cell, HeightMap.Blocker.DOOR)
			info["doors"].append(cell)

## 島のふちの断面の深さ（段）。マスごとに決まっている。
static func foundation_levels(cell: Vector2i) -> int:
	return FOUNDATION_MIN + variant(cell + Vector2i(7, 3), 3)

## 柱の下の端（段）。隣（斜めも）の床の一番低い所まで描く。隣が島の外なら断面として0より下へ伸ばす。
## 水と橋のマスは水面が低いので、その隣は1段下まで描く（岸が見える）。奈落の隣は裂け目の底まで。
static func column_bottom(map: HeightMap, cell: Vector2i, deco: Dictionary = {}) -> int:
	var h := map.get_height(cell)
	var wet := _is_wet(map, cell, deco)
	var bottom := h - 1 if wet else h
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var n: Vector2i = cell + Vector2i(dx, dy)
			var f: int
			if map.is_void(n):
				f = -foundation_levels(cell) - (FALL_EXTRA_LEVELS if wet else 0)
			elif map.is_pit(n):
				f = -foundation_levels(n)
			elif _is_wet(map, n, deco):
				f = map.get_height(n) - 1
			else:
				f = map.get_height(n)
			bottom = mini(bottom, f)
	return bottom

static func _is_wet(map: HeightMap, cell: Vector2i, deco: Dictionary) -> bool:
	return map.is_water(cell) or deco.get(cell, "") == "bridge"

## 地形を並べる。deco は parse が返す info["deco"]（木・岩・花・橋などの場所）。
## 墓石や扉のマスには、その下の地面を置く（墓石・扉の絵はステージ側で上に置く）。
## 作ったモデルはステージをまたいで使い回す（輪切りの画像を作るのが重いため）
static var _models := {}

## 木・岩・茂み（歩けないマスの上の物）の draw_bias。同じ奥行きなら、キャラや鉄球より後に描く。
const DECO_BIAS := 5

static func build(map: HeightMap, camera: StackCamera, parent: Node2D, deco: Dictionary = {}) -> void:
	for y in map.size.y:
		for x in map.size.x:
			var cell := Vector2i(x, y)
			var keys := _cell_keys(map, cell, deco)
			if keys.is_empty():
				continue
			var h := map.get_height(cell)
			var bottom := 0 if keys[0] == "wall" else column_bottom(map, cell, deco)
			var s := _place(parent, camera, cell, bottom, 0, _cached(keys[0]))
			if keys[0].begins_with("ground/"):
				# 段のふちの明るい線は、モデルを増やさずにスプライトが上の面に描く
				s.rim_sides = lower_sides(map, cell)
				s.rim_layer = (h - bottom) * StackSprite.LEVEL_PX
				s.rim_color = top_color(h).lightened(0.38)
			if keys.size() > 1:
				_place(parent, camera, cell, h, DECO_BIAS, _cached(keys[1]))

## そのマスに置くモデルの名前（地面と、木などの物）。描かないマスは空。
static func _cell_keys(map: HeightMap, cell: Vector2i, deco: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if map.is_void(cell) or map.is_pit(cell):
		return out  # 島の外と奈落は描かない（奈落は、隣の柱の断面が裂け目の壁になる）
	var kind: String = deco.get(cell, "")
	var h := map.get_height(cell)
	var v := variant(cell, 3)
	var bottom := column_bottom(map, cell, deco)
	if map.is_wall(cell) and map.get_blocker(cell) == HeightMap.Blocker.NONE and kind == "":
		out.append("wall")
	elif map.is_water(cell):
		out.append("water/%d/%d/%d/%d/%d" % [h, h - bottom, v, int(_has_higher_water(map, cell)), int(_next_to_void(map, cell))])
	elif kind == "bridge":
		var across_ns := map.is_water(cell + Vector2i.UP) or map.is_water(cell + Vector2i.DOWN)
		out.append("bridge/%d/%d/%d" % [h, h - bottom, int(across_ns)])
	else:
		out.append("ground/%d/%d/%d/%d/%d" % [h, h - bottom, v, int(kind == "flower"), bottom])
	if kind in ["rock", "tree", "pine", "bush"]:
		out.append("%s/%d" % [kind, v])
	return out

## その地図を描くのに要るモデルの名前（重なりなし）。
static func model_keys(map: HeightMap, deco: Dictionary) -> Array[String]:
	var seen := {}
	for y in map.size.y:
		for x in map.size.x:
			for k in _cell_keys(map, Vector2i(x, y), deco):
				seen[k] = true
	var out: Array[String] = []
	out.assign(seen.keys())
	return out

static func is_cached(key: String) -> bool:
	return _models.has(key)

## keys のモデルを、budget_ms ミリ秒まで前もって作っておく。作り終えた名前は keys から取り除く。
## エリアに初めて入るときに待たせないよう、遊んでいる間に少しずつ呼ぶ。
static func warm(keys: Array[String], budget_ms: float) -> void:
	var start := Time.get_ticks_usec()
	while not keys.is_empty() and (Time.get_ticks_usec() - start) < budget_ms * 1000.0:
		_cached(keys.pop_back()).textures()

## 暗いグラデーションの背景を一番奥に置く（島が浮いて見えるように）。
static func add_background(parent: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	var rect := TextureRect.new()
	var tex := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, SKY_TOP)
	g.set_color(1, SKY_BOTTOM)
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 64
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # クリックやドラッグを横取りしない
	rect.position = Vector2.ZERO
	rect.size = Vector2(320, 180)
	layer.add_child(rect)
	parent.add_child(layer)
	RenderingServer.set_default_clear_color(SKY_BOTTOM)

## マスごとに決まった 0〜n-1 の値。見た目にばらつきを出すのに使う（毎回同じになる）。
static func variant(cell: Vector2i, n: int) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663)) % n

static func _has_higher_water(map: HeightMap, cell: Vector2i) -> bool:
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if map.is_water(cell + d) and map.get_height(cell + d) > map.get_height(cell):
			return true
	return false

static func _next_to_void(map: HeightMap, cell: Vector2i) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if map.is_void(cell + Vector2i(dx, dy)):
				return true
	return false

static func _place(parent: Node2D, camera: StackCamera, cell: Vector2i, h: int, bias: int, m: VoxelModel) -> StackSprite:
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = HeightMap.cell_center(cell)
	s.base_height = h
	s.draw_bias = bias
	s.voxel_scale = 1.0 / FINE
	s.layer_px = 1.0
	s.set_model(m)
	parent.add_child(s)
	return s

static func _cached(key: String) -> VoxelModel:
	if not _models.has(key):
		_models[key] = _make(key)
	return _models[key]

static func _make(key: String) -> VoxelModel:
	var p := key.split("/")
	match p[0]:
		"wall":
			return wall_model()
		"water":
			return water_model(int(p[1]), int(p[2]), int(p[3]), p[4] == "1", p[5] == "1")
		"bridge":
			return bridge_model(int(p[1]), int(p[2]), p[3] == "1")
		"ground":
			return ground_model(int(p[1]), int(p[2]), int(p[3]), p[4] == "1", int(p[5]))
		"rock":
			return rock_model(int(p[1]))
		"tree":
			return tree_model(int(p[1]))
		"pine":
			return pine_model(int(p[1]))
		"bush":
			return bush_model(int(p[1]))
	push_error("unknown terrain model: " + key)
	return VoxelModel.new()

## 位置から決まる、ばらつき用の値（0〜n-1）
static func _hash3(x: int, y: int, z: int, n: int) -> int:
	return absi((x * 92837111) ^ (y * 689287499) ^ (z * 283923481)) % n

## 上の面の色。高い所ほど少し明るくする（0〜8段）。
static func top_color(h: int) -> Color:
	return Color("5aa23a").lerp(Color("c4e48a"), clampf(h / 8.0, 0.0, 1.0))

## 隣が低い辺のビット（1＝北、2＝東、4＝南、8＝西）。マップの外・島の外・奈落も低いとみなす。
static func lower_sides(map: HeightMap, cell: Vector2i) -> int:
	var h := map.get_height(cell)
	var bits := 0
	var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for i in 4:
		var n: Vector2i = cell + dirs[i]
		if not map.in_bounds(n) or map.is_void(n) or map.is_pit(n) or map.get_height(n) < h:
			bits |= 1 << i
	return bits

## 地形の細かさ。1マスを 32×32 の輪切りで描き、ボクセル1つを本当の画面の1pxにする（主人公や小物と同じ細かさ）。
## 輪切りの間はゲームの座標の1pxのまま（描く枚数を増やさない）。側面は外側の2つの輪が見えるので、
## 外側（d=0）を下半分、内側（d=1）を上半分として塗ると、正面から見た崖も本当の画面の1pxで描ける。
const FINE := 2
const TEX := 16 * FINE
## 側面の向き（0 北・1 東・2 南・3 西）ごとの影の濃さ（VoxelShade.SHADOW へ寄せる割合）。
## 光は南西の上から来る（主人公や小物の影と同じ向き）
const SIDE_SHADE := [0.36, 0.28, 0.1, 0.18]
## 上の面に、ほんの少し光の色を足す
const TOP_LIGHT := 0.06

## 外側の2つの輪の上の点（x, y, 輪の深さ d, 向き face, 辺に沿った位置 along）。正方形 [lo, hi) のふち。
static func _ring(lo: int, hi: int) -> Array:
	var out := []
	for d in 2:
		var a := lo + d
		var b := hi - 1 - d
		for t in range(a, b + 1):
			out.append([t, b, d, 2, t])  # 南
			out.append([t, a, d, 0, t])  # 北
		for t in range(a + 1, b):
			out.append([a, t, d, 3, t])  # 西
			out.append([b, t, d, 1, t])  # 東
	return out

static var _rings := {}

static func _ring_cached(lo: int, hi: int) -> Array:
	var k := lo * 1000 + hi
	if not _rings.has(k):
		_rings[k] = _ring(lo, hi)
	return _rings[k]

## 側面の色に向きの影を付ける。
static func _side(c: Color, face: int) -> Color:
	return c.lerp(VoxelShade.SHADOW, SIDE_SHADE[face])

## 地面の柱。depth は柱の高さ（段）、bottom は柱の下の端の段（土の縞を隣とそろえるのに使う）。
## 上の面は草（マスごとに色を少しずらし、草の葉と草むらか花を足す）。側面は上から草のふち→土の縞→
## 0より下は暗い土と岩。島のふちの柱は、下の端が少しすぼまってでこぼこになる。
## 側面は1段ごとに暗い線を入れて、何段ぶんの崖かを数えられるようにする。
## 段のふちの明るい線はモデルには入れず、StackSprite.rim_sides で描く。
static func ground_model(h: int, depth: int, v: int = 0, flowers: bool = false, bottom: int = 0) -> VoxelModel:
	var layers := depth * StackSprite.LEVEL_PX + 1
	var grass: Color = top_color(h)
	grass = [grass, grass.lightened(0.05), grass.darkened(0.05)][v] as Color
	var base_px := bottom * StackSprite.LEVEL_PX
	var images: Array[Image] = []
	for z in layers:
		var abs_px := base_px + z  # 0 が高さ0の地面
		var from_top := layers - 1 - z
		var img := Image.create(TEX, TEX, false, Image.FORMAT_RGBA8)
		if from_top == 0:
			_grass_top(img, grass, v, h)
		else:
			# 島の下の端は、すぼめてでこぼこにする
			var inset := 0
			if bottom < 0 and z < 10:
				inset = ((10 - z) / 3 + (1 if (v + z) % 4 == 0 else 0)) * FINE
			img.fill_rect(Rect2i(inset, inset, TEX - 2 * inset, TEX - 2 * inset), _side(_cliff_color(grass, abs_px * FINE + 1, from_top * FINE - 1, 0, 2, v), 2))
			for r in _ring_cached(inset, TEX - inset):
				var vf: int = abs_px * FINE + r[2]
				var c := _cliff_color(grass, vf, from_top * FINE - r[2], r[4] + r[3] * 37, r[3], v)
				img.set_pixel(r[0], r[1], _side(c, r[3]))
		images.append(img)
	# 上の面の上に、草むらか花を立てる（2枚）
	var tuft_a := Image.create(TEX, TEX, false, Image.FORMAT_RGBA8)
	var tuft_b := Image.create(TEX, TEX, false, Image.FORMAT_RGBA8)
	if flowers:
		var petals := [Color("f6f1e4"), Color("ffd84a"), Color("ff8fb3"), Color("b9a6ff")]
		for i in 7:
			var px := (3 + i * 9 + v * 7) % 27 + 2
			var py := (5 + i * 13 + v * 5) % 27 + 2
			var pc: Color = petals[(i + v) % petals.size()]
			tuft_a.set_pixel(px, py, grass.darkened(0.25))
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				tuft_b.set_pixel(px + d.x, py + d.y, pc if d != Vector2i.ZERO else Color("ffe27a"))
	elif v != 2:
		var tuft := grass.darkened(0.2)
		for i in 4:
			var px := (5 + i * 9 + v * 8) % 27 + 2
			var py := (3 + i * 13 + v * 10) % 27 + 2
			for dx in [-1, 0, 1, 2]:
				tuft_a.set_pixel(px + dx, py, tuft)
			tuft_b.set_pixel(px - 1, py, tuft.lightened(0.1))
			tuft_b.set_pixel(px + 1, py, tuft.lightened(0.18))
			tuft_b.set_pixel(px + 2, py, tuft.lightened(0.1))
	images.append(tuft_a)
	images.append(tuft_b)
	return VoxelModel.from_images(images)

## 上の面の草：まだらの色・草の葉・小さな石。
static func _grass_top(img: Image, grass: Color, v: int, h: int) -> void:
	var light := grass
	img.fill(light)
	for y in TEX:
		for x in TEX:
			var k := _hash3(x / 2 + v * 17, y / 2 + h * 5, 3, 11)
			if k == 0:
				img.set_pixel(x, y, light.lightened(0.06))
			elif k == 1:
				img.set_pixel(x, y, light.darkened(0.06))
	# 草の葉（暗い根もとと、明るい先）
	for i in 14:
		var px := (i * 7 + v * 11 + h * 3) % 30 + 1
		var py := (i * 11 + v * 5 + h * 7) % 29 + 2
		img.set_pixel(px, py, light.darkened(0.16))
		img.set_pixel(px, py - 1, light.lightened(0.1))
	if v == 1:
		img.set_pixel(9, 21, STONE_COLOR.lightened(0.2))
		img.set_pixel(10, 21, STONE_COLOR)

## 崖の側面の1点の色。vf は高さ（本当の画面のpx、0 が高さ0の地面）、from_top は上の面からの深さ（同じ単位）、
## along は辺に沿った位置（ばらつき用）。
static func _cliff_color(grass: Color, vf: int, from_top: int, along: int, face: int, v: int) -> Color:
	var c: Color
	if from_top <= 3 or (from_top <= 6 and _hash3(along, v, face, 3) != 0):
		c = grass.darkened(0.05 * from_top)  # 崖のふちに草が少し垂れる
	elif vf >= 0:
		c = DIRT_COLORS[(vf / 6) % 2]
		c = c.darkened(clampf(from_top * 0.003, 0.0, 0.2))  # 下ほど少し暗く
		if _hash3(along / 2, vf / 2, face, 19) == 0:
			c = STONE_COLOR
		elif _hash3(along, vf / 9, face, 29) == 0:
			c = Color("6e4a2c")  # 根や割れ目
	else:
		var deep := clampi(-vf / 24, 0, DEEP_COLORS.size() - 1)
		c = DEEP_COLORS[deep]
		if _hash3(along / 2, vf / 3, face, 7) == 0:
			c = STONE_COLOR.darkened(0.1 * deep)
	if from_top > 6 and vf > 0 and vf % (StackSprite.LEVEL_PX * FINE) == 0:
		c = c.darkened(0.2)  # 1段ごとの線
	return c

## 水の柱。上の面は水面（地面より WATER_DROP_PX 低い）、側面は滝（縦の筋）。
## foam：上の段から滝が落ちてくる所なので、水面に白い泡を出す。
## falls_off：島のふちから落ちる滝なので、下の方ほど薄くする。
static func water_model(h: int, depth: int, v: int, foam: bool = false, falls_off: bool = false) -> VoxelModel:
	var layers := depth * StackSprite.LEVEL_PX - WATER_DROP_PX + 1
	var images: Array[Image] = []
	for z in layers:
		var img := Image.create(TEX, TEX, false, Image.FORMAT_RGBA8)
		if z == layers - 1:
			img.fill(WATER_COLOR)
			for y in TEX:
				for x in TEX:
					var k := _hash3(x / 3 + v * 5, y, 0, 37)
					if k == 0:
						# 水面のきらめき（横に短い光）
						img.set_pixel(x, y, WATER_COLOR.lightened(0.35))
						img.set_pixel(mini(x + 1, TEX - 1), y, WATER_COLOR.lightened(0.2))
					elif k == 1:
						img.set_pixel(x, y, WATER_COLOR.darkened(0.08))
					if foam and _hash3(x / 2, y / 2 + v, 1, 3) == 0:
						img.set_pixel(x, y, FOAM_COLOR)
		else:
			var fade := 1.0
			if falls_off and z < 24:
				fade = 0.25 + 0.75 * float(z) / 24.0
			var base := Color(FALL_COLORS[0], fade)
			if z < 3 and not falls_off:
				base = FOAM_COLOR  # 滝の下のしぶき
			img.fill(base)
			if not (z < 3 and not falls_off):
				for r in _ring_cached(0, TEX):
					var c: Color = FALL_COLORS[_hash3(r[4] + r[3] * 37, v, 0, FALL_COLORS.size())]
					if _hash3(r[4], z * FINE + r[2], r[3], 9) == 0:
						c = FOAM_COLOR  # 落ちる水のしぶき
					c.a = fade
					img.set_pixel(r[0], r[1], c)
		images.append(img)
	return VoxelModel.from_images(images)

## 橋：水の柱の上に板を渡す。across_ns なら北と南が水（東西に渡る）なので、手すりを北と南に付ける。
static func bridge_model(h: int, depth: int, across_ns: bool) -> VoxelModel:
	var water := water_model(h, depth, 0)
	var plank_z := depth * StackSprite.LEVEL_PX
	var images: Array[Image] = []
	for img in water.slices():
		images.append(img)
	while images.size() < plank_z + 3:
		images.append(Image.create(TEX, TEX, false, Image.FORMAT_RGBA8))
	var plank_img := images[plank_z]
	var rail := images[plank_z + 1]
	var post := images[plank_z + 2]
	for yy in TEX:
		for xx in TEX:
			var along := xx if across_ns else yy  # 板の継ぎ目は渡る向きと直角（板は渡る向きに並ぶ）
			var across := yy if across_ns else xx
			var plank := Color("a06a3a") if (along / 8) % 2 == 0 else Color("94603a")
			if along % 8 == 7:
				plank = Color("6e4526")
			elif (along % 8 == 1) and (across == 4 or across == 27):
				plank = Color("4a3020")  # くぎ
			elif _hash3(along / 8, across / 3, 5, 7) == 0:
				plank = plank.darkened(0.08)  # 木目
			plank_img.set_pixel(xx, yy, plank.lerp(VoxelShade.LIGHT, TOP_LIGHT))
			var edge := (across <= 1 or across >= TEX - 2)
			if edge:
				rail.set_pixel(xx, yy, Color("6e4526"))
				if along % 10 < 2:
					post.set_pixel(xx, yy, Color("5b3a22"))
	return VoxelModel.from_images(images)

## 岩：灰色の塊で、上は白っぽい。並べると岩山になるように、マスいっぱいの形にする（角は少し丸める）。
## 8×8 の塊ごとに高さを変えてごつごつさせ、側面は横の地層と、塊の境の割れ目で描く。
static func rock_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	var top_h: int = [22, 26, 30][v]
	m.size = Vector3i(TEX, TEX, top_h + 4)
	for yy in TEX:
		for xx in TEX:
			if (xx <= 1 or xx >= TEX - 2) and (yy <= 1 or yy >= TEX - 2):
				continue
			var bx := xx / 8
			var by := yy / 8
			var bump := (bx * 7 + by * 13 + v * 5) % 4
			var hh: int = top_h + bump
			var shift := _hash3(bx, by, v, 4)
			for z in hh:
				var c := Color("8d8f94") if ((z + shift) / 4) % 2 == 0 else Color("858790")
				if z == hh - 1:
					c = Color("e4e7ea") if bump == 3 else Color("b9bdc3")
				elif z == hh - 2:
					c = Color("a4a8ae")
				elif (xx % 8 == 0 or yy % 8 == 0) and _hash3(bx, by, z / 3, 3) == 0:
					c = Color("6a6c73")  # 塊の境の割れ目
				if z < 3 and _hash3(xx / 2, yy / 2, z, 3) == 0:
					c = Color("5f8f45")  # 根元の苔
				m.set_voxel(Vector3i(xx, yy, z), c)
	return VoxelShade.apply(m)

## 葉の影：面の向き n と光から4段階。明るい所と暗い所に、ときどき1つだけ違う色を混ぜて葉の細かさを出す。
static func _leaf_shade(c: Color, n: Vector3, speck: int) -> Color:
	var k := n.normalized().dot(VoxelShade.LIGHT_DIR.normalized()) if n != Vector3.ZERO else 1.0
	if k > 0.6:
		return c.lerp(VoxelShade.LIGHT, 0.42 if speck == 0 else 0.26)
	elif k > 0.15:
		return c.lerp(VoxelShade.LIGHT, 0.14) if speck == 0 else c
	elif k > -0.3:
		return c.lerp(VoxelShade.SHADOW, 0.22)
	return c.lerp(VoxelShade.SHADOW, 0.42 if speck != 0 else 0.3)

## 玉（葉のかたまり）をいくつか重ねた葉を置く。clumps は [中心（ゲームの座標のpx。z は輪切りの番号）, 半径] の列。
## 見える面の向きは、その点がふちに一番近い玉から出す（玉ごとに光が当たり、葉のかたまりに見える）。
## berry があれば、明るい側にときどき実を付ける。
static func _clumps(m: VoxelModel, clumps: Array, leaf: Color, z0: int, berry := Color(0, 0, 0, 0)) -> void:
	# 全部の玉を囲む球の外は調べない（速くするため）
	var center: Vector3 = clumps[0][0]
	var reach := 0.0
	for cl in clumps:
		reach = maxf(reach, center.distance_to(cl[0]) + cl[1])
	for z in range(z0, m.size.z):
		for yy in m.size.y:
			for xx in m.size.x:
				var p := Vector3((xx + 0.5) / FINE, (yy + 0.5) / FINE, z + 0.5)
				if p.distance_to(center) > reach:
					continue
				var lim := 1.0 - 0.07 * _hash3(xx / 3, yy / 3, z / 2, 3)
				var best := -1.0
				var n := Vector3.ZERO
				for cl in clumps:
					var d: Vector3 = p - cl[0]
					var q: float = d.length() / cl[1]
					if q <= lim and q > best:
						best = q
						n = d
				if best < 0.0:
					continue
				var c := leaf.darkened(0.1) if z < z0 + 2 else leaf
				c = _leaf_shade(c, n, _hash3(xx, yy, z, 11))
				if berry.a > 0.0 and best > 0.75 and _hash3(xx / 2, yy / 2, z, 19) == 0:
					c = berry
				m.set_voxel(Vector3i(xx, yy, z), c)

## 幹（立てた円柱）。光の側は明るく、反対は暗い。
static func _trunk(m: VoxelModel, center: Vector2, r: float, z1: int, bark: Color) -> void:
	for z in z1:
		for yy in m.size.y:
			for xx in m.size.x:
				var d := Vector2((xx + 0.5) / FINE, (yy + 0.5) / FINE) - center
				if d.length() > r:
					continue
				var c := bark if (xx + z * 3) % 7 != 0 else bark.darkened(0.18)  # 木の皮のすじ
				m.set_voxel(Vector3i(xx, yy, z), VoxelShade.band(c, Vector3(d.x, d.y, 0.0), VoxelShade.LIGHT_DIR.normalized()))

## 丸い木：マスより少し大きい、こんもりした葉。葉のかたまりごとに光が当たる。v で色と形を少し変える。
static func tree_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(40, 40, 30)
	_trunk(m, Vector2(10, 10), 2.2, 12, Color("7a4a2a"))
	var leaf: Color = [Color("3f9a3a"), Color("4aa843"), Color("379140")][v]
	var c := Vector3(10, 10, 17)
	var clumps := [[c, 7.2 - v * 0.3], [c + Vector3(0, 0, 6), 5.0]]
	for i in 6:
		var a := TAU * i / 6.0 + v * 0.7
		var off := Vector2.from_angle(a) * (4.6 - v * 0.2)
		clumps.append([c + Vector3(off.x, off.y, -1.0 + (i % 3) * 1.5), 4.4])
	_clumps(m, clumps, leaf, 8)
	return m

## とがった木：段々に細くなる葉の傘を4つ重ねる。傘ごとに上が明るく、下が暗い。
static func pine_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(TEX, TEX, 32)
	_trunk(m, Vector2(8, 8), 1.5, 8, Color("6b4026"))
	var leaf: Color = [Color("2f7a45"), Color("357f3c"), Color("2b6e4a")][v]
	for z in range(5, 32):
		var tier := (z - 5) % 7
		var level := (z - 5) / 7
		var radius := maxf(0.8, 7.5 - level * 1.6 - tier * 0.55)
		for yy in TEX:
			for xx in TEX:
				var d := Vector2((xx + 0.5) / FINE - 8.0, (yy + 0.5) / FINE - 8.0)
				var lim := radius - 0.3 * _hash3(xx / 2, yy / 2, z, 3)
				if d.length() > lim:
					continue
				# 傘の面：外向きで、上を向いている（下の2枚は傘の裏で暗い）
				var n := Vector3(d.x, d.y, 0.0).normalized() + Vector3(0, 0, 1.1 if tier >= 2 else -0.4)
				var c := _leaf_shade(leaf, n, _hash3(xx, yy, z, 11))
				m.set_voxel(Vector3i(xx, yy, z), c)
	return m

## 茂み：低くて丸い葉のかたまり。v=1 は赤い実が付く。
static func bush_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(TEX, TEX, 11)
	var leaf := Color("4fae45") if v != 2 else Color("5bb84d")
	var c := Vector3(8, 8, 2.5)
	var clumps := [[c, 6.0]]
	for i in 5:
		var a := TAU * i / 5.0 + v * 1.1
		var off := Vector2.from_angle(a) * 3.6
		clumps.append([c + Vector3(off.x, off.y, 1.0 + (i % 2) * 1.5), 3.8])
	_clumps(m, clumps, leaf, 0, Color("d9463b") if v == 1 else Color(0, 0, 0, 0))
	return m

## 石の壁（試作1）：れんがを積んだ柱。
static func wall_model() -> VoxelModel:
	var n := 14 * FINE
	var images: Array[Image] = []
	for z in 20:
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var mortar := z % 5 == 0
		if z == 19:
			img.fill(WALL_COLOR.lerp(VoxelShade.LIGHT, 0.12))
		else:
			img.fill(WALL_COLOR)
			for r in _ring_cached(0, n):
				var brick: bool = mortar or ((r[4] + (z / 5) * 8) % 14 == 0)
				img.set_pixel(r[0], r[1], _side(WALL_COLOR.darkened(0.15) if brick else WALL_COLOR, r[3]))
		images.append(img)
	return VoxelModel.from_images(images)
