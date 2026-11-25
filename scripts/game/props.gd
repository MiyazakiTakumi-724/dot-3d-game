class_name Props
extends RefCounted
## 主人公以外の物の模型（矢・たき火・宝箱・墓石・門・拾いもの・出口の矢印・魔法の弾・敵の弾・炎・狙いの印）。
## 主人公と同じ2倍の細かさで作り、ボクセル1つを本当の画面の1pxで描く（StackSprite.voxel_scale = VOXEL_SCALE）。
## 影は VoxelShade で主人公と同じように付ける（炎や魔法の弾は光っているので影を付けない）。作った模型は使い回す。
## 大きさは偶数にする（奇数だと真ん中に置いたとき本当の画面の半ピクセルずれる）。

const VOXEL_SCALE := 0.5

const SHAFT := Color("b07a46")
const ARROW_HEAD := Color("dfe7f0")
const POISON_HEAD := Color("8fdc5a")
const FEATHER := Color("f4f1ea")
const FEATHER_BAND := Color("d9463b")
const POISON_FEATHER := Color("5c9e3c")

## 矢の長さ（ボクセル）と、模型の大きさ。矢の真ん中が模型の真ん中に来る
const ARROW_LEN := 20
const ARROW_BOX := Vector3i(6, 22, 22)
## 傾きの段（この角度ごとに模型を作る）と、一番の傾き
const PITCH_STEP := PI / 12.0
const PITCH_MAX := PI * 5.0 / 12.0

static var _cache := {}

## 飛んでいる矢の模型。pitch は上向きを正とする傾き（ラジアン）。PITCH_STEP ごとにまとめて使い回す。
static func arrow_model(kind: Arrow.Kind, pitch: float) -> VoxelModel:
	var q := roundi(clampf(pitch, -PITCH_MAX, PITCH_MAX) / PITCH_STEP)
	var key := "arrow|%d|%d" % [kind, q]
	if not _cache.has(key):
		_cache[key] = VoxelShade.apply(arrow_raw(kind, q * PITCH_STEP))
	return _cache[key]

## 影をつける前の矢。前（+y）が矢じり。軸は1本、矢じりは横に広い三角、後ろに上下左右の羽根。
static func arrow_raw(kind: Arrow.Kind, pitch: float) -> VoxelModel:
	var m := VoxelModel.new()
	m.size = ARROW_BOX
	var center := Vector3(ARROW_BOX) / 2.0 - Vector3(0.5, 0.5, 0.5)
	var fwd := Vector3(0, cos(pitch), sin(pitch))
	var up := Vector3(0, -sin(pitch), cos(pitch))  # 矢から見た上
	var head_c := POISON_HEAD if kind == Arrow.Kind.POISON else ARROW_HEAD
	var feather_c := POISON_FEATHER if kind == Arrow.Kind.POISON else FEATHER
	var half := ARROW_LEN / 2.0
	# 軸（後ろから前へ、半ボクセルずつ置いて切れ目がないように）
	for i in range(0, ARROW_LEN * 2):
		var t := -half + i * 0.5
		_put(m, center + fwd * t, SHAFT)
	# 矢じり：先へいくほど細い
	for i in 4:
		var t := half - i
		var w := mini(i, 2)
		for dx in range(-w, w + 1):
			_put(m, center + fwd * t + Vector3(dx * 0.5, 0, 0), head_c)
			_put(m, center + fwd * t + up * (dx * 0.5), head_c)
	# 羽根：後ろの5つぶん、横と上下に2つ出す。真ん中に赤い帯
	for i in 5:
		var t := -half + 1 + i
		var c := FEATHER_BAND if i == 2 and kind == Arrow.Kind.NORMAL else feather_c
		for side in [-2, -1, 1, 2]:
			_put(m, center + fwd * t + Vector3(side, 0, 0), c)
			_put(m, center + fwd * t + up * side, c)
	return m

