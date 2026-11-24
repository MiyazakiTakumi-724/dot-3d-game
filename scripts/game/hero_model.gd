class_name HeroModel
extends RefCounted
## 主人公の姿（ボクセル）。頭の大きいちびキャラで、手に持つ物と防具が姿で分かる。
## 前は +y、上は +z。体の真ん中が模型の真ん中（SIZE の半分）に来る。
## build(手に持つ品物の id, 防具の id) で作る。持つ物：剣・弓・杖は品物の id、回復は "heal"、何も持たない（鉄球）は ""。

const SIZE := Vector3i(14, 14, 18)

const SKIN := Color("f4dcc0")
const CHEEK := Color("f6a7a7")
const EYE := Color("2a2238")
const HAIR := Color("6b3a22")
const TUNIC := Color("3b6dd8")
const PANTS := Color("3a3552")
const BOOTS := Color("5a3a28")
const BELT := Color("6b4426")
const GOLD := Color("e8c04a")
const SCARF := Color("d23c3c")
const ARMOR_COLOR := Color("aab6c6")
const STEEL := Color("dfe6ee")
const WOOD := Color("9a6a3a")
const STRING := Color("eee4cc")
const NONE_ORB := Color("c8b6ff")
const FIRE_ORB := Color("ff7a2e")
const POTION := Color("ff6fa8")

static var _cache := {}

## 姿を作る（同じ組み合わせは使い回す）。上を向いた面は明るく、横の面は暗くしてある。
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

static func _fill(m: VoxelModel, from: Vector3i, to: Vector3i, c: Color) -> void:
	for z in range(from.z, to.z + 1):
		for y in range(from.y, to.y + 1):
			for x in range(from.x, to.x + 1):
				m.set_voxel(Vector3i(x, y, z), c)

static func _clear(m: VoxelModel, p: Vector3i) -> void:
	m.set_voxel(p, Color(0, 0, 0, 0))

static func _body(m: VoxelModel) -> void:
	# 足（くつは前へ少し出す）とズボン
	for lx in [4, 8]:
		_fill(m, Vector3i(lx, 6, 0), Vector3i(lx + 1, 8, 1), BOOTS)
		m.set_voxel(Vector3i(lx, 9, 0), BOOTS)
		m.set_voxel(Vector3i(lx + 1, 9, 0), BOOTS)
		_fill(m, Vector3i(lx, 6, 2), Vector3i(lx + 1, 8, 3), PANTS)
	# 胴（服）とベルト
	_fill(m, Vector3i(4, 5, 4), Vector3i(9, 8, 8), TUNIC)
	_fill(m, Vector3i(4, 5, 4), Vector3i(9, 8, 4), BELT)
	m.set_voxel(Vector3i(6, 8, 4), GOLD)
	m.set_voxel(Vector3i(7, 8, 4), GOLD)
	# 腕（そで）と手
	for ax in [3, 10]:
		_fill(m, Vector3i(ax, 6, 5), Vector3i(ax, 7, 8), TUNIC)
		_fill(m, Vector3i(ax, 6, 4), Vector3i(ax, 7, 4), SKIN)
	# 首のマフラー（後ろに垂れる）
	_fill(m, Vector3i(4, 5, 8), Vector3i(9, 8, 8), SCARF)
	_fill(m, Vector3i(8, 4, 5), Vector3i(9, 4, 8), SCARF)
	# 頭（大きめ）
	_fill(m, Vector3i(3, 4, 9), Vector3i(10, 9, 15), SKIN)
	# 髪：てっぺん、後ろ、横、前髪
	_fill(m, Vector3i(3, 4, 14), Vector3i(10, 9, 15), HAIR)
	_fill(m, Vector3i(3, 4, 10), Vector3i(10, 5, 15), HAIR)
	_fill(m, Vector3i(3, 4, 11), Vector3i(3, 9, 15), HAIR)
	_fill(m, Vector3i(10, 4, 11), Vector3i(10, 9, 15), HAIR)
	for bx in [4, 5, 7, 8, 9]:
		m.set_voxel(Vector3i(bx, 9, 13), HAIR)
	_fill(m, Vector3i(6, 6, 16), Vector3i(7, 7, 16), HAIR)  # アホ毛
	m.set_voxel(Vector3i(7, 7, 17), HAIR)
	# 頭の角を落として丸くする（縦の4つの角と、てっぺん・あごのふち）
	for z in range(9, 16):
		for c in [Vector2i(3, 4), Vector2i(10, 4), Vector2i(3, 9), Vector2i(10, 9)]:
			_clear(m, Vector3i(c.x, c.y, z))
	for z in [9, 15]:
		for x in range(3, 11):
			_clear(m, Vector3i(x, 4, z))
			_clear(m, Vector3i(x, 9, z))
		for y in range(4, 10):
			_clear(m, Vector3i(3, y, z))
			_clear(m, Vector3i(10, y, z))
	# 目とほお
	for ex in [5, 8]:
		_fill(m, Vector3i(ex, 9, 11), Vector3i(ex, 9, 12), EYE)
	m.set_voxel(Vector3i(4, 9, 10), CHEEK)
	m.set_voxel(Vector3i(9, 9, 10), CHEEK)

