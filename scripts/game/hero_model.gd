class_name HeroModel
extends RefCounted
## 主人公の姿（ボクセル）。頭の大きいちびキャラの勇者で、手に持つ物と防具が姿で分かる。
## ほかの物の2倍の細かさで作り、ボクセル1つを本当の画面の1pxで描く（VOXEL_SCALE）。ゲームの座標では 14×14×19 の大きさ。
## 前は +y、上は +z。体の真ん中が模型の真ん中（SIZE の半分）に来る。左右の x は 27 − x で写す。
## build(手に持つ品物の id, 防具の id, 姿勢) で作る。持つ物：鉄球・剣・弓・杖は品物の id、回復は "heal"、何も持たないときは ""。
## 姿勢（HeroAnim.pose）：""（立ち）・step_l / step_r（歩く。立ち姿の足と腕をずらして作るので軽い）・release（鉄球を放した、両手を前に出した姿）。
## 持つ物ごとの姿（item_poses）：剣 slash（振る）・thrust（突く）、弓 draw（引く）・draw_full（引ききる）、杖 cast（ふるう）、回復 drink（飲む）。
## 何も持たない姿（ITEMLESS_POSES）：release・climb（よじ登る、奈落に落ちる）・push（門を押す）・down（倒れて横たわる。大きさが違う）。
## デザインは STYLES の中から style で選ぶ（2026-11-25 にユーザーへ見せた案。選ばれたものを残す）。

const SIZE := Vector3i(28, 28, 38)
const VOXEL_SCALE := 0.5  ## = 1 / StackCamera.PIXEL_SCALE
## 杖の先の玉の、手前の横の1つ（杖を持っているときだけある。玉の色そのまま）
const STAFF_TIP := Vector3i(20, 16, 33)
## 両手で持った鉄球の真ん中と半径。地面の鉄球（ball_model）も同じ大きさ
const BALL_CENTER := Vector3(13.5, 21.0, 11.5)
const BALL_RADIUS := 5.2
const BALL_BOX := 12  ## 地面の鉄球の模型の大きさ（偶数）
## 歩くときに前後へずらす足（x の範囲）と腕。どちらも x の小さい側が先
const LEG_X := [Vector2i(9, 12), Vector2i(15, 18)]
const ARM_X := [Vector2i(5, 7), Vector2i(20, 22)]
## 動きの姿で、腕を描き直すときの肩の位置（左・右）
const SHOULDER_L := Vector3(6.0, 13.5, 16.5)
const SHOULDER_R := Vector3(21.0, 13.5, 16.5)
## 弓を引いた姿の矢じりの先・杖をふるった姿の玉・薬を飲む姿のびん・よじ登る姿の左手（テストと光の位置に使う）
const NOCKED_TIP := Vector3i(13, 27, 15)
const CAST_ORB := Vector3(22.5, 24.0, 32.5)
const CAST_TIP := Vector3i(20, 24, 32)
const DRINK_POTION := Vector3i(16, 22, 22)
const CLIMB_HAND := Vector3i(3, 18, 29)
## 何も持たない姿で描く姿勢（手に持つ物はしまう）
const ITEMLESS_POSES := ["release", "climb", "push", "down"]
## 腕を描き直す姿勢
const POSED_ARMS := ["slash", "thrust", "draw", "draw_full", "cast", "drink", "climb", "push"]

const SKIN := Color("f7d3b0")
const CHEEK := Color("f29a9a")
const MOUTH := Color("c4685c")
const EYE := Color("2b2140")
const EYE_SHINE := Color("ffffff")
const SOLE := Color("3a2418")
const BELT := Color("7b4a2b")
const GOLD := Color("f2c14e")
const SILVER := Color("c9d3df")
const ARMOR_COLOR := Color("aab6c6")
const STEEL := Color("dfe7f0")
const WOOD := Color("a26b3c")
const STRING := Color("f1e6c8")
const SHAFT := Color("b07a46")
const FEATHER := Color("f4f1ea")
const NONE_ORB := Color("c8b6ff")
const FIRE_ORB := Color("ff7a2e")
const POTION := Color("ff6fa8")
const GLASS_SHINE := Color("ffe6f1")
const BALL := Color("6b6f78")
const STRONG_BALL := Color("7a2230")
const NONE := Color(0, 0, 0, 0)

