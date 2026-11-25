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

func test_starts_in_town_at_bonfire():
	assert_eq(f.area.id, "town")
	assert_eq(f.player.mover.cell(), Continent.START_CELL)

func test_walking_out_through_exit_switches_area():
	var ex := _exit("town", "hills")
	var from := _mid(ex)
	_walk_out(ex)
	assert_eq(f.area.id, "hills")
	var expect: Dictionary = f.world.arrival("town", ex, from)
	assert_eq(f.player.mover.cell(), expect["cell"])
	assert_false(f.is_switching())

func test_standing_on_exit_does_not_switch():
	var ex := _exit("town", "hills")
	f.player.mover.place(_mid(ex))
	for i in 10:
		f._process(0.1)
	assert_eq(f.area.id, "town")

func test_arrival_does_not_bounce_back():
	_walk_out(_exit("town", "hills"))
	for i in 20:
		f._process(0.1)
	assert_eq(f.area.id, "hills")

func test_input_ignored_while_switching():
	var ex := _exit("town", "hills")
	f.player.mover.place(_mid(ex))
	f.player.mover.move(Vector2(ex.outward()) * 12.0)
	f._process(0.016)
	assert_true(f.is_switching())
	assert_false(f.use_item())
	assert_false(f.try_open_door())
	assert_false(f.open_inventory())

func test_area_title_shown_on_enter():
	_walk_out(_exit("town", "hills"))
	assert_string_contains(f.ui_message(), "丘陵")
	f._process(2.5)
	assert_false(f.ui_message().contains("丘陵"))

func test_killed_enemy_stays_dead_on_death_and_returns_after_300s_and_reentry():
	_walk_out(_exit("town", "hills"))
	var e: Enemy = f.enemies[0]
	var idx: int = f.enemy_index(e)
	e.walker.take_damage(e.walker.hp)
	f.kill_player(false)
	_finish_death()
	assert_eq(f.area.id, "town")
	_walk_out(_exit("town", "hills"))
	assert_false(f.has_enemy(idx))
	f.roster.tick(300.0)
	_walk_out(_exit("hills", "town"))
	_walk_out(_exit("town", "hills"))
	assert_true(f.has_enemy(idx))

func test_enemy_not_back_while_staying_in_area():
	_walk_out(_exit("town", "hills"))
	var e: Enemy = f.enemies[0]
	var idx: int = f.enemy_index(e)
	e.walker.take_damage(e.walker.hp)
	f.roster.tick(301.0)
	for i in 5:
		f._process(0.1)
	assert_false(f.has_enemy(idx))

func test_enemies_skip_entry_cells():
	_walk_out(_exit("town", "hills"))
	var safe: Dictionary = f.area.entry_safe_cells()
	for e in f.enemies:
		assert_eq(e.walker.forbidden, safe)

func test_grave_blocks_only_in_its_area():
	_walk_out(_exit("town", "hills"))
	var c := _open_cell()
	f.player.mover.place(c)
	f.kill_player(false)
	_finish_death()
	assert_eq(f.run.grave.area_id, "hills")
	assert_false(f.map.is_grave(c))
	_walk_out(_exit("town", "hills"))
	assert_true(f.map.is_grave(c))
	assert_string_contains(f.status_text(), "墓石：丘陵")

func test_ball_on_grave_breaks_it_in_its_area():
	_walk_out(_exit("town", "hills"))
	var c := _open_cell()
	f.run.inventory.money = 40
	f.player.mover.place(c)
	f.kill_player(false)
	_finish_death()
	_walk_out(_exit("town", "hills"))
	f.player.mover.place(c + Vector2i(-1, 0))
	var b: IronBall = f.ball.rules_ball
	assert_true(b.drop_at(f.player.mover, f.map, HeightMap.cell_center(c)))
	b.update(1.0, f.player.mover, f.map, f.rules)
	assert_null(f.run.grave)
	assert_false(f.map.is_wall(c))
	assert_eq(f.run.inventory.money, 40)

func test_gate_closed_from_camp_and_opens_from_forest():
	var camp_gate := _exit("town", "forest", true)
	f.player.mover.place(_mid(camp_gate, 1))
	assert_false(f.try_open_door())
	f.player.mover.move(Vector2(camp_gate.outward()) * 20.0)
	f._process(0.016)
	assert_false(f.is_switching())
	# 丘陵を通って奥の森へ
	_walk_out(_exit("town", "hills"))
	_walk_out(_exit("hills", "forest"))
	assert_eq(f.area.id, "forest")
	var gate := _exit("forest", "town", true)
	f.player.mover.place(_mid(gate, 1))
	assert_string_contains(f.ui_message(), "門を開ける")
	assert_true(f.try_open_door())
	assert_true(f.run.is_door_open(gate.door_id))
	_walk_out(gate)
	assert_eq(f.area.id, "town")
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
	_walk_out(_exit("town", "hills"))
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
	_walk_out(_exit("town", "hills"))
	var c := _open_cell()
	f.player.mover.place(c)
	f.kill_player(false)
	assert_eq(f.run.grave.cell, c)
	_finish_death()
	assert_eq(f.area.id, "town")
	assert_eq(f.player.mover.cell(), f.run.respawn_cell())
	assert_eq(f.player.hp, f.player.max_hp)
	assert_eq(f.run.inventory.money, 15)

func test_checkpoint_heals_in_town():
	f.player.set_hp(1)
	f._process(0.016)
	assert_eq(f.player.hp, f.player.max_hp)

## 宝箱でない拾いものの番号（宝箱は F で開ける）
func _loose_pickup() -> int:
	for i in f.area.pickups.size():
		if not f.is_chest(f.area.pickups[i][1]):
			return i
	return -1

func _chest_pickup() -> int:
	for i in f.area.pickups.size():
		if f.is_chest(f.area.pickups[i][1]):
			return i
	return -1

func test_walking_on_pickup_collects_it():
	_walk_out(_exit("town", "hills"))
	var i := _loose_pickup()
	var p = f.area.pickups[i]
	f.player.mover.place(p[0])
	f._process(0.016)
	assert_true(f.run.is_picked(f.area.pickup_id(i)))

## 宝箱は歩いても開かず、そばで F を押すと開く。開けた宝箱は開いたまま残る（2026-11-26）
func test_chest_opens_with_f():
	_walk_out(_exit("town", "hills"))
	var i := _chest_pickup()
	assert_gt(i, -1, "丘陵に宝箱がある")
	var p = f.area.pickups[i]
	f.player.mover.place(p[0])
	f._process(0.016)
	assert_false(f.run.is_picked(f.area.pickup_id(i)), "歩いただけでは開かない")
	f._notice_time = 0.0
	f._title_time = 0.0
	assert_eq(f.ui_message(), "F：宝箱を開ける")
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_F
	f._unhandled_input(key)
	assert_true(f.run.is_picked(f.area.pickup_id(i)))
	assert_true(f.run.inventory.equipment.has(p[1]))
	assert_eq(f.chest_here(), -1)
	assert_false(f.try_open_chest(), "2回は開かない")

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
	_walk_out(_exit("town", "hills"))
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
	# 町：西・東・南の出口に矢印、北の門と南西の封印の門には矢印なし（出口の幅の分だけ。2026-11-26 に広げた）
	var n := 0
	for ex in f.area.exits:
		if ex.door_id == "":
			n += ex.cells(f.area.size()).size()
	assert_eq(n, 11)
	assert_eq(f.arrow_count(), n)

## 死んでいる間に着いた鉄球で、できたばかりの墓石が壊れない（レビューの指摘）
func test_ball_landing_while_dying_does_not_break_new_grave():
	f.run.inventory.money = 40
	f.run.inventory.add("hide", 3)
	var b: IronBall = f.ball.rules_ball
	assert_true(b.drop_at(f.player.mover, f.map, f.player.mover.pos + Vector2(6, 0)))
	f.kill_player(false)
	b.update(1.0, f.player.mover, f.map, f.rules)
	assert_not_null(f.run.grave)
	assert_eq(f.run.inventory.count("hide"), 0)

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
	var ex := _exit("town", "hills")
	f.player.mover.place(_mid(ex))
	f.player.mover.move(Vector2(ex.outward()) * 12.0)
	f._process(0.016)
	f._process(0.25)  # 暗くなりきって、エリアを作る
	f._process(3.0)   # 重いフレームの後
	assert_true(f.is_switching())

