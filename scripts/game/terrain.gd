class_name Terrain
extends RefCounted
## 文字の地図から高さマップを作り、地形を輪切りの絵で並べる。ステージ同士で共有する。
## 記号：数字＝高さ、# ＝壁、_ ＝奈落、C ＝チェックポイント、D ＝扉、G ＝ゴール（C・D・G は高さ0）。

const LEVEL_COLORS := [Color("5f8f4e"), Color("7a9a55"), Color("98a85c"), Color("b5b063")]
const WALL_COLOR := Color("8a8f99")

## 地図を map に書き込み、チェックポイント・ゴール・扉の場所を返す。見つからないものは入れない（doors は常に入る）。
static func parse(layout: Array, map: HeightMap) -> Dictionary:
	var info := {"doors": []}
	for y in layout.size():
		for x in layout[y].length():
			var cell := Vector2i(x, y)
			var ch: String = layout[y][x]
			match ch:
				"#":
					map.set_wall(cell, true)
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

## 地形を並べる。奈落には何も置かない（背景の暗い色が見える）。
## 墓石や扉のマスには、その下の地面を置く（墓石・扉の絵はステージ側で上に置く）。
static func build(map: HeightMap, camera: StackCamera, parent: Node2D) -> void:
	var models := {}
	for y in map.size.y:
		for x in map.size.x:
			var cell := Vector2i(x, y)
			if map.is_pit(cell):
				continue
			var is_plain_wall := map.is_wall(cell) and map.get_blocker(cell) == HeightMap.Blocker.NONE
			var key: String = "wall" if is_plain_wall else str(map.get_height(cell))
			if not models.has(key):
				models[key] = wall_model() if key == "wall" else ground_model(int(key))
			var s := StackSprite.new()
			s.camera = camera
			s.world_pos = HeightMap.cell_center(cell)
			s.set_model(models[key])
			parent.add_child(s)

static func ground_model(h: int) -> VoxelModel:
	var layers := maxi(1, h * StackSprite.LEVEL_PX)
	var top: Color = LEVEL_COLORS[clampi(h, 0, LEVEL_COLORS.size() - 1)]
	var m := VoxelModel.new()
	m.size = Vector3i(16, 16, layers)
	for z in layers:
		var c := top if z == layers - 1 else Color("6b5a45").lightened(0.03 * (z % 8))
		for yy in 16:
			for xx in 16:
				# 上面の縁を少し暗くしてマスの区切りを見せる
				var edge := xx == 0 or yy == 0 or xx == 15 or yy == 15
				m.set_voxel(Vector3i(xx, yy, z), c.darkened(0.12) if edge and z == layers - 1 else c)
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
