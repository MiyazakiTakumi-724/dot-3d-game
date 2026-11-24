class_name MeleeAttack
extends RefCounted
## 敵2の近接攻撃。近くにいると0.5秒ためて（体が光る）から叩く。
## ためている間に離れるか、1段でも上へ逃げればよけられる（下から上へは叩けない）。叩いた後は1秒休む。

enum State { IDLE, WINDUP, COOLDOWN }

const RANGE := 16.0  ## 叩ける距離（体の前1マスほど）
const WINDUP := 0.5
const COOLDOWN := 1.0
const MAX_LEVEL_DIFF := 1  ## 1段下までは届く

var state: State = State.IDLE
var _timer := 0.0

static func in_reach(self_pos: Vector2, self_h: int, target_pos: Vector2, target_h: int) -> bool:
	return self_pos.distance_to(target_pos) <= RANGE and Damage.can_hit(self_h, target_h) and self_h - target_h <= MAX_LEVEL_DIFF

## 叩いて当たった瞬間だけ true。
func update(delta: float, self_pos: Vector2, self_h: int, target_pos: Vector2, target_h: int) -> bool:
	match state:
		State.IDLE:
			if in_reach(self_pos, self_h, target_pos, target_h):
				state = State.WINDUP
				_timer = WINDUP
		State.WINDUP:
			_timer -= delta
			if _timer <= 0.0:
				state = State.COOLDOWN
				_timer = COOLDOWN
				return in_reach(self_pos, self_h, target_pos, target_h)
		State.COOLDOWN:
			_timer -= delta
			if _timer <= 0.0:
				state = State.IDLE
	return false

func is_winding_up() -> bool:
	return state == State.WINDUP

func reset() -> void:
	state = State.IDLE
	_timer = 0.0
