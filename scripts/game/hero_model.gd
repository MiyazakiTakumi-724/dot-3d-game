class_name HeroModel
extends RefCounted
## 主人公の姿（ボクセル）。頭の大きいちびキャラで、手に持つ物と防具が姿で分かる。
## ほかの物の2倍の細かさで作り、ボクセル1つを本当の画面の1pxで描く（VOXEL_SCALE）。ゲームの座標では 14×14×19 の大きさ。
## 前は +y、上は +z。体の真ん中が模型の真ん中（SIZE の半分）に来る。左右の x は 27 − x で写す。
## build(手に持つ品物の id, 防具の id) で作る。持つ物：剣・弓・杖は品物の id、回復は "heal"、何も持たない（鉄球）は ""。

const SIZE := Vector3i(28, 28, 38)
const VOXEL_SCALE := 0.5  ## = 1 / StackCamera.PIXEL_SCALE
## 杖の先の玉の、手前の横の1つ（杖を持っているときだけある。玉の色そのまま）
const STAFF_TIP := Vector3i(20, 16, 33)

const SKIN := Color("f7d3b0")
const CHEEK := Color("f29a9a")
const MOUTH := Color("c4685c")
const EYE := Color("2b2140")
const IRIS := Color("4a74e8")
const EYE_SHINE := Color("ffffff")
const HAIR := Color("7a3f24")
const TUNIC := Color("3567d6")
const TRIM := Color("f2c14e")
const PANTS := Color("3b3456")
const BOOTS := Color("6a3f2a")
const SOLE := Color("3a2418")
const BELT := Color("7b4a2b")
const GOLD := Color("f2c14e")
const SCARF := Color("e0413f")
const ARMOR_COLOR := Color("aab6c6")
const STEEL := Color("dfe7f0")
const WOOD := Color("a26b3c")
const STRING := Color("f1e6c8")
const NONE_ORB := Color("c8b6ff")
const FIRE_ORB := Color("ff7a2e")
const POTION := Color("ff6fa8")
const GLASS_SHINE := Color("ffe6f1")
## 影は青紫へ、光は暖かい白へ寄せる（色相をずらして、暗い所も濁らないように）
const SHADOW := Color("2b1d47")
const LIGHT := Color("fff3d6")

static var _cache := {}

## 姿を作る（同じ組み合わせは使い回す）。上を向いた面は明るく、ふちは光り、横と下は暗い。
static func build(held: String, armor: String) -> VoxelModel:
	var key := held + "|" + armor
	if not _cache.has(key):
		_cache[key] = _shade(raw(held, armor))
	return _cache[key]

## 影をつける前の姿。
static func raw(held: String, armor: String) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = SIZE
	_body(m)
	_head(m)
	if armor != "":
		_armor(m)
	match ItemCatalog.slot(held) if ItemCatalog.exists(held) else -1:
		Equipment.Slot.SWORD:
			_sword(m)
		Equipment.Slot.BOW:
			_bow(m)
		Equipment.Slot.STAFF:
			_staff(m, orb_color(held))
	if held == "heal":
		_potion(m)
	return m

## 杖の先の玉の色（杖の種類で決まる）。
static func orb_color(staff_id: String) -> Color:
	if staff_id.begins_with("staff_fire"):
		return FIRE_ORB
	return NONE_ORB

# ---------------------------------------------------------------- 形を作る道具

static func _fill(m: VoxelModel, from: Vector3i, to: Vector3i, c: Color) -> void:
	for z in range(from.z, to.z + 1):
		for y in range(from.y, to.y + 1):
			for x in range(from.x, to.x + 1):
				m.set_voxel(Vector3i(x, y, z), c)

## 左右の両方に置く（x を 27 − x に写したものも）。
static func _both(m: VoxelModel, from: Vector3i, to: Vector3i, c: Color) -> void:
	_fill(m, from, to, c)
	_fill(m, Vector3i(27 - to.x, from.y, from.z), Vector3i(27 - from.x, to.y, to.z), c)

