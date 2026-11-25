class_name BossModels
extends RefCounted
## ボスの形（2026-11-25 夜に、主人公と同じ細かさで作り直した）。ボクセル1つを本当の画面の1px（VOXEL_SCALE 0.5）で描く。
## 前は +y、上は +z。影は VoxelShade。一度作った形は使い回す（大きいので1つ作るのに少しかかる。field が先に作る）。
## variant：宝箱の王の "open"（口を開けた）・"decoy"（にせものの宝箱。背中の金のしっぽがない）、
## 岩窟のぬしの "curl"（丸まって転がる）、"boulder"（巨人の転がす大岩）。

const VOXEL_SCALE := 0.5

const EYE_GLOW := Color("ffcf4a")
const PUPIL := Color("1a1420")
const GOLD := Color("e8b83a")

static var _cache := {}

static func model(g: String, variant := "") -> VoxelModel:
	var key := g + "/" + variant
	if not _cache.has(key):
		_cache[key] = VoxelShade.apply(_build(g, variant))
	return _cache[key]

static func is_cached(g: String, variant := "") -> bool:
	return _cache.has(g + "/" + variant)

## 2つ並んだ目（幅2・高さ2）。
static func _eyes(m: VoxelModel, y: int, z: int, xs: Array, c: Color, pupil := PUPIL) -> void:
	for x in xs:
		VoxelDraw.fill(m, Vector3i(x, y, z), Vector3i(x + 1, y, z + 1), c)
		m.set_voxel(Vector3i(x + 1, y, z), pupil)

## 岩のでこぼこ（色をまだらに）
static func _speckle(m: VoxelModel, c: Color, n := 5) -> void:
	for p in m.voxels().keys():
		if m.voxels()[p] == c:
			var h := VoxelDraw.hash3(p.x, p.y, p.z, n)
			if h == 0:
				m.set_voxel(p, c.darkened(0.12))
			elif h == 1:
				m.set_voxel(p, c.lightened(0.08))

