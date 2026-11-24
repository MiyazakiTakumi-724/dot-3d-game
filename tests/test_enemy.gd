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

func test_enemy_turns_at_water():
	var m := HeightMap.new(Vector2i(6, 3))
	m.set_water(Vector2i(3, 1), true)
	var w := EnemyWalker.new(m, Vector2i(1, 1), Vector2.RIGHT)
	for i in 200:
		w.step(0.05)
		assert_ne(w.cell(), Vector2i(3, 1))

func test_walker_custom_hp():
	var e := EnemyWalker.new(HeightMap.new(Vector2i(4, 4)), Vector2i(1, 1), Vector2.RIGHT, 1)
	assert_eq(e.hp, 1)
	e.take_damage(1)
	assert_false(e.alive)

## 体当たりは、同じ高さで体が触れているときだけ
func test_touches_needs_same_height():
	var map := HeightMap.new(Vector2i(4, 4))
	var e := EnemyWalker.new(map, Vector2i(1, 1), Vector2.RIGHT)
	assert_true(e.touches(e.pos + Vector2(6, 0), 0))
	assert_false(e.touches(e.pos + Vector2(6, 0), 1))
	assert_false(e.touches(e.pos + Vector2(16, 0), 0))
	e.take_damage(99)
	assert_false(e.touches(e.pos, 0))

func test_enemy_turns_at_void():
	var m := HeightMap.new(Vector2i(6, 3))
	m.set_void(Vector2i(3, 1), true)
	var w := EnemyWalker.new(m, Vector2i(1, 1), Vector2.RIGHT)
	for i in 200:
		w.step(0.05)
		assert_ne(w.cell(), Vector2i(3, 1))

func _flat() -> HeightMap:
	return HeightMap.new(Vector2i(8, 8))

func test_weak_walker_turns_at_one_level_step():
	var map := _flat()
	map.set_height(Vector2i(3, 1), 1)
	var w := EnemyWalker.new(map, Vector2i(1, 1), Vector2.RIGHT, 1, 0)
	for i in 60: w.step(1.0 / 30)
	assert_lt(w.pos.x, HeightMap.cell_center(Vector2i(3, 1)).x)

func test_melee_walker_climbs_one_level():
	var map := _flat()
	for x in range(3, 8):
		map.set_height(Vector2i(x, 1), 1)
	var w := EnemyWalker.new(map, Vector2i(1, 1), Vector2.RIGHT, 2, 1)
	for i in 60: w.step(1.0 / 30)
	assert_eq(w.height, 1)

func test_melee_walker_never_enters_two_level_step():
	var map := _flat()
	map.set_height(Vector2i(3, 1), 2)
	map.set_water(Vector2i(1, 2), true)
	var w := EnemyWalker.new(map, Vector2i(2, 1), Vector2.RIGHT, 2, 1)
	w.forbidden[Vector2i(1, 1)] = true
	for i in 300:
		w.chase(HeightMap.cell_center(Vector2i(3, 1)), 2)
		w.step(1.0 / 30)
		var c := w.cell()
		assert_true(c != Vector2i(3, 1) and c != Vector2i(1, 2) and c != Vector2i(1, 1))

func test_chase_only_within_48px():
	var w := EnemyWalker.new(_flat(), Vector2i(1, 1), Vector2.UP, 2, 1)
	w.chase(w.pos + Vector2(60, 0), 0)
	assert_eq(w.dir, Vector2.UP)
	w.chase(w.pos + Vector2(40, 0), 0)
	assert_eq(w.dir, Vector2.RIGHT)

func test_weak_walker_does_not_chase():
	var w := EnemyWalker.new(_flat(), Vector2i(1, 1), Vector2.UP, 1, 0)
	w.chase(w.pos + Vector2(20, 0), 0)
	assert_eq(w.dir, Vector2.UP)

func test_kind_table():
	assert_eq(EnemyKind.hp(EnemyKind.Kind.WEAK), 1)
	assert_eq(EnemyKind.hp(EnemyKind.Kind.MELEE), 2)
	assert_eq(EnemyKind.climb(EnemyKind.Kind.MELEE), 1)
	assert_eq(EnemyKind.climb(EnemyKind.Kind.SHOOTER), 0)
	assert_true(EnemyKind.shoots(EnemyKind.Kind.SHOOTER))
	assert_false(EnemyKind.contact(EnemyKind.Kind.MELEE))
	assert_true(EnemyKind.contact(EnemyKind.Kind.WEAK))
