class_name Hotbar
extends RefCounted
## 手に持つアイテム。数字キー（1始まり）で選び、左クリックで使う。
## 1 鉄球、2 剣、3 弓、4 杖（魔法）、5 回復。持っていない武器は選べない（杖は最初から無の杖がある）。

enum Item { IRON_BALL, SWORD, BOW, STAFF, HEAL }

const SLOTS := [Item.IRON_BALL, Item.SWORD, Item.BOW, Item.STAFF, Item.HEAL]
## 武器のアイテムと、装備（Equipment）の種類の対応
const WEAPON_SLOT := {
	Item.IRON_BALL: Equipment.Slot.BALL,
	Item.SWORD: Equipment.Slot.SWORD,
	Item.BOW: Equipment.Slot.BOW,
	Item.STAFF: Equipment.Slot.STAFF,
}

var selected: Item = Item.IRON_BALL

## n 番目（1始まり）のアイテムを手に持つ。範囲外か、eq を渡したときにその武器を持っていなければ何もしない。
func select_slot(n: int, eq: Equipment = null) -> bool:
	if n < 1 or n > SLOTS.size():
		return false
	var item: Item = SLOTS[n - 1]
	if eq != null and WEAPON_SLOT.has(item) and eq.effective(WEAPON_SLOT[item]) == 0:
		return false
	selected = item
	return true