## デザインの案。hair_kind：soft（ふわっと）・spiky（ツンツン）。gear：頭の装備（circlet 額当て・wing_helm 羽根かぶと・hood フード）。
## cape・scarf・vest は NONE ならなし。
const STYLES := {
	"a": {"title": "王道の勇者", "hair": Color("6b3a22"), "hair_kind": "soft", "gear": "circlet", "gem": Color("3fa7ff"),
		"tunic": Color("2c4fb0"), "trim": Color("f2c14e"), "pants": Color("4a3b2f"), "boots": Color("6a3f2a"),
		"cape": Color("c8323c"), "scarf": NONE, "vest": NONE, "shoulder": true, "emblem": false, "iris": Color("3a6fd8")},
	"b": {"title": "若き勇者", "hair": Color("e8902a"), "hair_kind": "spiky", "gear": "", "gem": NONE,
		"tunic": Color("f2ead6"), "trim": Color("6b4426"), "pants": Color("3b4a6b"), "boots": Color("5a3a28"),
		"cape": NONE, "scarf": Color("e0413f"), "vest": Color("8a5a34"), "shoulder": false, "emblem": false, "iris": Color("3fa06a")},
	"c": {"title": "羽根かぶとの勇者", "hair": Color("f0d070"), "hair_kind": "soft", "gear": "wing_helm", "gem": NONE,
		"tunic": Color("3a7bd5"), "trim": Color("f2c14e"), "pants": Color("3b3456"), "boots": Color("8a93a3"),
		"cape": Color("2c3f9c"), "scarf": NONE, "vest": NONE, "shoulder": true, "emblem": true, "iris": Color("4a74e8")},
	"d": {"title": "外套の旅の勇者", "hair": Color("2a2430"), "hair_kind": "soft", "gear": "hood", "gem": NONE,
		"tunic": Color("d9c9a3"), "trim": Color("7b4a2b"), "pants": Color("4a4038"), "boots": Color("5a3a28"),
		"cape": Color("2f6f6a"), "scarf": NONE, "vest": NONE, "shoulder": false, "emblem": false, "iris": Color("d08a2c")},
}

## 今のデザイン（STYLES のキー）。ユーザーが C 羽根かぶとの勇者に決めた（2026-11-25）。ほかの案は残してある
static var style := "c"
static var _cache := {}

## 姿を作る（同じ組み合わせは使い回す）。歩く姿は、立ち姿を写して足と腕をずらすだけなので速い。
static func build(held: String, armor: String, pose := "") -> VoxelModel:
	var key := "%s|%s|%s|%s" % [style, held, armor, pose]
	if not _cache.has(key):
		if pose == "step_l" or pose == "step_r":
			_cache[key] = _step(build(held, armor), held, pose == "step_l")
		elif pose == "down":
			_cache[key] = _shade(_lay_down(raw("", armor)))
		else:
			_cache[key] = _shade(raw(held, armor, pose))
	return _cache[key]

## 持ちかえたときに止まらないよう、持つ物それぞれの立ち姿・歩く姿・動きの姿と、何も持たない姿を先に作っておく（輪切りの画像も）。
static func warm(helds: Array, armor: String) -> void:
	for h: String in helds:
		for pose in ["", "step_l", "step_r"] + item_poses(h):
			build(h, armor, pose).textures()
	for pose in ITEMLESS_POSES:
		build("", armor, pose).textures()

## 持つ物ごとの動きの姿。
static func item_poses(held: String) -> Array:
	if held == "heal":
		return ["drink"]
	if not ItemCatalog.exists(held):
		return []
	match ItemCatalog.slot(held):
		Equipment.Slot.SWORD:
			return ["slash", "thrust"]
		Equipment.Slot.BOW:
			return ["draw", "draw_full"]
		Equipment.Slot.STAFF:
			return ["cast"]
	return []