func test_pickup_collected_from_next_cell_edge():
	_walk_out(_exit("town", "hills"))
	var i := _loose_pickup()
	var p = f.area.pickups[i]
	var c: Vector2i = p[0]
	for d in [Vector2(13, 0), Vector2(-13, 0), Vector2(0, 13), Vector2(0, -13)]:
		f.player.mover.place(c)
		f.player.mover.pos += d
		if f.player.mover.cell() != c and f.map.get_height(f.player.mover.cell()) == f.map.get_height(c):
			break
	f._process(0.016)
	if f.player.mover.cell() == c or f.map.get_height(f.player.mover.cell()) != f.map.get_height(c):
		pending("となりのマスが同じ高さでない")
		return
	assert_true(f.run.is_picked(f.area.pickup_id(i)))

## 体力は数値（初期 PlayerStats.BASE_HP）で、敵の攻撃力の分だけ減る（17.1）
func test_player_hp_from_stats():
	assert_eq(f.player.max_hp, PlayerStats.BASE_HP)
	assert_eq(f.player.hp, PlayerStats.BASE_HP)
	assert_true(f.hurt_player(3))
	assert_eq(f.player.hp, PlayerStats.BASE_HP - 3)

func test_easy_mode_halves_damage():
	f.settings.easy_mode = true
	f.hurt_player(4)
	assert_eq(f.player.hp, PlayerStats.BASE_HP - 2)

## 鉄球のダメージは17章の式（初期の攻撃力5、同じ高さなら5）
func test_ball_damage_uses_formula():
	_walk_out(_exit("town", "hills"))
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
	assert_eq(hp - e.walker.hp, Damage.iron_ball(PlayerStats.BASE_ATTACK, b.fall_levels))

func test_killing_enemies_levels_up_and_raises_max_hp_with_points():
	_walk_out(_exit("town", "hills"))
	for e in f.enemies.duplicate():
		e.walker.take_damage(999)
	assert_gt(f.run.stats.level, 1)
	assert_string_contains(f.ui_message(), "レベル")
	f.run.stats.allocate(PlayerStats.Stat.VITALITY)
	f.apply_stats()
	assert_eq(f.player.max_hp, PlayerStats.BASE_HP + PlayerStats.HP_PER_POINT)

func test_potion_restores_fixed_amount():
	f.run.inventory.add("potion", 1)
	f.hotbar.select_slot(5)
	f.player.set_hp(2)
	assert_true(f.use_item())
	assert_eq(f.player.hp, 2 + 10)
	assert_eq(f.run.inventory.count("potion"), 0)
	assert_false(f.use_tool())

func test_enemy_level_follows_bosses():
	f.run.bosses_defeated = 2
	_walk_out(_exit("town", "hills"))
	var e: Enemy = f.enemies[0]
	assert_eq(e.level, 3)
	assert_eq(e.walker.max_hp, EnemyKind.hp(e.kind, 3))

## 画面でポイントを振ると、最大体力に反映される
func test_allocate_from_menu_applies_stats():
	f.run.stats.add_exp(5)
	f.open_inventory()
	f.menu.show_page(InventoryMenu.Page.STATS)
	assert_true(f.menu.allocate(PlayerStats.Stat.VITALITY))
	assert_eq(f.player.max_hp, PlayerStats.BASE_HP + PlayerStats.HP_PER_POINT)
	assert_eq(f.player.hp, PlayerStats.BASE_HP + PlayerStats.HP_PER_POINT)
	assert_false(f.menu.allocate(PlayerStats.Stat.VITALITY) and f.menu.allocate(PlayerStats.Stat.VITALITY))

## 画面で鉄球のランクを選ぶと、手に持つ鉄球が替わり攻撃力に足される
func test_choose_ball_rank_in_menu():
	f.run.inventory.equipment.gain("ball_heavy")
	f.open_inventory()
	f.menu.select_slot(Equipment.Slot.BALL)
	assert_true(f.menu.choose("ball_heavy"))
	f._process(0.016)
	assert_eq(f.ball_rank, 2)
	assert_true(f.ball.rules_ball.strong)
	assert_eq(f.player.held_look, "ball_heavy")
	assert_eq(f.current_attack(), PlayerStats.BASE_ATTACK + Equipment.ATTACK_PER_RANK + 2)  # 重い鉄球の特色：つよさ＋2
	assert_false(f.menu.choose("sword_1"))  # 持っていない品物は選べない

## 杖の枠は1つで、持っている杖（無の杖・炎の杖…）の中から選ぶ
func test_choose_staff_in_menu():
	f.run.inventory.equipment.gain("staff_none_1")
	f.run.inventory.equipment.gain("staff_fire_3")
	f.open_inventory()
	f.menu.select_slot(Equipment.Slot.STAFF)
	assert_eq(f.menu.listed_items(), ["staff_none_1", "staff_fire_3"])
	assert_true(f.menu.choose("staff_fire_3"))
	f.hotbar.select_slot(4, f.run.inventory.equipment)
	assert_eq(f.usable_spells(), [Magic.Spell.FIREBALL])
	assert_string_contains(f.hotbar_text(), "炎の杖★3")

## 広がる鉄球は当たる範囲が広い（特色 radius）
func test_wide_ball_hits_wider():
	var r := float(ItemCatalog.trait_value("ball_wide", "radius", 1.0))
	assert_false(IronBall.hits(Vector2.ZERO, 0, Vector2(10, 0), 0, IronBall.hit_radius(1.0)))
	assert_true(IronBall.hits(Vector2.ZERO, 0, Vector2(10, 0), 0, IronBall.hit_radius(r)))

## 町の武器屋で剣を買い、2で持ちかえて振ると、前の敵に当たる
func test_buy_sword_in_town_and_swing():
	f.run.inventory.money = 40
	f.shop_menu.open("weapon")
	assert_true(f.shop_menu.choose(0))
	assert_eq(f.run.inventory.money, 0)
	assert_eq(f.run.inventory.equipment.effective(Equipment.Slot.SWORD), 1)
	assert_true(f.hotbar.select_slot(2, f.run.inventory.equipment))
	f.shop_menu.close()
	_walk_out(_exit("town", "hills"))
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
	assert_eq(hp - e.walker.hp, Damage.sword(PlayerStats.BASE_ATTACK, 0, 0))
	assert_false(f.use_item())  # 振る間隔

func test_sword_not_usable_without_sword():
	f.hotbar.selected = Hotbar.Item.SWORD
	assert_false(f.swing_sword())

## 飛び降りてすぐに振ると落下斬り
func test_falling_slash_after_drop():
	f.run.inventory.equipment.gain("sword_1")
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
	assert_eq(hp - e.walker.hp, Damage.sword(PlayerStats.BASE_ATTACK, 0, 2))

## 剣は1段下の敵に当たる（高さの上乗せはない）。1段上の敵には、下から当たらない
func test_sword_down_but_not_up():
	f.run.inventory.equipment.gain("sword_1")
	f.hotbar.select_slot(2, f.run.inventory.equipment)
	var m := HeightMap.new(Vector2i(6, 3))
	m.set_height(Vector2i(1, 1), 1)
	f.map = m
	f.player.mover.map = m
	f.player.mover.place(Vector2i(1, 1))
	for e in f.enemies:
		e.queue_free()
	f.enemies.clear()
	var e := Enemy.new()
	e.setup(m, Vector2i(2, 1), Vector2.RIGHT, f.player, f.camera, EnemyKind.Kind.MELEE)
	add_child_autofree(e)
	e.set_process(false)
	f.enemies.append(e)
	e.walker.pos = f.player.mover.pos + Vector2(14, 0)
	f.player.mover.facing = Vector2.RIGHT
	f.run.stats.add_exp(PlayerStats.exp_to_reach(6))
	for i in 5:
		f.run.stats.allocate(PlayerStats.Stat.ATTACK)  # つよさ15
	var hp: int = e.walker.hp
	assert_true(f.swing_sword())
	assert_eq(hp - e.walker.hp, Damage.sword(PlayerStats.BASE_ATTACK + 5, 0, 0))
	# 入れ替えて、下から上の敵を斬る
	f.player.mover.place(Vector2i(2, 1))
	e.walker.pos = HeightMap.cell_center(Vector2i(1, 1))
	e.walker.height = 1
	f.player.mover.facing = Vector2.LEFT
	f.sword.update(1.0)
	hp = e.walker.hp
	assert_true(f.swing_sword())
	assert_eq(e.walker.hp, hp)

