extends GutTest

func test_enemy_stays_on_its_level():
	var map := HeightMap.new(Vector2i(8, 8))
	map.set_height(Vector2i(4, 1), 1)
	var e := EnemyWalker.new(map, Vector2i(1, 1), Vector2.RIGHT)
	for i in 300:
		e.step(0.016)
		assert_eq(map.get_height(HeightMap.world_to_cell(e.pos)), 0)

func test_enemy_turns_at_wall():
	var map := HeightMap.new(Vector2i(8, 8))
	map.set_wall(Vector2i(3, 1), true)
	var e := EnemyWalker.new(map, Vector2i(1, 1), Vector2.RIGHT)
	for i in 300:
		e.step(0.016)
		assert_ne(HeightMap.world_to_cell(e.pos), Vector2i(3, 1))

func test_enemy_dies_at_zero_hp():
	var e := EnemyWalker.new(HeightMap.new(Vector2i(4, 4)), Vector2i(1, 1), Vector2.RIGHT)
	watch_signals(e)
	e.take_damage(4)
	assert_signal_emitted(e, "died")
	assert_false(e.alive)

func test_enemy_survives_small_hit():
	var e := EnemyWalker.new(HeightMap.new(Vector2i(4, 4)), Vector2i(1, 1), Vector2.RIGHT)
	e.take_damage(1)
	assert_true(e.alive)
	assert_eq(e.hp, 2)

func test_dead_enemy_does_not_die_twice():
	var e := EnemyWalker.new(HeightMap.new(Vector2i(4, 4)), Vector2i(1, 1), Vector2.RIGHT)
	watch_signals(e)
	e.take_damage(4)
	e.take_damage(4)
	assert_signal_emit_count(e, "died", 1)

func test_enemy_turns_at_pit():
	var m := HeightMap.new(Vector2i(6, 3))
	m.set_pit(Vector2i(3, 1), true)
	var w := EnemyWalker.new(m, Vector2i(1, 1), Vector2.RIGHT)
	for i in 200:
		w.step(0.05)
		assert_ne(w.cell(), Vector2i(3, 1))
