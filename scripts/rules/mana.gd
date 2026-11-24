class_name Mana
extends RefCounted
## マナ（魔法を使うのに要る）。最大は50で、ふつうは上がらない（ステータスの「魔法」の技能で＋10）。
## 戦っている間も、いつも毎秒 REGEN ずつ戻る【提案】（2026-11-24 決定）。

const BASE_MAX := 50
const REGEN := 2.0

var max_value := BASE_MAX
var value: float = BASE_MAX

func update(delta: float) -> void:
	value = minf(float(max_value), value + REGEN * delta)

func try_spend(cost: int) -> bool:
	if value < cost:
		return false
	value -= cost
	return true

## 最大を変える。増えた分は今のマナも増え、減ったら切り詰める。
func set_max(m: int) -> void:
	if m > max_value:
		value += m - max_value
	max_value = m
	value = minf(value, float(m))
