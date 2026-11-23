extends GutTest

var area

func before_each():
	area = load("res://scenes/area_02.tscn").instantiate()
	add_child_autofree(area)

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
		assert_eq(en.walker.hp, EnemyWalker.MAX_HP)

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

func test_select_strong_ball_needs_it():
	assert_false(area.select_ball(true))
	area.run.inventory.has_strong_ball = true
	assert_true(area.select_ball(true))
	assert_true(area.ball.rules_ball.strong)

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
