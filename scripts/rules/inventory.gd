class_name Inventory
extends RefCounted
## プレイヤーの持ち物。所持数に制限はない。武器と防具は equipment（鉄球のランク1は最初から持っている）。

var money: int = 0
var materials: int = 0
var heals: int = 0
## 武器と防具（強い鉄球は鉄球のランク2）
var equipment := Equipment.new()

## 回復アイテム1つで戻る体力【提案】
const HEAL_AMOUNT := 5

## 回復アイテムを1つ使う。持っていないか、体力が最大なら使わずに false。
func try_use_heal(hp: int, max_hp: int) -> bool:
	if heals <= 0 or hp >= max_hp:
		return false
	heals -= 1
	return true