## 弓と矢を持ち、溜めて離すと、壁の向こうの敵にも山なりで当たる
func test_bow_from_camp_hits_over_wall():
	f.run.inventory.add("bow_1")
	f.run.inventory.add("arrow", 50)
	assert_eq(f.run.inventory.arrow_count(Arrow.Kind.NORMAL), 50)
	assert_true(f.hotbar.select_slot(3, f.run.inventory.equipment))
	var m := HeightMap.new(Vector2i(10, 3))
	m.set_wall(Vector2i(3, 1), true)
	f.map = m
	f.player.mover.map = m
	f.player.mover.place(Vector2i(1, 1))
	for e in f.enemies:
		e.queue_free()
	f.enemies.clear()
	var e := Enemy.new()
	e.setup(m, Vector2i(5, 1), Vector2.RIGHT, f.player, f.camera, EnemyKind.Kind.MELEE)
	add_child_autofree(e)
	e.set_process(false)
	f.enemies.append(e)
	assert_true(f.start_bow())
	f.bow.update(1.0)
	var r: float = f.bow.release()
	f._fire_arrow(Arrow.Kind.NORMAL, r, e.walker.pos)
	var hp: int = e.walker.hp
	for i in 30:
		f._step_shots(0.05)
	assert_eq(hp - e.walker.hp, Damage.bow(PlayerStats.BASE_ATTACK, 1.0, 1.0, 0))

func test_release_uses_one_arrow():
	f.run.inventory.equipment.gain("bow_1")
	f.run.inventory.add_arrows(Arrow.Kind.NORMAL, 2)
	f.hotbar.select_slot(3, f.run.inventory.equipment)
	assert_true(f.use_item())
	assert_true(f.release_bow())
	assert_eq(f.run.inventory.arrow_count(Arrow.Kind.NORMAL), 1)
	assert_eq(f.shots_in_flight(), 1)

## 飛んでいる矢は矢の形で、飛ぶ向きへ向き、傾きに合った模型になる。落ちると少しの間、刺さったまま見える
func test_arrow_drawn_as_arrow_and_sticks():
	f.run.inventory.equipment.gain("bow_1")
	f.run.inventory.add_arrows(Arrow.Kind.NORMAL, 1)
	f.hotbar.select_slot(3, f.run.inventory.equipment)
	assert_true(f.use_item())
	assert_true(f.release_bow())
	var a: Arrow = f._shots[0][0]
	var s: StackSprite = f._shots[0][1]
	assert_same(s._layers, Props.arrow_model(Arrow.Kind.NORMAL, atan(a.slope())).textures())
	assert_almost_eq(s.turn, a.direction().angle() - PI / 2, 0.001)
	var before: int = f._effects.size()
	for i in 40:
		f._step_shots(0.05)
	assert_eq(f.shots_in_flight(), 0)
	var c := HeightMap.world_to_cell(a.to)
	var sticks: bool = f.map.in_bounds(c) and not f.map.is_wall(c) and not f.map.is_water(c) and not f.map.is_pit(c)
	assert_eq(f._effects.size(), before + (1 if sticks else 0))

func test_no_arrows_no_charge():
	f.run.inventory.equipment.gain("bow_1")
	f.hotbar.select_slot(3, f.run.inventory.equipment)
	assert_false(f.start_bow())
	assert_string_contains(f.ui_message(), "矢がない")

func test_poison_arrow_choice_needs_skill():
	f.open_inventory()
	f.menu.select_slot(Equipment.Slot.BOW)
	assert_false(f.menu.choose_arrow(Arrow.Kind.POISON))
	f.run.stats.add_exp(PlayerStats.exp_to_reach(4))
	for i in 3:
		f.run.stats.allocate(PlayerStats.Stat.BOW)
	assert_true(f.menu.choose_arrow(Arrow.Kind.POISON))

func _solo_enemy(m: HeightMap, cell: Vector2i, kind := EnemyKind.Kind.MELEE) -> Enemy:
	for e in f.enemies:
		e.queue_free()
	f.enemies.clear()
	var e := Enemy.new()
	e.setup(m, cell, Vector2.RIGHT, f.player, f.camera, kind)
	add_child_autofree(e)
	e.set_process(false)
	f.enemies.append(e)
	return e

func _use_map(m: HeightMap, cell: Vector2i) -> void:
	f.map = m
	f.player.mover.map = m
	f.player.mover.place(cell)

## 無の杖で、敵にカーソルを重ねて無の弾を使うと、その高さへまっすぐ飛んで当たる
func test_null_bolt_auto_aims_enemy():
	assert_false(f.hotbar.select_slot(4, f.run.inventory.equipment))  # 最初は鉄球だけ
	f.run.inventory.add("staff_none_1")
	assert_true(f.hotbar.select_slot(4, f.run.inventory.equipment))
	var m := HeightMap.new(Vector2i(12, 3))
	for y in 3:
		m.set_height(Vector2i(1, y), 2)
	_use_map(m, Vector2i(1, 1))
	var e := _solo_enemy(m, Vector2i(6, 1))
	var screen: Vector2 = f.camera.world_to_screen(e.walker.pos, e.walker.height * StackSprite.LEVEL_PX + 4.0)
	var aim: Dictionary = f.magic_aim_at(screen)
	assert_eq(aim["enemy"], e)
	var hp: int = e.walker.hp
	assert_true(f.cast_spell(screen))
	assert_eq(f.mana.value, 50.0 - Magic.COST[Magic.Spell.NULL_BOLT])
	for i in 60:
		f._step_bolts(1.0 / 60)
	assert_eq(hp - e.walker.hp, Damage.magic(PlayerStats.BASE_ATTACK, Magic.POWER[Magic.Spell.NULL_BOLT], 0))
	assert_false(f.cast_spell(screen))  # 次に使えるまで少し待つ
	assert_string_contains(f.hotbar_text(), "無の弾(2)")  # あと何秒で使えるか

## マナが足りなければ使えない
func test_no_mana_no_cast():
	f.run.inventory.add("staff_none_1")
	f.hotbar.select_slot(4, f.run.inventory.equipment)
	f.mana.value = 2.0
	assert_false(f.cast_spell(Vector2(200, 90)))
	assert_string_contains(f.ui_message(), "マナが足りない")

## 炎の杖（ランク3）に持ちかえる。魔法に3ポイント振ると2つ目が使え、ホイールで替えられる
func test_fire_staff_and_wheel():
	var eq: Equipment = f.run.inventory.equipment
	eq.gain("staff_none_1")
	eq.gain("staff_fire_3")
	assert_eq(eq.current(Equipment.Slot.STAFF), "staff_none_1")
	assert_true(eq.equip("staff_fire_3"))
	f.hotbar.select_slot(4, eq)
	assert_eq(f.usable_spells(), [Magic.Spell.FIREBALL])
	f.run.stats.add_exp(PlayerStats.exp_to_reach(6))
	for i in 3:
		f.run.stats.allocate(PlayerStats.Stat.MAGIC)
	assert_eq(f.usable_spells().size(), 2)
	f.cycle_spell(1)
	assert_eq(f.current_spell(), Magic.Spell.FIRE_PILLAR)
	assert_string_contains(f.hotbar_text(), "火柱")
	assert_string_contains(f.status_text(), "マナ50/50")

