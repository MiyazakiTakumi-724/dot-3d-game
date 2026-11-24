extends GutTest
## 大陸のエリアを行き来するメインシーン（scenes/field.tscn）。

var f

func before_each():
	f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)

func after_each():
	get_tree().paused = false

func _exit(area_id: String, target: String, gated := false) -> ExitDef:
	for ex in f.world.area(area_id).exits:
		if ex.target == target and (ex.door_id != "") == gated:
			return ex
	return null

func _mid(ex: ExitDef, inward := 0) -> Vector2i:
	var cells: Array[Vector2i] = ex.cells(f.area.size())
	return cells[cells.size() / 2] - ex.outward() * inward

## 出口のマスに立って、外へ歩き続ける。切り替えが終わるまで進める。
func _walk_out(ex: ExitDef) -> void:
	f.player.mover.place(_mid(ex))
	f.player.mover.move(Vector2(ex.outward()) * 12.0)
	f._process(0.016)
	for i in 4:
		f._process(0.25)

func _finish_death():
	f.area_state.update(10.0)
	f.respawn()

## 平らで敵のいない、歩けるマスを探す（テスト用）。
func _open_cell() -> Vector2i:
	var safe: Dictionary = f.area.entry_safe_cells()
	for y in range(4, f.map.size.y - 4):
		for x in range(4, f.map.size.x - 4):
			var c := Vector2i(x, y)
			var ok := true
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1, 2]:
					var n := c + Vector2i(dx, dy)
					if f.map.is_wall(n) or f.map.is_water(n) or f.map.is_pit(n) or f.map.get_height(n) != f.map.get_height(c) or safe.has(n):
						ok = false
			if ok:
				return c
	return Vector2i(-1, -1)

func test_starts_in_camp_at_bonfire():
	assert_eq(f.area.id, "camp")
	assert_eq(f.player.mover.cell(), Continent.START_CELL)

func test_walking_out_through_exit_switches_area():
	var ex := _exit("camp", "hills")
	var from := _mid(ex)
	_walk_out(ex)
	assert_eq(f.area.id, "hills")
	var expect: Dictionary = f.world.arrival("camp", ex, from)
	assert_eq(f.player.mover.cell(), expect["cell"])
	assert_false(f.is_switching())

func test_standing_on_exit_does_not_switch():
	var ex := _exit("camp", "hills")
	f.player.mover.place(_mid(ex))
	for i in 10:
		f._process(0.1)
	assert_eq(f.area.id, "camp")

func test_arrival_does_not_bounce_back():
	_walk_out(_exit("camp", "hills"))
	for i in 20:
		f._process(0.1)
	assert_eq(f.area.id, "hills")

func test_input_ignored_while_switching():
	var ex := _exit("camp", "hills")
	f.player.mover.place(_mid(ex))
	f.player.mover.move(Vector2(ex.outward()) * 12.0)
	f._process(0.016)
	assert_true(f.is_switching())
	assert_false(f.use_item())
	assert_false(f.try_open_door())
	assert_false(f.open_inventory())

func test_area_title_shown_on_enter():
	_walk_out(_exit("camp", "hills"))
	assert_string_contains(f.ui_message(), "丘陵")
	f._process(2.5)
	assert_false(f.ui_message().contains("丘陵"))

func test_killed_enemy_stays_dead_on_death_and_returns_after_300s_and_reentry():
	_walk_out(_exit("camp", "hills"))
	var e: Enemy = f.enemies[0]
	var idx: int = f.enemy_index(e)
	e.walker.take_damage(10)
	f.kill_player(false)
	_finish_death()
	assert_eq(f.area.id, "camp")
	_walk_out(_exit("camp", "hills"))
	assert_false(f.has_enemy(idx))
	f.roster.tick(300.0)
	_walk_out(_exit("hills", "camp"))
	_walk_out(_exit("camp", "hills"))
	assert_true(f.has_enemy(idx))

func test_enemy_not_back_while_staying_in_area():
	_walk_out(_exit("camp", "hills"))
	var e: Enemy = f.enemies[0]
	var idx: int = f.enemy_index(e)
	e.walker.take_damage(10)
	f.roster.tick(301.0)
	for i in 5:
		f._process(0.1)
	assert_false(f.has_enemy(idx))

func test_enemies_skip_entry_cells():
	_walk_out(_exit("camp", "hills"))
	var safe: Dictionary = f.area.entry_safe_cells()
	for e in f.enemies:
		assert_eq(e.walker.forbidden, safe)

