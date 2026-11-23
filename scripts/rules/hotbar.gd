class_name Hotbar
extends RefCounted
## 手に持つアイテム。数字キー（1始まり）で選び、左クリックで使う。武器が増えたら SLOTS に足す。

enum Item { IRON_BALL, HEAL }

const SLOTS := [Item.IRON_BALL, Item.HEAL]

var selected: Item = Item.IRON_BALL

## n 番目（1始まり）のアイテムを手に持つ。範囲外なら何もしない。
func select_slot(n: int) -> bool:
	if n < 1 or n > SLOTS.size():
		return false
	selected = SLOTS[n - 1]
	return true
