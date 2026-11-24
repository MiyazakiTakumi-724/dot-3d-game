class_name Bullet
extends RefCounted
## 敵の弾。撃った点から狙った点へまっすぐ飛ぶ（高さ z も一定の傾き slope で変わる）。
## 壁のマスと、弾より高い地面（崖の側面や、下へ向けて撃った先の地面）に触れると消える。
## 高い所から撃たれると下まで届き、下から撃つと崖に当たりやすい（高所の有利）。
## aim を使わずに height だけ決めた弾は、その段の体の真ん中の高さを水平に飛ぶ。

const CENTER_PX := 4.0  ## 体の真ん中の高さ（地面から px）
const BODY_PX := 8.0  ## 立っている体の高さ（px）

var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
## 撃った敵の段（描くときの土台）
var height: int = 0
## 弾の高さ（px）。NAN なら height の体の真ん中
var z: float = NAN
var slope := 0.0  ## 1px進むごとの高さの変化
## 当たったときに与えるダメージ（撃った敵の攻撃力）
var damage: int = 1
var alive := true

## from（段 from_h）から、target に立つ段 target_h の相手の体の真ん中へ向けて、speed px/秒で撃つ。
func aim(from: Vector2, from_h: int, target: Vector2, target_h: int, speed: float) -> void:
	pos = from
	height = from_h
	z = from_h * 8.0 + CENTER_PX
	var d := target - from
	var dist := d.length()
	if dist < 1.0:
		d = Vector2.RIGHT
		dist = 1.0
	vel = d / dist * speed
	slope = (target_h * 8.0 + CENTER_PX - z) / dist

func get_z() -> float:
	return height * 8.0 + CENTER_PX if is_nan(z) else z

func step(delta: float, map: HeightMap) -> void:
	if not alive:
		return
	var move := vel * delta
	var z0 := get_z()
	var z1 := z0 + slope * move.length()
	var hit := _first_wall_on_path(pos, pos + move, map, z0, z1)
	if hit >= 0.0:
		pos += move * hit
		z = z0 + (z1 - z0) * hit
		alive = false
		return
	pos += move
	z = z1

## target に立っている、段 target_height のものに当たるか。距離が radius 未満で、弾の高さが体の中（足元から BODY_PX まで）のとき。
## 撃った敵より高い所に立つものには当たらない（下から上へは攻撃できない）。
func hits(target: Vector2, target_height: int, radius: float) -> bool:
	var rel := get_z() - target_height * 8.0
	return alive and Damage.can_hit(height, target_height) and rel >= -1.0 and rel < BODY_PX - 1.0 and pos.distance_to(target) < radius

## from から to までの線が通るマスを順に調べ（グリッドを1マスずつたどる）、
## 最初に壁か、弾より高い地面へ入る位置を 0〜1 の割合で返す。なければ -1。弾の高さは z0 から z1 へまっすぐ変わる。
## 点を間引いて調べないので、壁の角をかすめても必ず当たる。下りの弾は、マスの途中で地面に着いた所で止まる。
static func _first_wall_on_path(from: Vector2, to: Vector2, map: HeightMap, z0: float, z1: float) -> float:
	var size := float(HeightMap.CELL_PX)
	var c := HeightMap.world_to_cell(from)
	if _blocks(map, c, z0):
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
	while true:
		var t := minf(t_max_x, t_max_y)
		var t_end := minf(t, 1.0)
		# 今のマスの中で、下りの弾が地面に着くか
		var ground := map.get_height(c) * 8.0
		var z_end := z0 + (z1 - z0) * t_end
		if z_end < ground:
			return clampf((ground - z0) / (z1 - z0), 0.0, t_end)
		if t > 1.0:
			break
		if t_max_x < t_max_y:
			c.x += step_x
			t_max_x += t_delta_x
		else:
			c.y += step_y
			t_max_y += t_delta_y
		if _blocks(map, c, z0 + (z1 - z0) * t):
			return t
	return -1.0

static func _blocks(map: HeightMap, c: Vector2i, z_px: float) -> bool:
	return map.is_wall(c) or map.get_height(c) * 8.0 > z_px
