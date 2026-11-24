class_name AirGun
extends RefCounted
## エアガンの撃つ間隔（design.md 17.5）。1秒に4発、技能「速射」で6発。押したままで撃ち続ける。
## 撃つ高さは、カーソルの下の地面の高さに、マウスホイールで足し引きした段数（敵にカーソルを重ねると、その敵の高さ）。

const INTERVAL := 0.25
const FAST_INTERVAL := 1.0 / 6.0
const MAX_OFFSET := 3  ## ホイールで変えられる段数（上下それぞれ）

var cooldown := 0.0

func update(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)

func try_fire(fast: bool) -> bool:
	if cooldown > 0.0:
		return false
	cooldown = FAST_INTERVAL if fast else INTERVAL
	return true
