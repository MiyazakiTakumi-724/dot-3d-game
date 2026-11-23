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

static func build(map: HeightMap, camera: StackCamera, parent: Node2D, deco: Dictionary = {}) -> void:
	for y in map.size.y:
		for x in map.size.x:
			var cell := Vector2i(x, y)
			if map.is_void(cell) or map.is_pit(cell):
				continue  # 島の外と奈落は描かない（奈落は、隣の柱の断面が裂け目の壁になる）
			var kind: String = deco.get(cell, "")
			var h := map.get_height(cell)
			var v := variant(cell, 3)
			var bottom := column_bottom(map, cell, deco)
			var key: String
			if map.is_wall(cell) and map.get_blocker(cell) == HeightMap.Blocker.NONE and kind == "":
				key = "wall"
				bottom = 0
			elif map.is_water(cell):
				key = "water/%d/%d/%d/%d/%d" % [h, h - bottom, v, int(_has_higher_water(map, cell)), int(_next_to_void(map, cell))]
			elif kind == "bridge":
				var across_ns := map.is_water(cell + Vector2i.UP) or map.is_water(cell + Vector2i.DOWN)
				key = "bridge/%d/%d/%d" % [h, h - bottom, int(across_ns)]
			else:
				key = "ground/%d/%d/%d/%d/%d" % [h, h - bottom, v, int(kind == "flower"), bottom]
			_place(parent, camera, cell, bottom, 0, _cached(key))
			if kind in ["rock", "tree", "pine", "bush"]:
				_place(parent, camera, cell, h, 1, _cached("%s/%d" % [kind, v]))

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

static func _place(parent: Node2D, camera: StackCamera, cell: Vector2i, h: int, bias: int, m: VoxelModel) -> void:
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = HeightMap.cell_center(cell)
	s.base_height = h
	s.draw_bias = bias
	s.set_model(m)
	parent.add_child(s)

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

## 地面の柱。depth は柱の高さ（段）、bottom は柱の下の端の段（土の縞を隣とそろえるのに使う）。
## 上の面は草（マスごとに色を少しずらし、草むらか花を足す）。側面は上から草のふち→土の縞→
## 0より下は暗い土と岩。島のふちの柱は、下の端が少しすぼまってでこぼこになる。
static func ground_model(h: int, depth: int, v: int = 0, flowers: bool = false, bottom: int = 0) -> VoxelModel:
	var layers := depth * StackSprite.LEVEL_PX + 1
	var grass: Color = GRASS_COLORS[clampi(h, 0, GRASS_COLORS.size() - 1)]
	grass = [grass, grass.lightened(0.05), grass.darkened(0.05)][v] as Color
	var m := VoxelModel.new()
	m.size = Vector3i(16, 16, layers + 2)
	var base_px := bottom * StackSprite.LEVEL_PX
	for z in layers:
		var abs_px := base_px + z  # 0 が高さ0の地面
		var from_top := layers - 1 - z
		# 島の下の端は、すぼめてでこぼこにする
		var inset := 0
		if bottom < 0 and z < 10:
			inset = (10 - z) / 3 + (1 if (v + z) % 4 == 0 else 0)
		for yy in range(inset, 16 - inset):
			for xx in range(inset, 16 - inset):
				var c: Color
				if from_top == 0:
					c = grass
				elif from_top <= 2 and (from_top == 1 or (xx * 3 + yy * 5) % 4 != 0):
					c = grass.darkened(0.12 * from_top)  # 崖のふちに草が少し垂れる
				elif abs_px >= 0:
					c = DIRT_COLORS[(abs_px / 3) % 2]
					c = c.darkened(clampf(from_top * 0.006, 0.0, 0.2))  # 下ほど少し暗く
					if _hash3(xx, yy, abs_px, 23) == 0:
						c = STONE_COLOR
					elif _hash3(xx, yy, abs_px / 5, 31) == 0:
						c = Color("6e4a2c")  # 根や割れ目
				else:
					var deep := clampi(-abs_px / 12, 0, DEEP_COLORS.size() - 1)
					c = DEEP_COLORS[deep]
					if _hash3(xx, yy, abs_px / 3, 7) == 0:
						c = STONE_COLOR.darkened(0.1 * deep)
				m.set_voxel(Vector3i(xx, yy, z), c)
	var top := layers
	if flowers:
		var petals := [Color("f6f1e4"), Color("ffd84a"), Color("ff8fb3"), Color("b9a6ff")]
		for i in 6:
			var px := (2 + i * 5 + v * 3) % 14 + 1
			var py := (3 + i * 7 + v * 4) % 14 + 1
			m.set_voxel(Vector3i(px, py, top), grass.darkened(0.2))
			m.set_voxel(Vector3i(px, py, top + 1), petals[(i + v) % petals.size()])
	elif v != 2:
		var tuft := grass.darkened(0.22)
		for i in 3:
			var px := (3 + i * 5 + v * 4) % 14 + 1
			var py := (2 + i * 7 + v * 5) % 14 + 1
			m.set_voxel(Vector3i(px, py, top), tuft)
			m.set_voxel(Vector3i(px + 1, py, top), tuft)
			m.set_voxel(Vector3i(px, py, top + 1), tuft.lightened(0.12))
	return m