## 火の玉が自分より高い地面で弾けても、そこは燃えない（下から上へは攻撃できない）
func test_fireball_does_not_burn_higher_ground():
	var m := HeightMap.new(Vector2i(12, 3))
	for y in 3:
		for x in range(4, 12):
			m.set_height(Vector2i(x, y), 2)
	_use_map(m, Vector2i(1, 1))
	f._explode(HeightMap.cell_center(Vector2i(5, 1)), 2 * StackSprite.LEVEL_PX, 0)
	assert_eq(f.fires_burning(), 0)
	f._explode(HeightMap.cell_center(Vector2i(2, 1)), 0.0, 0)
	assert_eq(f.fires_burning(), 1)

## 火柱は下の敵に当たってやけどにする。崖の上（自分より高い所）の敵には当たらない
func test_fire_pillar_only_hits_at_or_below():
	var eq: Equipment = f.run.inventory.equipment
	eq.gain("staff_fire_3")
	eq.equip("staff_fire_3")
	f.run.stats.add_exp(PlayerStats.exp_to_reach(6))
	for i in 3:
		f.run.stats.allocate(PlayerStats.Stat.MAGIC)
	f.hotbar.select_slot(4, eq)
	f.cycle_spell(1)
	assert_eq(f.current_spell(), Magic.Spell.FIRE_PILLAR)
	var m := HeightMap.new(Vector2i(12, 3))
	for y in 3:
		for x in range(4, 12):
			m.set_height(Vector2i(x, y), 2)
	_use_map(m, Vector2i(1, 1))
	var e := _solo_enemy(m, Vector2i(4, 1))
	var hp: int = e.walker.hp
	f._fire_pillar(e.walker.pos)
	assert_eq(e.walker.hp, hp)
	# 崖の上から、下の敵を焼く
	f.player.mover.place(Vector2i(5, 1))
	e.walker.pos = HeightMap.cell_center(Vector2i(2, 1))
	e.walker.height = 0
	e.walker.hp = 50
	f._fire_pillar(e.walker.pos)
	assert_eq(50 - e.walker.hp, Damage.magic(f.current_attack(), Magic.POWER[Magic.Spell.FIRE_PILLAR], 3))
	assert_eq(f.current_attack(), PlayerStats.BASE_ATTACK + Equipment.rank_attack(3))  # 杖のランクもつよさに足される
	assert_true(e.walker.is_burning())

## 火の玉は当たった所で弾けて敵をやけどにし、地面が少しの間燃える
func test_fireball_burns():
	var eq: Equipment = f.run.inventory.equipment
	eq.gain("staff_fire_2")
	eq.equip("staff_fire_2")
	f.hotbar.select_slot(4, eq)
	var m := HeightMap.new(Vector2i(12, 3))
	_use_map(m, Vector2i(1, 1))
	var e := _solo_enemy(m, Vector2i(5, 1))
	var screen: Vector2 = f.camera.world_to_screen(e.walker.pos, 4.0)
	var hp: int = e.walker.hp
	assert_true(f.cast_spell(screen))
	for i in 60:
		f._step_bolts(1.0 / 60)
	assert_eq(hp - e.walker.hp, Damage.magic(f.current_attack(), Magic.POWER[Magic.Spell.FIREBALL], 0))
	assert_true(e.walker.is_burning())
	assert_eq(f.fires_burning(), 1)

## 炎の雨：高い所から使うほど広い。自分より高い所の敵には当たらない
func test_fire_rain_from_high_ground():
	var eq: Equipment = f.run.inventory.equipment
	eq.gain("staff_star")
	eq.equip("staff_star")
	f.run.stats.add_exp(PlayerStats.exp_to_reach(10))
	for i in 9:
		f.run.stats.allocate(PlayerStats.Stat.MAGIC)
	f.hotbar.select_slot(4, eq)
	f.cycle_spell(2)
	assert_eq(f.current_spell(), Magic.Spell.FIRE_RAIN)
	var m := HeightMap.new(Vector2i(14, 5))
	for y in 5:
		for x in 3:
			m.set_height(Vector2i(x, y), 3)
	_use_map(m, Vector2i(1, 2))
	var low := _solo_enemy(m, Vector2i(6, 2))
	var hp: int = low.walker.hp
	# 地面の点を狙う：段差3なら広さは 16 + 24 = 40px。敵は中心から 20px
	f._fire_rain(low.walker.pos + Vector2(20, 0))
	assert_lt(low.walker.hp, hp)

## 敵の落とし物は拾える（エリアを出ると消える）
func test_enemy_drop_and_pick():
	var c := Continent.START_CELL + Vector2i(2, 0)
	f.spawn_drop(c, "potion", 1)
	f.player.mover.place(c)
	f._process(0.016)
	assert_eq(f.run.inventory.count("potion"), 1)
	assert_eq(f.drops_left(), 0)
	f.spawn_drop(c, "potion", 1)
	_walk_out(_exit("town", "hills"))
	assert_eq(f.drops_left(), 0)

## 技能（体の動き）：しゃがみ・受け身・よじ登りが、ポイントを振ると使えるようになる
func test_move_skills_apply():
	f.run.stats.add_exp(PlayerStats.exp_to_reach(10))
	f.open_inventory()
	watch_signals(f.menu)
	for i in 9:
		f.menu.allocate(PlayerStats.Stat.MOVE)
	assert_signal_emit_count(f.menu, "skill_learned", 3)
	assert_true(f.player.can_crouch)
	assert_eq(f.rules.max_drop, 4)
	assert_true(f.player.mover.slow_climb)
	assert_string_contains(f.ui_message(), "よじ登り")

## しゃがむと、撃つ敵の弾が当たらない
func test_crouch_dodges_bullets():
	var b := Bullet.new()
	b.pos = f.player.mover.pos
	b.height = f.player.mover.height
	b.vel = Vector2(1, 0)
	b.damage = 3
	f.player.crouching = true
	f._bullets.append([b, StackSprite.new()])
	f._step_bullets(0.016)
	assert_eq(f.player.hp, f.player.max_hp)

## 防具を手に入れると最大いのちが増える
func test_armor_raises_max_hp():
	f.run.inventory.add("armor_1")
	f._process(0.016)
	assert_eq(f.player.max_hp, PlayerStats.BASE_HP + Equipment.HP_PER_ARMOR_RANK)

## 回転斬り：剣の技能を3つ覚えると、Space で後ろの敵にも当たる
func test_spin_slash_needs_skill():
	f.run.inventory.equipment.gain("sword_1")
	f.hotbar.select_slot(2, f.run.inventory.equipment)
	assert_false(f.spin_slash())
	f.run.stats.add_exp(PlayerStats.exp_to_reach(10))
	for i in 9:
		f.run.stats.allocate(PlayerStats.Stat.SWORD)
	var m := HeightMap.new(Vector2i(8, 3))
	_use_map(m, Vector2i(3, 1))
	var e := _solo_enemy(m, Vector2i(2, 1))
	f.player.mover.facing = Vector2.RIGHT
	var hp: int = e.walker.hp
	assert_true(f.spin_slash())
	assert_lt(e.walker.hp, hp)

func test_easy_mode_from_settings_page():
	f.open_inventory()
	f.menu.show_page(InventoryMenu.Page.SETTINGS)
	f.menu.set_easy(true)
	assert_true(f.settings.easy_mode)
	f.hurt_player(4)
	assert_eq(f.player.hp, PlayerStats.BASE_HP - 2)

