extends GutTest

var rs: RunState

func before_each():
	rs = RunState.new("hills", Vector2i(1, 1))

func _fill():
	rs.inventory.money = 40
	rs.inventory.materials = 3
	rs.inventory.heals = 2
	rs.inventory.equipment.gain(Equipment.Slot.BALL, 2)
	rs.stats.add_exp(5)

func test_death_moves_belongings_to_grave():
	_fill()
	var g := rs.on_death("hills", Vector2i(9, 4))
	assert_eq(g.cell, Vector2i(9, 4))
	assert_eq([g.money, g.materials, g.heals, g.equipment], [20, 3, 2, {Equipment.Slot.BALL: [2]}])
	var inv := rs.inventory
	assert_eq([inv.money, inv.materials, inv.heals, inv.equipment.ranks(Equipment.Slot.BALL), rs.stats.exp], [20, 0, 0, [1], 5])

func test_odd_money_keeps_larger_half():
	rs.inventory.money = 25
	var g := rs.on_death("hills", Vector2i(2, 2))
	assert_eq(g.money, 12)
	assert_eq(rs.inventory.money, 13)

func test_break_grave_returns_everything():
	_fill()
	rs.on_death("hills", Vector2i(9, 4))
	rs.break_grave()
	var inv := rs.inventory
	assert_eq([inv.money, inv.materials, inv.heals, inv.equipment.ranks(Equipment.Slot.BALL), rs.stats.exp], [40, 3, 2, [1, 2], 5])
	assert_null(rs.grave)

func test_second_death_erases_old_grave():
	_fill()
	rs.on_death("hills", Vector2i(9, 4))          # 墓石に 20, 手元 20
	rs.inventory.materials = 1
	var g2 := rs.on_death("hills", Vector2i(3, 3)) # 墓石に 10, 手元 10
	assert_eq(rs.grave, g2)
	assert_eq([g2.money, g2.materials, g2.equipment], [10, 1, {}])
	rs.break_grave()
	assert_eq(rs.inventory.money, 20)
	assert_false(rs.inventory.equipment.has(Equipment.Slot.BALL, 2))

func test_empty_death_still_replaces_old_grave():
	_fill()
	rs.on_death("hills", Vector2i(9, 4))
	rs.inventory.money = 0
	var g2 := rs.on_death("hills", Vector2i(3, 3))
	assert_eq(rs.grave, g2)
	assert_eq([g2.money, g2.materials, g2.heals, g2.equipment], [0, 0, 0, {}])

func test_break_without_grave_does_nothing():
	rs.break_grave()
	assert_eq(rs.inventory.money, 0)

func test_enemy_reward():
	assert_eq(rs.on_enemy_killed(EnemyKind.Kind.WEAK, 1), 0)
	assert_eq([rs.inventory.money, rs.stats.exp], [10, 2])
	assert_eq(rs.on_enemy_killed(EnemyKind.Kind.MELEE, 1), 1)  # 経験 6 でレベル2
	assert_eq(rs.stats.level, 2)

## 死んでもレベル・経験値・振り分けは残る
func test_death_keeps_stats():
	rs.stats.add_exp(5)
	rs.stats.allocate(PlayerStats.Stat.ATTACK)
	rs.on_death("hills", Vector2i(2, 2))
	assert_eq([rs.stats.level, rs.stats.exp, rs.stats.points_in(PlayerStats.Stat.ATTACK)], [2, 5, 1])

## 敵のレベルは、その敵のレベルに倒したボスの数を足したもの（8章）
func test_enemy_level_rises_with_bosses():
	assert_eq(rs.enemy_level(1), 1)
	rs.bosses_defeated = 2
	assert_eq(rs.enemy_level(1), 3)

func test_pickups_only_once():
	assert_true(rs.collect("a:7", RunState.PickupKind.MONEY, 15))
	assert_false(rs.collect("a:7", RunState.PickupKind.MONEY, 15))
	assert_true(rs.is_picked("a:7"))
	assert_eq(rs.inventory.money, 15)
	rs.collect("a:8", RunState.PickupKind.STRONG_BALL, 0)
	rs.collect("a:9", RunState.PickupKind.HEAL, 1)
	rs.collect("a:10", RunState.PickupKind.MATERIAL, 2)
	assert_eq([rs.inventory.equipment.has(Equipment.Slot.BALL, 2), rs.inventory.heals, rs.inventory.materials], [true, 1, 2])

func test_pickups_stay_picked_after_death():
	rs.collect("a:7", RunState.PickupKind.HEAL, 1)
	rs.on_death("hills", Vector2i(2, 2))
	assert_true(rs.is_picked("a:7"))

func test_doors_stay_open_after_death():
	rs.open_door("d0")
	rs.on_death("hills", Vector2i(2, 2))
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
	assert_true(rs.is_near_checkpoint("hills", Vector2i(1, 1)))
	assert_true(rs.is_near_checkpoint("hills", Vector2i(2, 2)))
	assert_false(rs.is_near_checkpoint("hills", Vector2i(3, 1)))

func test_equip_survives_death_and_returns_with_grave():
	var eq := rs.inventory.equipment
	eq.gain(Equipment.Slot.BALL, 2)
	eq.equip(Equipment.Slot.BALL, 2)
	rs.on_death("hills", Vector2i(4, 4))
	assert_eq(eq.effective(Equipment.Slot.BALL), 1)
	rs.break_grave()
	assert_eq(eq.effective(Equipment.Slot.BALL), 2)

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

## 落ちているものは、マスの中心から 14px まで近づけば拾える（同じ高さだけ）。ユーザーの指示 2026-11-24。
func test_pickup_reach_is_14px_same_height():
	var c := Vector2i(3, 3)
	var center := HeightMap.cell_center(c)
	assert_true(RunState.can_reach_pickup(center + Vector2(13, 0), 1, c, 1))  # となりのマスのふち
	assert_false(RunState.can_reach_pickup(center + Vector2(15, 0), 1, c, 1))
	assert_false(RunState.can_reach_pickup(center + Vector2(4, 0), 2, c, 1))  # 高さがちがう
