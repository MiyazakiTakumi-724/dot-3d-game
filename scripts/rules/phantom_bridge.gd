class_name PhantomBridge
extends RefCounted
## 幻の橋（2026-11-26 独自の開発1）【提案】。カメラの回転を活かす仕掛け。
## 高い所のふち（start）の床に「瞳の印」があり、印の目が向く方（dir）を画面の上にして見たときだけ、
## 向こうの高い所（goal）へ渡る橋が見えて、歩ける。ほかの向きから見ると、橋はない（下の地面へ落ちる）。
## 「灯りの瞳」：物の本当の姿を、向きを変えて見る力（ゲームの名前）。向こう側には記憶のかけらや宝が置いてある。
## 橋の下は、奈落・水でない低い地面（落ちても死なない）。goal は、歩いては行けない高い所。

## 見える向きのはば（ラジアン）。この内なら橋がある
const SHOW := PI / 7.0
## 見えはじめる向きのはば（うすく光る）
const HINT := PI / 2.5
## 向きを外しても、乗っている間はこの秒だけ消えない
const GRACE := 0.6
## 橋の長さ（すきまのマス数）
const MIN_GAP := 1
const MAX_GAP := 3
## 橋の下は、この段数より低い
const MIN_DROP := 2

const DIRS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

var start := Vector2i.ZERO
var goal := Vector2i.ZERO
var dir := Vector2i.RIGHT
var height := 0
## 橋のマスと、その元の高さ
var cells: Array[Vector2i] = []
var _under: Array[int] = []
var solid := false
var _grace := 0.0
## 見える向きのはばの倍率（装飾品「瞳の首飾り」で広がる）
var view_scale := 1.0
## 向こうの柱（低い地面を高くして作る、2×2）。宝はここに置く
var pillar: Array[Vector2i] = []

static func make(m: HeightMap, s: Vector2i, d: Vector2i, gap: int) -> PhantomBridge:
	var b := PhantomBridge.new()
	b.start = s
	b.dir = d
	b.height = m.get_height(s)
	for i in range(1, gap + 1):
		var c := s + d * i
		b.cells.append(c)
		b._under.append(m.get_height(c))
	b.goal = s + d * (gap + 1)
	return b

## 見る向き（カメラの angle）。dir を画面の上にする角度。
func view_angle() -> float:
	return Vector2(dir).angle() + PI / 2.0

## angle からどれだけ外れているか（0〜PI）。
func off(angle: float) -> float:
	return absf(angle_difference(angle, view_angle()))

## 見えるか（橋がある）。
func shows(angle: float) -> bool:
	return off(angle) <= SHOW * view_scale

## 絵の濃さ（0〜1）。SHOW の内は1、HINT の外は0、その間はうすく光る。
func alpha(angle: float) -> float:
	var o := off(angle)
	var show := SHOW * view_scale
	var hint := maxf(HINT, show + 0.2)
	if o <= show:
		return 1.0
	if o >= hint:
		return 0.0
	return 0.35 * (1.0 - (o - show) / (hint - show))

func has(c: Vector2i) -> bool:
	return cells.has(c)

## カメラの向きと、主人公の立つマスで、橋をかける・外す。変わったら true。
func update(m: HeightMap, angle: float, standing: Vector2i, delta: float) -> bool:
	var want := shows(angle)
	if not want and solid and cells.has(standing):
		_grace += delta
		if _grace < GRACE:
			want = true  # 乗っている間は、少しだけ待つ
	else:
		_grace = 0.0
	if want == solid:
		return false
	set_solid(m, want)
	return true

func set_solid(m: HeightMap, on: bool) -> void:
	solid = on
	for i in cells.size():
		m.set_height(cells[i], height if on else _under[i])

# ---------------------------------------------------------------- 置く所

## 橋をかける所を探す。reach は歩いて行けるマス。start は行ける高い所で、goal は行けない同じ高さの所。
## そのあいだ（MIN_GAP〜MAX_GAP マス）は、奈落・水・壁でない MIN_DROP 段以上低い地面。
## start の後ろ（-dir）も同じ高さの行ける所（橋へ向かって歩ける）。goal の向こうの広さが大きいものを先に、同じなら seed の順。
static func find(m: HeightMap, reach: Dictionary, avoid: Dictionary, seed_value: int) -> PhantomBridge:
	var best: PhantomBridge = null
	var best_key := []
	for s in reach:
		if avoid.has(s):
			continue
		var h := m.get_height(s)
		if h < MIN_DROP or not _ground(m, s):
			continue
		for d: Vector2i in DIRS:
			var back: Vector2i = s - d
			if not reach.has(back) or m.get_height(back) != h:
				continue
			for gap in range(MIN_GAP, MAX_GAP + 1):
				var ok := true
				for i in range(1, gap + 1):
					var c: Vector2i = s + d * i
					if not _ground(m, c) or m.get_height(c) > h - MIN_DROP or avoid.has(c):
						ok = false
						break
				if not ok:
					break
				var g: Vector2i = s + d * (gap + 1)
				if not _ground(m, g) or reach.has(g) or m.get_height(g) != h:
					continue
				var room := region(m, g, reach).size()
				var key := [-room, gap, hash([seed_value, s.x, s.y, d.x, d.y]) % 100000]
				if best == null or key < best_key:
					best = make(m, s, d, gap)
					best_key = key
				break
	return best

