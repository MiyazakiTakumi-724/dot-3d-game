class_name EnemyWalker
extends RefCounted
## 敵の歩き方と体力。自分の段と同じ高さのマスだけを往復する。

signal died

const SPEED := 24.0
const MAX_HP := 3

var map: HeightMap
var pos: Vector2
var dir: Vector2
var height: int
var hp: int = MAX_HP
var alive := true

func _init(height_map: HeightMap, start_cell: Vector2i, start_dir: Vector2) -> void:
	map = height_map
	pos = HeightMap.cell_center(start_cell)
	dir = start_dir.normalized()
	height = map.get_height(start_cell)

func cell() -> Vector2i:
	return HeightMap.world_to_cell(pos)

func step(delta: float) -> void:
	if not alive:
		return
	# 体の半分先（8px）のマスを見て、入れなければ引き返す
	var ahead := HeightMap.world_to_cell(pos + dir * (HeightMap.CELL_PX * 0.5 + 0.1))
	if ahead != cell() and (map.is_wall(ahead) or map.get_height(ahead) != height):
		dir = -dir
		return
	pos += dir * SPEED * delta

func take_damage(n: int) -> void:
	if not alive:
		return
	hp -= n
	if hp <= 0:
		hp = 0
		alive = false
		died.emit()