func test_grave_blocks_only_in_its_area():
	_walk_out(_exit("camp", "hills"))
	var c := _open_cell()
	f.player.mover.place(c)
	f.kill_player(false)
	_finish_death()
	assert_eq(f.run.grave.area_id, "hills")
	assert_false(f.map.is_grave(c))
	_walk_out(_exit("camp", "hills"))
	assert_true(f.map.is_grave(c))
	assert_string_contains(f.status_text(), "墓石：丘陵")

func test_ball_on_grave_breaks_it_in_its_area():
	_walk_out(_exit("camp", "hills"))
	var c := _open_cell()
	f.run.inventory.money = 40
	f.player.mover.place(c)
	f.kill_player(false)
	_finish_death()
	_walk_out(_exit("camp", "hills"))
	f.player.mover.place(c + Vector2i(-1, 0))
	var b: IronBall = f.ball.rules_ball
	assert_true(b.drop_at(f.player.mover, f.map, HeightMap.cell_center(c)))
	b.update(1.0, f.player.mover, f.map, f.rules)
	assert_null(f.run.grave)
	assert_false(f.map.is_wall(c))
	assert_eq(f.run.inventory.money, 40)

func test_gate_closed_from_camp_and_opens_from_forest():
	var camp_gate := _exit("camp", "forest", true)
	f.player.mover.place(_mid(camp_gate, 1))
	assert_false(f.try_open_door())
	f.player.mover.move(Vector2(camp_gate.outward()) * 20.0)
	f._process(0.016)
	assert_false(f.is_switching())
	# 丘陵を通って奥の森へ
	_walk_out(_exit("camp", "hills"))
	_walk_out(_exit("hills", "forest"))
	assert_eq(f.area.id, "forest")
	var gate := _exit("forest", "camp", true)
	f.player.mover.place(_mid(gate, 1))
	assert_string_contains(f.ui_message(), "門を開ける")
	assert_true(f.try_open_door())
	assert_true(f.run.is_door_open(gate.door_id))
	_walk_out(gate)
	assert_eq(f.area.id, "camp")
	_walk_out(camp_gate)
	assert_eq(f.area.id, "forest")

func test_clock_runs_while_inventory_open():
	assert_true(f.open_inventory())
	var before: float = f.roster.clock
	await get_tree().process_frame
	await get_tree().process_frame
	assert_gt(f.roster.clock, before)
	f.close_inventory()

func test_ball_hits_enemy_where_aimed():
	_walk_out(_exit("camp", "hills"))
	var c := _open_cell()
	var e: Enemy = f.enemies[0]
	e.set_process(false)
	f.player.mover.place(c)
	var target: Vector2 = f.player.mover.pos + Vector2(14, 3)
	e.walker.pos = target + Vector2(3, 0)
	e.walker.height = f.map.get_height(HeightMap.world_to_cell(target))
	var hp: int = e.walker.hp
	var b: IronBall = f.ball.rules_ball
	assert_true(b.drop_at(f.player.mover, f.map, target))
	b.update(1.0, f.player.mover, f.map, f.rules)
	assert_lt(e.walker.hp, hp)

func test_death_places_grave_and_respawns_at_bonfire():
	f.run.inventory.money = 30
	_walk_out(_exit("camp", "hills"))
	var c := _open_cell()
	f.player.mover.place(c)
	f.kill_player(false)
	assert_eq(f.run.grave.cell, c)
	_finish_death()
	assert_eq(f.area.id, "camp")
	assert_eq(f.player.mover.cell(), Continent.START_CELL)
	assert_eq(f.player.hp, f.player.max_hp)
	assert_eq(f.run.inventory.money, 15)

func test_checkpoint_heals_in_camp():
	f.player.set_hp(1)
	f._process(0.016)
	assert_eq(f.player.hp, f.player.max_hp)

func test_walking_on_pickup_collects_it():
	_walk_out(_exit("camp", "hills"))
	var p = f.area.pickups[0]
	f.player.mover.place(p[0])
	f._process(0.016)
	assert_true(f.run.is_picked(f.area.pickup_id(0)))

func test_no_control_while_dying():
	f.kill_player(false)
	assert_false(f.player.controllable)
	assert_false(f.use_item())

func test_respawn_clears_invulnerability():
	assert_true(f.player.take_hit())
	f.kill_player(false)
	_finish_death()
	assert_true(f.player.take_hit())

func test_melee_enemy_hit_hurts_player():
	_walk_out(_exit("camp", "hills"))
	for e in f.enemies:
		if e.kind == EnemyKind.Kind.MELEE:
			e.melee_hit.emit()
			assert_eq(f.player.hp, f.player.max_hp - e.attack)
			return
	fail_test("丘陵に敵2がいない")

