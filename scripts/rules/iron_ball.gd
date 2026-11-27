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
const RETURN_AFTER := 1.0  ## 歩いて行けない所に落ちた鉄球が足元へ戻るまでの秒数
const RECHECK := 0.5  ## 同じマスに立っていても、歩いて行けるかをこの秒数ごとに調べ直す（門や仕掛けで道が変わる）
const REACH_PX := 24.0  ## 届く距離（1.5マス）
const HIT_RADIUS := 8.0  ## 落ちた点からこの半径の中にいる、同じ高さのものに当たる
const PICK_RADIUS := 12.0  ## 体の中心がこの距離まで近づくと拾う

var state: State = State.HELD
## 強い鉄球か。ダメージが「落ちた段数＋2」になる。切り替えは手に持っているときだけ。
var strong := false
## 手に持っている鉄球の品物（ItemCatalog の id）。見た目に使う。切り替えは手に持っているときだけ
var item := "ball_1"
## 届く距離（px）。鉄球の特色「届く×」で伸びる
var reach := REACH_PX
var pos: Vector2 = Vector2.ZERO
var height: int = 0
var fall_levels: int = 0
## 放したときに立っていた点と高さ（落ちていく鉄球を、手元から描くのに使う）
var from_pos: Vector2 = Vector2.ZERO
var from_height: int = 0
var _timer: float = 0.0
var _fall_time: float = 0.0
var _unreachable_for: float = 0.0
## 歩いて行けるかを最後に調べたときの立ち位置（マスと高さ）と答え
var _reach_key := Vector3i(-9999, 0, 0)
var _reach_ok := false
var _reach_age := 0.0
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

## 手に持つ鉄球の品物を替える（落としている間は替えない）。届く距離は特色の reach で伸びる。
func set_item(id: String) -> bool:
	if state != State.HELD:
		return false
	item = id
	reach = REACH_PX * float(ItemCatalog.trait_value(id, "reach", 1.0))
	return true

## 死んだときなどに、どこにあっても手元へ戻す。
func return_to_hand() -> void:
	state = State.HELD
	_unreachable_for = 0.0

func cell() -> Vector2i:
	return HeightMap.world_to_cell(pos)

## from から target へ、届く所まで縮めた点。
static func reach_point(from: Vector2, target: Vector2, reach_px := REACH_PX) -> Vector2:
	var d := target - from
	if d.length() <= reach_px:
		return target
	return from + d.normalized() * reach_px

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

## 当たる半径。鉄球の特色「当たる範囲×」（radius）を掛ける（2026-11-25）。
static func hit_radius(mult := 1.0) -> float:
	return HIT_RADIUS * mult

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
	var p := reach_point(player.pos, target, reach)
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
				_reach_key = Vector3i(-9999, 0, 0)  # 落ちた所が変わったので調べ直す
				# 落ちた時にもう離れていれば、近づいたらすぐ拾える
				_pick_armed = player.pos.distance_to(pos) > PICK_RADIUS or player.height != height
				landed.emit(pos, damage_for(fall_levels, strong))
		State.ON_GROUND:
			if rules.can_step(player.height, height) or _walkable(delta, player, _map, rules):
				_unreachable_for = 0.0
				return
			_unreachable_for += delta
			if _unreachable_for >= RETURN_AFTER:
				pos = player.pos
				height = player.height
				_unreachable_for = 0.0

## 今の立ち位置から鉄球のマスまで歩いて行けるか（段差・壁・水・奈落を考える）。
## 台地に置いた鉄球が、階段を降りている途中で戻ってこないように。答えは立ち位置が変わるまで使い回す。
func _walkable(delta: float, player: PlayerMover, map: HeightMap, rules: MovementRules) -> bool:
	if map == null:
		return false
	var start := HeightMap.world_to_cell(player.pos)
	var key := Vector3i(start.x, start.y, player.height)
	_reach_age += delta
	if key == _reach_key and _reach_age < RECHECK:
		return _reach_ok
	_reach_key = key
	_reach_age = 0.0
	_reach_ok = can_walk(map, rules, start, player.height, cell(), player.slow_climb)
	return _reach_ok

## start（高さ from_h）から goal まで歩いて行けるか。幅優先で調べる。slow_climb ならよじ登り（登れる段＋1）も使う。
static func can_walk(map: HeightMap, rules: MovementRules, start: Vector2i, from_h: int, goal: Vector2i, slow_climb := false) -> bool:
	if start == goal:
		return true
	if not map.in_bounds(start) or not map.in_bounds(goal):
		return false
	var climb := rules.max_climb + (1 if slow_climb else 0)
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	var heights := {start: from_h}
	var head := 0
	while head < todo.size():
		var c: Vector2i = todo[head]
		head += 1
		var h: int = heights[c]
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if seen.has(n) or map.is_wall(n) or map.is_water(n) or map.is_pit(n):
				continue
			var nh := map.get_height(n)
			if nh - h > climb or h - nh > rules.max_drop:
				continue
			if n == goal:
				return true
			seen[n] = true
			heights[n] = nh
			todo.append(n)
	return false

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
