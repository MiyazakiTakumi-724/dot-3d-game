extends GutTest

var rs: RunState

func before_each():
	rs = RunState.new("hills", Vector2i(1, 1))

func _fill():
	rs.inventory.money = 40
	rs.inventory.add("hide", 3)
	rs.inventory.add("potion", 2)
	rs.inventory.equipment.gain("ball_heavy")
	rs.stats.add_exp(5)

func test_death_moves_belongings_to_grave():
	_fill()
	var g := rs.on_death("hills", Vector2i(9, 4))
	assert_eq(g.cell, Vector2i(9, 4))
	assert_eq([g.money, g.counts, g.equipment], [20, {"hide": 3, "potion": 2}, ["ball_heavy"]])
	var inv := rs.inventory
	assert_eq([inv.money, inv.counts, inv.equipment.items(Equipment.Slot.BALL), rs.stats.exp], [20, {}, ["ball_1"], 5])

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
	assert_eq([inv.money, inv.count("hide"), inv.count("potion"), inv.equipment.items(Equipment.Slot.BALL), rs.stats.exp], [40, 3, 2, ["ball_1", "ball_heavy"], 5])
	assert_null(rs.grave)

func test_second_death_erases_old_grave():
	_fill()
	rs.on_death("hills", Vector2i(9, 4))          # 墓石に 20, 手元 20
	rs.inventory.add("bone", 1)
	var g2 := rs.on_death("hills", Vector2i(3, 3)) # 墓石に 10, 手元 10
	assert_eq(rs.grave, g2)
	assert_eq([g2.money, g2.counts, g2.equipment], [10, {"bone": 1}, []])
	rs.break_grave()
	assert_eq(rs.inventory.money, 20)
	assert_false(rs.inventory.equipment.has("ball_heavy"))

func test_empty_death_still_replaces_old_grave():
	_fill()
	rs.on_death("hills", Vector2i(9, 4))
	rs.inventory.money = 0
	var g2 := rs.on_death("hills", Vector2i(3, 3))
	assert_eq(rs.grave, g2)
	assert_eq([g2.money, g2.counts, g2.equipment], [0, {}, []])

func test_break_without_grave_does_nothing():
	rs.break_grave()
	assert_eq(rs.inventory.money, 0)

func test_enemy_reward():
	assert_eq(rs.on_enemy_killed(EnemyKind.Kind.WEAK, 1), 0)
	assert_eq(rs.stats.exp, EnemyKind.exp_reward(EnemyKind.Kind.WEAK, 1))
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
	assert_true(rs.collect("a:7", "money", 15))
	assert_false(rs.collect("a:7", "money", 15))
	assert_true(rs.is_picked("a:7"))
	assert_eq(rs.inventory.money, 15)
	rs.collect("a:8", "ball_heavy", 1)
	rs.collect("a:9", "potion", 1)
	rs.collect("a:10", "wood", 2)
	assert_eq([rs.inventory.equipment.has("ball_heavy"), rs.inventory.count("potion"), rs.inventory.count("wood")], [true, 1, 2])

func test_pickups_stay_picked_after_death():
	rs.collect("a:7", "potion", 1)
	rs.on_death("hills", Vector2i(2, 2))
	assert_true(rs.is_picked("a:7"))

func test_doors_stay_open_after_death():
	rs.open_door("d0")
	rs.on_death("hills", Vector2i(2, 2))
	assert_true(rs.is_door_open("d0"))
	assert_false(rs.is_door_open("d1"))

func test_near_checkpoint():
	assert_true(rs.is_near_checkpoint("hills", Vector2i(1, 1)))
	assert_true(rs.is_near_checkpoint("hills", Vector2i(2, 2)))
	assert_false(rs.is_near_checkpoint("hills", Vector2i(3, 1)))

func test_equip_survives_death_and_returns_with_grave():
	var eq := rs.inventory.equipment
	eq.gain("ball_heavy")
	eq.equip("ball_heavy")
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
	assert_true(run.collect("hills:0", "money", 5))
	assert_true(run.collect("rocks:0", "money", 5))
	assert_false(run.collect("hills:0", "money", 5))

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

## 矢は持ち物なので、死ぬとすべて墓石に入り、壊すと戻る
func test_arrows_go_to_grave():
	rs.inventory.add_arrows(Arrow.Kind.NORMAL, 12)
	rs.inventory.add_arrows(Arrow.Kind.POISON, 3)
	var g := rs.on_death("hills", Vector2i(2, 2))
	assert_eq(rs.inventory.arrow_count(Arrow.Kind.NORMAL), 0)
	assert_eq(g.counts, {"arrow": 12, "arrow_poison": 3})
	rs.inventory.add_arrows(Arrow.Kind.NORMAL, 1)
	rs.break_grave()
	assert_eq(rs.inventory.arrow_count(Arrow.Kind.NORMAL), 13)
	assert_eq(rs.inventory.arrow_count(Arrow.Kind.POISON), 3)

func test_bow_and_arrow_pickups():
	rs.collect("c:0", "bow_1", 1)
	rs.collect("c:1", "arrow", 30)
	rs.collect("c:2", "arrow_poison", 5)
	assert_eq(rs.inventory.equipment.effective(Equipment.Slot.BOW), 1)
	assert_eq(rs.inventory.arrow_count(Arrow.Kind.NORMAL), 30)
	assert_eq(rs.inventory.arrow_count(Arrow.Kind.POISON), 5)