## 影をつける前の姿。
static func raw(held: String, armor: String, pose := "") -> VoxelModel:
	var s: Dictionary = STYLES[style]
	var m := VoxelModel.new()
	m.size = SIZE
	var posed := pose in POSED_ARMS
	_body(m, s, not posed)
	_head(m, s)
	if s["shoulder"]:
		_shoulders(m, SILVER)
	if armor != "":
		_armor(m)
	if posed:
		_pose(m, s, held, pose)
		return m
	match ItemCatalog.slot(held) if ItemCatalog.exists(held) else -1:
		Equipment.Slot.BALL:
			_iron_ball(m, s, STRONG_BALL if ItemCatalog.rank(held) >= 2 else BALL)
		Equipment.Slot.SWORD:
			_sword(m)
		Equipment.Slot.BOW:
			_bow(m)
		Equipment.Slot.STAFF:
			_staff(m, orb_color(held))
	if held == "heal":
		_potion(m)
	if pose == "release":
		_release_arms(m, s)
	return m

## 地面に落ちている鉄球（手に持つ鉄球と同じ細かさ・同じ大きさ・同じ影の付け方）。
static func ball_model(strong: bool) -> VoxelModel:
	var key := "ball|%s" % strong
	if not _cache.has(key):
		var m := VoxelModel.new()
		m.size = Vector3i.ONE * BALL_BOX
		var c := (BALL_BOX - 1) / 2.0
		_ball(m, Vector3(c, c, c), STRONG_BALL if strong else BALL)
		_cache[key] = _shade(m)
	return _cache[key]

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
	m.set_voxel(p, NONE)

static func _filled(m: VoxelModel, p: Vector3i) -> bool:
	return m.get_voxel(p).a > 0.0

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

## 前（+y）から見て、列 (x, z) の一番手前のボクセルが only の色なら c に変える（only が NONE なら何色でも）。
static func _paint_front(m: VoxelModel, x: int, z: int, c: Color, only := SKIN) -> void:
	for y in range(SIZE.y - 1, -1, -1):
		var v := m.get_voxel(Vector3i(x, y, z))
		if v.a > 0.0:
			if only.a <= 0.0 or v == only:
				m.set_voxel(Vector3i(x, y, z), c)
			return

## 高さ z の輪切りで、外側（となりが空いている）ボクセルを c に塗る。y_min より後ろと、x_min〜x_max の外は塗らない。
static func _paint_ring(m: VoxelModel, z: int, c: Color, y_min := 0, x_min := 0, x_max := SIZE.x - 1) -> void:
	var cells := []
	for y in range(y_min, SIZE.y):
		for x in range(x_min, x_max + 1):
			var p := Vector3i(x, y, z)
			if not _filled(m, p):
				continue
			for d in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0)]:
				if not _filled(m, p + d):
					cells.append(p)
					break
	for p in cells:
		m.set_voxel(p, c)

## 列 (x, y) の一番上のボクセルの高さ。なければ -1。
static func _top_z(m: VoxelModel, x: int, y: int) -> int:
	for z in range(SIZE.z - 1, -1, -1):
		if _filled(m, Vector3i(x, y, z)):
			return z
	return -1

# ---------------------------------------------------------------- 体

const HEAD_CENTER := Vector3(13.5, 13.5, 26.0)
const HEAD_RADIUS := Vector3(8.0, 7.2, 7.6)

