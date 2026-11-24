extends GutTest

var rs: RunState

func before_each():
	rs = RunState.new("area_02", Vector2i(1, 1))

func _fill():
	rs.inventory.money = 40
	rs.inventory.materials = 3
	rs.inventory.heals = 2
	rs.inventory.has_strong_ball = true
	rs.inventory.exp = 5

func test_death_moves_belongings_to_grave():
	_fill()
	var g := rs.on_death("area_02", Vector2i(9, 4))
	assert_eq(g.cell, Vector2i(9, 4))
	assert_eq([g.money, g.materials, g.heals, g.has_strong_ball], [20, 3, 2, true])
	var inv := rs.inventory
	assert_eq([inv.money, inv.materials, inv.heals, inv.has_strong_ball, inv.exp], [20, 0, 0, false, 5])

func test_odd_money_keeps_larger_half():
	rs.inventory.money = 25
	var g := rs.on_death("area_02", Vector2i(2, 2))
	assert_eq(g.money, 12)
	assert_eq(rs.inventory.money, 13)

func test_break_grave_returns_everything():
	_fill()
	rs.on_death("area_02", Vector2i(9, 4))
	rs.break_grave()
	var inv := rs.inventory
	assert_eq([inv.money, inv.materials, inv.heals, inv.has_strong_ball, inv.exp], [40, 3, 2, true, 5])
	assert_null(rs.grave)

func test_second_death_erases_old_grave():
	_fill()
	rs.on_death("area_02", Vector2i(9, 4))          # 墓石に 20, 手元 20
	rs.inventory.materials = 1
	var g2 := rs.on_death("area_02", Vector2i(3, 3)) # 墓石に 10, 手元 10
	assert_eq(rs.grave, g2)
	assert_eq([g2.money, g2.materials, g2.has_strong_ball], [10, 1, false])
	rs.break_grave()
	assert_eq(rs.inventory.money, 20)
	assert_false(rs.inventory.has_strong_ball)

func test_empty_death_still_replaces_old_grave():
	_fill()
	rs.on_death("area_02", Vector2i(9, 4))
	rs.inventory.money = 0
	var g2 := rs.on_death("area_02", Vector2i(3, 3))
	assert_eq(rs.grave, g2)
	assert_eq([g2.money, g2.materials, g2.heals, g2.has_strong_ball], [0, 0, 0, false])

func test_break_without_grave_does_nothing():
	rs.break_grave()
	assert_eq(rs.inventory.money, 0)

func test_enemy_reward():
	rs.on_enemy_killed()
	assert_eq([rs.inventory.money, rs.inventory.exp], [10, 1])

func test_pickups_only_once():
	assert_true(rs.collect("a:7", RunState.PickupKind.MONEY, 15))
	assert_false(rs.collect("a:7", RunState.PickupKind.MONEY, 15))
	assert_true(rs.is_picked("a:7"))
	assert_eq(rs.inventory.money, 15)
	rs.collect("a:8", RunState.PickupKind.STRONG_BALL, 0)
	rs.collect("a:9", RunState.PickupKind.HEAL, 1)
	rs.collect("a:10", RunState.PickupKind.MATERIAL, 2)
	assert_eq([rs.inventory.has_strong_ball, rs.inventory.heals, rs.inventory.materials], [true, 1, 2])

func test_pickups_stay_picked_after_death():
	rs.collect("a:7", RunState.PickupKind.HEAL, 1)
	rs.on_death("area_02", Vector2i(2, 2))
	assert_true(rs.is_picked("a:7"))

func test_doors_stay_open_after_death():
	rs.open_door("d0")
	rs.on_death("area_02", Vector2i(2, 2))
	assert_true(rs.is_door_open("d0"))
	assert_false(rs.is_door_open("d1"))

func test_heal_use():
	rs.inventory.heals = 1
	assert_false(rs.inventory.try_use_heal(3, 3))
	assert_eq(rs.inventory.heals, 1)
	assert_true(rs.inventory.try_use_heal(2, 3))
	assert_eq(rs.inventory.heals, 0)
	assert_false(rs.inventory.try_use_heal(1, 3))

func test_near_checkpoint():
	assert_true(rs.is_near_checkpoint("area_02", Vector2i(1, 1)))
	assert_true(rs.is_near_checkpoint("area_02", Vector2i(2, 2)))
	assert_false(rs.is_near_checkpoint("area_02", Vector2i(3, 1)))

func test_ball_is_strong_needs_both():
	var inv := rs.inventory
	inv.equipped_strong = true
	assert_false(inv.ball_is_strong())
	inv.has_strong_ball = true
	assert_true(inv.ball_is_strong())
	inv.equipped_strong = false
	assert_false(inv.ball_is_strong())

func test_equip_survives_death_and_returns_with_grave():
	rs.inventory.has_strong_ball = true
	rs.inventory.equipped_strong = true
	rs.on_death("area_02", Vector2i(4, 4))
	assert_false(rs.inventory.ball_is_strong())
	rs.break_grave()
	assert_true(rs.inventory.ball_is_strong())

func test_grave_remembers_area():
	var run := RunState.new("camp", Vector2i(5, 5))
	var g := run.on_death("hills", Vector2i(3, 4))
	assert_eq(g.area_id, "hills")

func test_pickup_ids_per_area():
	var run := RunState.new("camp", Vector2i(5, 5))
	assert_true(run.collect("hills:0", RunState.PickupKind.MONEY, 5))
	assert_true(run.collect("rocks:0", RunState.PickupKind.MONEY, 5))
	assert_false(run.collect("hills:0", RunState.PickupKind.MONEY, 5))

func test_checkpoint_only_in_its_area():
	var run := RunState.new("camp", Vector2i(5, 5))
	assert_true(run.is_near_checkpoint("camp", Vector2i(6, 5)))
	assert_false(run.is_near_checkpoint("hills", Vector2i(6, 5)))
