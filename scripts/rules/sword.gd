class_name Sword
extends RefCounted
## 剣（design.md 7章、17.3）。向いている方の前、扇の形（左右60°、22pxまで）に当たる。
## 当たるのは同じ高さと1段下。1段上には、ランク2の特性か技能「斬り上げ」で届く。
## 段差を飛び降りてすぐ（0.35秒以内）に振ると「落下斬り」になり、落ちた段数の分だけ強くなる。

const INTERVAL := 0.4  ## 振る間隔（秒）
const REACH := 22.0  ## 体の中心から届く距離（px）
const HALF_ARC := PI / 3.0  ## 正面から左右にこの角度まで
const CLOSE := 6.0  ## これより近いものは、向きに関係なく当たる
const FALL_WINDOW := 0.35  ## 飛び降りてからこの秒数のうちに振ると落下斬り
const SPIN_INTERVAL := 0.8  ## 回転斬り（技能）の後、次に振れるまで【提案】

var cooldown := 0.0

func update(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)

## 振れれば振って true。振った後 INTERVAL の間は振れない。
func try_swing() -> bool:
	if cooldown > 0.0:
		return false
	cooldown = INTERVAL
	return true

## 回転斬り（技能）。振れれば true。
func try_spin() -> bool:
	if cooldown > 0.0:
		return false
	cooldown = SPIN_INTERVAL
	return true

## 回転斬り：向きに関係なく、周りの REACH の中に当たる（高さの決まりは普通の一振りと同じ）。
static func hits_around(origin: Vector2, h: int, target: Vector2, target_h: int, reach_up := false) -> bool:
	var dh := target_h - h
	if dh < -1 or dh > (1 if reach_up else 0):
		return false
	return origin.distance_to(target) <= REACH

## 1段上へ届くか：ランク2以上の剣か、技能「斬り上げ」を覚えている。
static func reaches_up(rank: int, has_upswing: bool) -> bool:
	return rank >= 2 or has_upswing

## origin（高さ h）から facing の向きに振って、target（高さ target_h）に当たるか。
static func hits(origin: Vector2, h: int, facing: Vector2, target: Vector2, target_h: int, reach_up := false) -> bool:
	var dh := target_h - h
	if dh < -1 or dh > (1 if reach_up else 0):
		return false
	var d := target - origin
	var dist := d.length()
	if dist > REACH:
		return false
	if dist < CLOSE:
		return true
	return absf(facing.angle_to(d)) <= HALF_ARC