static func _clear(m: VoxelModel, p: Vector3i) -> void:
	m.set_voxel(p, Color(0, 0, 0, 0))

## 箱の縦の4つの角を落とす（丸く見せる）。
static func _round_box(m: VoxelModel, from: Vector3i, to: Vector3i, c: Color) -> void:
	_fill(m, from, to, c)
	for z in range(from.z, to.z + 1):
		for p in [Vector2i(from.x, from.y), Vector2i(to.x, from.y), Vector2i(from.x, to.y), Vector2i(to.x, to.y)]:
			_clear(m, Vector3i(p.x, p.y, z))

static func _inside_ellipsoid(p: Vector3i, center: Vector3, radius: Vector3) -> bool:
	var d := (Vector3(p) - center) / radius
	return d.length_squared() <= 1.0

static func _ellipsoid(m: VoxelModel, center: Vector3, radius: Vector3, c: Color, keep := Callable()) -> void:
	for z in range(int(floor(center.z - radius.z)), int(ceil(center.z + radius.z)) + 1):
		for y in range(int(floor(center.y - radius.y)), int(ceil(center.y + radius.y)) + 1):
			for x in range(int(floor(center.x - radius.x)), int(ceil(center.x + radius.x)) + 1):
				var p := Vector3i(x, y, z)
				if _inside_ellipsoid(p, center, radius) and (not keep.is_valid() or keep.call(p)):
					m.set_voxel(p, c)

## 前（+y）から見て、列 (x, z) の一番手前にある肌のボクセルの色を変える（顔に目や口を描く）。
static func _paint_face(m: VoxelModel, x: int, z: int, c: Color) -> void:
	for y in range(SIZE.y - 1, -1, -1):
		var v := m.get_voxel(Vector3i(x, y, z))
		if v.a > 0.0:
			if v == SKIN:
				m.set_voxel(Vector3i(x, y, z), c)
			return

# ---------------------------------------------------------------- 体

const HEAD_CENTER := Vector3(13.5, 13.5, 26.5)
const HEAD_RADIUS := Vector3(8.2, 7.2, 8.0)

static func _body(m: VoxelModel) -> void:
	# くつ（底は暗く、つま先は前へ）とズボン
	_both(m, Vector3i(9, 11, 0), Vector3i(12, 16, 3), BOOTS)
	_both(m, Vector3i(9, 17, 0), Vector3i(12, 17, 1), BOOTS)
	_both(m, Vector3i(9, 11, 0), Vector3i(12, 17, 0), SOLE)
	_both(m, Vector3i(9, 12, 4), Vector3i(12, 15, 7), PANTS)
	# 服：すそは少し広がって、金のふち
	_round_box(m, Vector3i(7, 9, 8), Vector3i(20, 18, 9), TUNIC)
	for y in range(9, 19):
		for x in range(7, 21):
			if (x == 7 or x == 20 or y == 9 or y == 18) and m.get_voxel(Vector3i(x, y, 8)).a > 0.0:
				m.set_voxel(Vector3i(x, y, 8), TRIM)
	_round_box(m, Vector3i(8, 10, 10), Vector3i(19, 17, 17), TUNIC)
	# ベルトと、前の金の留め金
	_round_box(m, Vector3i(8, 10, 11), Vector3i(19, 17, 12), BELT)
	_fill(m, Vector3i(12, 18, 11), Vector3i(15, 18, 12), GOLD)
	_fill(m, Vector3i(13, 18, 11), Vector3i(14, 18, 12), BELT)
	# 腕（そで）と手
	_both(m, Vector3i(5, 12, 11), Vector3i(7, 15, 17), TUNIC)
	_both(m, Vector3i(5, 12, 8), Vector3i(7, 15, 10), SKIN)
	for z in [8, 17]:
		for y in [12, 15]:
			_clear(m, Vector3i(5, y, z))
			_clear(m, Vector3i(22, y, z))
	# 首のマフラーと、後ろに垂れるはし
	_round_box(m, Vector3i(8, 10, 16), Vector3i(19, 17, 18), SCARF)
	_round_box(m, Vector3i(9, 11, 19), Vector3i(18, 16, 19), SCARF)
	_fill(m, Vector3i(15, 8, 9), Vector3i(18, 9, 17), SCARF)
	_fill(m, Vector3i(16, 7, 8), Vector3i(18, 7, 11), SCARF)