## arms が false なら腕を描かない（動きの姿で、腕を別に描くとき）。
static func _body(m: VoxelModel, s: Dictionary, arms := true) -> void:
	var tunic: Color = s["tunic"]
	var trim: Color = s["trim"]
	# マントは体より先に置いて、体で前をふさぐ
	var cape: Color = s["cape"]
	if cape.a > 0.0:
		_cape(m, cape)
	# くつ（底は暗く、つま先は前へ）とズボン
	_both(m, Vector3i(9, 11, 0), Vector3i(12, 16, 3), s["boots"])
	_both(m, Vector3i(9, 17, 0), Vector3i(12, 17, 1), s["boots"])
	_both(m, Vector3i(9, 11, 0), Vector3i(12, 17, 0), SOLE)
	_both(m, Vector3i(9, 12, 4), Vector3i(12, 15, 7), s["pants"])
	# 服：すそは少し広がって、ふちの色
	_round_box(m, Vector3i(7, 9, 8), Vector3i(20, 18, 9), tunic)
	for y in range(9, 19):
		for x in range(7, 21):
			if (x == 7 or x == 20 or y == 9 or y == 18) and _filled(m, Vector3i(x, y, 8)):
				m.set_voxel(Vector3i(x, y, 8), trim)
	_round_box(m, Vector3i(8, 10, 10), Vector3i(19, 17, 17), tunic)
	# 革のベスト（前は開いて、下の服が見える）
	var vest: Color = s["vest"]
	if vest.a > 0.0:
		for z in range(12, 18):
			_paint_ring(m, z, vest, 0, 8, 19)
		_fill(m, Vector3i(12, 17, 12), Vector3i(15, 17, 17), tunic)
	# 胸の金の紋章（十字）
	if s["emblem"]:
		for z in range(13, 17):
			for x in [13, 14]:
				_paint_front(m, x, z, GOLD, NONE)
		for x in [12, 15]:
			_paint_front(m, x, 15, GOLD, NONE)
	# ベルトと、前の金の留め金
	_round_box(m, Vector3i(8, 10, 11), Vector3i(19, 17, 12), BELT)
	_fill(m, Vector3i(12, 18, 11), Vector3i(15, 18, 12), GOLD)
	_fill(m, Vector3i(13, 18, 11), Vector3i(14, 18, 12), BELT)
	# 腕（そで）と手
	if arms:
		_rest_arm(m, 0, tunic)
		_rest_arm(m, 1, tunic)
	# 首まわり：マフラー（長いはしが後ろへなびく）か、服のえり
	var scarf: Color = s["scarf"]
	if scarf.a > 0.0:
		_round_box(m, Vector3i(8, 10, 16), Vector3i(19, 17, 18), scarf)
		_round_box(m, Vector3i(9, 11, 19), Vector3i(18, 16, 19), scarf)
		for k in 9:
			var y := 9 - k
			var z := 17 - k / 2
			var x := 16 + k / 3
			_fill(m, Vector3i(x, maxi(y, 0), z - 1), Vector3i(x + 1, maxi(y, 0), z), scarf)
		for k in 6:
			_fill(m, Vector3i(11 - k / 3, maxi(9 - k, 0), 15 - k / 2), Vector3i(12 - k / 3, maxi(9 - k, 0), 16 - k / 2), scarf)
	else:
		_round_box(m, Vector3i(9, 11, 18), Vector3i(18, 16, 18), trim)

## マント：肩から下へ、後ろに垂れて少し広がる。肩の上にえり。
static func _cape(m: VoxelModel, c: Color) -> void:
	for z in range(2, 19):
		var t := (18 - z) / 16.0  # 上 0 → 下 1
		var half := 6.0 + 2.0 * t
		var y := 8 - int(round(1.5 * t))
		var x0 := int(ceil(13.5 - half))
		var x1 := int(floor(13.5 + half))
		for x in range(x0, x1 + 1):
			m.set_voxel(Vector3i(x, y, z), c)
			m.set_voxel(Vector3i(x, y + 1, z), c)
		# 両わきへ回りこむ
		for yy in range(y + 2, 12):
			m.set_voxel(Vector3i(x0, yy, z), c)
			m.set_voxel(Vector3i(x1, yy, z), c)
	# 肩の上のえり
	_round_box(m, Vector3i(6, 8, 18), Vector3i(21, 13, 18), c)

static func _shoulders(m: VoxelModel, c: Color) -> void:
	for cx in [6.0, 21.0]:
		_ellipsoid(m, Vector3(cx, 13.5, 17.0), Vector3(2.6, 3.0, 1.8), c)