static func _put(m: VoxelModel, p: Vector3, c: Color) -> void:
	m.set_voxel(Vector3i(p.round()), c)

# ---------------------------------------------------------------- 小物

const STONE := Color("8d8f94")
const ASH := Color("3a3030")
const LOG := Color("7a4a2a")
const WOOD_LIGHT := Color("a8743f")
const WOOD_DARK := Color("6e4526")
const GOLD := Color("ffd23f")
const IRON := Color("5a5f6b")
const GRAVE_STONE := Color("d8d4e8")
const GRAVE_MARK := Color("6c5c9a")
const FLAME_COLORS := [Color("e8452c"), Color("ff7a2e"), Color("ffb347"), Color("ffe27a"), Color("fff6d0")]
const EXIT_ARROW := Color("ffe27a")
const EXIT_ARROW_EDGE := Color("c9932e")
const NULL_BOLT := Color("c8b6ff")
const FIRE_BOLT := Color("ff8a3d")
const BULLET := Color("ffd23f")

## たき火：石の輪・灰・組んだまき・燃える炎。frame（0〜2）で炎の形が少し変わる（ゆらめき）。
static func bonfire(frame := 0) -> VoxelModel:
	var key := "bonfire|%d" % frame
	if not _cache.has(key):
		var m := VoxelModel.new()
		m.size = Vector3i(24, 24, 28)
		var c := Vector2(11.5, 11.5)
		VoxelDraw.cylinder(m, c, 7.0, 0, 0, ASH)
		for i in 9:
			var a := TAU * i / 9.0
			var p := c + Vector2.from_angle(a) * 9.0
			var tone := STONE.darkened(0.1 * (i % 3))
			VoxelDraw.ellipsoid(m, Vector3(p.x, p.y, 1.5), Vector3(2.6, 2.6, 2.2), tone)
		for i in 4:
			var a := TAU * i / 4.0 + 0.4
			var foot := c + Vector2.from_angle(a) * 6.5
			VoxelDraw.rod(m, Vector3(foot.x, foot.y, 1.0), Vector3(c.x, c.y, 9.0), LOG if i % 2 == 0 else WOOD_DARK)
		var shaded := VoxelShade.apply(m)
		_flame(shaded, Vector3(c.x, c.y, 4.0), 4.2, 19, frame)
		_cache[key] = shaded
	return _cache[key]

## 炎（下が赤く、上ほど黄色く、真ん中は白っぽい）。base の高さから height だけ、半径 r から細くなる。
static func _flame(m: VoxelModel, base: Vector3, r: float, height: int, frame: int) -> void:
	for dz in height:
		var t := float(dz) / height
		var sway := sin(t * 5.0 + frame * 2.1) * 1.2 * t
		var rad := r * pow(1.0 - t, 0.75)
		if rad < 0.6:
			continue
		var cx := base.x + sway
		var cy := base.y + cos(t * 4.0 + frame * 1.7) * 0.8 * t
		for y in range(floori(cy - rad), ceili(cy + rad) + 1):
			for x in range(floori(cx - rad), ceili(cx + rad) + 1):
				var d := Vector2(x, y).distance_to(Vector2(cx, cy)) / rad
				if d > 1.0:
					continue
				# 炎の舌：ふちは上へいくほど切れ切れにする
				if d > 0.7 and VoxelDraw.hash3(x, y, dz + frame * 31, 4) == 0 and t > 0.3:
					continue
				var heat := clampf((1.0 - d) * 0.9 + (1.0 - t) * 0.35, 0.0, 1.0)
				var i := clampi(int(heat * FLAME_COLORS.size()), 0, FLAME_COLORS.size() - 1)
				m.set_voxel(Vector3i(x, y, int(base.z) + dz), FLAME_COLORS[i])

