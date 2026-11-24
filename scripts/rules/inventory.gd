class_name Inventory
extends RefCounted
## プレイヤーの持ち物。所持数に制限はない。普通の鉄球（最低ランク）は常に持っているので、ここには入れない。

var money: int = 0
var materials: int = 0
var heals: int = 0
var has_strong_ball := false
var exp: int = 0
## インベントリ画面で「強い鉄球を使う」に設定したか。死んでも消えない好みなので、
## 墓石から強い鉄球を取り返すと、設定し直さなくても強い鉄球に戻る。
var equipped_strong := false

func ball_is_strong() -> bool:
	return equipped_strong and has_strong_ball

## 回復アイテムを1つ使う。持っていないか、体力が最大なら使わずに false。
func try_use_heal(hp: int, max_hp: int) -> bool:
	if heals <= 0 or hp >= max_hp:
		return false
	heals -= 1
	return true
