class_name Bullet
extends RefCounted
## 敵の弾。壁のマスに触れると消える。段差は越えて飛ぶ（防げるのは壁だけ）。

const SAMPLE_PX := 4.0

var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var height: int = 0
var alive := true

func step(delta: float, map: HeightMap) -> void:
	if not alive:
		return
	var move := vel * delta
	# 速くても壁をすり抜けないよう、通り道を4px刻みで調べる
	var samples := maxi(1, ceili(move.length() / SAMPLE_PX))
	for i in range(1, samples + 1):
		var p := pos + move * (float(i) / samples)
		if map.is_wall(HeightMap.world_to_cell(p)):
			pos = p
			alive = false
			return
	pos += move
