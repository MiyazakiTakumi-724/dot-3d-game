extends GutTest
## 鉤縄（2026-11-26 独自の開発1）。

func _map() -> HeightMap:
	var m := HeightMap.new(Vector2i(10, 3))
	m.set_height(Vector2i(3, 1), 2)
	m.set_height(Vector2i(4, 1), 4)
	m.set_height(Vector2i(5, 1), 6)
	m.set_wall(Vector2i(2, 0), true)
	return m

func test_hooks_onto_higher_ground_in_reach():
	var m := _map()
	var from := HeightMap.cell_center(Vector2i(1, 1))
	assert_eq(Hook.ledge(m, from, 0, HeightMap.cell_center(Vector2i(3, 1))), Vector2i(3, 1), "2段上")
	assert_eq(Hook.ledge(m, from, 0, HeightMap.cell_center(Vector2i(4, 1))), Vector2i(-1, -1), "4段上は高すぎる")
	assert_eq(Hook.ledge(m, from, 2, HeightMap.cell_center(Vector2i(4, 1))), Vector2i(4, 1), "2段の所からなら4段へ")
	assert_eq(Hook.ledge(m, from, 0, HeightMap.cell_center(Vector2i(0, 1))), Vector2i(-1, -1), "同じ高さには使わない")
	assert_eq(Hook.ledge(m, from, 0, HeightMap.cell_center(Vector2i(2, 0))), Vector2i(-1, -1), "壁")

func test_hook_range():
	var m := _map()
	m.set_height(Vector2i(9, 1), 1)
	assert_eq(Hook.ledge(m, HeightMap.cell_center(Vector2i(1, 1)), 0, HeightMap.cell_center(Vector2i(9, 1))), Vector2i(-1, -1), "遠すぎる")
	assert_true(Hook.reaches(Vector2.ZERO, Vector2(50, 0)))
	assert_false(Hook.reaches(Vector2.ZERO, Vector2(60, 0)))

func test_cooldown():
	var h := Hook.new()
	assert_true(h.is_ready())
	h.use()
	assert_false(h.is_ready())
	h.update(Hook.COOLDOWN)
	assert_true(h.is_ready())

# ---------------------------------------------------------------- 画面の中で（field）

func _field():
	var f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)
	var m := HeightMap.new(Vector2i(8, 3))
	m.set_height(Vector2i(3, 1), 3)
	m.set_height(Vector2i(4, 1), 3)
	f.map = m
	f.player.mover.map = m
	f.player.mover.place(Vector2i(1, 1))
	for e in f.enemies:
		e.queue_free()
	f.enemies.clear()
	return f

func test_needs_the_hook():
	var f = _field()
	assert_false(f.use_hook(f.camera.world_to_screen(HeightMap.cell_center(Vector2i(3, 1)), 24.0)))

func test_hook_pulls_the_hero_up_a_ledge():
	var f = _field()
	f.run.inventory.add(Hook.ID)
	var screen: Vector2 = f.camera.world_to_screen(HeightMap.cell_center(Vector2i(3, 1)), 3 * StackSprite.LEVEL_PX)
	assert_true(f.use_hook(screen))
	assert_true(f.hook_pulling())
	assert_false(f.player.controllable)
	for i in 30:
		f._step_hook(1.0 / 60.0)
	assert_false(f.hook_pulling())
	assert_eq(f.player.mover.cell(), Vector2i(3, 1))
	assert_eq(f.player.mover.height, 3, "3段上に立った")
	assert_true(f.player.controllable)
	assert_false(f.use_hook(screen), "待ち時間の間は使えない")

func test_hook_drags_an_enemy_down_from_a_ledge():
	var f = _field()
	f.run.inventory.add(Hook.ID)
	var e := Enemy.new()
	e.setup(f.map, Vector2i(3, 1), Vector2.RIGHT, f.player, f.camera, EnemyKind.Kind.SHOOTER, Enemy.SHOOT_INTERVAL, 10)
	add_child_autofree(e)
	f._wire_enemy(e)
	f.enemies.append(e)
	var hp := e.walker.hp
	var screen: Vector2 = f.camera.world_to_screen(e.walker.pos, e.walker.height * StackSprite.LEVEL_PX + 4.0)
	assert_true(f.use_hook(screen))
	assert_true(e.walker.knocking())
	for i in 40:
		e._process(1.0 / 40.0)
	assert_eq(e.walker.height, 0, "台から引きずり下ろした")
	assert_lt(e.walker.hp, hp, "3段落ちて痛い")
