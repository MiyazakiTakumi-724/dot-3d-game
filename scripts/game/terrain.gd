class_name Terrain
extends RefCounted
## 文字の地図から高さマップを作り、地形を輪切りの絵で並べる。ステージ同士で共有する。
## 記号：数字＝高さ、# ＝レンガの壁（試作1）、R ＝岩、T ＝木、~ ＝水、= ＝橋、_ ＝奈落、
## C ＝チェックポイント、D ＝扉（門）、G ＝ゴール（R・T・=・C・D・G は高さ0）。
## R と T は壁と同じく移動も弾も止める。水は入れないが弾は通る。

const WALL_COLOR := Color("8a8f99")
## 草の上面の色（高さ0〜3）。高い所ほど少し明るい。
const GRASS_COLORS := [Color("79c04a"), Color("86c955"), Color("93d161"), Color("a2d86d")]
const DIRT_COLORS := [Color("a0703f"), Color("8c5f35")]
const WATER_COLOR := Color("4fc3c9")
const SEA_COLOR := Color("2f8f9d")  ## マップの外（背景）の色

## 地図を map に書き込み、チェックポイント・ゴール・扉の場所を返す。見つからないものは入れない（doors は常に入る）。
static func parse(layout: Array, map: HeightMap) -> Dictionary:
	var info := {"doors": [], "deco": {}}
	for y in layout.size():
		for x in layout[y].length():
			var cell := Vector2i(x, y)
			var ch: String = layout[y][x]
			match ch:
				"#":
					map.set_wall(cell, true)
				"R":
					map.set_wall(cell, true)
					info["deco"][cell] = "rock"
				"T":
					map.set_wall(cell, true)
					info["deco"][cell] = "tree"
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
				_:
					map.set_height(cell, int(ch))
	return info

## 地形を並べる。deco は parse が返す info["deco"]（岩・木・橋の場所）。
## 墓石や扉のマスには、その下の地面を置く（墓石・扉の絵はステージ側で上に置く）。
static func build(map: HeightMap, camera: StackCamera, parent: Node2D, deco: Dictionary = {}) -> void:
	var models := {}
	for y in map.size.y:
		for x in map.size.x:
			var cell := Vector2i(x, y)
			var kind: String = deco.get(cell, "")
			var v := variant(cell, 3)
			var key: String
			if map.is_pit(cell):
				key = "pit"
			elif map.is_water(cell):
				key = "water%d" % v
			elif kind == "bridge":
				key = "bridge"
			elif map.is_wall(cell) and map.get_blocker(cell) == HeightMap.Blocker.NONE and kind == "":
				key = "wall"
			else:
				key = "ground%d_%d" % [map.get_height(cell), v]
			_place(parent, camera, cell, 0, 0, _cached(models, key))
			if kind == "rock" or kind == "tree":
				_place(parent, camera, cell, map.get_height(cell), 1, _cached(models, "%s%d" % [kind, v]))

## マスごとに決まった 0〜n-1 の値。見た目にばらつきを出すのに使う（毎回同じになる）。
static func variant(cell: Vector2i, n: int) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663)) % n

static func _place(parent: Node2D, camera: StackCamera, cell: Vector2i, h: int, bias: int, m: VoxelModel) -> void:
	var s := StackSprite.new()
	s.camera = camera
	s.world_pos = HeightMap.cell_center(cell)
	s.base_height = h
	s.draw_bias = bias
	s.set_model(m)
	parent.add_child(s)

static func _cached(models: Dictionary, key: String) -> VoxelModel:
	if not models.has(key):
		models[key] = _make(key)
	return models[key]

static func _make(key: String) -> VoxelModel:
	if key == "pit":
		return VoxelModel.box(Vector3i(16, 16, 1), Color("1b1a22"))
	if key == "wall":
		return wall_model()
	if key == "bridge":
		return bridge_model()
	var v := int(key.right(1))
	if key.begins_with("water"):
		return water_model(v)
	if key.begins_with("rock"):
		return rock_model(v)
	if key.begins_with("tree"):
		return tree_model(v)
	# "ground<h>_<v>"
	return ground_model(int(key.substr(6, 1)), v)

