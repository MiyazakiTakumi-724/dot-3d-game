class_name HeightMap
extends RefCounted
## マスごとの高さ（段）と壁。奈落と、壁のようにふさぐもの（墓石・閉じた扉）も持つ。

const CELL_PX := 16

## 壁のように通れなくするもの。NONE に戻すと元の地形になる。
enum Blocker { NONE, GRAVE, DOOR }

var size: Vector2i
var _heights: PackedInt32Array
var _walls: PackedByteArray
var _pits: PackedByteArray
var _water: PackedByteArray
var _blockers: PackedByteArray

func _init(map_size: Vector2i) -> void:
	size = map_size
	_heights.resize(size.x * size.y)
	_walls.resize(size.x * size.y)
	_pits.resize(size.x * size.y)
	_water.resize(size.x * size.y)
	_blockers.resize(size.x * size.y)

static func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL_PX), floori(p.y / CELL_PX))

static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_PX + Vector2(CELL_PX, CELL_PX) * 0.5

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y

func set_height(cell: Vector2i, h: int) -> void:
	if in_bounds(cell):
		_heights[cell.y * size.x + cell.x] = h

func get_height(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return 0
	return _heights[cell.y * size.x + cell.x]

func set_wall(cell: Vector2i, wall: bool) -> void:
	if in_bounds(cell):
		_walls[cell.y * size.x + cell.x] = 1 if wall else 0

## マップの外は壁として扱う（外へは出られない）。ふさぐものがあるマスも壁。
func is_wall(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return true
	var i := cell.y * size.x + cell.x
	return _walls[i] == 1 or _blockers[i] != Blocker.NONE

## 奈落：踏み込むと落ちて死ぬマス。マップの外は奈落ではない。
func set_pit(cell: Vector2i, pit: bool) -> void:
	if in_bounds(cell):
		_pits[cell.y * size.x + cell.x] = 1 if pit else 0

func is_pit(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return false
	return _pits[cell.y * size.x + cell.x] == 1

## 水：入れないが、壁ではないので弾は上を飛ぶ。
func set_water(cell: Vector2i, water: bool) -> void:
	if in_bounds(cell):
		_water[cell.y * size.x + cell.x] = 1 if water else 0

func is_water(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return false
	return _water[cell.y * size.x + cell.x] == 1

func set_blocker(cell: Vector2i, kind: Blocker) -> void:
	if in_bounds(cell):
		_blockers[cell.y * size.x + cell.x] = kind

func get_blocker(cell: Vector2i) -> Blocker:
	if not in_bounds(cell):
		return Blocker.NONE
	return _blockers[cell.y * size.x + cell.x] as Blocker

func is_grave(cell: Vector2i) -> bool:
	return get_blocker(cell) == Blocker.GRAVE
