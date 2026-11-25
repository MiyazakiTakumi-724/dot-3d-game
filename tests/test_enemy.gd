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

## 2026-11-25 夜に強くした（体力はおよそ3倍、攻撃力はおよそ1.6倍）
func test_kind_table():
	assert_eq(EnemyKind.hp(EnemyKind.Kind.WEAK), 14)
	assert_eq(EnemyKind.attack(EnemyKind.Kind.WEAK), 4)
	assert_eq(EnemyKind.hp(EnemyKind.Kind.MELEE), 28)
	assert_eq(EnemyKind.attack(EnemyKind.Kind.MELEE), 6)
	assert_eq(EnemyKind.climb(EnemyKind.Kind.MELEE), 1)
	assert_eq(EnemyKind.climb(EnemyKind.Kind.SHOOTER), 0)
	assert_true(EnemyKind.shoots(EnemyKind.Kind.SHOOTER))
	assert_false(EnemyKind.contact(EnemyKind.Kind.MELEE))
	assert_true(EnemyKind.contact(EnemyKind.Kind.WEAK))

## 斜めに追うとき、マスの角をすり抜けて2段上の崖に入らない（レビューの指摘）
func test_diagonal_chase_does_not_cut_corner_into_cliff():
	var m := HeightMap.new(Vector2i(12, 12))
	m.set_height(Vector2i(7, 6), 2)
	var w := EnemyWalker.new(m, Vector2i(6, 6), Vector2.RIGHT, 2, 1)
	for i in 600:
		w.chase(Vector2(130, 79.7), 0)
		w.step(1.0 / 60)
		assert_ne(w.cell(), Vector2i(7, 6))
		if w.cell() == Vector2i(7, 6):
			return

func test_chase_fuzz_never_enters_bad_cell():
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for run in 300:
		var m := HeightMap.new(Vector2i(10, 10))
		for y in 10:
			for x in 10:
				m.set_height(Vector2i(x, y), rng.randi_range(0, 3))
				if rng.randf() < 0.06:
					m.set_water(Vector2i(x, y), true)
		var start := Vector2i(5, 5)
		m.set_water(start, false)
		var w := EnemyWalker.new(m, start, Vector2.RIGHT, 2, 1)
		var target := Vector2(rng.randf_range(20, 140), rng.randf_range(20, 140))
		var prev := w.cell()
		for i in 240:
			w.chase(target, w.height)
			w.step(1.0 / 60)
			var c := w.cell()
			if c != prev:
				assert_false(m.is_water(c), "water %s" % c)
				assert_lte(absi(m.get_height(c) - m.get_height(prev)), 1, "step %s→%s" % [prev, c])
				prev = c

## 敵のレベルで体力と攻撃力が20%ずつ増える（17.1）
func test_kind_stats_scale_with_level():
	assert_eq(EnemyKind.hp(EnemyKind.Kind.WEAK, 3), 19)
	assert_eq(EnemyKind.attack(EnemyKind.Kind.WEAK, 3), 5)
	assert_eq(EnemyKind.exp_reward(EnemyKind.Kind.WEAK, 1), 4)
	assert_eq(EnemyKind.exp_reward(EnemyKind.Kind.MELEE, 2), 14)

func test_walker_remembers_max_hp():
	var w := EnemyWalker.new(_flat(), Vector2i(1, 1), Vector2.UP, 7, 0)
	w.take_damage(3)
	assert_eq([w.hp, w.max_hp], [4, 7])

## 毒：5秒間、毎秒1ダメージ（17.4）
func test_poison_ticks_once_per_second_for_five_seconds():
	var w := EnemyWalker.new(_flat(), Vector2i(1, 1), Vector2.UP, 20, 0)
	w.poison(5.0)
	assert_true(w.is_poisoned())
	var total := 0
	for i in 70:
		total += w.update_poison(0.1)
	assert_eq(total, 5 * EnemyWalker.DOT_DAMAGE)
	assert_eq(w.hp, 20 - 5 * EnemyWalker.DOT_DAMAGE)
	assert_false(w.is_poisoned())

## やけど（火の魔法）：毒と同じく毎秒1ダメージ。やけどの間は is_burning
func test_burn_ticks():
	var m := HeightMap.new(Vector2i(4, 4))
	var w := EnemyWalker.new(m, Vector2i(1, 1), Vector2.RIGHT, 30)
	w.burn(3.0)
	assert_true(w.is_burning())
	var total := 0
	for i in 40:
		total += w.update_poison(0.1)
	assert_eq(total, 3 * EnemyWalker.DOT_DAMAGE)
	assert_false(w.is_burning())
	w.poison(2.0)
	assert_false(w.is_burning())
