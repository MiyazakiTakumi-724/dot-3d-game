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

func _init(height_map: HeightMap, start_cell: Vector2i, start_dir: Vector2, hp_max: int = MAX_HP, climb_levels: int = 0) -> void:
	map = height_map
	hp = hp_max
	max_hp = hp_max
	climb = climb_levels
	pos = HeightMap.cell_center(start_cell)
	dir = start_dir.normalized()
	height = map.get_height(start_cell)

func cell() -> Vector2i:
	return HeightMap.world_to_cell(pos)

## 近くにいる target（高さ target_h）へ向きを変える。step() の前に毎フレーム呼ぶ。
func chase(target: Vector2, target_h: int) -> void:
	_chasing = false
	if climb <= 0 or not alive:
		return
	var d := target - pos
	if d.length() > CHASE_RANGE or d == Vector2.ZERO or absi(target_h - height) > climb:
		return
	dir = d.normalized()
	_chasing = true
	_chase_target = target

func can_enter(c: Vector2i) -> bool:
	if map.is_wall(c) or map.is_pit(c) or map.is_water(c) or forbidden.has(c):
		return false
	return absi(map.get_height(c) - height) <= climb

func step(delta: float) -> void:
	if not alive:
		return
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
	pos += v * SPEED * delta
	height = map.get_height(cell())
	return true

## pos に立っている、高さ h のものに触れているか。
func touches(p: Vector2, h: int) -> bool:
	return alive and h == height and pos.distance_to(p) < TOUCH_RADIUS

## 毒にする（毒矢）。seconds 秒の間、毎秒1ダメージ。もう毒なら長い方にする。
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
		dmg += 1
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
