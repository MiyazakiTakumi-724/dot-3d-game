extends GutTest
## 剣（design.md 7章、17.3）。同じ高さと1段下に当たる。振る間隔は0.4秒。

func test_hits_in_front_same_height():
	assert_true(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(16, 0), 2))
	assert_true(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(12, 8), 2))

func test_misses_behind_and_far():
	assert_false(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(-16, 0), 2))
	assert_false(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(30, 0), 2))
	assert_false(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(0, 16), 2))

func test_very_close_hits_any_direction():
	assert_true(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(-3, 2), 2))

func test_one_below_hits_but_not_above_or_two_below():
	assert_true(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(16, 0), 1))
	assert_false(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(16, 0), 0))
	assert_false(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(16, 0), 3))


func test_swing_interval():
	var s := Sword.new()
	assert_true(s.try_swing())
	assert_false(s.try_swing())
	s.update(0.3)
	assert_false(s.try_swing())
	s.update(0.11)
	assert_true(s.try_swing())


## 回転斬り：周りの敵をまとめて斬る（後ろにも当たる）
func test_spin_hits_all_around():
	assert_true(Sword.hits_around(Vector2.ZERO, 2, Vector2(-16, 0), 2))
	assert_true(Sword.hits_around(Vector2.ZERO, 2, Vector2(0, 18), 1))
	assert_false(Sword.hits_around(Vector2.ZERO, 2, Vector2(0, 30), 2))
	assert_false(Sword.hits_around(Vector2.ZERO, 2, Vector2(0, 10), 3))

func test_spin_has_longer_interval():
	var s := Sword.new()
	assert_true(s.try_spin())
	s.update(Sword.INTERVAL + 0.01)
	assert_false(s.try_swing())
	s.update(Sword.SPIN_INTERVAL)
	assert_true(s.try_swing())

## 技能「突き」：前へ細く長く届く（斬り上げの代わり。2026-11-24 決定）
func test_thrust_reaches_farther_in_front():
	assert_false(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(30, 0), 2))
	assert_true(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(30, 0), 2, true))
	assert_false(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(Sword.THRUST_REACH + 2, 0), 2, true))
	# 細いので、斜め前の遠くには届かない
	assert_false(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(26, 18), 2, true))
	# 上へは届かない
	assert_false(Sword.hits(Vector2.ZERO, 2, Vector2.RIGHT, Vector2(30, 0), 3, true))
	assert_eq(PlayerStats.SKILLS[PlayerStats.Stat.SWORD][1], "突き")