static func _head(m: VoxelModel, s: Dictionary) -> void:
	var hair: Color = s["hair"]
	var gear: String = s["gear"]
	# 顔
	_ellipsoid(m, HEAD_CENTER, HEAD_RADIUS, SKIN)
	# 髪：頭より一回り大きく、てっぺんと後ろと横をおおう（顔の前は空けて、45°の見下ろしでも顔が見えるように）
	var shell := HEAD_RADIUS + Vector3(0.9, 0.9, 0.7)
	_ellipsoid(m, HEAD_CENTER, shell, hair, func(p: Vector3i) -> bool:
		return p.z >= 30 or p.y <= 12 or (p.z >= 23 and absf(p.x - 13.5) >= 6.5 and p.y <= 16))
	# 前髪（ぎざぎざに下りる）
	var fringe := [0, 1, 2, 1, 0, 2, 1, 0, 1, 2, 0, 1, 2, 0, 1, 2, 1]
	for x in range(5, 22):
		for z in range(28 - fringe[x - 5], 35):
			_paint_front(m, x, z, hair)
	# 顔の横に下りる髪
	_both(m, Vector3i(5, 15, 19), Vector3i(6, 18, 28), hair)
	if s["hair_kind"] == "spiky":
		_spikes(m, hair)
	elif gear == "" or gear == "circlet":
		m.set_voxel(Vector3i(14, 14, 34), hair)  # アホ毛
		m.set_voxel(Vector3i(15, 15, 35), hair)
	# 目（上は濃く、下は色。光を1つ）
	var iris: Color = s["iris"]
	for ex in [9, 17]:
		for x in [ex, ex + 1]:
			_paint_front(m, x, 25, EYE)
			_paint_front(m, x, 24, EYE)
			_paint_front(m, x, 23, iris)
			_paint_front(m, x, 22, iris)
		_paint_front(m, ex, 24, EYE_SHINE)
	# ほおと口
	for x in [7, 8, 19, 20]:
		_paint_front(m, x, 21, CHEEK)
	for x in [13, 14]:
		_paint_front(m, x, 20, MOUTH)
	match gear:
		"circlet":
			_circlet(m, s["gem"])
		"wing_helm":
			_wing_helm(m)
		"hood":
			_hood(m, s["cape"])

## ツンツンの髪：てっぺんと後ろに、とがった房を立てる。
static func _spikes(m: VoxelModel, hair: Color) -> void:
	var spots := [Vector2i(13, 13), Vector2i(9, 12), Vector2i(17, 12), Vector2i(11, 8), Vector2i(16, 8), Vector2i(13, 16), Vector2i(7, 9), Vector2i(20, 9)]
	var lean := [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1)]
	for i in spots.size():
		var p: Vector2i = spots[i]
		var top := _top_z(m, p.x, p.y)
		if top < 0:
			continue
		_fill(m, Vector3i(p.x, p.y, top + 1), Vector3i(p.x + 1, p.y + 1, top + 2), hair)
		var q: Vector2i = p + lean[i]
		m.set_voxel(Vector3i(q.x, q.y, top + 3), hair)
		m.set_voxel(Vector3i(q.x + 1, q.y, top + 3), hair)

## 額当て：頭のまわりの銀の輪と、おでこの宝石。
static func _circlet(m: VoxelModel, gem: Color) -> void:
	_paint_ring(m, 28, SILVER, 6)
	_paint_ring(m, 29, SILVER, 6)
	for x in [13, 14]:
		_paint_front(m, x, 28, gem, SILVER)
		_paint_front(m, x, 29, gem, SILVER)
	_paint_front(m, 12, 28, GOLD, SILVER)
	_paint_front(m, 15, 28, GOLD, SILVER)

## 羽根かぶと：頭の上半分をおおう銀のかぶとと、両横の白い羽根。
static func _wing_helm(m: VoxelModel) -> void:
	var r := HEAD_RADIUS + Vector3(1.4, 1.4, 1.2)
	_ellipsoid(m, HEAD_CENTER, r, SILVER, func(p: Vector3i) -> bool:
		return p.z >= 28 and not (p.y >= 17 and p.z <= 28))
	# ひさしの金のふち
	_paint_ring(m, 28, GOLD)
	var white := Color("ffffff")
	for side in [0, 1]:
		var x0 := 4 if side == 0 else 23
		var dx := -1 if side == 0 else 1
		_fill(m, Vector3i(mini(x0, x0 + dx), 11, 28), Vector3i(maxi(x0, x0 + dx), 15, 30), white)
		_fill(m, Vector3i(x0 + dx, 9, 31), Vector3i(x0 + dx, 14, 32), white)
		_fill(m, Vector3i(x0 + dx, 8, 33), Vector3i(x0 + dx, 12, 34), white)
		_fill(m, Vector3i(x0 + 2 * dx, 7, 34), Vector3i(x0 + 2 * dx, 10, 35), white)

