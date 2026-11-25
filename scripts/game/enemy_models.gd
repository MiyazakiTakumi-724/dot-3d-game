class_name EnemyModels
extends RefCounted
## 敵の形（2026-11-25 夜に主人公と同じ細かさで作り直した）。ボクセル1つを本当の画面の1px（VOXEL_SCALE 0.5）で描く。
## 前は +y、上は +z。影は VoxelShade（まわりの空き方から面の向きを出して4段階）。一度作った形は使い回す。

const VOXEL_SCALE := 0.5

const EYE := Color("fff8e0")
const PUPIL := Color("1a1420")
const SKIN_GOBLIN := Color("6aa84f")
const LEATHER := Color("7a5634")
const IRON := Color("8a909c")
const DARK_IRON := Color("4a4f5a")
const WOOD := Color("9a6a3a")

static var _cache := {}

## 種類の形。擬態箱は awake で、宝箱のふりの形と、口を開けた形が替わる。
static func model(k: EnemyKind.Kind, awake := true) -> VoxelModel:
	var key := "%d/%s" % [k, awake]
	if not _cache.has(key):
		_cache[key] = VoxelShade.apply(_build(k, awake))
	return _cache[key]

static func _eyes(m: VoxelModel, y: int, z: int, xs: Array, white := EYE, pupil := PUPIL) -> void:
	for x in xs:
		m.set_voxel(Vector3i(x, y, z), white)
		m.set_voxel(Vector3i(x + 1, y, z), white)
		m.set_voxel(Vector3i(x, y, z + 1), white)
		m.set_voxel(Vector3i(x + 1, y, z + 1), pupil)