## 主人公の姿は、手に持つ物と防具で変わる。鉄球は持っている間、両手で抱えて見せる（鉄球の絵は出さない）
func test_hero_look_follows_held_item():
	var eq: Equipment = f.run.inventory.equipment
	f._process(0.016)
	f.ball._process(0.0)
	assert_eq(f.player.held_look, "ball_1")
	assert_true(f.ball.force_hidden)
	assert_true(f.ball.rules_ball.drop_at(f.player.mover, f.map, f.player.mover.pos))
	f._process(0.016)
	f.ball._process(0.0)
	assert_eq(f.player.held_look, "")  # 落としたあとは手に何もない
	assert_false(f.ball.force_hidden)
	# 放した直後は、両手を前に出した姿。鉄球は手元から落ちていく
	assert_eq(f.player.anim.pose(), "release")
	assert_same(f.player._layers, HeroModel.build("", "", "release").textures())
	f.player.anim.update(HeroAnim.RELEASE_TIME, 0.0)
	eq.gain("staff_none_1")
	assert_true(f.hotbar.select_slot(4, eq))
	f._process(0.016)
	assert_eq(f.player.held_look, "staff_none_1")
	eq.gain("sword_1")
	eq.gain("armor_1")
	assert_true(f.hotbar.select_slot(2, eq))
	f._process(0.016)
	assert_eq([f.player.held_look, f.player.armor_look], ["sword_1", "armor_1"])
	assert_same(f.player._layers, HeroModel.build("sword_1", "armor_1").textures())

## 放した鉄球は、主人公の手元（体の前、足元より上）から落とした点へ落ちていき、着くと土ぼこりが立つ
func test_dropped_ball_falls_from_hands_to_target():
	_walk_out(_exit("town", "hills"))
	f.player.mover.place(_open_cell())
	f.player.mover.facing = Vector2.RIGHT
	var target: Vector2 = f.player.mover.pos + Vector2(14, 0)
	var b: IronBall = f.ball.rules_ball
	assert_true(b.drop_at(f.player.mover, f.map, target))
	f.ball._process(0.0)
	assert_almost_eq(f.ball.world_pos, f.player.mover.pos + Vector2(Ball.HAND_FORWARD_PX, 0), Vector2(0.01, 0.01))
	assert_gt(f.ball.lift_px, 0.0)
	f.ball._process(IronBall.DROP_TIME * 0.5)
	assert_gt(f.ball.world_pos.x, f.player.mover.pos.x + Ball.HAND_FORWARD_PX)
	var dust_before: int = f.get_children().filter(func(n: Node) -> bool: return n is ImpactDust).size()
	f.ball._process(1.0)
	assert_eq(f.ball.world_pos, b.pos)
	assert_eq(f.ball.lift_px, 0.0)
	assert_eq(f.get_children().filter(func(n: Node) -> bool: return n is ImpactDust).size(), dust_before + 1)

## 歩くと足を交互に出す姿になり、止まると立ち姿に戻る
func test_walking_switches_step_poses():
	f.player.anim.update(0.016, 1.0)
	f.player._apply_model()
	assert_same(f.player._layers, HeroModel.build(f.player.held_look, f.player.armor_look, "step_l").textures())
	f.player.anim.update(0.016, 0.0)
	f.player._apply_model()
	assert_same(f.player._layers, HeroModel.build(f.player.held_look, f.player.armor_look).textures())

## 本当の画面は640×360で、ゲームの座標（320×180）を2倍にして描く。主人公はボクセル1つを本当の画面の1pxで、ふちを付けて描く
func test_pixel_scale_and_fine_hero():
	assert_eq(f.scale, Vector2.ONE * StackCamera.PIXEL_SCALE)
	assert_eq(f.player.voxel_scale, 1.0 / StackCamera.PIXEL_SCALE)
	assert_gt(f.player.outline_color.a, 0.0)
	assert_eq(f.menu.scale, Vector2.ONE * StackCamera.PIXEL_SCALE)

## インベントリの姿は、選んでいる枠の品物を持つ
func test_portrait_holds_selected_slot_item():
	f.run.inventory.equipment.gain("staff_fire_3")
	f.run.inventory.equipment.equip("staff_fire_3")
	f.open_inventory()
	f.menu.select_slot(Equipment.Slot.STAFF)
	assert_eq(f.menu.portrait_look(), ["staff_fire_3", ""])
	f.menu.select_slot(Equipment.Slot.BALL)
	assert_eq(f.menu.portrait_look(), ["ball_1", ""])

## 動きの姿：薬を飲む・杖をふるう・ダメージ・倒れる・再開で、主人公の姿が変わる
func test_actions_set_hero_poses():
	f.run.inventory.add("potion", 1)
	f.player.set_hp(2)
	assert_true(f.use_tool())
	assert_eq(f.player.anim.pose(), "drink")
	f.player.anim.update(HeroAnim.DRINK_TIME, 0.0)
	f.run.inventory.add("staff_none_1")
	assert_true(f.hotbar.select_slot(4, f.run.inventory.equipment))
	assert_true(f.cast_spell(Vector2(200, 90)))
	assert_eq(f.player.anim.pose(), "cast")
	f.player.set_look(f.held_look(), "")
	assert_same(f.player._layers, HeroModel.build(f.held_look(), "", "cast").textures())
	assert_true(f.hurt_player(1))
	assert_gt(f.player.anim.hurt_flash(), 0.0)
	f.kill_player(false)
	f.player.anim.update(HeroAnim.KNEEL_TIME, 0.0)
	f.player._apply_model()
	assert_same(f.player._layers, HeroModel.build("", f.player.armor_look, "down").textures())
	f.respawn()
	assert_eq(f.player.anim.pose(), "")

# ---- 大陸の全体（2026-11-25）：たき火・仕掛け・封印の門・商人・全体マップ

func _gimmick(area_id: String, kind: Gimmick.Kind) -> Gimmick:
	for g in f.world.area(area_id).gimmicks:
		if g.kind == kind:
			return g
	return null

func _gimmick_area(kind: Gimmick.Kind) -> String:
	for id in f.world.ids():
		if _gimmick(id, kind) != null:
			return id
	return ""

func test_resting_at_another_bonfire_sets_respawn_there():
	f.enter_area("mt_2", Vector2i(2, 2))
	var info: Dictionary = Continent.load_map(f.area)[1]
	var fire: Vector2i = info["checkpoint"]
	f.player.mover.place(fire + Vector2i(0, 1))
	f._process(0.016)
	assert_eq(f.run.checkpoint_area, "mt_2")
	f.kill_player(false)
	_finish_death()
	assert_eq(f.area.id, "mt_2")
	assert_eq(f.player.mover.cell(), fire + Vector2i(0, 1))

func test_entering_an_area_marks_it_visited():
	assert_true(f.run.has_visited("town"))
	assert_false(f.run.has_visited("hills"))
	_walk_out(_exit("town", "hills"))
	assert_eq(f.area.id, "hills")
	assert_true(f.run.has_visited("hills"))

func test_ball_from_above_breaks_a_crack():
	var id := _gimmick_area(Gimmick.Kind.CRACK)
	var g := _gimmick(id, Gimmick.Kind.CRACK)
	f.enter_area(id, g.cells[0])
	assert_true(f.map.is_wall(g.cells[0]))
	assert_eq(f.gimmick_markers(g.id), 1)
	f.ball.rules_ball.fall_levels = 1
	f._on_ball_landed(HeightMap.cell_center(g.cells[0]), 0)
	assert_true(f.run.is_gimmick_open(g.id))
	assert_false(f.map.is_wall(g.cells[0]))
	assert_eq(f.gimmick_markers(g.id), 0)
	# 出て入り直しても、開いたまま
	f.enter_area("town", Continent.START_CELL)
	f.enter_area(id, g.cells[0])
	assert_false(f.map.is_wall(g.cells[0]))

func test_arrow_on_target_lowers_bridge():
	var id := _gimmick_area(Gimmick.Kind.TARGET)
	var g := _gimmick(id, Gimmick.Kind.TARGET)
	f.enter_area(id, Continent.START_CELL)
	assert_true(f.map.is_water(g.cells[0]))
	var a := Arrow.new()
	a.launch(HeightMap.cell_center(g.trigger[0]), 8.0, HeightMap.cell_center(g.trigger[0]), 8.0)
	a.from_h = 8
	f._arrow_landed(a, 1)
	assert_true(f.run.is_gimmick_open(g.id))
	for c in g.cells:
		assert_false(f.map.is_water(c))