## フード：頭を後ろからおおい、顔のまわりだけ開いている。後ろにとがった先。
static func _hood(m: VoxelModel, c: Color) -> void:
	var r := HEAD_RADIUS + Vector3(1.6, 1.6, 1.3)
	_ellipsoid(m, HEAD_CENTER, r, c, func(p: Vector3i) -> bool:
		var opening := p.y >= 16 and absf(p.x - 13.5) <= 6.0 and p.z <= 29
		return (p.z >= 19 and not opening and not _filled(m, p)) or (p.z >= 30 and p.y >= 9))
	_fill(m, Vector3i(13, 7, 31), Vector3i(14, 8, 33), c)
	_fill(m, Vector3i(13, 6, 30), Vector3i(14, 6, 31), c)
	# 顔のまわりのふち
	for z in range(20, 31):
		for x in [6, 7, 20, 21]:
			_paint_front(m, x, z, c.darkened(0.25), c)

static func _armor(m: VoxelModel) -> void:
	# 胸当て（胴のまわり）と、金の鋲
	for z in range(13, 17):
		for y in range(10, 18):
			for x in range(8, 20):
				if (x == 8 or x == 19 or y == 10 or y == 17) and _filled(m, Vector3i(x, y, z)):
					m.set_voxel(Vector3i(x, y, z), ARMOR_COLOR)
	_fill(m, Vector3i(13, 17, 14), Vector3i(14, 17, 15), GOLD)
	_shoulders(m, ARMOR_COLOR)

# ---------------------------------------------------------------- 手に持つ物

## 鉄球の玉と、左上の光。
static func _ball(m: VoxelModel, center: Vector3, c: Color) -> void:
	_ellipsoid(m, center, Vector3.ONE * BALL_RADIUS, c)
	m.set_voxel(Vector3i((center + Vector3(-2.5, -2.0, 3.5)).round()), c.lightened(0.5))

## 鉄球：両手で体の前に抱える。
static func _iron_ball(m: VoxelModel, s: Dictionary, c: Color) -> void:
	_ball(m, BALL_CENTER, c)
	# 腕を前へ出して、両わきから支える
	_both(m, Vector3i(6, 15, 11), Vector3i(7, 18, 14), s["tunic"])
	_both(m, Vector3i(7, 19, 10), Vector3i(8, 22, 13), SKIN)

## 鉄球を放した手：両腕を前と外へ広げ、手を開く（鉄球を抱えていた所が空く。正面から見ても手が体の外に出て分かる）。
static func _release_arms(m: VoxelModel, s: Dictionary) -> void:
	_both(m, Vector3i(4, 14, 11), Vector3i(6, 17, 13), s["tunic"])
	_both(m, Vector3i(2, 17, 10), Vector3i(4, 20, 13), SKIN)
	_both(m, Vector3i(2, 20, 12), Vector3i(2, 20, 13), SKIN)  # 開いた指

## 下ろした腕（立ち姿の腕）。side 0 は左（x の小さい側）、1 は右。
static func _rest_arm(m: VoxelModel, side: int, tunic: Color) -> void:
	var x0: int = ARM_X[side].x
	_fill(m, Vector3i(x0, 12, 11), Vector3i(x0 + 2, 15, 17), tunic)
	_fill(m, Vector3i(x0, 12, 8), Vector3i(x0 + 2, 15, 10), SKIN)
	var outer := 5 if side == 0 else 22
	for z in [8, 17]:
		for y in [12, 15]:
			_clear(m, Vector3i(outer, y, z))

## 肩から手まで伸ばした腕（そでは服の色、先の手ははだの色）。
static func _arm(m: VoxelModel, shoulder: Vector3, hand: Vector3, tunic: Color) -> void:
	var n := maxi(2, ceili(shoulder.distance_to(hand) * 3.0))
	for i in n + 1:
		var t := float(i) / n
		if t > 0.72:
			break
		var p := shoulder.lerp(hand, t)
		for dz in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if absi(dx) + absi(dy) + absi(dz) <= 2:
						m.set_voxel(Vector3i(p.round()) + Vector3i(dx, dy, dz), tunic)
	_ellipsoid(m, hand, Vector3.ONE * 1.6, SKIN)

