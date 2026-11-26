class_name EnemyWalker
extends RefCounted
## 敵の歩き方と体力。往復して歩き、入れないマスの前で引き返す。奈落・水・壁・forbidden には入らない。
## 登り降りできる段数は climb（敵1は0で平らな所だけ、敵2は1）。
## climb が1以上の敵は、chase() で近くのプレイヤーへ寄っていく。
## 体当たり：同じ高さで体が触れているかを touches() で調べる。

signal died

const SPEED := 24.0
const MAX_HP := 3
## 体当たりになる、中心どうしの距離（px）。敵の体は8px、プレイヤーは6px。
const TOUCH_RADIUS := 9.0
## 体当たりの範囲（大きい敵・ボスは広い。2026-11-26）
var touch_radius := TOUCH_RADIUS
const CHASE_RANGE := 48.0  ## これより近いと寄ってくる（3マス）
const CHASE_STOP := 10.0  ## これより近づいたら止まる（重ならないように）

var map: HeightMap
var pos: Vector2
var dir: Vector2
var height: int
var hp: int = MAX_HP
var max_hp: int = MAX_HP
var alive := true
## 登り降りできる段数
var climb := 0
## 入らないマス（出口の近くなど）。Vector2i → true
var forbidden := {}
var _poison_left := 0.0
var _poison_clock := 0.0
var _burning := false
var _chasing := false
var _chase_target := Vector2.ZERO
## 速さの倍率（敵の種類・突進）
var speed_mult := 1.0
## 寄ってくる距離（px）。0なら寄らない
var chase_range := CHASE_RANGE
## 飛ぶ敵（コウモリ）：水・奈落・段差・壁の上も進む（マップの外へは出ない）
var flying := false
var _slow_left := 0.0
## 遅くなっている間の速さの倍率
const SLOW_MULT := 0.5
## 毒・やけどの1秒ごとのダメージ（2026-11-25 夜に1から上げた。敵の体力を上げたので）
const DOT_DAMAGE := 2

func _init(height_map: HeightMap, start_cell: Vector2i, start_dir: Vector2, hp_max: int = MAX_HP, climb_levels: int = 0) -> void:
	map = height_map
	hp = hp_max
	max_hp = hp_max
	climb = climb_levels
	chase_range = CHASE_RANGE if climb > 0 else 0.0  # 種類ごとの値は Enemy が入れる
	pos = HeightMap.cell_center(start_cell)
	dir = start_dir.normalized()
	height = map.get_height(start_cell)

func cell() -> Vector2i:
	return HeightMap.world_to_cell(pos)

# ---------------------------------------------------------------- 突き飛ばし（2026-11-26 独自の開発1）
## 剣・鉄球・爆弾で押されると、少しの間すべる。下への段差はいくつでも落ち（climb は関係ない）、上と壁と水には入らない。
## 奈落へ落ちると倒れる。2段以上落ちると、落ちた段数で痛い（fall_damage）。高い所から突き落とすのが、上を取る強み。
const KNOCK_SPEED := 160.0
## 1段より多く落ちたとき、1段ごとに最大いのちのこの割合
const FALL_PER_LEVEL := 0.15
var _knock_vel := Vector2.ZERO
var _knock_left := 0.0
var _knock_drop := 0
## 最後に突き飛ばされて落ちた段数と、そのダメージ（画面に出す用）
var last_fall_levels := 0
var last_fall_damage := 0
## 突き飛ばされて奈落へ落ちた
var fell_into_pit := false

## levels 段落ちたときのダメージ。1段までは0。
static func fall_damage(hp_max: int, levels: int) -> int:
	if levels <= 1:
		return 0
	return mini(hp_max, ceili(hp_max * FALL_PER_LEVEL * (levels - 1)))

## d の向きへ dist px 突き飛ばす。飛ぶ敵は押されない。
func knock(d: Vector2, dist: float) -> void:
	if not alive or flying or dist <= 0.0 or d == Vector2.ZERO:
		return
	if not knocking():
		_knock_drop = 0
	_knock_vel = d.normalized() * KNOCK_SPEED
	_knock_left = maxf(_knock_left, dist / KNOCK_SPEED)

func knocking() -> bool:
	return alive and _knock_left > 0.0

## 突き飛ばされて動く。この呼び出しで止まったら true（落ちた段数とダメージは last_fall_*）。
func update_knock(delta: float) -> bool:
	if not knocking():
		return false
	var t := minf(delta, _knock_left)
	_knock_left -= t
	var v := _knock_vel * t
	for axis in [Vector2(v.x, 0.0), Vector2(0.0, v.y)]:
		if axis == Vector2.ZERO or not _knock_axis(axis):
			continue
		if not alive:
			return true
	if _knock_left > 0.0:
		return false
	_knock_left = 0.0
	last_fall_levels = _knock_drop
	last_fall_damage = fall_damage(max_hp, _knock_drop)
	_knock_drop = 0
	if last_fall_damage > 0:
		take_damage(last_fall_damage)
	return true