static func _head(m: VoxelModel) -> void:
	# 顔
	_ellipsoid(m, HEAD_CENTER, HEAD_RADIUS, SKIN)
	# 髪：頭より一回り大きく、てっぺんと後ろと横をおおう（顔の前は空けて、45°の見下ろしでも顔が見えるように）
	var shell := HEAD_RADIUS + Vector3(0.9, 0.9, 0.7)
	_ellipsoid(m, HEAD_CENTER, shell, HAIR, func(p: Vector3i) -> bool:
		return p.z >= 31 or p.y <= 12 or (p.z >= 24 and absf(p.x - 13.5) >= 6.5 and p.y <= 16))
	# 前髪（ぎざぎざに下りる）
	var fringe := [0, 1, 2, 1, 0, 2, 1, 0, 1, 2, 0, 1, 2, 0, 1, 2, 1]
	for x in range(5, 22):
		for z in range(29 - fringe[x - 5], 36):
			_paint_face(m, x, z, HAIR)
	# 顔の横に下りる髪
	_both(m, Vector3i(5, 15, 20), Vector3i(6, 18, 29), HAIR)
	# アホ毛
	m.set_voxel(Vector3i(14, 14, 36), HAIR)
	m.set_voxel(Vector3i(15, 14, 36), HAIR)
	m.set_voxel(Vector3i(15, 15, 37), HAIR)
	m.set_voxel(Vector3i(16, 15, 37), HAIR)
	# 目（上は濃く、下は青。光を1つ）
	for ex in [9, 17]:
		for x in [ex, ex + 1]:
			_paint_face(m, x, 26, EYE)
			_paint_face(m, x, 25, EYE)
			_paint_face(m, x, 24, IRIS)
			_paint_face(m, x, 23, IRIS)
		_paint_face(m, ex, 25, EYE_SHINE)
	# ほおと口
	for x in [7, 8, 19, 20]:
		_paint_face(m, x, 22, CHEEK)
	for x in [13, 14]:
		_paint_face(m, x, 21, MOUTH)

static func _armor(m: VoxelModel) -> void:
	# 胸当て（胴のまわり）と、金の鋲
	for z in range(13, 17):
		for y in range(10, 18):
			for x in range(8, 20):
				if (x == 8 or x == 19 or y == 10 or y == 17) and m.get_voxel(Vector3i(x, y, z)).a > 0.0:
					m.set_voxel(Vector3i(x, y, z), ARMOR_COLOR)
	_fill(m, Vector3i(13, 17, 14), Vector3i(14, 17, 15), GOLD)
	# 肩当て（丸い）
	for cx in [6.0, 21.0]:
		_ellipsoid(m, Vector3(cx, 13.5, 17.0), Vector3(2.6, 3.0, 1.8), ARMOR_COLOR)

# ---------------------------------------------------------------- 手に持つ物

## 剣：右手に持ち、前へ突き出す。
static func _sword(m: VoxelModel) -> void:
	_fill(m, Vector3i(21, 12, 9), Vector3i(22, 12, 10), GOLD)  # 柄頭
	_fill(m, Vector3i(21, 13, 9), Vector3i(22, 16, 10), BELT)  # 柄
	_fill(m, Vector3i(19, 17, 9), Vector3i(24, 17, 10), GOLD)  # つば
	_fill(m, Vector3i(21, 18, 9), Vector3i(22, 26, 10), STEEL)  # 刃
	m.set_voxel(Vector3i(21, 27, 9), STEEL)  # 切っ先