## 宝箱：板の箱にふた、金具の帯と、前の金の錠。前は +y。
static func chest() -> VoxelModel:
	if not _cache.has("chest"):
		var m := VoxelModel.new()
		m.size = Vector3i(22, 16, 16)
		VoxelDraw.fill(m, Vector3i(1, 1, 0), Vector3i(20, 14, 8), WOOD_LIGHT)
		for z in [2, 5]:
			VoxelDraw.fill(m, Vector3i(1, 1, z), Vector3i(20, 14, z), WOOD_DARK)  # 板の継ぎ目
		VoxelDraw.fill(m, Vector3i(2, 2, 0), Vector3i(19, 13, 8), WOOD_LIGHT)
		VoxelDraw.fill(m, Vector3i(1, 1, 9), Vector3i(20, 14, 9), WOOD_DARK)  # ふたの境目
		# 丸いふた
		for z in range(10, 15):
			var inset := maxi(0, z - 12)
			VoxelDraw.fill(m, Vector3i(1, 1 + inset, z), Vector3i(20, 14 - inset, z), WOOD_LIGHT)
		for x in [4, 5, 16, 17]:
			for p: Vector3i in m.voxels().keys():
				if p.x == x:
					m.set_voxel(p, IRON)
		VoxelDraw.fill(m, Vector3i(9, 15, 6), Vector3i(12, 15, 10), GOLD)
		m.set_voxel(Vector3i(10, 15, 7), WOOD_DARK)
		m.set_voxel(Vector3i(11, 15, 7), WOOD_DARK)
		_cache["chest"] = VoxelShade.apply(m)
	return _cache["chest"]

## 墓石：遠くからでも見つけやすい、背の高い白っぽい石。上は丸く、前に十字を彫る。下に台。前は +y。
static func grave() -> VoxelModel:
	if not _cache.has("grave"):
		var m := VoxelModel.new()
		m.size = Vector3i(22, 14, 46)
		VoxelDraw.fill(m, Vector3i(1, 1, 0), Vector3i(20, 12, 3), GRAVE_STONE.darkened(0.15))
		for z in range(4, 46):
			var half := 8.0
			if z > 36:
				half = sqrt(maxf(0.0, 64.0 - pow(z - 36.0, 2.0) * 0.75))
			if half < 1.0:
				continue
			VoxelDraw.fill(m, Vector3i(roundi(10.5 - half), 3, z), Vector3i(roundi(10.5 + half) - 1, 10, z), GRAVE_STONE)
		VoxelDraw.fill(m, Vector3i(9, 10, 12), Vector3i(12, 10, 36), GRAVE_MARK)
		VoxelDraw.fill(m, Vector3i(5, 10, 27), Vector3i(16, 10, 30), GRAVE_MARK)
		_cache["grave"] = VoxelShade.apply(m)
	return _cache["grave"]

## 門（閉じた出口のマス）：丸太を並べた柵。先はとがり、鉄の帯でしめてある。どの向きの出口でも同じに見えるよう、マスいっぱいの四角。
static func gate() -> VoxelModel:
	if not _cache.has("gate"):
		var m := VoxelModel.new()
		m.size = Vector3i(28, 28, 46)
		for gy in 4:
			for gx in 4:
				var c := Vector2(3.5 + gx * 7.0, 3.5 + gy * 7.0)
				var top := 38 + (gx + gy * 3) % 3 * 2
				var tone := LOG if (gx + gy) % 2 == 0 else LOG.darkened(0.12)
				VoxelDraw.cylinder(m, c, 3.6, 0, top, tone)
				for z in range(top + 1, top + 6):
					VoxelDraw.cylinder(m, c, 3.6 * (1.0 - (z - top) / 6.0), z, z, tone.lightened(0.1))
		for z0 in [8, 30]:
			for p: Vector3i in m.voxels().keys():
				if p.z >= z0 and p.z <= z0 + 2 and (p.x <= 1 or p.x >= 26 or p.y <= 1 or p.y >= 26):
					m.set_voxel(p, IRON)
		_cache["gate"] = VoxelShade.apply(m)
	return _cache["gate"]