static func _build(g: String, variant: String) -> VoxelModel:
	var m := VoxelModel.new()
	if variant == "boulder":
		m.size = Vector3i(24, 24, 24)
		var rock := Color("8d8f94")
		VoxelDraw.ellipsoid(m, Vector3(11.5, 11.5, 11.5), Vector3(11.5, 11.5, 11.5), rock)
		_speckle(m, rock)
		for i in 6:
			var a := i * TAU / 6.0
			VoxelDraw.ellipsoid(m, Vector3(11.5 + cos(a) * 8.0, 11.5 + sin(a) * 8.0, 6 + i % 3 * 5), Vector3(2, 2, 2), rock.darkened(0.2))
		return m
	match g:
		"岩転がしの巨人":
			_giant(m, Color("8d8f94"), Color("5f8a4a"), false)
		"岩窟のぬし":
			if variant == "curl":
				m.size = Vector3i(36, 36, 34)
				var rock := Color("5f6168")
				VoxelDraw.ellipsoid(m, Vector3(17.5, 17.5, 16.5), Vector3(17.0, 17.0, 16.0), rock)
				_speckle(m, rock)
				for i in 8:
					var a := i * TAU / 8.0
					VoxelDraw.ellipsoid(m, Vector3(17.5 + cos(a) * 12.0, 17.5 + sin(a) * 12.0, 24), Vector3(2.5, 2.5, 4.0), Color("b06aff"))
				return m
			_giant(m, Color("5f6168"), Color("b06aff"), true)
		"草むらの大蛇":
			m.size = Vector3i(30, 54, 24)
			var scale := Color("4f8a3a")
			var belly := Color("c8d890")
			for i in 10:
				var cx := 15.0 + sin(i * 0.9) * 7.0
				var cy := 4.0 + i * 4.2
				var r := 4.0 + minf(i, 9 - i) * 0.35
				VoxelDraw.ellipsoid(m, Vector3(cx, cy, r), Vector3(r, r, r), scale)
				VoxelDraw.ellipsoid(m, Vector3(cx, cy, r * 0.5), Vector3(r * 0.8, r * 0.8, r * 0.5), belly)
			for p in m.voxels().keys():
				if m.voxels()[p] == scale and (p.x + p.y * 2 + p.z) % 5 == 0:
					m.set_voxel(p, scale.darkened(0.25))  # うろこの模様
			# 頭をもたげる
			VoxelDraw.rod(m, Vector3(15, 42, 6), Vector3(15, 46, 14), scale, 6)
			VoxelDraw.ellipsoid(m, Vector3(15.0, 48.0, 17.0), Vector3(7.0, 6.0, 4.5), scale.lightened(0.08))
			VoxelDraw.fill(m, Vector3i(10, 53, 14), Vector3i(20, 53, 15), Color("5a1010"))  # 口
			VoxelDraw.fill(m, Vector3i(12, 53, 12), Vector3i(12, 53, 13), Color("f0ece0"))  # きば
			VoxelDraw.fill(m, Vector3i(18, 53, 12), Vector3i(18, 53, 13), Color("f0ece0"))
			_eyes(m, 52, 18, [10, 18], Color("ffe14a"))
			VoxelDraw.fill(m, Vector3i(14, 53, 13), Vector3i(15, 53, 13), Color("e04a5a"))  # 舌
			m.set_voxel(Vector3i(14, 53, 12), Color("e04a5a"))
			m.set_voxel(Vector3i(15, 53, 11), Color("e04a5a"))
		"満ち引きする溶岩":
			m.size = Vector3i(40, 40, 30)
			var crust := Color("3a2420")
			VoxelDraw.ellipsoid(m, Vector3(19.5, 19.5, 11.0), Vector3(19.0, 19.0, 11.0), Color("c8401a"))
			VoxelDraw.ellipsoid(m, Vector3(19.5, 21.0, 18.0), Vector3(12.0, 11.0, 9.0), Color("ff7a1a"))
			for p in m.voxels().keys():
				var h := VoxelDraw.hash3(p.x / 4, p.y / 4, p.z / 5, 7)
				if h < 3 and p.z > 4:
					m.set_voxel(p, crust.lightened(h * 0.06))  # 冷えた岩のかさぶた
			VoxelDraw.ellipsoid(m, Vector3(19.5, 30.0, 18.0), Vector3(8.0, 3.0, 5.0), Color("ffd34d"))  # 顔の光
			_eyes(m, 33, 19, [13, 24], Color("fff6c0"), Color("ff4a1a"))
			VoxelDraw.fill(m, Vector3i(15, 33, 13), Vector3i(24, 33, 15), Color("2a0a08"))  # 口
			for x in range(16, 24, 2):
				m.set_voxel(Vector3i(x, 33, 15), Color("ffb03a"))
		"廃城の主":
			m.size = Vector3i(36, 30, 52)
			var steel := Color("6a6e80")
			var dark := Color("3a3648")
			var cape := Color("7a2a3a")
			VoxelDraw.fill(m, Vector3i(11, 11, 0), Vector3i(15, 17, 14), dark)  # 足
			VoxelDraw.fill(m, Vector3i(20, 11, 0), Vector3i(24, 17, 14), dark)
			VoxelDraw.fill(m, Vector3i(10, 12, 0), Vector3i(16, 19, 2), steel)  # 靴
			VoxelDraw.fill(m, Vector3i(19, 12, 0), Vector3i(25, 19, 2), steel)
			VoxelDraw.ellipsoid(m, Vector3(17.5, 14.5, 24.0), Vector3(10.0, 7.0, 11.0), steel)  # 胴
			VoxelDraw.fill(m, Vector3i(10, 21, 18), Vector3i(25, 21, 30), steel.lightened(0.12))  # 胸の板
			VoxelDraw.fill(m, Vector3i(16, 22, 20), Vector3i(19, 22, 28), Color("c8b070"))  # 紋章
			VoxelDraw.fill(m, Vector3i(7, 5, 6), Vector3i(28, 8, 34), cape)  # 背のマント
			for x in range(7, 29, 3):
				VoxelDraw.fill(m, Vector3i(x, 5, 4), Vector3i(x, 7, 5), cape.darkened(0.25))
			VoxelDraw.ellipsoid(m, Vector3(8.0, 14.5, 32.0), Vector3(5.0, 5.0, 4.0), steel.lightened(0.1))  # 肩当て
			VoxelDraw.ellipsoid(m, Vector3(27.0, 14.5, 32.0), Vector3(5.0, 5.0, 4.0), steel.lightened(0.1))
			VoxelDraw.ellipsoid(m, Vector3(17.5, 15.0, 41.0), Vector3(6.0, 6.0, 6.5), steel.lightened(0.05))  # かぶと
			VoxelDraw.fill(m, Vector3i(13, 21, 40), Vector3i(22, 21, 41), Color("1a1020"))  # 目のすき間
			m.set_voxel(Vector3i(15, 21, 40), Color("ff4a4a"))
			m.set_voxel(Vector3i(20, 21, 40), Color("ff4a4a"))
			VoxelDraw.rod(m, Vector3(17.5, 13, 47), Vector3(17.5, 6, 51), cape.lightened(0.2), 2)  # かぶとの飾り
			VoxelDraw.fill(m, Vector3i(29, 16, 14), Vector3i(31, 19, 28), steel)  # 腕
			VoxelDraw.rod(m, Vector3(30, 20, 12), Vector3(30, 27, 46), Color("d0d4dc"), 2)  # 大剣
			VoxelDraw.fill(m, Vector3i(27, 18, 15), Vector3i(33, 22, 16), Color("c8b070"))  # つば
			VoxelDraw.fill(m, Vector3i(4, 16, 14), Vector3i(6, 19, 28), steel)
		"溶岩洞のぬし":
			m.size = Vector3i(28, 50, 18)
			var skin := Color("9a3a2a")
			var glow := Color("ffb03a")
			VoxelDraw.ellipsoid(m, Vector3(13.5, 24.0, 7.0), Vector3(7.0, 12.0, 5.5), skin)
			VoxelDraw.ellipsoid(m, Vector3(13.5, 40.0, 8.0), Vector3(6.0, 6.0, 4.5), skin.lightened(0.08))  # 頭
			for y in [16, 30]:
				VoxelDraw.rod(m, Vector3(8, y, 4), Vector3(1, y + 3, 0), skin.darkened(0.2), 3)  # 足
				VoxelDraw.rod(m, Vector3(19, y, 4), Vector3(26, y + 3, 0), skin.darkened(0.2), 3)
			for y in range(14, 36, 4):
				VoxelDraw.fill(m, Vector3i(12, y, 12), Vector3i(15, y + 1, 13), glow)  # 背の光るうろこ
			VoxelDraw.rod(m, Vector3(13.5, 13, 5), Vector3(13.5, 0, 3), skin, 4)  # 尾
			for i in 5:
				VoxelDraw.ellipsoid(m, Vector3(13.5 + (i % 2) * 2 - 1, 2.0 + i, 5.0 + i * 2.0), Vector3(2, 2, 2), Color("ffd34d") if i % 2 == 0 else Color("ff6a1a"))
			_eyes(m, 45, 10, [9, 16], Color("fff6a0"), Color("ff3a10"))
			VoxelDraw.fill(m, Vector3i(10, 46, 6), Vector3i(17, 46, 7), Color("3a0a08"))
		"双子":
			m.size = Vector3i(26, 24, 42)
			var robe := Color("c9c3b6")
			VoxelDraw.cylinder(m, Vector2(12.5, 12.0), 9.0, 0, 4, robe.darkened(0.15))
			VoxelDraw.ellipsoid(m, Vector3(12.5, 12.0, 14.0), Vector3(9.0, 8.0, 11.0), robe)
			for z in range(2, 22, 4):
				VoxelDraw.fill(m, Vector3i(4, 19, z), Vector3i(21, 19, z), Color("8a6ab0"))  # 衣のふち
			VoxelDraw.ellipsoid(m, Vector3(12.5, 12.0, 30.0), Vector3(7.0, 7.0, 7.0), Color("e6e0d2"))  # 頭
			VoxelDraw.fill(m, Vector3i(7, 19, 27), Vector3i(18, 19, 34), Color("f4f0e8"))  # 仮面
			_eyes(m, 20, 31, [8, 15], Color("4a6aff"), Color("c0d0ff"))
			VoxelDraw.fill(m, Vector3i(11, 20, 28), Vector3i(14, 20, 28), Color("6a5a80"))
			for i in 5:  # 冠
				VoxelDraw.fill(m, Vector3i(7 + i * 3, 12, 36), Vector3i(7 + i * 3, 12, 39 + i % 2), GOLD)
			VoxelDraw.rod(m, Vector3(22, 16, 2), Vector3(22, 16, 30), Color("6a4a2a"), 2)  # 杖
			VoxelDraw.ellipsoid(m, Vector3(22.0, 16.0, 33.0), Vector3(2.5, 2.5, 2.5), Color("7ab0ff"))
		"らせん塔の番人":
			m.size = Vector3i(38, 34, 54)
			var stone := Color("b8b2a4")
			VoxelDraw.cylinder(m, Vector2(18.5, 16.5), 13.0, 0, 6, stone.darkened(0.2))
			VoxelDraw.ellipsoid(m, Vector3(18.5, 16.5, 22.0), Vector3(12.0, 11.0, 16.0), stone)
			for z in [10, 18, 26]:
				VoxelDraw.cylinder(m, Vector2(18.5, 16.5), 12.5 - absf(z - 20) * 0.2, z, z + 1, Color("8a7a5a"))  # 輪
			VoxelDraw.ellipsoid(m, Vector3(18.5, 16.5, 43.0), Vector3(8.0, 8.0, 7.0), stone.lightened(0.08))  # 頭
			VoxelDraw.fill(m, Vector3i(12, 24, 42), Vector3i(25, 24, 44), Color("2a2a30"))
			m.set_voxel(Vector3i(15, 24, 43), Color("7af0ff"))
			m.set_voxel(Vector3i(22, 24, 43), Color("7af0ff"))
			VoxelDraw.ellipsoid(m, Vector3(18.5, 4.0, 22.0), Vector3(6.0, 3.0, 6.0), Color("ff5a3a"))  # 背中の弱点（光る核）
			VoxelDraw.ellipsoid(m, Vector3(18.5, 3.0, 22.0), Vector3(3.0, 2.0, 3.0), Color("ffd0a0"))
			VoxelDraw.fill(m, Vector3i(2, 14, 18), Vector3i(6, 19, 34), stone.darkened(0.1))  # 腕
			VoxelDraw.fill(m, Vector3i(31, 14, 18), Vector3i(35, 19, 34), stone.darkened(0.1))
			VoxelDraw.ellipsoid(m, Vector3(4.0, 17.0, 16.0), Vector3(3.5, 3.5, 3.5), stone)
			VoxelDraw.ellipsoid(m, Vector3(33.0, 17.0, 16.0), Vector3(3.5, 3.5, 3.5), stone)
			_speckle(m, stone, 7)
		"ブライト":
			m.size = Vector3i(42, 38, 58)
			var robe := Color("e8e2f0")
			VoxelDraw.cylinder(m, Vector2(20.5, 18.5), 14.0, 0, 3, robe.darkened(0.15))
			VoxelDraw.ellipsoid(m, Vector3(20.5, 18.5, 22.0), Vector3(14.0, 12.0, 21.0), robe)
			for z in range(4, 40, 6):
				VoxelDraw.fill(m, Vector3i(8, 30, z), Vector3i(33, 30, z), Color("c8b8e8"))
			VoxelDraw.ellipsoid(m, Vector3(20.5, 18.5, 46.0), Vector3(8.0, 8.0, 7.5), Color("f4f0ff"))  # 頭
			VoxelDraw.fill(m, Vector3i(15, 26, 45), Vector3i(26, 26, 46), Color("6a60a0"))  # 目を閉じた顔
			for i in 7:  # 光の冠
				var a := i * TAU / 7.0
				VoxelDraw.rod(m, Vector3(20.5 + cos(a) * 6.0, 18.5 + sin(a) * 6.0, 52), Vector3(20.5 + cos(a) * 9.0, 18.5 + sin(a) * 9.0, 57), Color("ffe866"), 1)
			VoxelDraw.ellipsoid(m, Vector3(20.5, 3.0, 34.0), Vector3(7.0, 3.0, 6.0), Color("ffe866"))  # 背中の目
			VoxelDraw.ellipsoid(m, Vector3(20.5, 1.5, 34.0), Vector3(3.0, 1.5, 3.0), Color("2a2a60"))
			for side in [-1, 1]:  # 翼のような布
				for i in 8:
					VoxelDraw.fill(m, Vector3i(20 + side * (14 + i), 10, 20 + i), Vector3i(20 + side * (14 + i), 24, 30 + i), robe.lightened(0.05) if i % 2 == 0 else Color("d8d0f0"))
		"女王蜂":
			m.size = Vector3i(44, 40, 30)
			var yellow := Color("f0c030")
			var black := Color("2a2430")
			VoxelDraw.ellipsoid(m, Vector3(21.5, 12.0, 12.0), Vector3(9.0, 11.0, 8.0), yellow)  # 腹
			for p in m.voxels().keys():
				if int(p.y) % 6 < 3:
					m.set_voxel(p, black)
			VoxelDraw.fill(m, Vector3i(21, 0, 10), Vector3i(22, 1, 11), Color("e8e0d0"))  # 針
			VoxelDraw.ellipsoid(m, Vector3(21.5, 25.0, 14.0), Vector3(6.0, 5.0, 6.0), Color("a06a20"))  # 胸
			VoxelDraw.ellipsoid(m, Vector3(21.5, 33.0, 16.0), Vector3(6.0, 5.0, 5.5), black.lightened(0.1))  # 頭
			_eyes(m, 37, 17, [16, 26], Color("ff4a5a"), Color("ff9aa0"))
			for i in 5:  # 冠
				VoxelDraw.fill(m, Vector3i(17 + i * 2, 33, 21), Vector3i(17 + i * 2, 33, 23 + i % 2), GOLD)
			VoxelDraw.rod(m, Vector3(19, 37, 19), Vector3(16, 39, 25), black, 1)  # 触角
			VoxelDraw.rod(m, Vector3(24, 37, 19), Vector3(27, 39, 25), black, 1)
			for side in [-1, 1]:  # 羽（すきとおる）
				VoxelDraw.ellipsoid(m, Vector3(21.5 + side * 13.0, 22.0, 22.0), Vector3(9.0, 7.0, 2.0), Color("d8ecff"))
				VoxelDraw.ellipsoid(m, Vector3(21.5 + side * 11.0, 15.0, 21.0), Vector3(6.0, 5.0, 1.5), Color("c8e0f8"))
			for y in [22, 26, 30]:  # 足
				VoxelDraw.rod(m, Vector3(17, y, 9), Vector3(13, y + 2, 2), black, 1)
				VoxelDraw.rod(m, Vector3(26, y, 9), Vector3(30, y + 2, 2), black, 1)
		"宝箱の王":
			_chest_king(m, variant)
		_:
			m = VoxelModel.box(Vector3i(32, 32, 32), Color("9a968e"))
	return m

