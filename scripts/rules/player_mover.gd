class_name PlayerMover
extends RefCounted
## 高さを考えたプレイヤーの移動。段差は近づくだけで自動で登る（ジャンプはない）。

var map: HeightMap
var rules: MovementRules
var pos: Vector2 = Vector2.ZERO
var height: int = 0
var facing: Vector2 = Vector2.DOWN
## 奈落に踏み込んだら true。以後 move は何もしない。
var fell := false
## 最後に立っていた奈落以外のマス。奈落で死んだときの墓石の場所に使う。
var last_safe_cell: Vector2i
## 直前の move でマップの外へ歩こうとして止まった向き（外向き、1軸だけ）。なければ ZERO。
## エリアの端の出口を外へ歩いたかを調べるのに使う。
var edge_push: Vector2i = Vector2i.ZERO
## 最後に飛び降りた（下の段へ移った）段数と、それからの秒数。落下斬りに使う
var last_drop := 0
var since_drop := INF
## 技能「よじ登り」：2段の段差を、押し続けると CLIMB_SECONDS で登れる
var slow_climb := false
const CLIMB_SECONDS := 0.6
var _climb_time := 0.0
var _climb_pushed := false

func _init(height_map: HeightMap, movement_rules: MovementRules) -> void:
	map = height_map
	rules = movement_rules

## マスの中心に置き直す（再開するときなど）。
func place(c: Vector2i) -> void:
	pos = HeightMap.cell_center(c)
	height = map.get_height(c)
	fell = false
	last_safe_cell = c
	last_drop = 0
	since_drop = INF

## world_delta だけ動く。delta（秒）はよじ登りで押し続けた時間を数えるのに使う。
func move(world_delta: Vector2, delta := 0.0) -> void:
	edge_push = Vector2i.ZERO
	_climb_pushed = false
	if fell or world_delta == Vector2.ZERO:
		_climb_time = 0.0
		return
	facing = world_delta.normalized()
	if not _try(pos + world_delta):
		# 斜めに壁へ当たったときは、動ける方の軸だけ動かして壁沿いに滑らせる
		if not _try(pos + Vector2(world_delta.x, 0)):
			_try(pos + Vector2(0, world_delta.y))
	if _climb_pushed:
		_climb_time += delta
		if _climb_time >= CLIMB_SECONDS:
			_climb_time = 0.0
			_climb_up(world_delta)
	else:
		_climb_time = 0.0

## よじ登りの進み具合（0〜1）。見た目用。
func climb_progress() -> float:
	return _climb_time / CLIMB_SECONDS

## 押していた2段上のマスへ登る。マスの境目を少し越えた所に立つ。
func _climb_up(world_delta: Vector2) -> void:
	var dir := world_delta.normalized()
	var p := pos
	for i in HeightMap.CELL_PX:
		p += dir
		var c := HeightMap.world_to_cell(p)
		if c != cell():
			if not map.in_bounds(c) or map.is_wall(c) or map.is_water(c) or map.is_pit(c):
				return
			height = map.get_height(c)
			last_safe_cell = c
			pos = p + dir
			return

func tick(delta: float) -> void:
	since_drop += delta

## window 秒のうちに飛び降りていれば、その段数。なければ0。
func recent_drop(window: float) -> int:
	return last_drop if since_drop <= window else 0

## 目の前のマス。マスの中心から1マス分先を見るので、斜めを向いていても必ず隣のマスになる。
func front_cell() -> Vector2i:
	return HeightMap.world_to_cell(HeightMap.cell_center(cell()) + facing * HeightMap.CELL_PX)

func cell() -> Vector2i:
	return HeightMap.world_to_cell(pos)

func _try(new_pos: Vector2) -> bool:
	var to := HeightMap.world_to_cell(new_pos)
	if to != cell():
		if not map.in_bounds(to):
			if to.x < 0 or to.x >= map.size.x:
				edge_push = Vector2i(signi(to.x - cell().x), 0)
			else:
				edge_push = Vector2i(0, signi(to.y - cell().y))
			return false
		if map.is_wall(to) or map.is_water(to):
			return false
		if map.is_pit(to):
			# 奈落は高さに関係なく踏み込めて、そのまま落ちる
			fell = true
			pos = new_pos
			return true
		var to_h := map.get_height(to)
		if not rules.can_step(height, to_h):
			if slow_climb and to_h - height == rules.max_climb + 1:
				_climb_pushed = true
			return false
		if to_h < height:
			last_drop = height - to_h
			since_drop = 0.0
		height = to_h
		last_safe_cell = to
	pos = new_pos
	return true
