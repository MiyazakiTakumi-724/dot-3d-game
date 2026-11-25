class_name Crouch
extends RefCounted
## しゃがみ（技能）の時間（2026-11-26 の4回目の直し）。続けてしゃがめるのは MAX_TIME 秒まで。
## 立ったら（離しても、時間が切れても）COOLDOWN 秒は、またしゃがめない。時間が切れたあとは、一度離すまでしゃがまない。

const MAX_TIME := 1.5
const COOLDOWN := 2.0

var crouching := false
var _held := 0.0
var _cool := 0.0
## 時間が切れて立ったあと、キーを離すのを待っている
var _wait_release := false

## want：しゃがむキーを押しているか。しゃがんでいるかを返す。
func update(want: bool, delta: float) -> bool:
	if not want:
		_wait_release = false
	if crouching:
		_held += delta
		if not want or _held >= MAX_TIME:
			_stand()
			if want:
				_wait_release = true
	else:
		_cool = maxf(0.0, _cool - delta)
		if want and _cool <= 0.0 and not _wait_release:
			crouching = true
			_held = delta
	return crouching

func _stand() -> void:
	crouching = false
	_cool = COOLDOWN
	_held = 0.0

## 待っているところか（またしゃがめるまで）。
func cooling() -> bool:
	return not crouching and _cool > 0.0

## 画面に出す量（0〜1）。しゃがんでいる間は残りの時間、待っている間は戻り具合。
func gauge() -> float:
	if crouching:
		return clampf(1.0 - _held / MAX_TIME, 0.0, 1.0)
	return clampf(1.0 - _cool / COOLDOWN, 0.0, 1.0)

func reset() -> void:
	crouching = false
	_held = 0.0
	_cool = 0.0
	_wait_release = false