## 水の柱。上の面は水面（地面より WATER_DROP_PX 低い）、側面は滝（縦の筋）。
## foam：上の段から滝が落ちてくる所なので、水面に白い泡を出す。
## falls_off：島のふちから落ちる滝なので、下の方ほど薄くする。
static func water_model(h: int, depth: int, v: int, foam: bool = false, falls_off: bool = false) -> VoxelModel:
	var layers := depth * StackSprite.LEVEL_PX - WATER_DROP_PX + 1
	var m := VoxelModel.new()
	m.size = Vector3i(16, 16, layers)
	for z in layers:
		var top := z == layers - 1
		var fade := 1.0
		if falls_off and z < 24:
			fade = 0.25 + 0.75 * float(z) / 24.0
		for yy in 16:
			for xx in 16:
				var c: Color
				if top:
					c = WATER_COLOR
					if _hash3(xx + v * 5, yy, 0, 29) == 0:
						c = WATER_COLOR.lightened(0.35)  # 水面のきらめき
					if foam and _hash3(xx, yy + v, 1, 3) == 0:
						c = FOAM_COLOR
				else:
					c = FALL_COLORS[_hash3(xx, yy, v, FALL_COLORS.size())]
					if z < 3 and not falls_off:
						c = FOAM_COLOR  # 滝の下のしぶき
					c.a = fade
				m.set_voxel(Vector3i(xx, yy, z), c)
	return m

## 橋：水の柱の上に板を渡す。across_ns なら北と南が水（東西に渡る）なので、手すりを北と南に付ける。
static func bridge_model(h: int, depth: int, across_ns: bool) -> VoxelModel:
	var water := water_model(h, depth, 0)
	var m := VoxelModel.new()
	var water_layers := water.size.z
	var plank_z := depth * StackSprite.LEVEL_PX
	m.size = Vector3i(16, 16, plank_z + 3)
	for p: Vector3i in water._voxels:
		m.set_voxel(p, water._voxels[p])
	for yy in 16:
		for xx in 16:
			var along := yy if across_ns else xx  # 板の継ぎ目は渡る向きと直角
			var plank := Color("a06a3a") if (along / 4) % 2 == 0 else Color("94603a")
			if along % 4 == 3:
				plank = Color("6e4526")
			m.set_voxel(Vector3i(xx, yy, plank_z), plank)
			var edge := (yy == 0 or yy == 15) if across_ns else (xx == 0 or xx == 15)
			if edge:
				m.set_voxel(Vector3i(xx, yy, plank_z + 1), Color("6e4526"))
				if (xx + yy) % 5 == 0:
					m.set_voxel(Vector3i(xx, yy, plank_z + 2), Color("5b3a22"))
	assert(water_layers <= plank_z)
	return m

