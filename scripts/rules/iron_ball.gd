class_name IronBall
extends RefCounted
## 鉄球。手の届く範囲（体の中心から24px）の好きな場所に落とす。マス目には合わせない。
## 落ちた段数でダメージが決まり、拾い直すまで使えない。

enum State { HELD, FALLING, ON_GROUND }

signal landed(pos: Vector2, damage: int)
## 手から放したとき・拾ったとき（主人公の動きに使う）
signal dropped
signal picked_up

const SECONDS_PER_LEVEL := 0.1
const DROP_TIME := 0.15  ## 手から放して足元の高さまで落ちる時間。落ちる段があれば、1段につき SECONDS_PER_LEVEL 足す
const RETURN_AFTER := 1.0  ## 登れない所に落ちた鉄球が足元へ戻るまでの秒数
const REACH_PX := 24.0  ## 届く距離（1.5マス）
const HIT_RADIUS := 8.0  ## 落ちた点からこの半径の中にいる、同じ高さのものに当たる
const PICK_RADIUS := 12.0  ## 体の中心がこの距離まで近づくと拾う

var state: State = State.HELD
## 強い鉄球か。ダメージが「落ちた段数＋2」になる。切り替えは手に持っているときだけ。
var strong := false
var pos: Vector2 = Vector2.ZERO
var height: int = 0
var fall_levels: int = 0
## 放したときに立っていた点と高さ（落ちていく鉄球を、手元から描くのに使う）
var from_pos: Vector2 = Vector2.ZERO
var from_height: int = 0
var _timer: float = 0.0
var _fall_time: float = 0.0
var _unreachable_for: float = 0.0
## false の間は拾わない。すぐそばに落としたとき、落ちたとたんに拾い直さないように。
## 一度 PICK_RADIUS の外へ出ると true になる。
var _pick_armed := true

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

## 高さ from_height に立って、その点に鉄球を落とせるか。マップの外・奈落・水・壁と、
## 自分より高い地面には落とせない。墓石は壁と同じく通れないが、鉄球を落として壊せる。
static func can_drop_at(point: Vector2, map: HeightMap, from_height: int) -> bool:
	var target := HeightMap.world_to_cell(point)
	if not map.in_bounds(target) or map.is_pit(target) or map.is_water(target):
		return false
	if map.get_height(target) > from_height:
		return false
	# 墓石と、ひびの入った岩（仕掛け）の上には落とせる
	return map.is_grave(target) or map.get_blocker(target) == HeightMap.Blocker.CRACK or not map.is_wall(target)

## ランクごとの当たる半径。ランク2の特性は「当たる範囲が広い」（design.md 7章）。
static func hit_radius(rank: int) -> float:
	return HIT_RADIUS * 1.5 if rank >= 2 else HIT_RADIUS

## 落ちた点（高さ land_h）が、other_pos に立つ高さ other_h のものに当たるか。
static func hits(land_pos: Vector2, land_h: int, other_pos: Vector2, other_h: int, radius := HIT_RADIUS) -> bool:
	return land_h == other_h and land_pos.distance_to(other_pos) < radius

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
	if not can_drop_at(p, map, player.height):
		return false
	pos = p
	height = map.get_height(cell())
	from_pos = player.pos
	from_height = player.height
	fall_levels = player.height - height
	_fall_time = DROP_TIME + fall_levels * SECONDS_PER_LEVEL
	_timer = _fall_time
	state = State.FALLING
	_pick_armed = false
	dropped.emit()
	return true

func update(delta: float, player: PlayerMover, _map: HeightMap, rules: MovementRules) -> void:
	match state:
		State.FALLING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.ON_GROUND
				_unreachable_for = 0.0
				# 落ちた時にもう離れていれば、近づいたらすぐ拾える
				_pick_armed = player.pos.distance_to(pos) > PICK_RADIUS or player.height != height
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
	var near := player.pos.distance_to(pos) <= PICK_RADIUS and player.height == height
	if not near:
		_pick_armed = true
		return false
	if not _pick_armed:
		return false
	state = State.HELD
	picked_up.emit()
	return true

## 放してから着くまでの進み具合（0〜1）。落ちている間だけ動き、地面にあれば1、持っていれば0。描画用。
func fall_progress() -> float:
	match state:
		State.FALLING:
			return clampf(1.0 - _timer / _fall_time, 0.0, 1.0) if _fall_time > 0.0 else 1.0
		State.ON_GROUND:
			return 1.0
	return 0.0