## 落ちている物（拾いもの・敵の落とし物）。武器と防具は宝箱、強い鉄球は鉄球そのもの。
static func pickup(kind: RunState.PickupKind) -> VoxelModel:
	match kind:
		RunState.PickupKind.SWORD, RunState.PickupKind.BOW, RunState.PickupKind.STAFF_FIRE, RunState.PickupKind.ARMOR:
			return chest()
		RunState.PickupKind.STRONG_BALL:
			return HeroModel.ball_model(true)
	var key := "pickup|%d" % kind
	if not _cache.has(key):
		var m := VoxelModel.new()
		match kind:
			RunState.PickupKind.MONEY:
				# 金貨を3枚、少しずらして重ねる
				m.size = Vector3i(12, 12, 6)
				for i in 3:
					var c := Vector2(5.5 + (i % 2) * 1.5, 5.5 + (i / 2) * 1.0 - (i % 2))
					VoxelDraw.cylinder(m, c, 3.6, i * 2, i * 2 + 1, GOLD.darkened(0.25))
					VoxelDraw.cylinder(m, c, 2.6, i * 2 + 1, i * 2 + 1, GOLD)
			RunState.PickupKind.MATERIAL:
				# 素材：板の小箱
				m.size = Vector3i(10, 10, 8)
				VoxelDraw.fill(m, Vector3i(1, 1, 0), Vector3i(8, 8, 7), WOOD_LIGHT)
				for z in [0, 7]:
					VoxelDraw.fill(m, Vector3i(1, 1, z), Vector3i(8, 8, z), WOOD_DARK)
				VoxelDraw.rod(m, Vector3(1, 8, 0), Vector3(8, 1, 7), WOOD_DARK, 1)
			RunState.PickupKind.HEAL:
				# 回復の薬：丸いびん・首・せん・光
				m.size = Vector3i(10, 10, 14)
				VoxelDraw.ellipsoid(m, Vector3(4.5, 4.5, 4.0), Vector3(3.8, 3.8, 3.8), HeroModel.POTION)
				VoxelDraw.fill(m, Vector3i(4, 4, 8), Vector3i(5, 5, 10), HeroModel.GLASS_SHINE)
				VoxelDraw.fill(m, Vector3i(4, 4, 11), Vector3i(5, 5, 12), WOOD_DARK)
				m.set_voxel(Vector3i(3, 6, 6), HeroModel.GLASS_SHINE)
			RunState.PickupKind.ARROWS, RunState.PickupKind.POISON_ARROWS:
				# 矢の束：3本を横に寝かせてひもでしばる
				m.size = Vector3i(20, 8, 4)
				var head := POISON_HEAD if kind == RunState.PickupKind.POISON_ARROWS else ARROW_HEAD
				var feather := POISON_FEATHER if kind == RunState.PickupKind.POISON_ARROWS else FEATHER
				for i in 3:
					var y := 2 + i * 2
					var z := 1 if i == 1 else 0
					VoxelDraw.fill(m, Vector3i(3, y, z), Vector3i(16, y, z), SHAFT)
					VoxelDraw.fill(m, Vector3i(17, y, z), Vector3i(19, y, z), head)
					VoxelDraw.fill(m, Vector3i(0, y, z), Vector3i(3, y, z), feather)
					m.set_voxel(Vector3i(1, y - 1, z), feather)
					m.set_voxel(Vector3i(1, y + 1, z), feather)
				VoxelDraw.fill(m, Vector3i(9, 1, 0), Vector3i(10, 7, 2), FEATHER_BAND)
			_:
				m.size = Vector3i(8, 8, 8)
				VoxelDraw.ellipsoid(m, Vector3(3.5, 3.5, 3.5), Vector3.ONE * 3.6, HeroModel.STRONG_BALL)
		_cache[key] = VoxelShade.apply(m)
	return _cache[key]