## 地面。上面は草（マスごとに色を少しずらし、草むらを足す）、側面は土の縞。
static func ground_model(h: int, v: int = 0) -> VoxelModel:
	var layers := maxi(1, h * StackSprite.LEVEL_PX)
	var grass: Color = GRASS_COLORS[clampi(h, 0, GRASS_COLORS.size() - 1)]
	grass = [grass, grass.lightened(0.05), grass.darkened(0.05)][v] as Color
	var tuft := grass.darkened(0.25)
	var m := VoxelModel.new()
	m.size = Vector3i(16, 16, layers + 2)
	for z in layers:
		var dirt: Color = DIRT_COLORS[(z / 2) % 2]
		for yy in 16:
			for xx in 16:
				var c := dirt
				if z == layers - 1:
					c = grass
				elif z == layers - 2 and (xx + yy * 3) % 5 == 0:
					c = grass.darkened(0.1)  # 崖のふちに草が少し垂れる
				m.set_voxel(Vector3i(xx, yy, z), c)
	# 草むら（マスによって場所が変わる）
	if v != 2:
		for i in 3:
			var px := (3 + i * 5 + v * 4) % 14 + 1
			var py := (2 + i * 7 + v * 5) % 14 + 1
			m.set_voxel(Vector3i(px, py, layers), tuft)
			m.set_voxel(Vector3i(px + 1, py, layers), tuft)
			m.set_voxel(Vector3i(px, py, layers + 1), tuft.lightened(0.1))
	return m

static func water_model(v: int) -> VoxelModel:
	var m := VoxelModel.box(Vector3i(16, 16, 1), WATER_COLOR)
	for i in 4:  # 水面のきらめき
		var px := (2 + i * 4 + v * 3) % 15
		var py := (1 + i * 6 + v * 5) % 15
		m.set_voxel(Vector3i(px, py, 0), WATER_COLOR.lightened(0.35))
		m.set_voxel(Vector3i(px + 1, py, 0), WATER_COLOR.lightened(0.35))
	return m

static func bridge_model() -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(16, 16, 3)
	for yy in 16:
		for xx in 16:
			m.set_voxel(Vector3i(xx, yy, 0), WATER_COLOR)
			var plank := Color("a06a3a") if (xx / 4) % 2 == 0 else Color("94603a")
			if xx % 4 == 3:
				plank = Color("6e4526")
			m.set_voxel(Vector3i(xx, yy, 1), plank)
			if yy == 0 or yy == 15:
				m.set_voxel(Vector3i(xx, yy, 2), Color("6e4526"))  # 手すり
	return m

## 岩：灰色の塊で、上は白っぽい。並べると岩山になるように、マスいっぱいの形にする。
static func rock_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	var top_h: int = [22, 26, 30][v]
	m.size = Vector3i(16, 16, top_h + 4)
	for yy in 16:
		for xx in 16:
			# 4×4 の塊ごとに高さを少し変えて、ごつごつさせる
			var bump := ((xx / 4) * 7 + (yy / 4) * 13 + v * 5) % 4
			var hh: int = top_h + bump
			for z in hh:
				var c := Color("8d8f94")
				if z >= hh - 2:
					c = Color("e4e7ea")
				elif (z + xx * 3 + yy) % 9 == 0:
					c = Color("6f7177")
				m.set_voxel(Vector3i(xx, yy, z), c)
	return m

## 木：v=0,1 は丸い木、v=2 はとがった木。
static func tree_model(v: int) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(14, 14, 22)
	var trunk := Color("7a4a2a")
	for z in 6:
		for yy in range(5, 9):
			for xx in range(5, 9):
				m.set_voxel(Vector3i(xx, yy, z), trunk)
	var leaf := Color("3f9a3a") if v != 1 else Color("4aa843")
	if v == 2:
		for z in range(4, 22):
			var r := 6 - (z - 4) / 3
			for yy in range(7 - r, 7 + r):
				for xx in range(7 - r, 7 + r):
					m.set_voxel(Vector3i(xx, yy, z), leaf.lightened(0.12) if z % 3 == 0 else leaf)
	else:
		for z in range(5, 16):
			for yy in 14:
				for xx in 14:
					var top := z >= 14
					m.set_voxel(Vector3i(xx, yy, z), leaf.lightened(0.15) if top else leaf)
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