## a から b までの棒（太さ w。剣の刃・杖・弦・矢）。
static func _rod(m: VoxelModel, a: Vector3, b: Vector3, c: Color, w := 2) -> void:
	var n := maxi(1, ceili(a.distance_to(b) * 3.0))
	var half := (w - 1) * 0.5
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		var lo := Vector3i((p - Vector3.ONE * half).round())
		_fill(m, lo, lo + Vector3i.ONE * (w - 1), c)

## 動きの姿：腕を描き直し、持つ物をその姿の位置に描く。
static func _pose(m: VoxelModel, s: Dictionary, held: String, pose: String) -> void:
	var tunic: Color = s["tunic"]
	match pose:
		"slash":
			# 剣を持つ右腕を前の外へ振り出し、左腕は後ろへ
			_arm(m, SHOULDER_L, Vector3(4.0, 10.0, 12.5), tunic)
			_arm(m, SHOULDER_R, Vector3(22.5, 18.0, 14.0), tunic)
			var d := Vector3(0.75, 1.0, 0.0).normalized()
			var h := Vector3(22.5, 18.0, 14.0)
			_rod(m, h - d * 2.0, h + d * 0.5, BELT)
			var g := h + d * 1.5
			var side := Vector3(-d.y, d.x, 0.0)
			_rod(m, g - side * 2.5, g + side * 2.5, GOLD)
			_rod(m, h + d * 2.5, h + d * 9.5, STEEL)
		"thrust":
			# 剣をまっすぐ前へ突き出す。左腕は後ろへ
			_arm(m, SHOULDER_L, Vector3(4.5, 9.5, 12.5), tunic)
			_arm(m, SHOULDER_R, Vector3(20.0, 19.5, 14.0), tunic)
			_rod(m, Vector3(20.5, 17.5, 13.5), Vector3(20.5, 20.5, 13.5), BELT)
			_fill(m, Vector3i(18, 21, 13), Vector3i(23, 21, 14), GOLD)
			_rod(m, Vector3(20.5, 22.0, 13.5), Vector3(20.5, 27.0, 13.5), STEEL)
		"draw", "draw_full":
			_draw_bow(m, tunic, pose == "draw_full")
		"cast":
			_cast(m, tunic, orb_color(held))
		"drink":
			_drink(m, tunic)
		"climb":
			# 両手を肩より上へ（崖のふちをつかむ・落ちていく）
			_arm(m, SHOULDER_L, Vector3(3.5, 18.0, 29.0), tunic)
			_arm(m, SHOULDER_R, Vector3(23.5, 18.0, 29.0), tunic)
		"push":
			# 両手を前へまっすぐ出して押す
			_arm(m, SHOULDER_L, Vector3(8.5, 22.0, 15.0), tunic)
			_arm(m, SHOULDER_R, Vector3(18.5, 22.0, 15.0), tunic)

## 弓を引く：弓を前に構えて矢を番え、右手で弦を胸もとへ引く（full なら引ききる）。上から見えるよう、矢は弓の上に乗せる。
static func _draw_bow(m: VoxelModel, tunic: Color, full: bool) -> void:
	var nock := 18.0 if full else 20.5
	var ends := []
	for k in 37:
		var a := deg_to_rad(-62.0 + 124.0 * k / 36.0)
		var p := Vector2(13.5 + 11.0 * sin(a), 17.5 + 7.0 * cos(a))
		var c := Vector2i(roundi(p.x), roundi(p.y))
		_fill(m, Vector3i(c.x, c.y, 13), Vector3i(c.x, c.y, 14), WOOD)
		if k == 0 or k == 36:
			ends.append(Vector3(c.x, c.y, 14))
	_fill(m, Vector3i(13, 24, 13), Vector3i(14, 25, 14), BELT)  # 握り
	var notch := Vector3(13.5, nock, 14.0)
	_rod(m, ends[0], notch, STRING, 1)
	_rod(m, ends[1], notch, STRING, 1)
	_arm(m, SHOULDER_L, Vector3(11.0, 23.5, 13.5), tunic)
	_arm(m, SHOULDER_R, Vector3(16.0, nock, 14.5), tunic)
	# 矢：羽根・矢柄・矢じり
	_fill(m, Vector3i(13, int(nock), 15), Vector3i(14, 25, 15), SHAFT)
	_fill(m, Vector3i(12, int(nock), 15), Vector3i(15, int(nock) + 1, 15), FEATHER)
	_fill(m, Vector3i(13, 26, 15), Vector3i(14, 27, 15), STEEL)

