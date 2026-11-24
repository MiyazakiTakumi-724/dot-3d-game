class_name ExitDef
extends RefCounted
## エリアの出口。エリアの辺の一部（from〜to のマス、両端を含む）で、そこから外へ歩くと target のエリアへ行く。
## 北・南の辺は x の範囲、東・西の辺は y の範囲。door_id があれば門で閉じた出口で、開けるまで通れない。

enum Edge { NORTH, EAST, SOUTH, WEST }

var edge: Edge = Edge.NORTH
var from: int = 0
var to: int = 0
var target: String = ""
## 空でなければ門で閉じた出口（RunState.open_door で開ける）
var door_id: String = ""
## このエリアの側から門を開けられる
var opens_here := false

## 外向きの向き。
static func dir(e: Edge) -> Vector2i:
	match e:
		Edge.NORTH:
			return Vector2i(0, -1)
		Edge.EAST:
			return Vector2i(1, 0)
		Edge.SOUTH:
			return Vector2i(0, 1)
	return Vector2i(-1, 0)

func outward() -> Vector2i:
	return ExitDef.dir(edge)

## 出口のマス（エリアの中の座標）。
func cells(size: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i in range(from, to + 1):
		match edge:
			Edge.NORTH:
				out.append(Vector2i(i, 0))
			Edge.SOUTH:
				out.append(Vector2i(i, size.y - 1))
			Edge.WEST:
				out.append(Vector2i(0, i))
			Edge.EAST:
				out.append(Vector2i(size.x - 1, i))
	return out

func has_cell(c: Vector2i, size: Vector2i) -> bool:
	return cells(size).has(c)