## 弓：両手で前に構える（上から見て弧が見えるように、横に寝かせる）。
static func _bow(m: VoxelModel) -> void:
	var ends := []
	for k in 41:
		var a := deg_to_rad(-75.0 + 150.0 * k / 40.0)
		var p := Vector2(13.5 + 11.5 * sin(a), 17.0 + 9.0 * cos(a))
		var c := Vector2i(roundi(p.x), roundi(p.y))
		_fill(m, Vector3i(c.x, c.y, 10), Vector3i(c.x, c.y, 11), WOOD)
		if k == 0 or k == 40:
			ends.append(c)
	_fill(m, Vector3i(13, 25, 10), Vector3i(14, 26, 11), BELT)  # 握り
	var y: int = ends[0].y
	_fill(m, Vector3i(ends[0].x + 1, y, 11), Vector3i(ends[1].x - 1, y, 11), STRING)
	# 両手を前へ
	_both(m, Vector3i(6, 16, 10), Vector3i(8, 18, 11), SKIN)

## 杖：右手で立てて持つ。先の玉の色で杖の種類が分かる。
static func _staff(m: VoxelModel, orb: Color) -> void:
	_fill(m, Vector3i(22, 16, 1), Vector3i(23, 17, 29), WOOD)
	for y in range(15, 19):
		for x in range(21, 25):
			if x == 21 or x == 24 or y == 15 or y == 18:
				_fill(m, Vector3i(x, y, 29), Vector3i(x, y, 30), GOLD)
	_ellipsoid(m, Vector3(22.5, 16.5, 33.0), Vector3(2.6, 2.6, 2.6), orb)
	_fill(m, Vector3i(22, 16, 33), Vector3i(23, 17, 34), orb.lightened(0.45))

## 回復の薬：右手に持つ（丸いびん）。
static func _potion(m: VoxelModel) -> void:
	_ellipsoid(m, Vector3(22.5, 16.5, 10.5), Vector3(2.6, 2.6, 2.4), POTION)
	_fill(m, Vector3i(22, 16, 13), Vector3i(23, 17, 14), GLASS_SHINE)
	_fill(m, Vector3i(22, 16, 15), Vector3i(23, 17, 15), BELT)
	m.set_voxel(Vector3i(21, 18, 11), GLASS_SHINE)

# ---------------------------------------------------------------- 影

## 光の向き（上から、少し前と左から）
const LIGHT_DIR := Vector3(-0.3, 0.45, 1.0)

## 影をつける。まわりの空いている向きから面の向きを出し、光の当たり方で4段階に塗る（明るい・ふつう・影・濃い影）。
## 影は青紫へ、明るい所は暖かい白へ寄せる。輪切りのふちごとに縞が出ないよう、ボクセル1つの上下だけでなく、まわり全部で向きを決める。
static func _shade(src: VoxelModel) -> VoxelModel:
	var sx := src.size.x
	var sy := src.size.y
	var sz := src.size.z
	var occ := PackedByteArray()
	occ.resize(sx * sy * sz)
	var vox := src.voxels()
	for p: Vector3i in vox:
		if vox[p].a > 0.0:
			occ[(p.z * sy + p.y) * sx + p.x] = 1
	var light := LIGHT_DIR.normalized()
	var m := VoxelModel.new()
	m.size = src.size
	for p: Vector3i in vox:
		var c: Color = vox[p]
		if c.a <= 0.0:
			continue
		var n := Vector3.ZERO
		for dz in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var q := p + Vector3i(dx, dy, dz)
					var empty := q.x < 0 or q.y < 0 or q.z < 0 or q.x >= sx or q.y >= sy or q.z >= sz \
						or occ[(q.z * sy + q.y) * sx + q.x] == 0
					if empty:
						n += Vector3(dx, dy, dz)
		var out := c.lerp(SHADOW, 0.2)
		if n != Vector3.ZERO:
			var k := n.normalized().dot(light)
			if k > 0.72:
				out = c.lerp(LIGHT, 0.35)
			elif k > 0.3:
				out = c.lerp(LIGHT, 0.08)
			elif k > -0.15:
				out = c.lerp(SHADOW, 0.2)
			else:
				out = c.lerp(SHADOW, 0.38)
		m.set_voxel(p, out)
	return m
