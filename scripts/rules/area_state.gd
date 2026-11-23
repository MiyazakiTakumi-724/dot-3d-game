class_name AreaState
extends RefCounted
## エリアの状態。死んだら DYING になり、待ち時間が尽きたらチェックポイントから再開する。
## ゲームオーバーはない。ゴールに着くと CLEAR で、以後は変わらない。

enum Result { PLAYING, DYING, CLEAR }

const DEATH_SECONDS := 1.5  ## 「YOU DIED」を出しておく時間
const FALL_SECONDS := 0.5   ## 奈落に落ちていく演出の時間

var result: Result = Result.PLAYING
var _timer := 0.0
var _fall_left := 0.0

## 死亡処理を始める。PLAYING のときだけ受け付ける（倒れている間にもう一度死なない）。
func on_player_died(fell: bool) -> bool:
	if result != Result.PLAYING:
		return false
	result = Result.DYING
	_fall_left = FALL_SECONDS if fell else 0.0
	_timer = DEATH_SECONDS + _fall_left
	return true

func is_falling() -> bool:
	return result == Result.DYING and _fall_left > 0.0

## 待ち時間が尽きた瞬間に PLAYING に戻して true。このとき呼び出し側が再開処理をする。
func update(delta: float) -> bool:
	if result != Result.DYING:
		return false
	_timer -= delta
	_fall_left -= delta
	if _timer <= 0.0:
		result = Result.PLAYING
		_fall_left = 0.0
		return true
	return false

func on_goal() -> void:
	if result == Result.PLAYING:
		result = Result.CLEAR