## 柱を立てて橋をかける所を探す（地図に行けない高い所がないとき）。行ける高い所 start のふちから dir へ、
## gap マスの低い地面の先に、2×2 の柱（高さ start と同じ）を立てる。柱のまわり（斜めも）は MIN_DROP 段以上低く、
## 柱を立てても、まわりの行けるマスどうしが（柱を通らずに）つながったまま。決まったら柱は立てずに返す（raise で立てる）。
static func plan(m: HeightMap, reach: Dictionary, avoid: Dictionary, seed_value: int, tries := 3000) -> PhantomBridge:
	var cands: Array = []
	for s in reach:
		if avoid.has(s) or not _ground(m, s):
			continue
		var h := m.get_height(s)
		if h < MIN_DROP + 1:
			continue
		for d: Vector2i in DIRS:
			var back: Vector2i = s - d
			if reach.has(back) and m.get_height(back) == h:
				for gap in range(MIN_GAP, MAX_GAP + 1):
					cands.append([hash([seed_value, s.x, s.y, d.x, d.y, gap]) % 1000003, s, d, gap])
	cands.sort()
	for i in mini(tries, cands.size()):
		var c = cands[i]
		var b := _try_pillar(m, reach, avoid, c[1], c[2], c[3])
		if b != null:
			return b
	return null

static func _try_pillar(m: HeightMap, reach: Dictionary, avoid: Dictionary, s: Vector2i, d: Vector2i, gap: int) -> PhantomBridge:
	var h := m.get_height(s)
	for i in range(1, gap + 1):
		var c: Vector2i = s + d * i
		if not _ground(m, c) or m.get_height(c) > h - MIN_DROP or avoid.has(c):
			return null
	var g: Vector2i = s + d * (gap + 1)
	var side := Vector2i(d.y, d.x)
	for p: Vector2i in [side, -side]:
		var cells: Array[Vector2i] = [g, g + p, g + d, g + d + p]
		var ok := true
		for c in cells:
			if not _ground(m, c) or not reach.has(c) or avoid.has(c) or m.get_height(c) > h - MIN_DROP:
				ok = false
				break
		if not ok:
			continue
		# まわり（斜めも）は低いまま。登って上がれないように
		for c in cells:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var n: Vector2i = c + Vector2i(dx, dy)
					if cells.has(n) or not m.in_bounds(n):
						continue
					if not m.is_wall(n) and m.get_height(n) > h - MIN_DROP:
						ok = false
		if not ok or _splits(m, reach, cells):
			continue
		var b := make(m, s, d, gap)
		b.pillar = cells
		return b
	return null

## 柱を立てる（橋のマスは元の高さのまま）。
func raise(m: HeightMap) -> void:
	for c in pillar:
		m.set_height(c, height)

## 柱のマスをふさぐと、まわりの行けるマスが（まわり5マスの中で）つながらなくなるか。
static func _splits(m: HeightMap, reach: Dictionary, cells: Array[Vector2i]) -> bool:
	var block := {}
	for c in cells:
		block[c] = true
	var center: Vector2i = cells[0]
	var around: Array = []
	for c in cells:
		for d in DIRS:
			var n: Vector2i = c + d
			if not block.has(n) and reach.has(n) and not around.has(n):
				around.append(n)
	if around.size() <= 1:
		return false
	var seen := {around[0]: true}
	var todo: Array = [around[0]]
	while not todo.is_empty():
		var p: Vector2i = todo.pop_back()
		for d in DIRS:
			var q: Vector2i = p + d
			if seen.has(q) or block.has(q) or not reach.has(q):
				continue
			if maxi(absi(q.x - center.x), absi(q.y - center.y)) > 5:
				continue
			if absi(m.get_height(q) - m.get_height(p)) > 1:
				continue
			seen[q] = true
			todo.append(q)
	for n in around:
		if not seen.has(n):
			return true
	return false

## goal から、行けないマスだけを通ってつながる高い所（同じ高さか1段の差）。宝を置く所に使う。
static func region(m: HeightMap, g: Vector2i, reach: Dictionary) -> Array:
	var seen := {g: true}
	var todo: Array = [g]
	while not todo.is_empty() and seen.size() < 64:
		var p: Vector2i = todo.pop_back()
		for d in DIRS:
			var q: Vector2i = p + d
			if seen.has(q) or reach.has(q) or not _ground(m, q) or absi(m.get_height(q) - m.get_height(p)) > 1:
				continue
			seen[q] = true
			todo.append(q)
	return seen.keys()

## 立てる地面（壁・水・奈落・島の外でない）。
static func _ground(m: HeightMap, c: Vector2i) -> bool:
	return m.in_bounds(c) and not m.is_wall(c) and not m.is_water(c) and not m.is_pit(c)
