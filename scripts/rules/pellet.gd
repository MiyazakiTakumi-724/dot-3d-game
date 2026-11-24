class_name Pellet
## まっすぐ飛ぶ弾（魔法の無の弾・火の玉）。撃った点から狙った点（高さも含めた3Dの点）へまっすぐ飛び、そのまま同じ傾きで進む。
## 高さ z（px、地面の高さ×8が基準）が、そのマスの地面より低くなるか、壁に入ると止まる。
## 跳弾（bounces が残っている）なら、壁で1回はね返る。墓石に当たると止まり、hit_grave にそのマスを入れる。

const SPEED := 240.0
const RANGE := 200.0  ## これだけ進むと消える（px）
const HIT_RADIUS := 6.0
const SUBSTEP := 2.0  ## 何pxごとにマスを調べるか
const BODY_PX := 8.0  ## 敵の体の高さ（px）

var pos: Vector2
var z := 0.0
var vel: Vector2
var slope := 0.0  ## 1px進むごとの高さの変化
var bounces := 0
var alive := true
var traveled := 0.0
var hit_grave := Vector2i(-1, -1)

## from（高さ from_z px）から target（高さ target_z px）へ向けて撃つ。
func aim(from: Vector2, from_z: float, target: Vector2, target_z: float, ricochets := 0) -> void:
	pos = from
	z = from_z
	var d := target - from
	var dist := d.length()
	if dist < 1.0:
		d = Vector2.RIGHT
		dist = 1.0
	vel = d / dist * SPEED
	slope = (target_z - from_z) / dist
	bounces = ricochets
	alive = true
	traveled = 0.0

func step(delta: float, map: HeightMap) -> void:
	var left := SPEED * delta
	while alive and left > 0.0:
		var s := minf(SUBSTEP, left)
		left -= s
		_substep(s, map)

func _substep(s: float, map: HeightMap) -> void:
	var dir := vel.normalized()
	var np := pos + dir * s
	var nz := z + slope * s
	var oc := HeightMap.world_to_cell(pos)
	var nc := HeightMap.world_to_cell(np)
	if not map.in_bounds(nc):
		alive = false
		return
	if map.is_grave(nc):
		hit_grave = nc
		alive = false
		return
	if map.is_wall(nc):
		if bounces <= 0:
			alive = false
			return
		bounces -= 1
		var flipped := false
		if nc.x != oc.x and map.is_wall(Vector2i(nc.x, oc.y)):
			vel.x = -vel.x
			flipped = true
		if nc.y != oc.y and map.is_wall(Vector2i(oc.x, nc.y)):
			vel.y = -vel.y
			flipped = true
		if not flipped:
			vel = -vel
		return
	if nz < map.get_height(nc) * 8.0:
		alive = false  # 地面（崖の側面や、下へ向けて撃った先の地面）に当たった
		return
	pos = np
	z = nz
	traveled += s
	if traveled >= RANGE:
		alive = false

## target に立つ、高さ target_h のものの体に当たっているか。
func hits_body(target: Vector2, target_h: int) -> bool:
	var base := target_h * 8.0
	return alive and pos.distance_to(target) < HIT_RADIUS and z >= base - 1.0 and z <= base + BODY_PX + 1.0