## 撃つ矢：選んだ種類が使えて残っていればそれ、なければ普通の矢
func test_take_arrow_falls_back_to_normal():
	var inv := rs.inventory
	inv.add_arrows(Arrow.Kind.NORMAL, 1)
	inv.add_arrows(Arrow.Kind.POISON, 1)
	inv.arrow_kind = Arrow.Kind.POISON
	assert_eq(inv.take_arrow(0), Arrow.Kind.NORMAL)  # 技能がないと毒矢は使えない
	assert_eq(inv.take_arrow(1), Arrow.Kind.POISON)
	assert_eq(inv.take_arrow(1), -1)

## 炎の杖（ランク3）を拾う。死ぬと墓石に入り、ランク1の無の杖は手元に残る
func test_fire_staff_goes_to_grave():
	rs.collect("c:3", "staff_fire_3", 1)
	rs.collect("c:4", "staff_none_1", 1)
	var eq := rs.inventory.equipment
	assert_true(eq.has("staff_fire_3"))
	rs.on_death("hills", Vector2i(2, 2))
	assert_false(eq.has("staff_fire_3"))
	assert_true(eq.has("staff_none_1"))
	rs.break_grave()
	assert_true(eq.has("staff_fire_3"))

## 敵の落とし物は拾い済みとして覚えない（何度でも拾える）
func test_drop_pickup_not_remembered():
	rs.take_drop("potion", 1)
	rs.take_drop("potion", 1)
	assert_eq(rs.inventory.count("potion"), 2)

# ---- 全体の地図（2026-11-25）：たき火・仕掛け・行ったエリア・封印の門

func test_resting_at_a_bonfire_moves_the_checkpoint():
	rs.set_checkpoint("grass_2", Vector2i(12, 10))
	assert_eq(rs.checkpoint_area, "grass_2")
	assert_eq(rs.checkpoint_cell, Vector2i(12, 10))
	assert_true(rs.is_near_checkpoint("grass_2", Vector2i(13, 11)))
	assert_false(rs.is_near_checkpoint("hills", Vector2i(1, 1)))

func test_respawn_is_just_south_of_the_bonfire():
	rs.set_checkpoint("camp", Vector2i(12, 10))
	assert_eq(rs.respawn_cell(), Vector2i(12, 11))

func test_opened_gimmicks_are_remembered():
	assert_false(rs.is_gimmick_open("mt_1:0"))
	rs.open_gimmick("mt_1:0")
	assert_true(rs.is_gimmick_open("mt_1:0"))
	rs.on_death("mt_1", Vector2i(2, 2))
	assert_true(rs.is_gimmick_open("mt_1:0"))

func test_visited_areas():
	assert_false(rs.has_visited("town"))
	rs.visit("town")
	assert_true(rs.has_visited("town"))
	assert_eq(rs.visited_ids(), ["town"])

## 封印は4つの地方のボスを倒すと開く（隠しボスは数えない）
func test_tower_seal_needs_four_region_bosses():
	assert_false(rs.can_open_door(RunState.SEAL_DOOR))
	assert_eq(rs.seal_bosses_left(), 4)
	rs.on_boss_killed("岩転がしの巨人", 10)
	rs.on_boss_killed("草むらの大蛇", 10)
	rs.on_boss_killed("岩窟のぬし", 10)
	rs.on_boss_killed("廃城の主", 10)
	assert_false(rs.can_open_door(RunState.SEAL_DOOR))
	assert_eq(rs.seal_bosses_left(), 1)
	assert_eq(rs.bosses_defeated, 4)
	rs.on_boss_killed("満ち引きする溶岩", 10)
	assert_true(rs.can_open_door(RunState.SEAL_DOOR))
	assert_true(rs.can_open_door("forest_gate"))

## 倒したボスは戻らない。2回目は数えない。ブライトでゲームの終わり
func test_bosses_are_remembered():
	assert_gt(rs.on_boss_killed("双子", 60), 0)
	assert_eq(rs.on_boss_killed("双子", 60), 0)
	assert_eq(rs.bosses_defeated, 1)
	assert_true(rs.is_boss_defeated("双子"))
	assert_false(rs.cleared)
	rs.on_boss_killed("ブライト", 10)
	assert_true(rs.cleared)

## 地方の印は死んでも墓石に入らない（鍵なので）。装備のレベルの制限は、冒険のステータスに合わせる
func test_seals_stay_on_death_and_equipment_knows_level():
	var rs := RunState.new("town", Vector2i(1, 1))
	rs.inventory.add("seal_mt", 2)
	rs.inventory.add("herb", 3)
	rs.on_death("town", Vector2i(2, 2))
	assert_eq(rs.inventory.count("seal_mt"), 2)
	assert_eq(rs.inventory.count("herb"), 0)
	rs.inventory.equipment.gain("sword_flame")
	assert_false(rs.inventory.equipment.usable("sword_flame"))
	rs.stats.add_exp(PlayerStats.exp_to_reach(12))
	assert_true(rs.inventory.equipment.usable("sword_flame"))

## ボスの間の門は、その地方の印が3つあると開く
func test_boss_doors_need_three_seals():
	var rs := RunState.new("town", Vector2i(1, 1))
	assert_false(rs.can_open_door("mt_boss"))
	assert_eq(rs.seals_left("mt_boss"), 3)
	rs.inventory.add("seal_mt", 3)
	assert_true(rs.can_open_door("mt_boss"))
	assert_true(rs.can_open_door("forest_gate"))