func test_fire_burns_thorns():
	var id := _gimmick_area(Gimmick.Kind.THORNS)
	var g := _gimmick(id, Gimmick.Kind.THORNS)
	f.enter_area(id, Continent.START_CELL)
	f._burn_gimmicks(HeightMap.cell_center(g.cells[0]), 4.0)
	assert_true(f.run.is_gimmick_open(g.id))
	assert_false(f.map.is_wall(g.cells[0]))

func test_sword_cuts_vines():
	var id := _gimmick_area(Gimmick.Kind.VINES)
	var g := _gimmick(id, Gimmick.Kind.VINES)
	f.enter_area(id, Continent.START_CELL)
	f.run.inventory.equipment.gain("sword_1")
	var c := g.cells[0]
	var stand := c
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var n: Vector2i = c + d
		if not f.map.is_wall(n) and not f.map.is_water(n) and f.map.get_height(n) == f.map.get_height(c):
			stand = n
			break
	f.player.mover.place(stand)
	f.player.mover.facing = Vector2(c - stand)
	assert_true(f.swing_sword())
	assert_true(f.run.is_gimmick_open(g.id))

# ---- 2026-11-26（3回目の直し）：仕掛けを増やした

## 押し板：鉄球を板に置くと鉄格子が上がり、板は沈んだ姿になる
func test_ball_on_plate_raises_bars():
	var id := _gimmick_area(Gimmick.Kind.PLATE)
	var g := _gimmick(id, Gimmick.Kind.PLATE)
	f.enter_area(id, Continent.START_CELL)
	assert_true(f.map.is_wall(g.cells[0]), "鉄格子")
	assert_false(f.map.is_wall(g.trigger[0]), "板の上は歩ける")
	assert_eq(f.gimmick_markers(g.id), g.cells.size())
	f.ball.rules_ball.fall_levels = 0
	f._on_ball_landed(HeightMap.cell_center(g.trigger[0]), 0)
	assert_true(f.run.is_gimmick_open(g.id))
	assert_false(f.map.is_wall(g.cells[0]))
	assert_eq(f.gimmick_markers(g.id), 0)

## レバー：となりに立つと「F：レバーを引く」が出て、F で鉄格子が上がる
func test_lever_pulled_with_f():
	var id := _gimmick_area(Gimmick.Kind.LEVER)
	var g := _gimmick(id, Gimmick.Kind.LEVER)
	f.enter_area(id, Continent.START_CELL)
	assert_false(f.try_pull_lever(), "遠いと引けない")
	var lever := g.trigger[0]
	var stand := lever
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var n: Vector2i = lever + d
		if not f.map.is_wall(n) and not f.map.is_water(n) and absi(f.map.get_height(n) - f.map.get_height(lever)) <= 1:
			stand = n
			break
	assert_ne(stand, lever)
	f.player.mover.place(stand)
	f._title_time = 0.0
	assert_eq(f.ui_message(), "F：レバーを引く")
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = KEY_F
	f._unhandled_input(ev)
	assert_true(f.run.is_gimmick_open(g.id))
	assert_false(f.map.is_wall(g.cells[0]))

## 魔法の水晶：魔法を当てると、入口の足場が2段せり上がり、3段高い台へ登れる
func test_magic_on_crystal_raises_steps():
	var id := _gimmick_area(Gimmick.Kind.CRYSTAL)
	var g := _gimmick(id, Gimmick.Kind.CRYSTAL)
	f.enter_area(id, Continent.START_CELL)
	var low: int = f.map.get_height(g.cells[0])
	assert_true(f.map.is_wall(g.trigger[0]), "水晶は通れない")
	f._magic_gimmicks(HeightMap.cell_center(g.trigger[0]), 4.0)
	assert_true(f.run.is_gimmick_open(g.id))
	for i in g.cells.size():
		assert_eq(f.map.get_height(g.cells[i]), g.heights[i])
	assert_gt(f.map.get_height(g.cells[0]), low)
	f.enter_area("town", Continent.START_CELL)
	f.enter_area(id, Continent.START_CELL)
	assert_eq(f.map.get_height(g.cells[0]), g.heights[0], "入り直しても上がったまま")

## もろい壁：爆弾でだけ崩れる
func test_bomb_breaks_brittle_wall():
	var id := _gimmick_area(Gimmick.Kind.BRITTLE)
	var g := _gimmick(id, Gimmick.Kind.BRITTLE)
	f.enter_area(id, Continent.START_CELL)
	assert_true(f.map.is_wall(g.cells[0]))
	f.ball.rules_ball.fall_levels = 3
	f._on_ball_landed(HeightMap.cell_center(g.cells[0]), 0)
	assert_false(f.run.is_gimmick_open(g.id), "鉄球では崩れない")
	f._bombs.append([HeightMap.cell_center(g.cells[0]) + Vector2(10, 0), f.map.get_height(g.cells[0]), 0.0, 10, 8])
	f._process(0.016)
	assert_true(f.run.is_gimmick_open(g.id))
	assert_false(f.map.is_wall(g.cells[0]))

func test_tower_seal_needs_four_bosses():
	f.enter_area("town", Vector2i(12, 13))
	var ex := _exit("town", "tw_1", true)
	assert_eq(ex.door_id, RunState.SEAL_DOOR)
	f.player.mover.place(_mid(ex, 1))
	assert_string_contains(f.ui_message(), "封印")
	assert_false(f.try_open_door())
	for b in RunState.REGION_BOSSES:
		f.run.on_boss_killed(b, 1)
	assert_true(f.try_open_door())
	assert_true(f.run.is_door_open(RunState.SEAL_DOOR))

## 町の商人のそばで F を押すとお店が開き、買える。鍛冶屋では素材とお金で作る
func test_town_shops_and_smith():
	f.enter_area("town", Continent.START_CELL)
	var shops: Array = f.area.merchants
	assert_eq(shops.map(func(m): return m[1]), ["tool", "weapon", "smith"])
	f.player.mover.place(shops[0][0] + Vector2i(0, 1))
	f._title_time = 0.0
	f._start_hint_time = 0.0
	assert_string_contains(f.ui_message(), "道具屋")
	assert_true(f.try_open_shop())
	assert_true(f.shop_menu.is_open())
	assert_eq(f.shop_menu.shop_id, "tool")
	assert_false(f.shop_menu.choose(0))  # お金がない
	f.run.inventory.money = 15
	assert_true(f.shop_menu.choose(0))
	assert_eq(f.run.inventory.count("potion"), 1)
	f.player.mover.place(Continent.START_CELL + Vector2i(0, 6))
	f._process(0.016)
	assert_false(f.shop_menu.is_open(), "離れると閉じる")
	# 鍛冶屋：丈夫な枝2と鉄くず2とお金10で剣
	f.player.mover.place(shops[2][0] + Vector2i(0, 1))
	assert_true(f.try_open_shop())
	f.run.inventory.money = 10
	f.run.inventory.add("wood", 2)
	f.run.inventory.add("scrap", 2)
	var idx := -1
	for i in Recipes.LIST.size():
		if Recipes.LIST[i][0] == "sword_1":
			idx = i
	assert_true(f.shop_menu.choose(idx))
	assert_true(f.run.inventory.equipment.has("sword_1"))
	assert_eq(f.run.inventory.count("wood"), 0)

## お店：スクロールしている間は説明を出さない。止まってからカーソルを動かすと出る。長い行は折り返して見切れない（2026-11-26）
func test_shop_tip_waits_while_scrolling_and_rows_fit():
	f.enter_area("town", Continent.START_CELL)
	f.player.mover.place(f.area.merchants[2][0] + Vector2i(0, 1))
	assert_true(f.try_open_shop())
	var sm: ShopMenu = f.shop_menu
	var b: Button = sm._box.get_child(0)
	b.mouse_entered.emit()
	assert_true(sm.tip.visible)
	sm._scroll.get_v_scroll_bar().value_changed.emit(30.0)
	assert_false(sm.tip.visible, "スクロールすると消える")
	var b2: Button = sm._box.get_child(3)
	b2.mouse_entered.emit()
	assert_false(sm.tip.visible, "スクロール中は出ない")
	sm.tip._process(ItemTip.QUIET_SECONDS + 0.05)
	var motion := InputEventMouseMotion.new()
	sm.tip._input(motion)
	assert_true(sm.tip.visible, "止まってからカーソルを動かすと出る")
	assert_eq(sm.tip.item_id, Recipes.LIST[3][0])
	for c in sm._box.get_children():
		assert_lte((c as Button).get_combined_minimum_size().x, ShopMenu.ROW_W + 0.5, "行は枠に収まる")