## 巨人と岩窟のぬし：岩の大きな体、太い腕、光る目。背中にこけ（巨人）か光る石（ぬし）。
static func _giant(m: VoxelModel, rock: Color, accent: Color, crystals: bool) -> void:
	m.size = Vector3i(46, 38, 54)
	VoxelDraw.fill(m, Vector3i(12, 14, 0), Vector3i(19, 22, 12), rock.darkened(0.2))  # 足
	VoxelDraw.fill(m, Vector3i(26, 14, 0), Vector3i(33, 22, 12), rock.darkened(0.2))
	VoxelDraw.ellipsoid(m, Vector3(22.5, 18.0, 26.0), Vector3(17.0, 13.0, 16.0), rock)  # 胴
	VoxelDraw.ellipsoid(m, Vector3(22.5, 22.0, 44.0), Vector3(9.0, 8.0, 8.0), rock.lightened(0.08))  # 頭
	VoxelDraw.fill(m, Vector3i(14, 29, 46), Vector3i(31, 30, 47), rock.darkened(0.3))  # まゆ
	_eyes(m, 30, 43, [17, 26], EYE_GLOW, Color("ff8a2a"))
	VoxelDraw.fill(m, Vector3i(19, 30, 38), Vector3i(26, 30, 39), rock.darkened(0.4))  # 口
	for side in [-1, 1]:  # 腕とこぶし
		var x: float = 22.5 + side * 19.0
		VoxelDraw.ellipsoid(m, Vector3(x, 20.0, 32.0), Vector3(5.0, 6.0, 7.0), rock.darkened(0.08))
		VoxelDraw.rod(m, Vector3(x, 21, 26), Vector3(x, 25, 12), rock.darkened(0.12), 6)
		VoxelDraw.ellipsoid(m, Vector3(x, 26.0, 9.0), Vector3(5.0, 5.0, 5.0), rock.darkened(0.05))
	_speckle(m, rock)
	if crystals:
		for i in 6:
			var x := 10 + i * 5
			var z := 30 + (i % 3) * 5
			VoxelDraw.rod(m, Vector3(x, 8, z), Vector3(x + (i % 2) * 2 - 1, 2, z + 7), accent, 2)
			m.set_voxel(Vector3i(x, 5, z + 4), accent.lightened(0.4))
	else:
		VoxelDraw.ellipsoid(m, Vector3(22.5, 14.0, 39.0), Vector3(14.0, 9.0, 3.0), accent)  # 肩と背のこけ
		for i in 8:
			m.set_voxel(Vector3i(12 + i * 3, 6 + i % 3, 37 + i % 2), accent.lightened(0.2))

