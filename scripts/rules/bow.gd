class_name Bow
extends RefCounted
## 弓（design.md 7章、17.4）。左ボタンを押している間に溜め、離すと撃つ。
## チャージ率は、すぐ離すと0.3、約1秒溜めると1.0（その間は直線的に増える）。チャージで飛距離も伸びる。
## 矢はカーソルの所へ山なりに飛び、壁を越える。届かなければ手前に落ちる。高い所から撃つほど遠くへ届く。

const FULL_CHARGE := 1.0  ## これだけ溜めるとチャージ率1.0（秒）
const MIN_RATE := 0.3
const BASE_RANGE := 120.0  ## 平らな所でフルチャージのときに届く距離（px、7.5マス）【提案】
const RANGE_PER_LEVEL := 16.0  ## 1段高い所から撃つと、これだけ遠くへ届く（低い所へは逆）【提案】
const MIN_RANGE := 8.0

var charging := false
var charge_time := 0.0

func start() -> void:
	charging = true
	charge_time = 0.0

func cancel() -> void:
	charging = false
	charge_time = 0.0

func update(delta: float) -> void:
	if charging:
		charge_time += delta

func rate() -> float:
	return MIN_RATE + (1.0 - MIN_RATE) * clampf(charge_time / FULL_CHARGE, 0.0, 1.0)

## 離して撃つ。そのときのチャージ率を返す。溜めていなければ0（撃たない）。
func release() -> float:
	if not charging:
		return 0.0
	var r := rate()
	cancel()
	return r

## チャージ率 r で、dh 段低い所（高い所なら負）へ届く距離。
static func max_range(r: float, dh: int) -> float:
	return maxf(MIN_RANGE, BASE_RANGE * r + RANGE_PER_LEVEL * dh)

## from（高さ from_h）から target を狙って、チャージ率 r で撃ったときに落ちる点。
## 届けば target、届かなければ同じ向きの、届く一番遠い点。途中の地面の高さで届く距離が変わるので、2pxずつ調べる。
static func landing(from: Vector2, from_h: int, target: Vector2, r: float, map: HeightMap) -> Vector2:
	var d := target - from
	var dist := d.length()
	if dist < 0.01 or dist <= max_range(r, from_h - _ground(map, target)):
		return target
	var dir := d / dist
	var best := 0.0
	var s := 0.0
	while s <= dist:
		var p := from + dir * s
		if s <= max_range(r, from_h - _ground(map, p)):
			best = s
		s += 2.0
	return from + dir * best

static func _ground(map: HeightMap, p: Vector2) -> int:
	return map.get_height(HeightMap.world_to_cell(p))