## 出口の地面に置く、平たい矢印（ふちは少し暗い）。dir は向き（北＝(0,-1)、東＝(1,0) など）。
static func exit_arrow(dir: Vector2i = Vector2i(0, -1)) -> VoxelModel:
	var key := "exit|%d|%d" % [dir.x, dir.y]
	if not _cache.has(key):
		var n := 24
		var north := {}
		for y in 12:  # 矢じり
			for x in range(maxi(0, 11 - y), mini(n, 13 + y)):
				north[Vector2i(x, y)] = true
		for y in range(12, 24):  # 軸
			for x in range(8, 16):
				north[Vector2i(x, y)] = true
		var m := VoxelModel.new()
		m.size = Vector3i(n, n, 1)
		for q: Vector2i in north:
			var edge := false
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if not north.has(q + d):
					edge = true
			var p := q
			match dir:
				Vector2i(1, 0):
					p = Vector2i(n - 1 - q.y, q.x)
				Vector2i(0, 1):
					p = Vector2i(n - 1 - q.x, n - 1 - q.y)
				Vector2i(-1, 0):
					p = Vector2i(q.y, n - 1 - q.x)
			m.set_voxel(Vector3i(p.x, p.y, 0), EXIT_ARROW_EDGE if edge else EXIT_ARROW)
		_cache[key] = m
	return _cache[key]

## 魔法の弾。無の弾は紫の結晶（とがった玉）、火の玉は外が赤く中が黄色い玉。光っているので影は付けない。
static func bolt(fire: bool) -> VoxelModel:
	var key := "bolt|%s" % fire
	if not _cache.has(key):
		var m := VoxelModel.new()
		m.size = Vector3i(8, 8, 8)
		var c := Vector3(3.5, 3.5, 3.5)
		if fire:
			VoxelDraw.ellipsoid(m, c, Vector3.ONE * 3.7, Color("e8452c"))
			VoxelDraw.ellipsoid(m, c + Vector3(-0.4, -0.4, 0.4), Vector3.ONE * 2.6, FIRE_BOLT)
			VoxelDraw.ellipsoid(m, c + Vector3(-0.8, -0.8, 0.8), Vector3.ONE * 1.4, Color("ffe27a"))
		else:
			for z in 8:
				var r := 3.6 - absf(z - 3.5)
				for y in 8:
					for x in 8:
						if absf(x - 3.5) + absf(y - 3.5) <= r + 0.5:
							m.set_voxel(Vector3i(x, y, z), NULL_BOLT if absf(x - 3.5) + absf(y - 3.5) > r - 1.0 else Color("f1ebff"))
		_cache[key] = m
	return _cache[key]

## 撃つ敵の弾：黄色い玉（下は少し暗い）。
static func bullet() -> VoxelModel:
	if not _cache.has("bullet"):
		var m := VoxelModel.new()
		m.size = Vector3i(6, 6, 6)
		VoxelDraw.ellipsoid(m, Vector3(2.5, 2.5, 2.5), Vector3.ONE * 2.8, BULLET.darkened(0.25))
		VoxelDraw.ellipsoid(m, Vector3(2.3, 2.3, 2.9), Vector3.ONE * 2.0, BULLET)
		m.set_voxel(Vector3i(1, 1, 4), Color("fff6d0"))
		_cache["bullet"] = m
	return _cache["bullet"]

## 地面の小さな炎（燃え広がった火・炎の雨）。
static func flame(frame := 0) -> VoxelModel:
	var key := "flame|%d" % frame
	if not _cache.has(key):
		var m := VoxelModel.new()
		m.size = Vector3i(12, 12, 16)
		_flame(m, Vector3(5.5, 5.5, 0.0), 5.0, 16, frame)
		_cache[key] = m
	return _cache[key]