static func _build(k: EnemyKind.Kind, awake: bool) -> VoxelModel:
	var m := VoxelModel.new()
	match k:
		EnemyKind.Kind.WEAK:
			# スライム：赤いぷるぷるの塊。上に光、前に目と口
			m.size = Vector3i(18, 18, 14)
			var c := Color("d6453a")
			VoxelDraw.ellipsoid(m, Vector3(8.5, 8.5, 4.5), Vector3(8.5, 8.5, 5.0), c)
			VoxelDraw.ellipsoid(m, Vector3(8.5, 8.5, 8.0), Vector3(6.0, 6.0, 4.5), c)
			VoxelDraw.ellipsoid(m, Vector3(6.0, 7.0, 11.0), Vector3(2.0, 2.0, 1.2), c.lightened(0.45))
			_eyes(m, 16, 7, [5, 11])
			VoxelDraw.fill(m, Vector3i(7, 17, 4), Vector3i(10, 17, 4), Color("5a1010"))
		EnemyKind.Kind.MELEE:
			# ゴブリン：緑の肌、とがった耳、革の服、こん棒
			m.size = Vector3i(22, 20, 22)
			VoxelDraw.fill(m, Vector3i(7, 8, 0), Vector3i(9, 11, 5), LEATHER.darkened(0.3))
			VoxelDraw.fill(m, Vector3i(12, 8, 0), Vector3i(14, 11, 5), LEATHER.darkened(0.3))
			VoxelDraw.ellipsoid(m, Vector3(10.5, 9.5, 9.0), Vector3(5.0, 4.0, 4.5), LEATHER)
			VoxelDraw.ellipsoid(m, Vector3(10.5, 10.0, 16.0), Vector3(4.5, 4.5, 4.0), SKIN_GOBLIN)
			VoxelDraw.fill(m, Vector3i(3, 9, 16), Vector3i(5, 10, 18), SKIN_GOBLIN)  # 耳
			VoxelDraw.fill(m, Vector3i(16, 9, 16), Vector3i(18, 10, 18), SKIN_GOBLIN)
			_eyes(m, 14, 16, [8, 12], Color("ffe14a"))
			m.set_voxel(Vector3i(10, 15, 14), SKIN_GOBLIN.darkened(0.3))
			VoxelDraw.fill(m, Vector3i(15, 9, 7), Vector3i(17, 11, 11), SKIN_GOBLIN)  # 腕
			VoxelDraw.rod(m, Vector3(17, 11, 8), Vector3(19, 18, 14), WOOD, 2)  # こん棒
			VoxelDraw.ellipsoid(m, Vector3(19.5, 18.5, 14.5), Vector3(2.0, 2.0, 2.0), WOOD.darkened(0.2))
		EnemyKind.Kind.SHOOTER:
			# 射手：フードの盗賊。弓を前に構える
			m.size = Vector3i(22, 20, 24)
			var cloak := Color("b9770e")
			VoxelDraw.fill(m, Vector3i(8, 8, 0), Vector3i(13, 12, 5), Color("4a3a2a"))
			VoxelDraw.ellipsoid(m, Vector3(10.5, 10.0, 10.0), Vector3(5.5, 4.5, 6.0), cloak)
			VoxelDraw.ellipsoid(m, Vector3(10.5, 10.0, 18.0), Vector3(4.5, 4.5, 4.5), cloak.darkened(0.15))
			VoxelDraw.fill(m, Vector3i(8, 14, 16), Vector3i(13, 14, 19), Color("2a2020"))  # フードの中
			_eyes(m, 14, 17, [8, 12], Color("ffcf6a"))
			for i in 13:
				var t := (i - 6) / 6.0
				m.set_voxel(Vector3i(4 + i, 17 + int(round(2.0 * (1.0 - t * t))), 11), WOOD.darkened(0.2))
			VoxelDraw.fill(m, Vector3i(4, 17, 11), Vector3i(16, 17, 11), Color("e8e0d0"))
		EnemyKind.Kind.SHIELD:
			# 盾持ち：鉄の鎧とかぶと、前に大きな木の盾
			m.size = Vector3i(22, 20, 24)
			VoxelDraw.fill(m, Vector3i(7, 6, 0), Vector3i(9, 9, 6), DARK_IRON)
			VoxelDraw.fill(m, Vector3i(12, 6, 0), Vector3i(14, 9, 6), DARK_IRON)
			VoxelDraw.ellipsoid(m, Vector3(10.5, 8.0, 11.0), Vector3(6.0, 4.5, 5.5), IRON)
			VoxelDraw.ellipsoid(m, Vector3(10.5, 8.0, 18.5), Vector3(4.5, 4.5, 4.0), IRON.lightened(0.1))
			VoxelDraw.fill(m, Vector3i(7, 12, 18), Vector3i(14, 12, 18), Color("1a1a22"))  # かぶとのすき間
			VoxelDraw.fill(m, Vector3i(10, 4, 22), Vector3i(11, 9, 23), Color("a02a3a"))  # 飾り
			VoxelDraw.fill(m, Vector3i(2, 14, 2), Vector3i(19, 16, 17), Color("a1784a"))  # 盾
			VoxelDraw.fill(m, Vector3i(2, 16, 2), Vector3i(19, 16, 3), IRON)
			VoxelDraw.fill(m, Vector3i(2, 16, 16), Vector3i(19, 16, 17), IRON)
			VoxelDraw.fill(m, Vector3i(9, 17, 8), Vector3i(12, 17, 11), Color("d9c27a"))
		EnemyKind.Kind.SHADOW:
			# 影：黒い煙のような人の形と赤い目（当たったときとためるときだけ見える）
			m.size = Vector3i(18, 18, 22)
			var dark := Color("1d1b26")
			VoxelDraw.ellipsoid(m, Vector3(8.5, 8.5, 6.0), Vector3(6.5, 6.0, 6.0), dark)
			VoxelDraw.ellipsoid(m, Vector3(8.5, 8.5, 14.0), Vector3(4.5, 4.5, 5.0), dark.lightened(0.08))
			for i in 10:
				var x := 2 + VoxelDraw.hash3(i, 3, 1, 14)
				var y := 2 + VoxelDraw.hash3(i, 7, 2, 14)
				m.set_voxel(Vector3i(x, y, 1 + i % 3), dark.lightened(0.15))
			_eyes(m, 12, 15, [6, 10], Color("ff3a3a"), Color("ff9a6a"))
		EnemyKind.Kind.FLYER:
			# コウモリ：小さな体に大きな翼、赤い目
			m.size = Vector3i(30, 12, 12)
			var body := Color("4a3b5c")
			VoxelDraw.ellipsoid(m, Vector3(14.5, 6.0, 6.0), Vector3(4.0, 4.0, 4.5), body)
			VoxelDraw.fill(m, Vector3i(12, 7, 10), Vector3i(12, 8, 11), body)  # 耳
			VoxelDraw.fill(m, Vector3i(17, 7, 10), Vector3i(17, 8, 11), body)
			for x in 11:
				var drop := int(abs(sin(x * 0.7)) * 2.0)
				for y in range(3, 9):
					m.set_voxel(Vector3i(x, y, 6 - drop + (1 if x < 3 else 0)), Color("3a2d4a"))
					m.set_voxel(Vector3i(29 - x, y, 6 - drop + (1 if x < 3 else 0)), Color("3a2d4a"))
			for x in [2, 6, 23, 27]:
				VoxelDraw.fill(m, Vector3i(x, 3, 5), Vector3i(x, 8, 7), Color("2a2036"))  # 翼の骨
			m.set_voxel(Vector3i(13, 10, 7), Color("ff5050"))
			m.set_voxel(Vector3i(16, 10, 7), Color("ff5050"))
		EnemyKind.Kind.CHARGER:
			# イノシシ：長い体、白いきば、鼻、短い足
			m.size = Vector3i(18, 28, 16)
			var fur := Color("7a5634")
			for x in [4, 12]:
				for y in [6, 19]:
					VoxelDraw.fill(m, Vector3i(x, y, 0), Vector3i(x + 1, y + 2, 3), fur.darkened(0.35))
			VoxelDraw.ellipsoid(m, Vector3(8.5, 13.0, 8.0), Vector3(7.0, 11.0, 5.5), fur)
			VoxelDraw.ellipsoid(m, Vector3(8.5, 23.0, 8.5), Vector3(5.0, 4.0, 4.5), fur.darkened(0.1))
			for y in range(4, 22, 3):
				VoxelDraw.fill(m, Vector3i(8, y, 13), Vector3i(9, y + 1, 14), fur.darkened(0.4))  # たてがみ
			VoxelDraw.fill(m, Vector3i(6, 27, 6), Vector3i(11, 27, 9), Color("c09080"))  # 鼻
			m.set_voxel(Vector3i(7, 27, 8), Color("4a2a20"))
			m.set_voxel(Vector3i(10, 27, 8), Color("4a2a20"))
			for x in [4, 13]:
				VoxelDraw.fill(m, Vector3i(x, 25, 5), Vector3i(x, 27, 6), Color("eee8d5"))  # きば
				m.set_voxel(Vector3i(x, 27, 7), Color("eee8d5"))
			_eyes(m, 25, 10, [5, 11], Color("ffd06a"))
		EnemyKind.Kind.BOMBER:
			# 火の玉：燃える玉に炎のとげ、怒った顔
			m.size = Vector3i(18, 18, 20)
			VoxelDraw.ellipsoid(m, Vector3(8.5, 8.5, 8.0), Vector3(7.0, 7.0, 7.0), Color("ff7a1a"))
			VoxelDraw.ellipsoid(m, Vector3(8.5, 9.5, 8.5), Vector3(4.5, 4.5, 4.5), Color("ffb03a"))
			for i in 7:
				var a := i * TAU / 7.0
				var x := int(round(8.5 + cos(a) * 5.0))
				var y := int(round(8.5 + sin(a) * 5.0))
				VoxelDraw.fill(m, Vector3i(x, y, 14), Vector3i(x, y, 16 + i % 3), Color("ffd34d"))
			VoxelDraw.fill(m, Vector3i(5, 16, 9), Vector3i(6, 16, 10), Color("3a1008"))
			VoxelDraw.fill(m, Vector3i(11, 16, 9), Vector3i(12, 16, 10), Color("3a1008"))
			VoxelDraw.fill(m, Vector3i(6, 16, 5), Vector3i(11, 16, 6), Color("5a1a08"))
		EnemyKind.Kind.GHOST:
			# 亡霊：白い布のような体、すそは ぎざぎざ、黒い目
			m.size = Vector3i(18, 18, 24)
			var cloth := Color("c8cfe8")
			VoxelDraw.ellipsoid(m, Vector3(8.5, 8.5, 15.0), Vector3(6.5, 6.5, 7.0), cloth)
			VoxelDraw.fill(m, Vector3i(2, 2, 3), Vector3i(15, 15, 14), cloth)
			for x in range(2, 16):
				for y in range(2, 16):
					if (x + y) % 3 == 0:
						for z in range(3, 6):
							m.voxels().erase(Vector3i(x, y, z))
			for x in range(3, 15):
				for y in range(3, 15):
					if not (x == 3 or x == 14 or y == 3 or y == 14):
						for z in range(3, 13):
							m.voxels().erase(Vector3i(x, y, z))
			VoxelDraw.fill(m, Vector3i(5, 15, 15), Vector3i(7, 15, 18), Color("2a2a40"))
			VoxelDraw.fill(m, Vector3i(10, 15, 15), Vector3i(12, 15, 18), Color("2a2a40"))
			VoxelDraw.fill(m, Vector3i(7, 15, 11), Vector3i(10, 15, 12), Color("4a4a60"))
		EnemyKind.Kind.SPEAR:
			# 槍兵：青い服とかぶと、前へ長い槍
			m.size = Vector3i(20, 32, 24)
			var cloth := Color("3a5a8a")
			VoxelDraw.fill(m, Vector3i(6, 6, 0), Vector3i(8, 9, 6), DARK_IRON)
			VoxelDraw.fill(m, Vector3i(11, 6, 0), Vector3i(13, 9, 6), DARK_IRON)
			VoxelDraw.ellipsoid(m, Vector3(9.5, 8.0, 11.0), Vector3(5.5, 4.0, 5.5), cloth)
			VoxelDraw.ellipsoid(m, Vector3(9.5, 8.0, 18.0), Vector3(4.0, 4.0, 4.0), Color("e0b090"))
			VoxelDraw.cylinder(m, Vector2(9.5, 8.0), 4.5, 20, 22, IRON)
			_eyes(m, 11, 18, [7, 11])
			VoxelDraw.rod(m, Vector3(15, 2, 11), Vector3(15, 27, 11), WOOD, 1)
			VoxelDraw.fill(m, Vector3i(14, 27, 10), Vector3i(16, 31, 12), Color("d8dce8"))
			m.set_voxel(Vector3i(15, 31, 13), Color("d8dce8"))
		EnemyKind.Kind.LOBBER:
			# 投石兵：大柄で毛皮をまとい、頭の上に石を持つ
			m.size = Vector3i(22, 18, 28)
			var skin := Color("b08060")
			VoxelDraw.fill(m, Vector3i(6, 6, 0), Vector3i(9, 10, 5), skin.darkened(0.3))
			VoxelDraw.fill(m, Vector3i(12, 6, 0), Vector3i(15, 10, 5), skin.darkened(0.3))
			VoxelDraw.ellipsoid(m, Vector3(10.5, 8.5, 10.0), Vector3(7.0, 5.0, 6.0), Color("8a6a4a"))
			VoxelDraw.ellipsoid(m, Vector3(10.5, 9.0, 17.0), Vector3(4.0, 4.0, 3.5), skin)
			_eyes(m, 12, 17, [8, 12])
			VoxelDraw.fill(m, Vector3i(3, 8, 12), Vector3i(4, 10, 22), skin)  # 両腕を上へ
			VoxelDraw.fill(m, Vector3i(17, 8, 12), Vector3i(18, 10, 22), skin)
			VoxelDraw.ellipsoid(m, Vector3(10.5, 9.0, 24.0), Vector3(6.0, 5.0, 3.5), Color("8d8f94"))
		EnemyKind.Kind.MAGE:
			# 魔術師：紫の長い衣、とんがり帽子、玉のついた杖
			m.size = Vector3i(22, 18, 32)
			var robe := Color("5a3a8a")
			VoxelDraw.cylinder(m, Vector2(10.5, 9.0), 6.0, 0, 3, robe.darkened(0.2))
			VoxelDraw.ellipsoid(m, Vector3(10.5, 9.0, 10.0), Vector3(5.5, 4.5, 7.5), robe)
			VoxelDraw.ellipsoid(m, Vector3(10.5, 9.0, 19.0), Vector3(3.5, 3.5, 3.5), Color("c8b0a0"))
			_eyes(m, 12, 19, [8, 11], Color("c0f0ff"))
			for z in 10:
				var r := 5.5 - z * 0.55
				VoxelDraw.cylinder(m, Vector2(10.5, 9.0), r, 22 + z, 22 + z, robe.lightened(0.05))
			VoxelDraw.rod(m, Vector3(17, 11, 0), Vector3(17, 11, 22), WOOD, 1)
			VoxelDraw.ellipsoid(m, Vector3(17.0, 11.0, 24.0), Vector3(2.0, 2.0, 2.0), Color("9ad0ff"))
		EnemyKind.Kind.BEETLE:
			# 甲虫：かたい光る殻、角、6本の足
			m.size = Vector3i(20, 24, 14)
			var shell := Color("2a5a6a")
			for x in [2, 17]:
				for y in [6, 11, 16]:
					VoxelDraw.fill(m, Vector3i(x, y, 0), Vector3i(x, y + 1, 3), Color("1a2a30"))
			VoxelDraw.ellipsoid(m, Vector3(9.5, 11.0, 5.0), Vector3(8.0, 9.5, 6.0), shell)
			VoxelDraw.fill(m, Vector3i(9, 2, 6), Vector3i(10, 19, 10), shell.darkened(0.35))  # 殻の合わせ目
			VoxelDraw.ellipsoid(m, Vector3(7.0, 9.0, 9.0), Vector3(2.0, 3.0, 1.0), shell.lightened(0.5))
			VoxelDraw.ellipsoid(m, Vector3(9.5, 20.0, 4.0), Vector3(4.0, 3.0, 3.0), Color("1a2a30"))
			VoxelDraw.rod(m, Vector3(9.5, 22, 5), Vector3(9.5, 23, 11), Color("3a3a3a"), 1)  # 角
			_eyes(m, 22, 4, [7, 11], Color("ffe080"))
		EnemyKind.Kind.WASP:
			# 蜂：黄色と黒のしま、すきとおる羽、針
			m.size = Vector3i(18, 14, 10)
			for y in range(1, 11):
				var r := 3.0 - absf(y - 5.0) * 0.35
				var c := Color("f0c030") if (y / 2) % 2 == 0 else Color("2a2020")
				VoxelDraw.ellipsoid(m, Vector3(8.5, y, 4.5), Vector3(r, 0.6, r), c)
			VoxelDraw.ellipsoid(m, Vector3(8.5, 11.5, 5.0), Vector3(2.5, 2.0, 2.5), Color("2a2020"))
			m.set_voxel(Vector3i(7, 13, 6), Color("ff5050"))
			m.set_voxel(Vector3i(10, 13, 6), Color("ff5050"))
			VoxelDraw.fill(m, Vector3i(8, 0, 4), Vector3i(9, 0, 4), Color("e0e0e0"))  # 針
			for x in range(1, 7):
				VoxelDraw.fill(m, Vector3i(x, 6, 8), Vector3i(x, 9, 8), Color(0.85, 0.92, 1.0))
				VoxelDraw.fill(m, Vector3i(17 - x, 6, 8), Vector3i(17 - x, 9, 8), Color(0.85, 0.92, 1.0))
		EnemyKind.Kind.MIMIC:
			m = Props.chest().copy() if not awake else _mimic_open()
			return m
		_:
			m = VoxelModel.box(Vector3i(16, 16, 16), Color("c0392b"))
	return m