static func _armor(m: VoxelModel) -> void:
	# 胸当てと肩当て
	_fill(m, Vector3i(4, 8, 5), Vector3i(9, 8, 7), ARMOR_COLOR)
	_fill(m, Vector3i(4, 5, 5), Vector3i(4, 8, 7), ARMOR_COLOR)
	_fill(m, Vector3i(9, 5, 5), Vector3i(9, 8, 7), ARMOR_COLOR)
	for ax in [3, 10]:
		_fill(m, Vector3i(ax, 5, 8), Vector3i(ax, 8, 8), ARMOR_COLOR)

## 剣：右手に持ち、前へ突き出す。
static func _sword(m: VoxelModel) -> void:
	_fill(m, Vector3i(11, 6, 5), Vector3i(11, 7, 5), BELT)  # 柄
	_fill(m, Vector3i(10, 8, 5), Vector3i(12, 8, 5), GOLD)  # つば
	_fill(m, Vector3i(11, 9, 5), Vector3i(11, 13, 5), STEEL)  # 刃

## 弓：両手で前に構える（上から見て弧が見えるように、横に寝かせる）。
static func _bow(m: VoxelModel) -> void:
	var limb := [Vector2i(1, 10), Vector2i(2, 11), Vector2i(3, 12), Vector2i(4, 12), Vector2i(5, 13), Vector2i(6, 13),
		Vector2i(7, 13), Vector2i(8, 13), Vector2i(9, 12), Vector2i(10, 12), Vector2i(11, 11), Vector2i(12, 10)]
	for p: Vector2i in limb:
		_fill(m, Vector3i(p.x, p.y, 5), Vector3i(p.x, p.y, 6), WOOD)
	_fill(m, Vector3i(2, 10, 6), Vector3i(11, 10, 6), STRING)
	# 両手を前へ
	for ax in [3, 10]:
		_fill(m, Vector3i(ax, 8, 5), Vector3i(ax, 9, 5), SKIN)

## 杖：右手で立てて持つ。先の玉の色で杖の種類が分かる。
static func _staff(m: VoxelModel, orb: Color) -> void:
	_fill(m, Vector3i(11, 8, 1), Vector3i(11, 8, 13), WOOD)
	_fill(m, Vector3i(10, 8, 15), Vector3i(12, 8, 15), orb)
	_fill(m, Vector3i(11, 7, 14), Vector3i(11, 9, 16), orb)
	m.set_voxel(Vector3i(11, 8, 15), orb.lightened(0.5))

## 回復の薬：右手に持つ。
static func _potion(m: VoxelModel) -> void:
	_fill(m, Vector3i(11, 7, 4), Vector3i(12, 8, 6), POTION)
	m.set_voxel(Vector3i(11, 7, 7), BELT)

## 上が空いているボクセル（上を向いた面）は明るく、ほかは少し暗くする。
static func _shade(src: VoxelModel) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = src.size
	for z in src.size.z:
		for y in src.size.y:
			for x in src.size.x:
				var c := src.get_voxel(Vector3i(x, y, z))
				if c.a <= 0.0:
					continue
				var top := src.get_voxel(Vector3i(x, y, z + 1)).a <= 0.0
				m.set_voxel(Vector3i(x, y, z), c.lightened(0.12) if top else c.darkened(0.1))
	return m
