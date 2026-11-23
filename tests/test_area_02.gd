extends GutTest

var area

func before_each():
	area = load("res://scenes/area_02.tscn").instantiate()
	add_child_autofree(area)

func after_each():
	get_tree().paused = false  # インベントリのテストが途中で失敗しても、ほかのテストを止めない

func _finish_death():
	area.area_state.update(10.0)
	area.respawn()

func _beside_start(dx: int) -> Vector2i:
	return Vector2i(area.PLAYER_START.x + dx, area.PLAYER_START.y)

func test_death_places_grave_and_respawns_at_checkpoint():
	area.run.inventory.money = 30
	var c := _beside_start(2)
	area.player.mover.place(c)
	area.kill_player(false)
	assert_eq(area.run.grave.cell, c)
	assert_true(area.map.is_grave(c))
	_finish_death()
	assert_eq(area.player.mover.cell(), area.PLAYER_START)
	assert_eq(area.player.hp, Player.MAX_HP)
	assert_eq(area.run.inventory.money, 15)

func test_respawn_clears_bullets_and_resets_enemies():
	var e: Enemy = area.enemies[0]
	e.walker.take_damage(99)
	var b := Bullet.new()
	b.pos = area.player.mover.pos + Vector2(40, 0)
	area._on_enemy_shot(b)
	area.kill_player(false)
	_finish_death()
	assert_eq(area._bullets.size(), 0)
	assert_eq(area.enemies.size(), area.ENEMIES.size())
	for en in area.enemies:
		assert_true(en.walker.alive)
		assert_eq(en.walker.hp, area.ENEMY_HP)

func test_new_death_moves_grave_marker():
	var c1 := _beside_start(2)
	area.player.mover.place(c1)
	area.kill_player(false)
	_finish_death()
	var c2 := _beside_start(3)
	area.player.mover.place(c2)
	area.kill_player(false)
	assert_false(area.map.is_grave(c1))
	assert_true(area.map.is_grave(c2))

func test_ball_on_grave_breaks_it():
	area.run.inventory.money = 30
	var c := _beside_start(2)
	area.player.mover.place(c)
	area.kill_player(false)
	_finish_death()
	var p: PlayerMover = area.player.mover
	p.place(Vector2i(c.x - 1, c.y))
	p.facing = Vector2.RIGHT
	var ball: IronBall = area.ball.rules_ball
	assert_true(ball.drop(p, area.map))
	ball.update(1.0, p, area.map, area.rules)
	assert_null(area.run.grave)
	assert_false(area.map.is_wall(c))
	assert_eq(area.run.inventory.money, 30)

func test_fall_puts_grave_on_last_safe_cell():
	# 奈落の隣の安全なマスを地図から探して、そこから奈落へ歩かせる
	var safe := Vector2i(-1, -1)
	for y in area.map.size.y:
		for x in area.map.size.x:
			var c := Vector2i(x, y)
			var left := Vector2i(x - 1, y)
			if area.map.is_pit(c) and not area.map.is_pit(left) and not area.map.is_wall(left):
				safe = left
	area.player.mover.place(safe)
	for i in 20:
		area.player.mover.move(Vector2(2, 0))
	area._process(0.016)
	assert_eq(area.area_state.result, AreaState.Result.DYING)
	assert_eq(area.run.grave.cell, safe)

func test_strong_ball_on_ground_goes_to_grave():
	area.run.inventory.has_strong_ball = true
	var ball: IronBall = area.ball.rules_ball
	ball.set_strong(true)
	var p: PlayerMover = area.player.mover
	p.facing = Vector2.RIGHT
	ball.drop(p, area.map)
	area.kill_player(false)
	_finish_death()
	assert_eq(ball.state, IronBall.State.HELD)
	assert_false(ball.strong)
	assert_true(area.run.grave.has_strong_ball)

func test_death_from_damage():
	area.player.set_hp(0)
	area._process(0.016)
	assert_eq(area.area_state.result, AreaState.Result.DYING)
	assert_not_null(area.run.grave)

func test_walking_on_pickup_collects_it():
	var p = area.PICKUPS[0]
	area.player.mover.place(p[0])
	area._process(0.016)
	assert_true(area.run.is_picked(0))
	assert_eq(area.run.inventory.money, p[2])

func test_door_opens_only_from_far_side():
	var door: Vector2i = area.doors[0]
	var mover: PlayerMover = area.player.mover
	mover.place(door + Vector2i.LEFT)   # 手前側（近道の通路）
	mover.facing = Vector2.RIGHT
	assert_false(area.try_open_door())
	assert_true(area.map.is_wall(door))
	mover.place(area.DOOR_OPEN_FROM[0])
	mover.facing = Vector2(door - area.DOOR_OPEN_FROM[0])
	assert_true(area.try_open_door())
	assert_false(area.map.is_wall(door))
	assert_true(area.run.is_door_open(0))