## 火柱：太い炎の柱。上ほど明るく、ところどころふくらむ。
static func pillar() -> VoxelModel:
	if not _cache.has("pillar"):
		var m := VoxelModel.new()
		m.size = Vector3i(16, 16, 80)
		for z in 80:
			var t := z / 80.0
			var r := 6.8 - 0.6 * float(z % 12) / 12.0 - 1.5 * t
			for y in 16:
				for x in 16:
					var d := Vector2(x - 7.5, y - 7.5).length() / r
					if d > 1.0:
						continue
					var heat := clampf((1.0 - d) * 0.8 + t * 0.5, 0.0, 1.0)
					m.set_voxel(Vector3i(x, y, z), FLAME_COLORS[clampi(int(heat * FLAME_COLORS.size()), 0, FLAME_COLORS.size() - 1)])
		_cache["pillar"] = m
	return _cache["pillar"]

## 炎の雨の降る範囲（地面の上の、すけた輪）。r はゲームの座標のpx。
static func rain_ring(r: float) -> VoxelModel:
	var key := "rain|%d" % ceili(r)
	if not _cache.has(key):
		var rr := ceili(r) * 2.0  # ボクセルで
		var n := int(rr) * 2
		var m := VoxelModel.new()
		m.size = Vector3i(n, n, 1)
		for y in n:
			for x in n:
				var d := Vector2(x - n / 2.0 + 0.5, y - n / 2.0 + 0.5).length()
				if d <= rr and d >= rr - 3.0:
					m.set_voxel(Vector3i(x, y, 0), Color(1.0, 0.55, 0.2, 0.9))
				elif d < rr - 3.0 and (x + y) % 5 == 0 and (x - y) % 3 == 0:
					m.set_voxel(Vector3i(x, y, 0), Color(1.0, 0.45, 0.15, 0.5))
		_cache[key] = m
	return _cache[key]

## 鉄球の落ちる所に出す、すけた丸い影。
static func aim_shadow() -> VoxelModel:
	if not _cache.has("aim_shadow"):
		var m := VoxelModel.new()
		m.size = Vector3i(12, 12, 1)
		for y in 12:
			for x in 12:
				var d := Vector2(x - 5.5, y - 5.5).length()
				if d <= 5.8:
					m.set_voxel(Vector3i(x, y, 0), Color(0, 0, 0, 0.4 if d < 4.5 else 0.25))
		_cache["aim_shadow"] = m
	return _cache["aim_shadow"]

## 魔法の弾で狙う高さに浮かべる、赤い四角の輪（角は空ける）。
static func aim_ring() -> VoxelModel:
	if not _cache.has("aim_ring"):
		var m := VoxelModel.new()
		m.size = Vector3i(16, 16, 1)
		for i in 16:
			for t in 2:
				for p in [Vector3i(i, t, 0), Vector3i(i, 15 - t, 0), Vector3i(t, i, 0), Vector3i(15 - t, i, 0)]:
					if (i >= 2 and i <= 13) or t == 0:
						m.set_voxel(p, Color("ff5050"))
		_cache["aim_ring"] = m
	return _cache["aim_ring"]

# ---------------------------------------------------------------- 全体の地図（2026-11-25）で足した物

