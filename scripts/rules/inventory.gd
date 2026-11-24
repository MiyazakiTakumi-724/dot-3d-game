class_name Inventory
extends RefCounted
## プレイヤーの持ち物。所持数に制限はない。武器と防具は equipment（鉄球のランク1は最初から持っている）。

var money: int = 0
var materials: int = 0
var heals: int = 0
## 武器と防具（強い鉄球は鉄球のランク2）
var equipment := Equipment.new()

## 矢の数（Arrow.Kind → 数）と、撃つ矢の種類（インベントリで選ぶ）
var arrows := {}
var arrow_kind: Arrow.Kind = Arrow.Kind.NORMAL

func arrow_count(k: Arrow.Kind) -> int:
	return arrows.get(k, 0)

func add_arrows(k: Arrow.Kind, n: int) -> void:
	arrows[k] = arrow_count(k) + n

## 撃つ矢を1本取り出して種類を返す。選んだ種類が使えて残っていればそれ、なければ普通の矢。どちらもなければ -1。
func take_arrow(bow_skills: int) -> int:
	var k := arrow_kind
	if not Arrow.usable(k, bow_skills) or arrow_count(k) <= 0:
		k = Arrow.Kind.NORMAL
	if arrow_count(k) <= 0:
		return -1
	arrows[k] = arrow_count(k) - 1
	return k

## 回復アイテム1つで戻る体力【提案】
const HEAL_AMOUNT := 5

## 回復アイテムを1つ使う。持っていないか、体力が最大なら使わずに false。
func try_use_heal(hp: int, max_hp: int) -> bool:
	if heals <= 0 or hp >= max_hp:
		return false
	heals -= 1
	return true