## 1軸だけ動かす。入れないマスなら止める。動けたら true。
func _knock_axis(v: Vector2) -> bool:
	var np := pos + v
	var c := HeightMap.world_to_cell(np)
	if c != cell():
		if map.is_pit(c):
			pos = np
			fell_into_pit = true
			last_fall_levels = height
			_knock_left = 0.0
			take_damage(hp)
			return true
		if map.is_wall(c) or map.is_water(c) or forbidden.has(c) or map.get_height(c) > height:
			_knock_left = 0.0
			return false
		_knock_drop += height - map.get_height(c)
		height = map.get_height(c)
	pos = np
	return true

## 近くにいる target（高さ target_h）へ向きを変える。step() の前に毎フレーム呼ぶ。
func chase(target: Vector2, target_h: int) -> void:
	_chasing = false
	if chase_range <= 0.0 or not alive:
		return
	var d := target - pos
	if d.length() > chase_range or d == Vector2.ZERO or (not flying and absi(target_h - height) > climb):
		return
	dir = d.normalized()
	_chasing = true
	_chase_target = target

func can_enter(c: Vector2i) -> bool:
	if flying:
		return map.in_bounds(c) and not forbidden.has(c)
	if map.is_wall(c) or map.is_pit(c) or map.is_water(c) or forbidden.has(c):
		return false
	return absi(map.get_height(c) - height) <= climb

func step(delta: float) -> void:
	if not alive:
		return
	_slow_left = maxf(0.0, _slow_left - delta)
	var chasing := _chasing
	_chasing = false
	if chasing and pos.distance_to(_chase_target) < CHASE_STOP:
		return
	if _try(dir, delta):
		return
	if chasing:
		return  # 追っている間は引き返さず、止まって待つ
	dir = -dir

## d の向きに進む。斜めのときは x と y を1軸ずつ動かし、それぞれ体の半分先（8px）のマスを確かめる
## （まとめて動かすと、マスの角をすり抜けて入れないマスに入ることがあるため）。少しでも進めたら true。
func _try(d: Vector2, delta: float) -> bool:
	var moved := false
	if d.x != 0.0:
		moved = _try_axis(Vector2(d.x, 0), delta) or moved
	if d.y != 0.0:
		moved = _try_axis(Vector2(0, d.y), delta) or moved
	return moved

func _try_axis(v: Vector2, delta: float) -> bool:
	var ahead := HeightMap.world_to_cell(pos + v.sign() * (HeightMap.CELL_PX * 0.5 + 0.1))
	if ahead != cell() and not can_enter(ahead):
		return false
	pos += v * SPEED * speed_mult * (SLOW_MULT if _slow_left > 0.0 else 1.0) * delta
	if not flying or not (map.is_wall(cell()) or map.is_pit(cell())):
		height = maxi(0, map.get_height(cell()))
	return true

## 遅くする（氷のつぶて・霜の武器）。もう遅ければ長い方にする。
func slow(seconds: float) -> void:
	if alive:
		_slow_left = maxf(_slow_left, seconds)

func is_slowed() -> bool:
	return alive and _slow_left > 0.0

## pos に立っている、高さ h のものに触れているか。
func touches(p: Vector2, h: int) -> bool:
	return alive and h == height and pos.distance_to(p) < touch_radius

## 毒にする（毒矢）。seconds 秒の間、毎秒 DOT_DAMAGE。もう毒なら長い方にする。
func poison(seconds: float) -> void:
	if not alive:
		return
	_burning = false
	_start_dot(seconds)

## やけど（火の魔法）。毒と同じく毎秒1ダメージ（同時にはどちらか1つ）。
func burn(seconds: float) -> void:
	if not alive:
		return
	_burning = true
	_start_dot(seconds)

func is_burning() -> bool:
	return is_poisoned() and _burning

func _start_dot(seconds: float) -> void:
	if _poison_left <= 0.0:
		_poison_clock = 0.0
	_poison_left = maxf(_poison_left, seconds)

func is_poisoned() -> bool:
	return alive and _poison_left > 0.0

## 毒の時間を進める。この間に入ったダメージを返す。
func update_poison(delta: float) -> int:
	if not is_poisoned():
		return 0
	var dmg := 0
	var step := minf(delta, _poison_left)
	_poison_left -= step
	_poison_clock += step
	while _poison_clock >= 1.0 - 0.0001:
		_poison_clock -= 1.0
		dmg += DOT_DAMAGE
	if dmg > 0:
		take_damage(dmg)
	if _poison_left <= 0.0001:
		_poison_left = 0.0
	return dmg

func take_damage(n: int) -> void:
	if not alive:
		return
	hp -= n
	if hp <= 0:
		hp = 0
		alive = false
		died.emit()