## 杖をふるう：右手で杖を前へ倒して高く掲げ、左手を横へ開く。
static func _cast(m: VoxelModel, tunic: Color, orb: Color) -> void:
	_arm(m, SHOULDER_L, Vector3(4.0, 17.5, 17.0), tunic)
	_arm(m, SHOULDER_R, Vector3(22.0, 20.0, 20.0), tunic)
	_rod(m, Vector3(22.5, 15.5, 9.0), Vector3(22.5, 23.2, 28.5), WOOD)
	for y in range(22, 26):
		for x in range(21, 25):
			if x == 21 or x == 24 or y == 22 or y == 25:
				_fill(m, Vector3i(x, y, 29), Vector3i(x, y, 30), GOLD)
	_ellipsoid(m, CAST_ORB, Vector3.ONE * 2.6, orb)
	_fill(m, Vector3i(22, 23, 33), Vector3i(23, 24, 34), orb.lightened(0.45))

## 薬を飲む：右手でびんを口もとへ。左手は下ろしたまま。
static func _drink(m: VoxelModel, tunic: Color) -> void:
	_rest_arm(m, 0, tunic)
	_arm(m, SHOULDER_R, Vector3(17.5, 20.0, 20.0), tunic)
	_ellipsoid(m, Vector3(16.0, 21.5, 22.5), Vector3(2.4, 2.4, 2.2), POTION)
	_rod(m, Vector3(14.5, 19.5, 21.5), Vector3(14.0, 19.0, 21.0), GLASS_SHINE, 1)
	m.set_voxel(Vector3i(17, 21, 24), GLASS_SHINE)

## 倒れた姿：立ち姿を後ろへ倒して、あおむけに横たわらせる（頭が後ろ、顔が上、足が前）。
static func _lay_down(src: VoxelModel) -> VoxelModel:
	var y_min := SIZE.y
	var vox := src.voxels()
	for p: Vector3i in vox:
		if vox[p].a > 0.0:
			y_min = mini(y_min, p.y)
	var m := VoxelModel.new()
	m.size = Vector3i(SIZE.x, SIZE.z, SIZE.y - y_min)
	for p: Vector3i in vox:
		if vox[p].a > 0.0:
			m.set_voxel(Vector3i(p.x, SIZE.z - 1 - p.z, p.y - y_min), vox[p])
	return m

## 歩く姿：立ち姿を写して、片方の足を前へ、もう片方を後ろへずらす（くつは2つ、ズボンは1つ）。
## 何も持っていなければ、腕を足と逆にふる（手は2つ、そでは1つ）。left_forward は x の小さい側の足が前。
static func _step(src: VoxelModel, held: String, left_forward: bool) -> VoxelModel:
	var m := src.copy()
	for i in 2:
		var dir := 1 if (i == 0) == left_forward else -1
		var xr: Vector2i = LEG_X[i]
		m.move_box(Vector3i(xr.x, 9, 0), Vector3i(xr.y, 18, 3), Vector3i(0, 2 * dir, 0))
		m.move_box(Vector3i(xr.x, 9, 4), Vector3i(xr.y, 18, 7), Vector3i(0, dir, 0))
	if held == "":
		for i in 2:
			var dir := -1 if (i == 0) == left_forward else 1
			var xr: Vector2i = ARM_X[i]
			m.move_box(Vector3i(xr.x, 10, 8), Vector3i(xr.y, 17, 10), Vector3i(0, 2 * dir, 0))
			m.move_box(Vector3i(xr.x, 10, 11), Vector3i(xr.y, 17, 13), Vector3i(0, dir, 0))
	return m

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

## 影をつける（VoxelShade。小物や地形と同じ付け方）。
static func _shade(src: VoxelModel) -> VoxelModel:
	return VoxelShade.apply(src)