## インベントリを開いても世界は止まらない（design.md 11章）。開いている間のクリックはアイテムに使わない
func test_inventory_keeps_world_running_and_closes():
	assert_true(f.open_inventory())
	assert_false(get_tree().paused)
	assert_true(f.menu.is_open())
	assert_false(f.use_item())
	f.close_inventory()
	assert_false(f.menu.is_open())

func test_start_hint_then_nothing():
	assert_string_contains(f.ui_message(), "矢印")
	f._process(9.0)
	assert_eq(f.ui_message(), "")

func test_arrows_on_open_exits_only():
	# 野営地：西と東の出口に矢印、北の門には矢印なし
	assert_eq(f.arrow_count(), 6)

## 死んでいる間に着いた鉄球で、できたばかりの墓石が壊れない（レビューの指摘）
func test_ball_landing_while_dying_does_not_break_new_grave():
	f.run.inventory.money = 40
	f.run.inventory.materials = 3
	var b: IronBall = f.ball.rules_ball
	assert_true(b.drop_at(f.player.mover, f.map, f.player.mover.pos + Vector2(6, 0)))
	f.kill_player(false)
	b.update(0.1, f.player.mover, f.map, f.rules)
	assert_not_null(f.run.grave)
	assert_eq(f.run.inventory.materials, 0)

## 遊んでいる間に、ほかのエリアのモデルを少しずつ作っておく（初めて入るエリアで待たせない）
func test_other_areas_models_warm_in_background():
	for i in 3000:
		if f.warm_left() == 0:
			break
		f._process(0.016)
	assert_eq(f.warm_left(), 0)
	for id in ["rocks", "hills", "forest"]:
		var loaded = Continent.load_map(f.world.area(id))
		for k in Terrain.model_keys(loaded[0], loaded[1]["deco"]):
			assert_true(Terrain.is_cached(k), k)

## 読み込みで長い1フレームがあっても、明るくする演出を飛ばさない
func test_fade_in_not_skipped_by_long_frame():
	var ex := _exit("camp", "hills")
	f.player.mover.place(_mid(ex))
	f.player.mover.move(Vector2(ex.outward()) * 12.0)
	f._process(0.016)
	f._process(0.25)  # 暗くなりきって、エリアを作る
	f._process(3.0)   # 重いフレームの後
	assert_true(f.is_switching())

func test_pickup_collected_from_next_cell_edge():
	_walk_out(_exit("camp", "hills"))
	var p = f.area.pickups[0]
	var c: Vector2i = p[0]
	f.player.mover.place(c)
	f.player.mover.pos += Vector2(13, 0)
	f._process(0.016)
	if f.player.mover.cell() == c or f.map.get_height(f.player.mover.cell()) != f.map.get_height(c):
		pending("となりのマスが同じ高さでない")
		return
	assert_true(f.run.is_picked(f.area.pickup_id(0)))

## 体力は数値（初期10）で、敵の攻撃力の分だけ減る（17.1）
func test_player_hp_from_stats():
	assert_eq(f.player.max_hp, 10)
	assert_eq(f.player.hp, 10)
	assert_true(f.hurt_player(3))
	assert_eq(f.player.hp, 7)

func test_easy_mode_halves_damage():
	f.easy_mode = true
	f.hurt_player(4)
	assert_eq(f.player.hp, 8)

## 鉄球のダメージは17章の式（初期の攻撃力5、同じ高さなら5）
func test_ball_damage_uses_formula():
	_walk_out(_exit("camp", "hills"))
	var c := _open_cell()
	var e: Enemy = f.enemies[0]
	e.set_process(false)
	f.player.mover.place(c)
	var target: Vector2 = f.player.mover.pos + Vector2(14, 3)
	e.walker.pos = target
	e.walker.height = f.map.get_height(HeightMap.world_to_cell(target))
	var hp: int = e.walker.hp
	var b: IronBall = f.ball.rules_ball
	assert_true(b.drop_at(f.player.mover, f.map, target))
	b.update(1.0, f.player.mover, f.map, f.rules)
	assert_eq(hp - e.walker.hp, Damage.iron_ball(5, b.fall_levels, 1))

func test_killing_enemies_levels_up_and_raises_max_hp_with_points():
	_walk_out(_exit("camp", "hills"))
	for e in f.enemies.duplicate():
		e.walker.take_damage(999)
	assert_gt(f.run.stats.level, 1)
	assert_string_contains(f.ui_message(), "レベル")
	f.run.stats.allocate(PlayerStats.Stat.VITALITY)
	f.apply_stats()
	assert_eq(f.player.max_hp, 10 + PlayerStats.HP_PER_POINT)