## 岩：灰色の塊で、上は白っぽい。並べると岩山になるように、マスいっぱいの形にする（角は少し丸める）。
static func rock_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	var top_h: int = [22, 26, 30][v]
	m.size = Vector3i(16, 16, top_h + 4)
	for yy in 16:
		for xx in 16:
			if (xx == 0 or xx == 15) and (yy == 0 or yy == 15):
				continue
			# 4×4 の塊ごとに高さを少し変えて、ごつごつさせる
			var bump := ((xx / 4) * 7 + (yy / 4) * 13 + v * 5) % 4
			var hh: int = top_h + bump
			for z in hh:
				var c := Color("8d8f94")
				if z == hh - 1:
					c = Color("e4e7ea") if bump == 3 else Color("b3b7bd")
				elif (z + xx * 3 + yy) % 9 == 0:
					c = Color("6f7177")
				elif (xx / 4 + yy / 4) % 2 == 0:
					c = Color("84868b")
				if z < 3 and (xx + yy + z) % 3 == 0:
					c = Color("5f8f45")  # 根元の苔
				m.set_voxel(Vector3i(xx, yy, z), c)
	return m

## 丸い木：マスより少し大きい、こんもりした葉。下は暗く、上は明るい。v で色と形を少し変える。
static func tree_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(20, 20, 30)
	var trunk := Color("7a4a2a")
	for z in 10:
		for yy in range(8, 12):
			for xx in range(8, 12):
				m.set_voxel(Vector3i(xx, yy, z), trunk if (xx + z) % 4 != 0 else trunk.darkened(0.15))
	var leaf: Color = [Color("3f9a3a"), Color("4aa843"), Color("379140")][v]
	var center := Vector3(9.5, 9.5, 18.0)
	var r := 9.2 - v * 0.4
	for z in range(7, 30):
		for yy in 20:
			for xx in 20:
				var d := Vector3(xx, yy, z) - center
				d.z *= 1.15
				# でこぼこした輪郭にする
				var bump := float(_hash3(xx / 3, yy / 3, z / 3, 5)) * 0.35
				if d.length() > r - bump:
					continue
				var c := leaf
				var t := float(z - 7) / 22.0
				if t < 0.3:
					c = leaf.darkened(0.25)
				elif t > 0.75:
					c = leaf.lightened(0.2)
				if _hash3(xx, yy, z, 9) == 0:
					c = c.lightened(0.15)
				m.set_voxel(Vector3i(xx, yy, z), c)
	return m

## とがった木：段々に細くなる葉。
static func pine_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(16, 16, 32)
	var trunk := Color("6b4026")
	for z in 8:
		for yy in range(7, 9):
			for xx in range(7, 9):
				m.set_voxel(Vector3i(xx, yy, z), trunk)
	var leaf: Color = [Color("2f7a45"), Color("357f3c"), Color("2b6e4a")][v]
	for z in range(5, 32):
		# 4段の傘を重ねる。それぞれの段は下が広い
		var tier := (z - 5) % 7
		var level := (z - 5) / 7
		var radius := 7.5 - level * 1.6 - tier * 0.55
		if radius < 0.8:
			radius = 0.8
		for yy in 16:
			for xx in 16:
				var d := Vector2(xx - 7.5, yy - 7.5).length()
				if d > radius:
					continue
				var c := leaf.darkened(0.2) if tier < 2 else leaf
				if tier >= 5:
					c = leaf.lightened(0.15)
				m.set_voxel(Vector3i(xx, yy, z), c)
	return m

## 茂み：低くて丸い葉のかたまり。v=1 は赤い実が付く。
static func bush_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(16, 16, 11)
	var leaf := Color("4fae45") if v != 2 else Color("5bb84d")
	var center := Vector3(7.5, 7.5, 3.0)
	for z in 11:
		for yy in 16:
			for xx in 16:
				var d := Vector3(xx, yy, z) - center
				d.z *= 1.4
				var bump := float(_hash3(xx / 2, yy / 2, z / 2, 4)) * 0.4
				if d.length() > 7.6 - bump:
					continue
				var c := leaf.darkened(0.2) if z < 3 else (leaf.lightened(0.15) if z > 7 else leaf)
				if v == 1 and _hash3(xx, yy, z, 17) == 0:
					c = Color("d9463b")
				m.set_voxel(Vector3i(xx, yy, z), c)
	return m

static func wall_model() -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(14, 14, 20)
	for z in 20:
		for yy in 14:
			for xx in 14:
				var brick := (z % 5 == 0) or ((xx + (z / 5) * 4) % 7 == 0)
				m.set_voxel(Vector3i(xx, yy, z), WALL_COLOR.darkened(0.15) if brick else WALL_COLOR)
	return m
