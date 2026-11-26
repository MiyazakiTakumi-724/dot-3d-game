class_name Boulder
extends RefCounted
## 転がる岩（2026-11-26 独自の開発1）【提案】。高低差を活かす戦いの1つ。
## 崖のふちの高い所に置いてあり、F で押すか剣・鉄球・爆弾を当てると、押した向きへまっすぐ転がる。
## 低い所へは落ちて、落ちた段数ほど速く・痛くなる。同じ高さか高い所・壁にぶつかると砕ける（ひびの岩・もろい壁なら壊す）。
## 奈落と島の外へは落ちて消え、水には沈む。通り道の敵にぶつかると、敵の体力の割合で痛い（落ちた段数で増える）。
## 置いてある間はマスをふさぐ（HeightMap.Blocker.BOULDER）。エリアに入るたびに元の所へ戻る（field.gd）。

enum State { REST, ROLLING, GONE }

const DIRS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
## 転がる速さ（px/秒）と、1段落ちるごとに増える速さ（6段まで）
const SPEED := 110.0
const SPEED_PER_LEVEL := 22.0
## 先のマスを調べる距離（岩の半径くらい）
const LEAD := 6.0
## 当たる広さ（px）
const RADIUS := 10.0
## 置く所：落ちる先がこの段数より低い
const MIN_DROP := 2
## 置く所どうしを離すマス数（チェビシェフ距離）
const APART := 3
## 敵へのダメージ：最大体力 ×（BASE ＋ 落ちた段数 × PER_LEVEL）。ボスは BOSS_* を使う
const BASE := 0.3
const PER_LEVEL := 0.15
const BOSS_BASE := 0.04
const BOSS_PER_LEVEL := 0.02
## 主人公へのダメージ（自分で押した岩の前に飛び降りたとき）
const PLAYER_BASE := 8
const PLAYER_PER_LEVEL := 3
## 押された敵が飛ばされる距離（px）
const KNOCK := 20.0

var map: HeightMap
var pos: Vector2
var height := 0
var dir := Vector2.ZERO
var state := State.REST
## 転がりだしてから落ちた段数
var fallen := 0
## 置いてあった所
var home := Vector2i.ZERO
## 砕けたときにぶつかったマス（ひびの岩・もろい壁を壊すのに使う）
var crash_cell := Vector2i(-1, -1)
var _cur := Vector2i.ZERO
var _hit := {}

func _init(m: HeightMap, cell: Vector2i) -> void:
	map = m
	home = cell
	_cur = cell
	pos = HeightMap.cell_center(cell)
	height = map.get_height(cell)
	map.set_blocker(cell, HeightMap.Blocker.BOULDER)

func cell() -> Vector2i:
	return HeightMap.world_to_cell(pos)

func resting() -> bool:
	return state == State.REST

func rolling() -> bool:
	return state == State.ROLLING

func speed() -> float:
	return SPEED + SPEED_PER_LEVEL * mini(fallen, 6)

## 向き d へ押す。いちばん近い縦横の向きにそろえる。となりが壁か高い所なら動かない（false）。
func push(d: Vector2) -> bool:
	if state != State.REST or d == Vector2.ZERO:
		return false
	var axis := Vector2(signf(d.x), 0.0) if absf(d.x) >= absf(d.y) else Vector2(0.0, signf(d.y))
	var next := cell() + Vector2i(axis)
	if map.is_wall(next) and not map.is_void(next):
		return false
	if map.in_bounds(next) and map.get_height(next) > height:
		return false
	map.set_blocker(cell(), HeightMap.Blocker.NONE)
	dir = axis
	state = State.ROLLING
	fallen = 0
	_hit.clear()
	return true

## 1回の転がりで、同じ相手（id）には1回だけ当たる。当ててよければ true。
func can_hit(id) -> bool:
	if _hit.has(id):
		return false
	_hit[id] = true
	return true

## 敵へのダメージ。
func damage_to(max_hp: int, boss := false) -> int:
	var rate := (BOSS_BASE + BOSS_PER_LEVEL * fallen) if boss else (BASE + PER_LEVEL * fallen)
	return clampi(ceili(max_hp * rate), 1, max_hp)

## ふつうの敵（体力100）へのダメージの目安。
func damage() -> int:
	return damage_to(100)