## 商人：大きな荷物を背負い、つばの広い帽子をかぶった人。v で服の色を変える（0 道具屋・1 武器屋・2 旅の商人）。前は +y。
static func merchant(v := 0) -> VoxelModel:
	var key := "merchant/%d" % v
	if not _cache.has(key):
		var m := VoxelModel.new()
		m.size = Vector3i(24, 24, 40)
		var cloth: Color = [Color("4f7a3a"), Color("8a3a3a"), Color("5a4a8a")][v]
		var skin := Color("f0c49a")
		VoxelDraw.fill(m, Vector3i(8, 9, 0), Vector3i(10, 12, 5), Color("4a3020"))  # 足
		VoxelDraw.fill(m, Vector3i(13, 9, 0), Vector3i(15, 12, 5), Color("4a3020"))
		VoxelDraw.ellipsoid(m, Vector3(11.5, 11, 12), Vector3(6, 5, 7.5), cloth)  # 胴（長い服）
		VoxelDraw.fill(m, Vector3i(6, 10, 15), Vector3i(17, 12, 16), Color("c9a66b"))  # 帯
		VoxelDraw.ellipsoid(m, Vector3(11.5, 11.5, 25), Vector3(5, 5, 5), skin)  # 頭
		m.set_voxel(Vector3i(9, 16, 25), Color("2a1a10"))
		m.set_voxel(Vector3i(14, 16, 25), Color("2a1a10"))
		VoxelDraw.fill(m, Vector3i(9, 16, 22), Vector3i(14, 16, 22), Color("d79a7a"))  # ほほえみ
		VoxelDraw.cylinder(m, Vector2(11.5, 11.5), 9.0, 30, 30, Color("b08a4a"))  # 帽子のつば
		VoxelDraw.cylinder(m, Vector2(11.5, 11.5), 5.0, 31, 34, Color("a07a3a"))
		VoxelDraw.fill(m, Vector3i(6, 1, 8), Vector3i(17, 5, 26), Color("9a6a3a"))  # 背負った荷物
		VoxelDraw.fill(m, Vector3i(6, 1, 15), Vector3i(17, 5, 16), Color("6e4526"))
		VoxelDraw.fill(m, Vector3i(8, 0, 27), Vector3i(15, 4, 29), Color("d9d0b8"))  # 荷物の上の巻いた布
		_cache[key] = VoxelShade.apply(m)
	return _cache[key]

## ボスの像：台の上の、フードをかぶった大きな石の像。ボスがまだいないので、居場所の目印に置く。
## tint でボスごとに石の色を変える。前は +y。
static func statue(tint := Color("9a968e")) -> VoxelModel:
	var key := "statue/" + tint.to_html()
	if not _cache.has(key):
		var m := VoxelModel.new()
		m.size = Vector3i(30, 30, 62)
		VoxelDraw.fill(m, Vector3i(1, 1, 0), Vector3i(28, 28, 7), Color("8a857c"))
		VoxelDraw.fill(m, Vector3i(3, 3, 8), Vector3i(26, 26, 9), Color("a39e94"))
		VoxelDraw.ellipsoid(m, Vector3(14.5, 14.5, 26), Vector3(10, 8, 17), tint)  # 体
		VoxelDraw.ellipsoid(m, Vector3(14.5, 14.5, 46), Vector3(7, 7, 8), tint.darkened(0.08))  # 頭（フード）
		VoxelDraw.fill(m, Vector3i(11, 21, 44), Vector3i(18, 22, 48), Color("2a2530"))  # 顔の影
		m.set_voxel(Vector3i(12, 22, 46), Color("ffd23f"))  # 目が光る
		m.set_voxel(Vector3i(17, 22, 46), Color("ffd23f"))
		VoxelDraw.rod(m, Vector3(4, 16, 18), Vector3(6, 20, 34), tint.darkened(0.12), 3)  # 腕
		VoxelDraw.rod(m, Vector3(25, 16, 18), Vector3(23, 20, 34), tint.darkened(0.12), 3)
		_cache[key] = VoxelShade.apply(m)
	return _cache[key]

## ひびの入った岩：上から鉄球を落とすと砕ける（仕掛け）。黒い割れ目が上から入っている。
static func crack_rock() -> VoxelModel:
	if not _cache.has("crack"):
		var m := VoxelModel.new()
		m.size = Vector3i(30, 30, 26)
		VoxelDraw.ellipsoid(m, Vector3(14.5, 14.5, 9), Vector3(14, 14, 15), Color("9a8f82"), func(p): return p.z >= 0)
		for p: Vector3i in m.voxels().keys():
			var on_crack := absi(p.x - 15 - int(sin(p.y * 0.5) * 2.0)) <= 0 or absi(p.y - 9 - p.x / 3) <= 0
			if on_crack and p.z > 4:
				m.set_voxel(p, Color("2a2420"))
			elif (p.x + p.y + p.z) % 7 == 0:
				m.set_voxel(p, Color("8a8074"))
		_cache["crack"] = VoxelShade.apply(m)
	return _cache["crack"]

