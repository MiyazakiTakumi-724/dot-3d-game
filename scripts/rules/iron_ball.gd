class_name IronBall
extends RefCounted
## 鉄球。目の前のマスに落とすだけ。落ちた段数でダメージが決まり、拾い直すまで使えない。

enum State { HELD, FALLING, ON_GROUND }

signal landed(cell: Vector2i, damage: int)

const SECONDS_PER_LEVEL := 0.1
const MIN_FALL_TIME := 0.05
const RETURN_AFTER := 1.0  ## 登れない所に落ちた鉄球が足元へ戻るまでの秒数

var state: State = State.HELD
## 強い鉄球か。ダメージが「落ちた段数＋2」になる。切り替えは手に持っているときだけ。
var strong := false
var cell: Vector2i
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

## そのマスに鉄球を落とせるか。マップの外・奈落・水・壁には落とせない。
## 墓石は壁と同じく通れないが、鉄球を落として壊せる。
static func can_drop_at(target: Vector2i, map: HeightMap) -> bool:
	if not map.in_bounds(target) or map.is_pit(target) or map.is_water(target):
		return false
	return map.is_grave(target) or not map.is_wall(target)

func drop(player: PlayerMover, map: HeightMap) -> bool:
	if state != State.HELD:
		return false
	var target := player.front_cell()
	if not can_drop_at(target, map):
		return false
	cell = target
	height = map.get_height(target)
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
				landed.emit(cell, damage_for(fall_levels, strong))
		State.ON_GROUND:
			if rules.can_step(player.height, height):
				_unreachable_for = 0.0
				return
			_unreachable_for += delta
			if _unreachable_for >= RETURN_AFTER:
				cell = player.cell()
				height = player.height
				_unreachable_for = 0.0

func try_pick_up(player: PlayerMover) -> bool:
	if state != State.ON_GROUND:
		return false
	if player.cell() != cell or player.height != height:
		return false
	state = State.HELD
	return true

## 落下中の残り高さ（段、小数）。描画用。
func remaining_fall_levels() -> float:
	if state != State.FALLING or _fall_time <= 0.0:
		return 0.0
	return maxf(0.0, fall_levels) * (_timer / _fall_time)