## 口を開けた擬態箱：ふたが上がり、歯と舌が見える。
static func _mimic_open() -> VoxelModel:
	var m := VoxelModel.new()
	m.size = Vector3i(22, 18, 22)
	var wood := Color("9a6a3a")
	VoxelDraw.fill(m, Vector3i(1, 1, 0), Vector3i(20, 14, 8), wood)
	VoxelDraw.fill(m, Vector3i(3, 3, 6), Vector3i(18, 12, 8), Color("5a1020"))  # 口の中
	for x in range(2, 20, 3):
		m.set_voxel(Vector3i(x, 14, 9), Color("f0ecd8"))  # 下の歯
	VoxelDraw.fill(m, Vector3i(8, 6, 8), Vector3i(13, 16, 8), Color("e05a7a"))  # 舌
	# 上がったふた（後ろへ傾く）
	for z in range(10, 21):
		var y0 := 1 + (z - 10) / 3
		VoxelDraw.fill(m, Vector3i(1, y0, z), Vector3i(20, y0 + 4, z), wood.lightened(0.05))
	for x in range(2, 20, 3):
		m.set_voxel(Vector3i(x, 6, 11), Color("f0ecd8"))  # 上の歯
	_eyes(m, 6, 17, [6, 13], Color("ffe14a"), Color("a01010"))
	for x in [4, 5, 16, 17]:
		VoxelDraw.fill(m, Vector3i(x, 1, 0), Vector3i(x, 14, 8), Color("6a6f7a"))
	return m
