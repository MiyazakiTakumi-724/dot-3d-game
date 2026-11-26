extends GutTest
## 高低差の戦い（2026-11-26 独自の開発1）：敵を崖から突き落とす。

func _map(w: int, h: int) -> HeightMap:
	var m := HeightMap.new(Vector2i(w, h))
	return m

func _knock_to_end(wk: EnemyWalker) -> bool:
	for i in 60:
		if wk.update_knock(1.0 / 60.0):
			return true
	return false

func test_knock_pushes_on_flat_ground():
	var m := _map(8, 3)
	var wk := EnemyWalker.new(m, Vector2i(2, 1), Vector2.RIGHT, 50, 1)
	var x0 := wk.pos.x
	wk.knock(Vector2.RIGHT, 16.0)
	assert_true(wk.knocking())
	assert_true(_knock_to_end(wk))
	assert_almost_eq(wk.pos.x - x0, 16.0, 0.5)
	assert_false(wk.knocking())
	assert_eq(wk.last_fall_levels, 0)
	assert_eq(wk.hp, 50, "平らな所では痛くない")

func test_knock_off_a_high_ledge_hurts_by_levels():
	var m := _map(8, 3)
	for x in 3:
		for y in 3:
			m.set_height(Vector2i(x, y), 4)  # 左の3列は4段の台地
	var wk := EnemyWalker.new(m, Vector2i(2, 1), Vector2.RIGHT, 100, 1)
	wk.knock(Vector2.RIGHT, 18.0)
	assert_true(_knock_to_end(wk))
	assert_eq(wk.height, 0)
	assert_eq(wk.last_fall_levels, 4)
	assert_eq(wk.last_fall_damage, EnemyWalker.fall_damage(100, 4))
	assert_eq(wk.hp, 100 - EnemyWalker.fall_damage(100, 4))

func test_fall_damage_grows_with_levels():
	assert_eq(EnemyWalker.fall_damage(100, 0), 0)
	assert_eq(EnemyWalker.fall_damage(100, 1), 0, "1段は痛くない")
	assert_gt(EnemyWalker.fall_damage(100, 2), 0)
	assert_gt(EnemyWalker.fall_damage(100, 4), EnemyWalker.fall_damage(100, 2))
	assert_eq(EnemyWalker.fall_damage(100, 20), 100, "とても高い所からは倒れる")

func test_knock_cannot_push_uphill_or_into_walls():
	var m := _map(8, 3)
	m.set_height(Vector2i(3, 1), 2)
	m.set_wall(Vector2i(1, 1), true)
	var wk := EnemyWalker.new(m, Vector2i(2, 1), Vector2.RIGHT, 50, 1)
	wk.knock(Vector2.RIGHT, 30.0)
	_knock_to_end(wk)
	assert_eq(wk.cell(), Vector2i(2, 1), "高い所へは押しこめない")
	wk.knock(Vector2.LEFT, 30.0)
	_knock_to_end(wk)
	assert_eq(wk.cell(), Vector2i(2, 1), "壁へも押しこめない")

func test_knock_into_a_pit_kills():
	var m := _map(8, 3)
	m.set_pit(Vector2i(3, 1), true)
	var wk := EnemyWalker.new(m, Vector2i(2, 1), Vector2.RIGHT, 50, 1)
	wk.knock(Vector2.RIGHT, 20.0)
	_knock_to_end(wk)
	assert_false(wk.alive)
	assert_true(wk.fell_into_pit)

func test_flying_enemies_are_not_knocked():
	var m := _map(8, 3)
	var wk := EnemyWalker.new(m, Vector2i(2, 1), Vector2.RIGHT, 50, 1)
	wk.flying = true
	wk.knock(Vector2.RIGHT, 16.0)
	assert_false(wk.knocking())

func test_kinds_resist_knockback():
	assert_eq(EnemyKind.knock_mult(EnemyKind.Kind.MELEE), 1.0)
	assert_eq(EnemyKind.knock_mult(EnemyKind.Kind.DARK_KNIGHT), 0.0, "黒騎士は動かない")
	assert_eq(EnemyKind.knock_mult(EnemyKind.Kind.FLYER), 0.0, "飛ぶ敵は押せない")
	assert_lt(EnemyKind.knock_mult(EnemyKind.Kind.BEETLE), 1.0, "甲虫は重い")

# ---------------------------------------------------------------- 画面の中で（field）

func _field_on_ledge():
	var f = load("res://scenes/field.tscn").instantiate()
	add_child_autofree(f)
	f.run.inventory.equipment.gain("sword_1")
	f.hotbar.select_slot(2, f.run.inventory.equipment)
	var m := HeightMap.new(Vector2i(8, 3))
	for x in 3:
		for y in 3:
			m.set_height(Vector2i(x, y), 4)  # 左の3列は4段の台地、その右は低い地面
	f.map = m
	f.player.mover.map = m
	f.player.mover.place(Vector2i(1, 1))
	for e in f.enemies:
		e.queue_free()
	f.enemies.clear()
	var e := Enemy.new()
	e.setup(m, Vector2i(2, 1), Vector2.RIGHT, f.player, f.camera, EnemyKind.Kind.MELEE, Enemy.SHOOT_INTERVAL, 10)
	add_child_autofree(e)
	f._wire_enemy(e)
	f.enemies.append(e)
	e.walker.pos = f.player.mover.pos + Vector2(19, 0)  # 台地のふちの近く
	f.player.mover.facing = Vector2.RIGHT
	return [f, e]

func test_sword_knocks_an_enemy_off_the_ledge():
	var fe = _field_on_ledge()
	var f = fe[0]
	var e: Enemy = fe[1]
	var hp0 := e.walker.hp
	assert_true(f.swing_sword())
	assert_true(e.walker.knocking(), "剣で押される")
	var hp_after_hit := e.walker.hp
	assert_lt(hp_after_hit, hp0)
	for i in 30:
		e._process(1.0 / 30.0)
	assert_eq(e.walker.height, 0, "台地から落ちた")
	assert_eq(e.walker.hp, hp_after_hit - EnemyWalker.fall_damage(e.walker.max_hp, 4), "落ちた段数で痛い")

func test_arrows_do_not_knock():
	var fe = _field_on_ledge()
	var f = fe[0]
	var e: Enemy = fe[1]
	f.damage_target(e, 1, f.player.mover.pos, "", Color.WHITE, "arrow")
	assert_false(e.walker.knocking(), "矢は押さない（剣・鉄球・爆弾の役目）")
