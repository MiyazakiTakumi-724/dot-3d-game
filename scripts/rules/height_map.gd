class_name HeightMap
extends RefCounted
## マスごとの高さ（段）と壁。

const CELL_PX := 16

var size: Vector2i
var _heights: PackedInt32Array
var _walls: PackedByteArray

func _init(map_size: Vector2i) -> void:
	size = map_size
	_heights.resize(size.x * size.y)
	_walls.resize(size.x * size.y)

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

## マップの外は壁として扱う（外へは出られない）。
func is_wall(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return true
	return _walls[cell.y * size.x + cell.x] == 1
