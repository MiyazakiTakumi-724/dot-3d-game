extends GutTest
## 手に持つアイテム：1 鉄球、2 剣、3 弓、4 エアガン、5 回復。持っていない武器は選べない。

func test_default_is_iron_ball():
	assert_eq(Hotbar.new().selected, Hotbar.Item.IRON_BALL)

func test_select_heal_and_back():
	var h := Hotbar.new()
	assert_true(h.select_slot(5))
	assert_eq(h.selected, Hotbar.Item.HEAL)
	assert_true(h.select_slot(1))
	assert_eq(h.selected, Hotbar.Item.IRON_BALL)

func test_out_of_range_slot_ignored():
	var h := Hotbar.new()
	h.select_slot(5)
	assert_false(h.select_slot(0))
	assert_false(h.select_slot(6))
	assert_eq(h.selected, Hotbar.Item.HEAL)

func test_weapon_needs_ownership():
	var h := Hotbar.new()
	var eq := Equipment.new()
	assert_false(h.select_slot(2, eq))
	assert_eq(h.selected, Hotbar.Item.IRON_BALL)
	eq.gain(Equipment.Slot.SWORD, 1)
	assert_true(h.select_slot(2, eq))
	assert_eq(h.selected, Hotbar.Item.SWORD)
