class_name IronBall
extends RefCounted
## 鉄球。手の届く範囲（体の中心から24px）の好きな場所に落とす。マス目には合わせない。
## 落ちた段数でダメージが決まり、拾い直すまで使えない。

enum State { HELD, FALLING, ON_GROUND }

signal landed(pos: Vector2, damage: int)

const SECONDS_PER_LEVEL := 0.1
const MIN_FALL_TIME := 0.05
const RETURN_AFTER := 1.0  ## 登れない所に落ちた鉄球が足元へ戻るまでの秒数
const REACH_PX := 24.0  ## 届く距離（1.5マス）
const HIT_RADIUS := 8.0  ## 落ちた点からこの半径の中にいる、同じ高さのものに当たる
const PICK_RADIUS := 6.0  ## 体の中心がこの距離まで近づくと拾う

var state: State = State.HELD
## 強い鉄球か。ダメージが「落ちた段数＋2」になる。切り替えは手に持っているときだけ。
var strong := false
var pos: Vector2 = Vector2.ZERO
var height: int = 0
var fall_levels: int = 0
var _timer: float = 0.0
var _fall_time: float = 0.0
var _unreachable_for: float = 0.0

static func damage_for(levels: int, is_strong: bool = false) -> int:
	if is_strong:
		return maxi(2, levels + 2)
	return maxi(1, levels + 1)

func set_strong(v: bool) -> bool:
	if state != State.HELD:
		return false
	strong = v
	return true

## 死んだときなどに、どこにあっても手元へ戻す。
func return_to_hand() -> void:
	state = State.HELD
	_unreachable_for = 0.0

func cell() -> Vector2i:
	return HeightMap.world_to_cell(pos)

## from から target へ、届く所まで縮めた点。
static func reach_point(from: Vector2, target: Vector2) -> Vector2:
	var d := target - from
	if d.length() <= REACH_PX:
		return target
	return from + d.normalized() * REACH_PX

## その点に鉄球を落とせるか。マップの外・奈落・水・壁には落とせない。
## 墓石は壁と同じく通れないが、鉄球を落として壊せる。
static func can_drop_at(point: Vector2, map: HeightMap) -> bool:
	var target := HeightMap.world_to_cell(point)
	if not map.in_bounds(target) or map.is_pit(target) or map.is_water(target):
		return false
	return map.is_grave(target) or not map.is_wall(target)

## 落ちた点（高さ land_h）が、other_pos に立つ高さ other_h のものに当たるか。
static func hits(land_pos: Vector2, land_h: int, other_pos: Vector2, other_h: int) -> bool:
	return land_h == other_h and land_pos.distance_to(other_pos) < HIT_RADIUS

## 落ちた点から半径の中に、そのマスの四角がかかるか（墓石を壊すのに使う）。
static func touches_cell(land_pos: Vector2, c: Vector2i) -> bool:
	var lo := Vector2(c) * HeightMap.CELL_PX
	var nearest := land_pos.clamp(lo, lo + Vector2.ONE * HeightMap.CELL_PX)
	return land_pos.distance_to(nearest) <= HIT_RADIUS

## target（カーソルの地面の点）に向けて落とす。届かなければ届く一番遠い所。
func drop_at(player: PlayerMover, map: HeightMap, target: Vector2) -> bool:
	if state != State.HELD:
		return false
	var p := reach_point(player.pos, target)
	if not can_drop_at(p, map):
		return false
	pos = p
	height = map.get_height(cell())
	fall_levels = player.height - height
	_fall_time = maxf(MIN_FALL_TIME, fall_levels * SECONDS_PER_LEVEL)
	_timer = _fall_time
	state = State.FALLING
	return true

func update(delta: float, player: PlayerMover, _map: HeightMap, rules: MovementRules) -> void:
	match state:
		State.FALLING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.ON_GROUND
				_unreachable_for = 0.0
				landed.emit(pos, damage_for(fall_levels, strong))
		State.ON_GROUND:
			if rules.can_step(player.height, height):
				_unreachable_for = 0.0
				return
			_unreachable_for += delta
			if _unreachable_for >= RETURN_AFTER:
				pos = player.pos
				height = player.height
				_unreachable_for = 0.0

func try_pick_up(player: PlayerMover) -> bool:
	if state != State.ON_GROUND:
		return false
	if player.pos.distance_to(pos) > PICK_RADIUS or player.height != height:
		return false
	state = State.HELD
	return true

## 落下中の残り高さ（段、小数）。描画用。
func remaining_fall_levels() -> float:
	if state != State.FALLING or _fall_time <= 0.0:
		return 0.0
	return maxf(0.0, fall_levels) * (_timer / _fall_time)
