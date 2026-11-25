extends GutTest
## 2026-11-26（4回目の直し）：一度休んだたき火へ移動できる。しゃがみは続けられる時間に限りがあり、続けて使えない。

func test_start_campfire_is_known() -> void:
	var r := RunState.new("town", Vector2i(5, 5))
	assert_eq(r.bonfire_areas(), ["town"])
	assert_eq(r.bonfire_cell("town"), Vector2i(5, 5))

func test_resting_remembers_the_campfire() -> void:
	var r := RunState.new("town", Vector2i(5, 5))
	r.set_checkpoint("mt_2", Vector2i(7, 3))
	r.set_checkpoint("gr_2", Vector2i(4, 4))
	assert_eq(r.bonfire_areas(), ["town", "mt_2", "gr_2"], "休んだ順")
	assert_eq(r.bonfire_cell("mt_2"), Vector2i(7, 3))
	r.set_checkpoint("mt_2", Vector2i(7, 3))
	assert_eq(r.bonfire_areas().size(), 3, "同じたき火は1つ")

func test_travel_moves_the_checkpoint() -> void:
	var r := RunState.new("town", Vector2i(5, 5))
	r.set_checkpoint("mt_2", Vector2i(7, 3))
	assert_true(r.travel_to("town"))
	assert_eq(r.checkpoint_area, "town")
	assert_eq(r.respawn_cell(), Vector2i(5, 6))
	assert_false(r.travel_to("lv_2"), "休んだことのないたき火へは行けない")
	assert_eq(r.checkpoint_area, "town")

func test_crouch_lasts_a_limited_time() -> void:
	var c := Crouch.new()
	assert_true(c.update(true, 0.1))
	var t := 0.1
	while t < Crouch.MAX_TIME - 0.05:
		assert_true(c.update(true, 0.05))
		t += 0.05
	c.update(true, 0.2)
	assert_false(c.crouching, "長くしゃがみ続けると立つ")
	assert_false(c.update(true, 0.05), "押したままでも、またしゃがまない")

func test_crouch_needs_rest_before_next_use() -> void:
	var c := Crouch.new()
	c.update(true, 0.3)
	assert_false(c.update(false, 0.05), "離すと立つ")
	assert_false(c.update(true, 0.05), "すぐには、またしゃがめない")
	c.update(false, Crouch.COOLDOWN)
	assert_true(c.update(true, 0.05), "待てば、またしゃがめる")

func test_crouch_gauge() -> void:
	var c := Crouch.new()
	assert_almost_eq(c.gauge(), 1.0, 0.001)
	c.update(true, Crouch.MAX_TIME * 0.5)
	assert_almost_eq(c.gauge(), 0.5, 0.05, "しゃがんでいる間は減る")
	c.update(false, 0.0)
	assert_true(c.cooling())
	c.update(false, Crouch.COOLDOWN * 0.5)
	assert_almost_eq(c.gauge(), 0.5, 0.05, "待つ間に戻る")