## 宝箱の王：金の飾りの大きな宝箱に冠。open は口を開けて歯と舌。本物だけ、背中に金のしっぽ（カメラを回すと見える）。
static func _chest_king(m: VoxelModel, variant: String) -> void:
	m.size = Vector3i(30, 26, 34)
	var wood := Color("8a5a2a")
	var band := GOLD
	var lid_z := 14
	VoxelDraw.fill(m, Vector3i(2, 2, 0), Vector3i(27, 23, lid_z), wood)
	if variant == "open":
		VoxelDraw.fill(m, Vector3i(4, 4, lid_z - 3), Vector3i(25, 22, lid_z), Color("3a0a10"))  # 口の中
		VoxelDraw.fill(m, Vector3i(8, 10, lid_z - 2), Vector3i(21, 20, lid_z - 1), Color("d04a5a"))  # 舌
		VoxelDraw.fill(m, Vector3i(2, 0, lid_z + 1), Vector3i(27, 6, lid_z + 18), wood.lightened(0.05))  # 開いたふた（後ろへ立つ）
		VoxelDraw.fill(m, Vector3i(2, 0, lid_z + 1), Vector3i(27, 1, lid_z + 18), band)
		for x in range(4, 26, 3):  # 歯
			VoxelDraw.fill(m, Vector3i(x, 23, lid_z - 2), Vector3i(x + 1, 23, lid_z), Color("f4f0e0"))
			VoxelDraw.fill(m, Vector3i(x + 1, 7, lid_z + 1), Vector3i(x + 2, 8, lid_z + 2), Color("f4f0e0"))
		_eyes(m, 7, lid_z + 12, [8, 19], Color("ffe14a"), Color("ff3a1a"))
	else:
		VoxelDraw.fill(m, Vector3i(2, 2, lid_z + 1), Vector3i(27, 23, lid_z + 6), wood.lightened(0.08))  # ふた
		VoxelDraw.ellipsoid(m, Vector3(14.5, 12.5, lid_z + 6.0), Vector3(12.5, 10.5, 3.0), wood.lightened(0.08))
		VoxelDraw.fill(m, Vector3i(13, 24, lid_z - 3), Vector3i(16, 24, lid_z + 2), band)  # 錠
		m.set_voxel(Vector3i(14, 25, lid_z - 1), Color("2a2020"))
	for x in [2, 14, 27]:  # 金の帯
		VoxelDraw.fill(m, Vector3i(x, 2, 0), Vector3i(x, 23, lid_z), band)
	VoxelDraw.fill(m, Vector3i(2, 2, 0), Vector3i(27, 23, 1), band.darkened(0.2))
	VoxelDraw.fill(m, Vector3i(2, 23, lid_z), Vector3i(27, 23, lid_z), band)
	if variant != "open":
		for i in 5:  # 冠
			VoxelDraw.fill(m, Vector3i(9 + i * 3, 12, lid_z + 8), Vector3i(10 + i * 3, 13, lid_z + 11 + i % 2 * 2), GOLD)
		VoxelDraw.fill(m, Vector3i(9, 11, lid_z + 7), Vector3i(22, 14, lid_z + 8), GOLD.darkened(0.15))
		m.set_voxel(Vector3i(15, 14, lid_z + 10), Color("e0304a"))
	if variant != "decoy":
		VoxelDraw.rod(m, Vector3(14.5, 2, 4), Vector3(14.5, 0, 9), GOLD, 2)  # 本物だけの金のしっぽ（背中）
		VoxelDraw.ellipsoid(m, Vector3(14.5, 0.0, 10.0), Vector3(2.0, 1.0, 2.0), GOLD.lightened(0.3))