func test_open_door_stays_open_after_death():
	var mover: PlayerMover = area.player.mover
	mover.place(area.DOOR_OPEN_FROM[0])
	mover.facing = Vector2(area.doors[0] - area.DOOR_OPEN_FROM[0])
	area.try_open_door()
	area.kill_player(false)
	_finish_death()
	assert_false(area.map.is_wall(area.doors[0]))

func test_heal_item():
	area.run.inventory.heals = 1
	area.player.mover.place(area.goal)  # チェックポイントから遠い所
	area.player.set_hp(1)
	assert_true(area.use_heal())
	assert_eq(area.player.hp, 2)
	assert_false(area.use_heal())

func test_checkpoint_heals_fully():
	area.player.set_hp(1)
	area.player.mover.place(area.checkpoint + Vector2i.RIGHT)
	area._process(0.016)
	assert_eq(area.player.hp, Player.MAX_HP)

func test_goal_clears():
	area.player.mover.place(area.goal)
	area._process(0.016)
	assert_eq(area.area_state.result, AreaState.Result.CLEAR)

func test_killing_enemy_gives_money_and_exp():
	area.enemies[0].walker.take_damage(99)
	assert_eq(area.run.inventory.money, RunState.ENEMY_MONEY)
	assert_eq(area.run.inventory.exp, RunState.ENEMY_EXP)

func test_no_control_while_dying():
	area.kill_player(false)
	assert_false(area.player.controllable)
	_finish_death()
	assert_true(area.player.controllable)

func test_old_enemy_shot_after_respawn_is_ignored():
	var old: Enemy = area.enemies[0]
	area.kill_player(false)
	_finish_death()
	var b := Bullet.new()
	b.pos = area.player.mover.pos + Vector2(40, 0)
	old.shot.emit(b)
	assert_eq(area._bullets.size(), 0)

func _screen_of(cell: Vector2i) -> Vector2:
	return area.camera.world_to_screen(HeightMap.cell_center(cell), area.map.get_height(cell) * StackSprite.LEVEL_PX)

func _aim_from(cell: Vector2i, offset: Vector2, target: Vector2i) -> Vector2i:
	var p: Player = area.player
	p.mover.place(cell)
	p.mover.pos += offset
	area.camera.focus = p.mover.pos
	p.aim_at_screen(_screen_of(target))
	return p.mover.front_cell()

func test_aim_hits_cell_under_cursor():
	assert_eq(_aim_from(_beside_start(1), Vector2.ZERO, _beside_start(2)), _beside_start(2))
	var below := _beside_start(1) + Vector2i.DOWN
	assert_eq(_aim_from(_beside_start(1), Vector2.ZERO, below), below)

## マスの角に立っていても、カーソルのマスに落ちる
func test_aim_from_cell_corner():
	assert_eq(_aim_from(_beside_start(1), Vector2(6, -6), _beside_start(2)), _beside_start(2))

## 高台から下のマスを指すと、そのマスに落ちる（高さの違いで斜めにずれない）
func test_aim_down_from_high_ground():
	# 2段以上の崖の上で、左隣が下の地面になっている所を地図から探す
	var m: HeightMap = area.map
	var top := Vector2i(-1, -1)
	for y in m.size.y:
		for x in m.size.x:
			var c := Vector2i(x, y)
			var l := c + Vector2i.LEFT
			if top.x < 0 and not m.is_wall(c) and not m.is_wall(l) and not m.is_water(c) and not m.is_water(l) \
					and not m.is_pit(l) and m.get_height(c) - m.get_height(l) >= 2:
				top = c
	assert_gt(top.x, 0)
	var below := top + Vector2i.LEFT
	assert_eq(_aim_from(top, Vector2.ZERO, below), below)

func test_aim_with_rotated_camera():
	area.camera.angle = 0.9
	var below := _beside_start(1) + Vector2i.DOWN
	assert_eq(_aim_from(_beside_start(1), Vector2.ZERO, below), below)

func test_cursor_on_player_keeps_facing():
	var p: Player = area.player
	p.mover.place(_beside_start(1))
	area.camera.focus = p.mover.pos
	p.mover.facing = Vector2.RIGHT
	p.aim_at_screen(_screen_of(_beside_start(1)) + Vector2(2, 1))
	assert_eq(p.mover.facing, Vector2.RIGHT)

func test_real_left_click_drops_ball():
	var p: PlayerMover = area.player.mover
	p.place(_beside_start(1))
	p.facing = Vector2.RIGHT
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	area._unhandled_input(e)
	assert_ne(area.ball.rules_ball.state, IronBall.State.HELD)

