extends GutTest
## ダメージの式（design.md 17章）。

func test_iron_ball_examples_from_design():
	assert_eq(Damage.iron_ball(5, 0, 1), 5)
	assert_eq(Damage.iron_ball(5, 1, 1), 7)  # 7.5 を切り捨て
	assert_eq(Damage.iron_ball(5, 0, 6), 7)
	assert_eq(Damage.iron_ball(5, 2, 1), 10)

func test_iron_ball_never_below_one():
	assert_eq(Damage.iron_ball(0, 0, 1), 1)

func test_iron_ball_below_own_height_counts_as_zero():
	assert_eq(Damage.iron_ball(5, -1, 1), 5)

func test_enemy_hit_and_easy_mode():
	assert_eq(Damage.enemy_hit(3), 3)
	assert_eq(Damage.enemy_hit(3, true), 1)
	assert_eq(Damage.enemy_hit(4, true), 2)
	assert_eq(Damage.enemy_hit(1, true), 1)

func test_enemy_stats_grow_20_percent_per_level():
	assert_eq(Damage.enemy_scaled(5, 1), 5)
	assert_eq(Damage.enemy_scaled(5, 3), 7)  # 5 × 1.4
	assert_eq(Damage.enemy_scaled(10, 2), 12)