## 敵を倒すと、お金とその地方の素材などを落とす
func test_enemy_drops_loot():
	_walk_out(_exit("town", "hills"))
	var e: Enemy = f.enemies[0]
	e.walker.take_damage(999)
	assert_gt(f.drops_left(), 0)
	assert_eq(f._drops[0][1], "money")

## 盾持ちは正面からの剣を防ぎ、背中からは通る
func test_shield_blocks_front():
	f.run.inventory.add("sword_1")
	f.hotbar.select_slot(2, f.run.inventory.equipment)
	var m := HeightMap.new(Vector2i(8, 3))
	_use_map(m, Vector2i(2, 1))
	for e in f.enemies:
		e.queue_free()
	f.enemies.clear()
	var e := Enemy.new()
	e.setup(m, Vector2i(3, 1), Vector2.LEFT, f.player, f.camera, EnemyKind.Kind.SHIELD)
	add_child_autofree(e)
	e.set_process(false)
	f.enemies.append(e)
	f.player.mover.facing = Vector2.RIGHT
	var hp: int = e.walker.hp
	assert_true(f.swing_sword())
	assert_eq(e.walker.hp, hp)
	e.face = Vector2.RIGHT  # 背中を向けた（盾は face の向き）
	f.sword.update(1.0)
	assert_true(f.swing_sword())
	assert_lt(e.walker.hp, hp)

## 浮いている敵（コウモリ・蜂）に剣と鉄球は届かない。矢と魔法は当たる
func test_flyers_dodge_sword_and_ball():
	var m := HeightMap.new(Vector2i(8, 3))
	_use_map(m, Vector2i(2, 1))
	for k in [EnemyKind.Kind.FLYER, EnemyKind.Kind.WASP]:
		var e := _solo_enemy(m, Vector2i(3, 1), k)
		var hp: int = e.walker.hp
		assert_false(f.damage_target(e, 3, f.player.mover.pos, "", Color.WHITE, "sword"))
		assert_false(f.damage_target(e, 3, e.walker.pos, "", Color.WHITE, "ball"))
		assert_eq(e.walker.hp, hp)
		assert_true(f.damage_target(e, 3, f.player.mover.pos, "", Color.WHITE, "arrow"))
		assert_true(f.damage_target(e, 3, f.player.mover.pos, "", Color.WHITE, "magic"))
		assert_eq(e.walker.hp, hp - 6)

## 甲虫はかたい（剣は1だけ）。鉄球でひっくり返すと、剣がふつうに入る
func test_beetle_flips_under_ball():
	var m := HeightMap.new(Vector2i(8, 3))
	_use_map(m, Vector2i(2, 1))
	var e := _solo_enemy(m, Vector2i(3, 1), EnemyKind.Kind.BEETLE)
	var hp: int = e.walker.hp
	f.damage_target(e, 8, f.player.mover.pos, "", Color.WHITE, "sword")
	assert_eq(e.walker.hp, hp - 1)
	f.damage_target(e, 2, e.walker.pos, "", Color.WHITE, "ball")
	assert_gt(e.flipped, 0.0)
	f.damage_target(e, 8, f.player.mover.pos, "", Color.WHITE, "sword")
	assert_eq(e.walker.hp, hp - 1 - 2 - 8)

## 目を回しているイノシシには2倍入る。すけている亡霊には入らない
func test_stunned_double_and_faded_pass():
	var m := HeightMap.new(Vector2i(8, 3))
	_use_map(m, Vector2i(2, 1))
	var e := _solo_enemy(m, Vector2i(3, 1), EnemyKind.Kind.CHARGER)
	var hp: int = e.walker.hp
	e.stunned = 1.0
	f.damage_target(e, 4, f.player.mover.pos)
	assert_eq(e.walker.hp, hp - 8)
	var g := _solo_enemy(m, Vector2i(3, 1), EnemyKind.Kind.GHOST)
	g.faded = true
	assert_false(f.damage_target(g, 4, f.player.mover.pos, "", Color.WHITE, "arrow"))

## 投石兵の石は、落ちる所に立っているとダメージ。よければ当たらない
func test_lobbed_stone_hits_where_it_lands():
	var m := HeightMap.new(Vector2i(10, 3))
	_use_map(m, Vector2i(2, 1))
	var e := _solo_enemy(m, Vector2i(8, 1), EnemyKind.Kind.LOBBER)
	f._on_enemy_lobbed(f.player.mover.pos, 0, 0.5, 4, e)
	f._step_lobs(0.6)
	assert_eq(f.player.hp, PlayerStats.BASE_HP - 4)
	f.player.clear_invulnerable()
	f._on_enemy_lobbed(f.player.mover.pos + Vector2(32, 0), 0, 0.5, 4, e)
	f._step_lobs(0.6)
	assert_eq(f.player.hp, PlayerStats.BASE_HP - 4)

## 擬態箱は宝箱のふりをしていて、近づくか攻撃されると目を覚ます
func test_mimic_wakes_up():
	var m := HeightMap.new(Vector2i(10, 3))
	_use_map(m, Vector2i(1, 1))
	var e := _solo_enemy(m, Vector2i(8, 1), EnemyKind.Kind.MIMIC)
	assert_false(e.awake)
	assert_false(e.touch_hurts())
	f.damage_target(e, 1, f.player.mover.pos, "", Color.WHITE, "arrow")
	assert_true(e.awake)

## 防具の守りで受けるダメージが減り、足の速い服で速くなる
func test_armor_traits():
	f.run.inventory.add("armor_leather")
	f.run.inventory.add("armor_travel")
	f.run.inventory.equipment.equip("armor_leather")
	f.apply_stats()
	var hp: int = f.player.hp
	f.hurt_player(4)
	assert_eq(hp - f.player.hp, 4 - 1)
	f.run.inventory.equipment.equip("armor_travel")
	f.apply_stats()
	assert_almost_eq(f.player.speed_mult, 1.1, 0.001)

## 道具はホイールで替える。力の薬で少しの間つよさ＋3
func test_tools_cycle_and_power_potion():
	f.run.inventory.add("potion", 1)
	f.run.inventory.add("power", 1)
	f.hotbar.select_slot(5)
	assert_eq(f.run.inventory.current_tool(), "potion")
	f.run.inventory.cycle_tool(1)
	assert_eq(f.run.inventory.current_tool(), "power")
	var before: int = f.current_attack()
	assert_true(f.use_item())
	assert_eq(f.current_attack(), before + 3)
	assert_string_contains(f.status_text(), "力")
	f._process(31.0)
	assert_eq(f.current_attack(), before)

## ボス：ボスの間に入るといて、倒すと覚えられ、ボスの素材（装備ではない）を落とす。入り直しても戻らない
func test_boss_defeat_is_remembered():
	f.enter_area("mt_5", Vector2i(10, 18))
	assert_eq(f.bosses.size(), 1)
	var b: Boss = f.bosses[0]
	assert_eq(b.group, "岩転がしの巨人")
	b.walker.take_damage(9999)
	assert_true(f.run.is_boss_defeated("岩転がしの巨人"))
	var ids: Array = f._drops.map(func(d): return d[1])
	assert_false("sword_giant" in ids)
	assert_true("giant_core" in ids)
	f.enter_area("mt_5", Vector2i(10, 18))
	assert_eq(f.bosses.size(), 0)

## ボスの間の門は、その地方の印を3つ持つと開く（たくさん探索してからボスを倒す形）
func test_boss_door_needs_three_seals():
	f.enter_area("mt_4", Vector2i(10, 7))
	var ex := _exit("mt_4", "mt_5", true)
	assert_not_null(ex)
	f.player.mover.place(_mid(ex, 1))
	assert_string_contains(f.ui_message(), "あと3個")
	assert_false(f.try_open_door())
	f.run.inventory.add("seal_mt", 3)
	assert_eq(f.ui_message(), "F：門を開ける")
	assert_true(f.try_open_door())

