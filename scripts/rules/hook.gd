class_name Hook
extends RefCounted
## 鉤縄（2026-11-26 独自の開発1。テラリアの鉤縄から）。R でカーソルの所へ投げる。
## ・1〜3段高い地面（届くのは RANGE まで）にかかると、そこへ体を引き上げる。高い所を素早く取れる。
## ・敵にかかると、その敵を手前へ引き寄せる。高い所にいる敵は段差から引きずり下ろされ、落ちた段数で痛い（EnemyWalker.knock）。
##   飛ぶ敵・重い敵（黒騎士・擬態箱）は動かない。下から上へは攻撃できない決まりでも、引き下ろしてから斬れる。
## 町の道具屋で買う（大事な物。死んでも墓石に入らない）。

const ID := "hook"
const RANGE := 56.0
const MAX_UP := 3
const COOLDOWN := 1.0
const PULL_TIME := 0.32
## 敵を引き寄せて、主人公からこの距離で止める
const PULL_STOP := 14.0

var cooldown := 0.0

func update(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)

func is_ready() -> bool:
	return cooldown <= 0.0

func use() -> void:
	cooldown = COOLDOWN

## aim（地面の点）のマスへ体を引き上げられるなら、そのマス。だめなら (-1, -1)。
static func ledge(map: HeightMap, from_pos: Vector2, from_h: int, aim: Vector2) -> Vector2i:
	var c := HeightMap.world_to_cell(aim)
	var none := Vector2i(-1, -1)
	if not map.in_bounds(c) or map.is_wall(c) or map.is_pit(c) or map.is_water(c) or map.is_void(c):
		return none
	var h := map.get_height(c)
	if h <= from_h or h > from_h + MAX_UP:
		return none
	if from_pos.distance_to(HeightMap.cell_center(c)) > RANGE:
		return none
	return c

## 敵に届くか。
static func reaches(from_pos: Vector2, enemy_pos: Vector2) -> bool:
	return from_pos.distance_to(enemy_pos) <= RANGE
