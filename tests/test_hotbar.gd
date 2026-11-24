extends GutTest

func test_default_is_iron_ball():
	assert_eq(Hotbar.new().selected, Hotbar.Item.IRON_BALL)

func test_select_slot_two_is_heal():
	var h := Hotbar.new()
	assert_true(h.select_slot(2))
	assert_eq(h.selected, Hotbar.Item.HEAL)
	assert_true(h.select_slot(1))
	assert_eq(h.selected, Hotbar.Item.IRON_BALL)

func test_out_of_range_slot_ignored():
	var h := Hotbar.new()
	h.select_slot(2)
	assert_false(h.select_slot(0))
	assert_false(h.select_slot(3))
	assert_eq(h.selected, Hotbar.Item.HEAL)