## 死んだらボスの体力は戻る
func test_boss_heals_when_player_dies():
	f.enter_area("gr_5", Vector2i(2, 9))
	var b: Boss = f.bosses[0]
	b.walker.take_damage(10)
	f.kill_player(false)
	_finish_death()
	f.enter_area("gr_5", Vector2i(2, 9))
	assert_eq(f.bosses[0].walker.hp, f.bosses[0].walker.max_hp)

## 双子は2体で、両方倒すと1つのボスとして数える
func test_twins_count_once():
	f.enter_area("tw_2", Vector2i(9, 2))
	assert_eq(f.bosses.size(), 2)
	f.bosses[0].walker.take_damage(9999)
	assert_false(f.run.is_boss_defeated("双子"))
	f.bosses[1].walker.take_damage(9999)
	assert_true(f.run.is_boss_defeated("双子"))
	assert_eq(f.run.bosses_defeated, 1)

## らせん塔の番人は背中にしか攻撃が効かない
func test_guardian_only_hurt_from_behind():
	f.enter_area("tw_3", Vector2i(9, 1))
	var b: Boss = f.bosses[0]
	var front: Vector2 = b.walker.pos + b.facing() * 20.0
	var back: Vector2 = b.walker.pos - b.facing() * 20.0
	assert_true(b.blocks(front))
	assert_false(b.blocks(back))

## ブライトの光で画面が白くなる。設定で弱められる
func test_bright_flash_can_be_softened():
	f.flash_screen(1.5)
	f._process(0.016)
	var strong: float = f._flash.color.a
	f.settings.soft_flash = true
	f._process(0.016)
	assert_gt(strong, 0.5)
	assert_lt(f._flash.color.a, strong)

## ブライトを倒すとゲームの終わり（そのあとも遊べる）
func test_bright_ends_the_game():
	f.enter_area("tw_4", Vector2i(9, 1))
	f.bosses[0].walker.take_damage(99999)
	assert_true(f.run.cleared)
	assert_string_contains(f.ui_message(), "おわり")
	assert_eq(f.area_state.result, AreaState.Result.PLAYING)

func test_map_toggles_with_m():
	assert_false(f.map_view.visible)
	f.toggle_map()
	assert_true(f.map_view.visible)
	assert_eq(f.map_view.current_id, "town")
	f.toggle_map()
	assert_false(f.map_view.visible)

## 2026-11-25 夜（2回目の直し）：全体マップに北・自分のいる所と画面の上の向き・次のエリアへの道・門を出す
func test_map_shows_exits_gates_and_unvisited_neighbors():
	f.toggle_map()
	var mv: WorldMapView = f.map_view
	var marks: Array = mv.exit_marks()
	var to_forest = marks.filter(func(m): return m["from"] == "town" and m["to"] == "forest")
	assert_eq(to_forest.size(), 1)
	assert_eq(to_forest[0]["kind"], "gate_closed", "奥の森の門は、まだ閉じている")
	assert_eq(marks.filter(func(m): return m["from"] == "town" and m["to"] == "rocks")[0]["kind"], "path")
	assert_eq(marks.filter(func(m): return m["from"] == "town" and m["to"] == "tw_1")[0]["kind"], "gate_closed")
	# 行ったことのないとなりのエリアは、うすい枠で出す（道の先にエリアがあると分かる）
	var next: Array = mv.unvisited_neighbors()
	for id in ["rocks", "hills", "forest", "lv_1", "tw_1"]:
		assert_true(id in next, id)
	assert_false("mt_1" in next, "道でつながっていないエリアは出さない")
	f.run.open_door("forest_gate")
	assert_eq(mv.exit_marks().filter(func(m): return m["from"] == "town" and m["to"] == "forest")[0]["kind"], "gate_open")

## 2026-11-26（3回目の直し）：全体マップは、エリアの本当の形で描く（島の外は透明）
func test_map_draws_area_shapes():
	var mv: WorldMapView = f.map_view
	var tex: ImageTexture = mv.shape_of("hills")
	assert_not_null(tex)
	var img := tex.get_image()
	var m: HeightMap = Continent.load_map(f.world.area("hills"))[0]
	assert_eq(img.get_size(), m.size)
	var clear := 0
	for y in m.size.y:
		for x in m.size.x:
			var c := Vector2i(x, y)
			assert_eq(img.get_pixel(x, y).a < 0.5, m.is_void(c), str(c))
			if m.is_void(c):
				clear += 1
	assert_gt(clear, 0, "四角でない形")

func test_map_follows_player_and_camera():
	f.toggle_map()
	f.player.mover.place(Vector2i(3, 4))
	f.camera.angle = 0.7
	f._process(0.016)
	assert_eq(f.map_view.player_pos, f.player.mover.pos)
	assert_almost_eq(f.map_view.view_angle, 0.7, 0.001)

## 画面の右上の方位：北（マップの上）が画面のどちらかを指す。カメラを回すと一緒に回る
func test_hud_compass_points_north():
	f.camera.angle = 0.0
	assert_true(f.hud.north_dir().is_equal_approx(Vector2.UP))
	f.camera.angle = PI / 2
	assert_true(f.hud.north_dir().is_equal_approx(Vector2.UP.rotated(-PI / 2)))
	# 北の向きへ歩くと、ワールドでは北（y が減る向き）へ進む
	var world: Vector2 = f.camera.screen_dir_to_world(f.hud.north_dir())
	assert_true(world.is_equal_approx(Vector2.UP))

## 持ち物のページ：持っている品物がアイコンで並び、カーソルを合わせると説明が出る（2026-11-25 夜）
func test_items_page_lists_icons_with_tips():
	var inv: Inventory = f.run.inventory
	inv.money = 12
	inv.add("herb", 3)
	inv.add("potion", 2)
	inv.add("seal_mt", 1)
	inv.equipment.gain("sword_flame")
	var ids: Array = f.menu.grid_items().map(func(r): return r[0])
	assert_eq(ids, ["money", "ball_1", "sword_flame", "seal_mt", "potion", "herb"])
	f.open_inventory()
	f.menu.show_page(InventoryMenu.Page.ITEMS)
	assert_eq(f.menu._items_box.get_child_count(), 6)
	var slot: Button = f.menu._items_box.get_child(2)
	slot.mouse_entered.emit()
	assert_true(f.menu.tip.visible)
	assert_eq(f.menu.tip.item_id, "sword_flame")
	var t: Array = f.menu.tip.texts("sword_flame")
	assert_string_contains(t[0], "炎の剣")
	assert_string_contains(t[1], "やけど")
	assert_false(t[1].contains("Lv12"), "装備のレベル制限はない")
	slot.mouse_exited.emit()
	assert_false(f.menu.tip.visible)

## 手に持つ物の箱：持っている武器だけアイコンが出て、弓は矢の数、杖は魔法の名前
func test_hotbar_slots_show_icons_and_counts():
	assert_eq(f.hotbar_slot(Hotbar.Item.IRON_BALL)["id"], "ball_1")
	assert_eq(f.hotbar_slot(Hotbar.Item.SWORD), {})
	f.run.inventory.equipment.gain("bow_1")
	f.run.inventory.add_arrows(Arrow.Kind.NORMAL, 7)
	assert_eq(f.hotbar_slot(Hotbar.Item.BOW)["count"], 7)
	f.run.inventory.equipment.gain("staff_none_1")
	f.hotbar.select_slot(4, f.run.inventory.equipment)
	assert_string_contains(f.hotbar_slot(Hotbar.Item.STAFF)["name"], "無の弾")
	f.run.inventory.add("bomb", 2)
	assert_eq(f.hotbar_slot(Hotbar.Item.TOOL)["id"], "bomb")
	assert_eq(f.hotbar_slot(Hotbar.Item.TOOL)["count"], 2)