func test_gate_opens_from_its_cell_whatever_the_facing():
	var mover: PlayerMover = area.player.mover
	mover.place(area.DOOR_OPEN_FROM[0])
	mover.facing = Vector2.UP
	assert_true(area.try_open_door())

func _drop_right_of_start() -> IronBall:
	var p: PlayerMover = area.player.mover
	p.place(_beside_start(1))
	p.facing = Vector2.RIGHT
	assert_true(area.use_item())
	var b: IronBall = area.ball.rules_ball
	b.update(1.0, p, area.map, area.rules)
	return b

func test_left_click_item_drops_ball():
	var b := _drop_right_of_start()
	assert_eq(b.state, IronBall.State.ON_GROUND)
	assert_eq(b.cell, _beside_start(2))

func test_heal_slot_uses_heal():
	area.run.inventory.heals = 1
	area.player.mover.place(area.goal)
	area.player.set_hp(1)
	area.hotbar.select_slot(2)
	assert_true(area.use_item())
	assert_eq(area.player.hp, 2)
	assert_eq(area.ball.rules_ball.state, IronBall.State.HELD)

func test_walk_over_ball_picks_it_up():
	var b := _drop_right_of_start()
	area.player.mover.place(_beside_start(2))
	area._process(0.016)
	assert_eq(b.state, IronBall.State.HELD)

func test_equip_applies_when_ball_back_in_hand():
	area.run.inventory.has_strong_ball = true
	var b := _drop_right_of_start()
	assert_true(area.menu.choose_ball(true))
	area._process(0.016)
	assert_false(b.strong)
	area.player.mover.place(_beside_start(2))
	area._process(0.016)
	assert_eq(b.state, IronBall.State.HELD)
	assert_true(b.strong)

func test_inventory_pauses_and_closes():
	assert_true(area.open_inventory())
	assert_true(get_tree().paused)
	assert_true(area.menu.is_open())
	area.close_inventory()
	assert_false(get_tree().paused)
	assert_false(area.menu.is_open())

func test_inventory_not_opened_while_dying():
	area.kill_player(false)
	assert_false(area.open_inventory())
	assert_false(get_tree().paused)

func test_menu_cannot_choose_strong_without_it():
	assert_false(area.menu.choose_ball(true))
	assert_false(area.run.inventory.equipped_strong)
	area.run.inventory.has_strong_ball = true
	assert_true(area.menu.choose_ball(true))
	assert_true(area.run.inventory.equipped_strong)

func test_aim_marker_on_drop_cell():
	var p: PlayerMover = area.player.mover
	p.place(_beside_start(1))
	p.facing = Vector2.RIGHT
	area._process(0.016)
	assert_false(area.aim_marker.force_hidden)
	assert_eq(area.aim_marker.world_pos, HeightMap.cell_center(_beside_start(2)))
	area.hotbar.select_slot(2)
	area._process(0.016)
	assert_true(area.aim_marker.force_hidden)

## 最初のステージの敵は、体力1で撃たない
func test_area_enemies_have_one_hp_and_do_not_shoot():
	assert_eq(area.ENEMY_HP, 1)
	for e in area.enemies:
		assert_eq(e.walker.hp, 1)
		assert_false(e.can_shoot)

## 敵に触れると1ダメージ。触れたままでも、1秒たつまでは次のダメージを受けない
func test_enemy_touch_damage_has_cooldown():
	var e: Enemy = area.enemies[0]
	area.player.mover.place(e.walker.cell())
	area.player.mover.pos = e.walker.pos
	area._process(0.016)
	assert_eq(area.player.hp, Player.MAX_HP - 1)
	for i in 10:
		area.player.mover.pos = e.walker.pos
		area._process(0.05)
	assert_eq(area.player.hp, Player.MAX_HP - 1)
	area.player._process(Player.INVULNERABLE_SECONDS)
	area.player.mover.pos = e.walker.pos
	area._process(0.016)
	assert_eq(area.player.hp, Player.MAX_HP - 2)

func test_respawn_clears_invulnerability():
	assert_true(area.player.take_hit())
	assert_false(area.player.take_hit())
	area.kill_player(false)
	_finish_death()
	assert_true(area.player.take_hit())

func test_messages_are_japanese():
	area.player.mover.place(area.DOOR_OPEN_FROM[0])
	assert_string_contains(area.ui_message(), "門を開ける")
	area.kill_player(false)
	assert_string_contains(area.ui_message(), "やられた")
	_finish_death()
	assert_string_contains(area.ui_message(), "墓石")

func test_start_hint_then_nothing():
	assert_string_contains(area.ui_message(), "旗")
	area._process(9.0)
	assert_eq(area.ui_message(), "")