func player_damage() -> int:
	return PLAYER_BASE + PLAYER_PER_LEVEL * fallen

## 進める。合図を返す："" 転がっている・"drop" 低い所へ落ちた・"crash" ぶつかって砕けた・"fall" 奈落か島の外へ落ちた・"sink" 水に沈んだ。
func update(delta: float) -> String:
	if state != State.ROLLING:
		return ""
	var next := pos + dir * speed() * delta
	var lc := HeightMap.world_to_cell(next + dir * LEAD)
	if lc != _cur:
		if map.is_void(lc):
			pos = next
			state = State.GONE
			return "fall"
		if map.is_wall(lc) or map.get_height(lc) > height:
			crash_cell = lc
			state = State.GONE
			return "crash"
	pos = next
	var here := HeightMap.world_to_cell(pos)
	if here == _cur:
		return ""
	_cur = here
	if map.is_pit(here):
		state = State.GONE
		return "fall"
	if map.is_water(here):
		state = State.GONE
		return "sink"
	var h := map.get_height(here)
	if h < height:
		fallen += height - h
		height = h
		return "drop"
	return ""

## 消す（エリアを出るときなど）。置いてあればマスのふさぎを外す。
func remove() -> void:
	if state == State.REST:
		map.set_blocker(cell(), HeightMap.Blocker.NONE)
	state = State.GONE

# ---------------------------------------------------------------- 置く所

## 置く所を選ぶ。高さ2以上で、となりに MIN_DROP 段以上低い歩ける所があり、その反対側に同じ高さの立てる所（押す所）がある。
## avoid のマスと、細い道をふさぐ所（そのマスを除くと、まわりがつながらなくなる所）には置かない。
## 落ちる段数が大きい所を先に選び、同じなら seed で決まる順。count まで。
static func spots(m: HeightMap, avoid: Dictionary, count: int, seed_value: int) -> Array:
	var cands: Array = []
	for y in m.size.y:
		for x in m.size.x:
			var c := Vector2i(x, y)
			if avoid.has(c) or not _open(m, c):
				continue
			var h := m.get_height(c)
			if h < MIN_DROP:
				continue
			var best := 0
			for d in DIRS:
				var front: Vector2i = c + d
				var behind: Vector2i = c - d
				if not _open(m, front) and not m.is_pit(front):
					continue
				if not _open(m, behind) or m.get_height(behind) != h or avoid.has(behind):
					continue
				var drop := h - m.get_height(front)
				if drop >= MIN_DROP:
					best = maxi(best, drop)
			if best == 0 or _cuts(m, c):
				continue
			var key := hash([seed_value, x, y]) % 100000
			cands.append([-best, key, c])
	cands.sort()
	var out: Array = []
	for cand in cands:
		if out.size() >= count:
			break
		var c: Vector2i = cand[2]
		var near := false
		for o in out:
			if maxi(absi(o.x - c.x), absi(o.y - c.y)) < APART:
				near = true
				break
		if not near:
			out.append(c)
	return out

## 歩いて入れるマス（壁・ふさぐもの・水・奈落・島の外でない）。
static func _open(m: HeightMap, c: Vector2i) -> bool:
	return m.in_bounds(c) and not m.is_wall(c) and not m.is_water(c) and not m.is_pit(c)

## c をふさぐと、c のまわり（となりで高さの差1段まで）が、c を通らずにつながらなくなるか。
## まわり3マスの中だけで調べる（遠回りの道は数えない）。
static func _cuts(m: HeightMap, c: Vector2i) -> bool:
	var h := m.get_height(c)
	var around: Array = []
	for d in DIRS:
		var n: Vector2i = c + d
		if _open(m, n) and absi(m.get_height(n) - h) <= 1:
			around.append(n)
	if around.size() <= 1:
		return false
	var seen := {around[0]: true}
	var todo: Array = [around[0]]
	while not todo.is_empty():
		var p: Vector2i = todo.pop_back()
		for d in DIRS:
			var q: Vector2i = p + d
			if q == c or seen.has(q) or not _open(m, q):
				continue
			if maxi(absi(q.x - c.x), absi(q.y - c.y)) > 3:
				continue
			if absi(m.get_height(q) - m.get_height(p)) > 1:
				continue
			seen[q] = true
			todo.append(q)
	for n in around:
		if not seen.has(n):
			return true
	return false