## 茨：とげのある黒っぽい枝のからまり。炎の魔法で燃える（仕掛け）。
static func thorns() -> VoxelModel:
	if not _cache.has("thorns"):
		var m := VoxelModel.new()
		m.size = Vector3i(30, 30, 26)
		for i in 14:
			var a := Vector3(VoxelDraw.hash3(i, 1, 0, 28) + 1, VoxelDraw.hash3(i, 2, 0, 28) + 1, 0)
			var b := Vector3(VoxelDraw.hash3(i, 3, 0, 28) + 1, VoxelDraw.hash3(i, 4, 0, 28) + 1, 12 + VoxelDraw.hash3(i, 5, 0, 12))
			VoxelDraw.rod(m, a, b, Color("4a3a4a") if i % 2 == 0 else Color("3a4a32"), 2)
		for p: Vector3i in m.voxels().keys():
			if VoxelDraw.hash3(p.x, p.y, p.z, 9) == 0:
				m.set_voxel(p + Vector3i(0, 0, 1), Color("d9d0e0"))  # とげ
			elif VoxelDraw.hash3(p.x, p.y, p.z, 23) == 0:
				m.set_voxel(p, Color("9a3a6a"))  # 実
		_cache["thorns"] = VoxelShade.apply(m)
	return _cache["thorns"]

## つた：上の枝から垂れた、太いつたの幕。剣で斬れる（仕掛け）。
static func vines() -> VoxelModel:
	if not _cache.has("vines"):
		var m := VoxelModel.new()
		m.size = Vector3i(30, 30, 40)
		VoxelDraw.rod(m, Vector3(0, 14, 36), Vector3(29, 15, 37), Color("6e4526"), 3)  # 上の枝
		for i in 12:
			var x := 1 + i * 2.4
			var y := 14.5 + sin(i * 1.7) * 3.0
			var bottom := VoxelDraw.hash3(i, 7, 0, 5)
			for z in range(bottom, 36):
				var sway := sin(z * 0.35 + i) * 1.2
				var c := Color("3f8a3a") if (z + i) % 5 != 0 else Color("62b04a")
				m.set_voxel(Vector3i(roundi(x + sway * 0.3), roundi(y + sway), z), c)
				if (z + i * 3) % 7 == 0:
					m.set_voxel(Vector3i(roundi(x + sway * 0.3) + 1, roundi(y + sway), z), Color("7cc24c"))  # 葉
		_cache["vines"] = VoxelShade.apply(m)
	return _cache["vines"]

## 弓の的：杭の上の、赤と白の丸い的。hit なら当たった後（緑に変わり、矢が刺さっている）。
static func target(hit := false) -> VoxelModel:
	var key := "target/%d" % int(hit)
	if not _cache.has(key):
		var m := VoxelModel.new()
		m.size = Vector3i(24, 24, 44)
		VoxelDraw.fill(m, Vector3i(10, 10, 0), Vector3i(13, 13, 26), WOOD_DARK)
		var c := Vector2(11.5, 32)
		for z in range(22, 43):
			for x in 24:
				var d := Vector2(x, z).distance_to(c)
				if d > 10.0:
					continue
				var ring := int(d / 2.5)
				var col := (Color("e83a2e") if ring % 2 == 0 else Color("f4efe4")) if not hit else (Color("5aa83a") if ring % 2 == 0 else Color("e4f4d4"))
				VoxelDraw.fill(m, Vector3i(x, 12, z), Vector3i(x, 13, z), col)
		if hit:
			VoxelDraw.rod(m, Vector3(11, 13, 32), Vector3(11, 22, 34), SHAFT, 1)
		_cache[key] = VoxelShade.apply(m)
	return _cache[key]