func test_heal_restores_fixed_amount():
	f.run.inventory.heals = 1
	f.player.set_hp(2)
	assert_true(f.use_heal())
	assert_eq(f.player.hp, 2 + Inventory.HEAL_AMOUNT)

func test_enemy_level_follows_bosses():
	f.run.bosses_defeated = 2
	_walk_out(_exit("camp", "hills"))
	var e: Enemy = f.enemies[0]
	assert_eq(e.level, 3)
	assert_eq(e.walker.max_hp, EnemyKind.hp(e.kind, 3))

## 画面でポイントを振ると、最大体力に反映される
func test_allocate_from_menu_applies_stats():
	f.run.stats.add_exp(5)
	f.open_inventory()
	f.menu.show_page(InventoryMenu.Page.STATS)
	assert_true(f.menu.allocate(PlayerStats.Stat.VITALITY))
	assert_eq(f.player.max_hp, 10 + PlayerStats.HP_PER_POINT)
	assert_eq(f.player.hp, 10 + PlayerStats.HP_PER_POINT)
	assert_false(f.menu.allocate(PlayerStats.Stat.VITALITY) and f.menu.allocate(PlayerStats.Stat.VITALITY))

## 画面で鉄球のランクを選ぶと、手に持つ鉄球が替わり攻撃力に足される
func test_choose_ball_rank_in_menu():
	f.run.inventory.equipment.gain(Equipment.Slot.BALL, 2)
	f.open_inventory()
	f.menu.select_slot(Equipment.Slot.BALL)
	assert_true(f.menu.choose(2))
	f._process(0.016)
	assert_eq(f.ball_rank, 2)
	assert_true(f.ball.rules_ball.strong)
	assert_eq(f.current_attack(), 5 + Equipment.ATTACK_PER_RANK)
	assert_false(f.menu.choose(3))

## ランク2の鉄球は当たる範囲が広い
func test_rank2_ball_hits_wider():
	assert_false(IronBall.hits(Vector2.ZERO, 0, Vector2(10, 0), 0, IronBall.hit_radius(1)))
	assert_true(IronBall.hits(Vector2.ZERO, 0, Vector2(10, 0), 0, IronBall.hit_radius(2)))

## 野営地の宝箱で剣を手に入れ、2で持ちかえて振ると、前の敵に当たる
func test_pick_sword_in_camp_and_swing():
	var p = f.area.pickups[0]
	assert_eq(p[1], RunState.PickupKind.SWORD)
	f.player.mover.place(p[0])
	f._process(0.016)
	assert_eq(f.run.inventory.equipment.effective(Equipment.Slot.SWORD), 1)
	assert_string_contains(f.ui_message(), "剣")
	assert_true(f.hotbar.select_slot(2, f.run.inventory.equipment))
	_walk_out(_exit("camp", "hills"))
	f.hotbar.select_slot(2, f.run.inventory.equipment)
	var c := _open_cell()
	var e: Enemy = f.enemies[0]
	e.set_process(false)
	f.player.mover.place(c)
	f.player.mover.facing = Vector2.RIGHT
	e.walker.pos = f.player.mover.pos + Vector2(14, 0)
	e.walker.height = f.player.mover.height
	var hp: int = e.walker.hp
	assert_true(f.use_item())
	assert_eq(hp - e.walker.hp, Damage.sword(5, 0, 0))
	assert_false(f.use_item())  # 振る間隔

func test_sword_not_usable_without_sword():
	f.hotbar.selected = Hotbar.Item.SWORD
	assert_false(f.swing_sword())

## 飛び降りてすぐに振ると落下斬り
func test_falling_slash_after_drop():
	f.run.inventory.equipment.gain(Equipment.Slot.SWORD, 1)
	f.hotbar.select_slot(2, f.run.inventory.equipment)
	var m := HeightMap.new(Vector2i(6, 3))
	m.set_height(Vector2i(1, 1), 2)
	f.map = m
	f.player.mover.map = m
	f.player.mover.place(Vector2i(1, 1))
	f.player.mover.move(Vector2(12, 0))
	assert_eq(f.player.mover.height, 0)
	for e in f.enemies:
		e.queue_free()
	f.enemies.clear()
	var e := Enemy.new()
	e.setup(m, Vector2i(3, 1), Vector2.RIGHT, f.player, f.camera, EnemyKind.Kind.MELEE)
	add_child_autofree(e)
	e.set_process(false)
	f.enemies.append(e)
	e.walker.pos = f.player.mover.pos + Vector2(12, 0)
	var hp: int = e.walker.hp
	assert_true(f.swing_sword())
	assert_eq(hp - e.walker.hp, Damage.sword(5, 0, 2))
