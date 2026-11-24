class_name Bullet
extends RefCounted
## 敵の弾。撃った敵の高さ（height）を飛び、壁のマスと、弾より高い地面（崖の側面）に触れると消える。
## 低い所の上は、その高さのまま飛び越える。

var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var height: int = 0
var alive := true

func step(delta: float, map: HeightMap) -> void:
	if not alive:
		return
	var move := vel * delta
	var hit := _first_wall_on_path(pos, pos + move, map, height)
	if hit >= 0.0:
		pos += move * hit
		alive = false
		return
	pos += move

## target に立っている、高さ target_height のものに当たるか。同じ高さで、距離が radius 未満のときだけ。
func hits(target: Vector2, target_height: int, radius: float) -> bool:
	return alive and target_height == height and pos.distance_to(target) < radius

## from から to までの線が通るマスを順に調べ（グリッドを1マスずつたどる）、
## 最初に壁（または bullet_height より高い地面）へ入る位置を 0〜1 の割合で返す。なければ -1。
## 点を間引いて調べないので、壁の角をかすめても必ず当たる。
static func _first_wall_on_path(from: Vector2, to: Vector2, map: HeightMap, bullet_height: int) -> float:
	var size := float(HeightMap.CELL_PX)
	var c := HeightMap.world_to_cell(from)
	var end := HeightMap.world_to_cell(to)
	if _blocks(map, c, bullet_height):
		return 0.0
	var d := to - from
	var step_x := 1 if d.x > 0 else -1
	var step_y := 1 if d.y > 0 else -1
	var t_delta_x := INF if d.x == 0 else size / absf(d.x)
	var t_delta_y := INF if d.y == 0 else size / absf(d.y)
	var next_x := (c.x + (1 if step_x > 0 else 0)) * size
	var next_y := (c.y + (1 if step_y > 0 else 0)) * size
	var t_max_x := INF if d.x == 0 else (next_x - from.x) / d.x
	var t_max_y := INF if d.y == 0 else (next_y - from.y) / d.y
	while c != end:
		var t: float
		if t_max_x < t_max_y:
			t = t_max_x
			c.x += step_x
			t_max_x += t_delta_x
		else:
			t = t_max_y
			c.y += step_y
			t_max_y += t_delta_y
		if t > 1.0:
			break
		if _blocks(map, c, bullet_height):
			return t
	return -1.0

static func _blocks(map: HeightMap, c: Vector2i, bullet_height: int) -> bool:
	return map.is_wall(c) or map.get_height(c) > bullet_height
