class_name Wanderer
extends RefCounted
## 町の人が歩きまわる（2026-11-27。ユーザーの「村人ランダムに歩かせて」）。
## 家（home）のまわりの歩いてよいマス（area。field.gd が、まわり8マスも同じ高さの平らな所だけを選ぶ）を、
## となりのマスへ1つずつ、ゆっくり歩く。1〜STEPS_MAX マス同じ向きに歩いたら、少し立ち止まる。
## 歩いている間は、出たマスと向かうマスの両方をふさぐ（occupied。field.gd がそのマスに Blocker.NPC を置く）。
## 行けるかどうか（主人公・敵・ほかの人がいないか）は、update に渡す is_free で決める。

## 歩く速さ（px／秒。主人公よりずっと遅い）
const SPEED := 18.0
## 立ち止まる時間（秒）
const WAIT_MIN := 1.5
const WAIT_MAX := 4.5
## 一度に同じ向きへ歩くマスの数の上限
const STEPS_MAX := 3
## 話したあと、立ち止まる時間（秒）
const TALK_PAUSE := 3.0
## 歩くときにはねる高さ（px）。半マスごとに、はねる・着くをくり返す
const BOB := 1.0
const BOB_STEP := 4.0

const DIRS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

var home := Vector2i.ZERO
var area := {}
## 今いるマス（歩いている間は向かうマス）と、出たマス
var cell := Vector2i.ZERO
var from_cell := Vector2i.ZERO
var pos := Vector2.ZERO
var moving := false
## 向いている向き（ワールド）
var facing := Vector2.DOWN
var wait := 0.0
var _hold := 0.0
var _left := 0
var _dir := Vector2i.ZERO
var _walked := 0.0
var rng := RandomNumberGenerator.new()

static func make(home_cell: Vector2i, cells: Dictionary, seed_value: int) -> Wanderer:
	var w := Wanderer.new()
	w.home = home_cell
	w.area = cells
	w.cell = home_cell
	w.from_cell = home_cell
	w.pos = HeightMap.cell_center(home_cell)
	w.rng.seed = seed_value
	w.wait = w.rng.randf_range(WAIT_MIN, WAIT_MAX)
	return w

## ふさいでいるマス。
func occupied() -> Array[Vector2i]:
	if moving:
		return [from_cell, cell]
	return [cell]

## 少しの間、新しく歩きださない（今のマスへ歩いている途中なら、着いてから止まる）。
func hold(t: float) -> void:
	_hold = maxf(_hold, t)
	_left = 0

## 歩くときにはねる高さ。
func lift() -> float:
	if not moving:
		return 0.0
	return BOB if fmod(_walked, BOB_STEP * 2.0) < BOB_STEP else 0.0

func update(delta: float, is_free: Callable) -> void:
	_hold = maxf(0.0, _hold - delta)
	if moving:
		_walk(delta, is_free)
		return
	wait -= delta
	if wait > 0.0 or _hold > 0.0:
		return
	var dirs := DIRS.duplicate()
	for i in range(dirs.size() - 1, 0, -1):  # 同じ seed なら同じ順に混ぜる
		var j := rng.randi_range(0, i)
		var t: Vector2i = dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = t
	for d: Vector2i in dirs:
		if _try_step(d, is_free):
			_left = rng.randi_range(1, STEPS_MAX)
			return
	wait = rng.randf_range(WAIT_MIN, WAIT_MAX) * 0.5  # どこへも行けない。少しして、また探す

func _walk(delta: float, is_free: Callable) -> void:
	var target := HeightMap.cell_center(cell)
	var to := target - pos
	var step := SPEED * delta
	if to.length() > step:
		pos += to.normalized() * step
		_walked += step
		return
	pos = target
	_walked += to.length()
	moving = false
	from_cell = cell
	_left -= 1
	if _left > 0 and _hold <= 0.0 and _try_step(_dir, is_free):
		return
	_walked = 0.0
	wait = rng.randf_range(WAIT_MIN, WAIT_MAX)

func _try_step(d: Vector2i, is_free: Callable) -> bool:
	var n := cell + d
	if not area.has(n) or not is_free.call(n):
		return false
	from_cell = cell
	cell = n
	_dir = d
	moving = true
	facing = Vector2(d)
	return true
