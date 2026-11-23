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

func _init(height_map: HeightMap, movement_rules: MovementRules) -> void:
	map = height_map
	rules = movement_rules

## マスの中心に置き直す（再開するときなど）。
func place(c: Vector2i) -> void:
	pos = HeightMap.cell_center(c)
	height = map.get_height(c)
	fell = false
	last_safe_cell = c

func move(world_delta: Vector2) -> void:
	if fell or world_delta == Vector2.ZERO:
		return
	facing = world_delta.normalized()
	if _try(pos + world_delta):
		return
	# 斜めに壁へ当たったときは、動ける方の軸だけ動かして壁沿いに滑らせる
	if not _try(pos + Vector2(world_delta.x, 0)):
		_try(pos + Vector2(0, world_delta.y))

## 目の前のマス。マスの中心から1マス分先を見るので、斜めを向いていても必ず隣のマスになる。
func front_cell() -> Vector2i:
	return HeightMap.world_to_cell(HeightMap.cell_center(cell()) + facing * HeightMap.CELL_PX)

func cell() -> Vector2i:
	return HeightMap.world_to_cell(pos)

func _try(new_pos: Vector2) -> bool:
	var to := HeightMap.world_to_cell(new_pos)
	if to != cell():
		if map.is_wall(to) or map.is_water(to):
			return false
		if map.is_pit(to):
			# 奈落は高さに関係なく踏み込めて、そのまま落ちる
			fell = true
			pos = new_pos
			return true
		var to_h := map.get_height(to)
		if not rules.can_step(height, to_h):
			return false
		height = to_h
		last_safe_cell = to
	pos = new_pos
	return true
