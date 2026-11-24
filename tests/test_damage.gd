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

## 剣：攻撃力 × 0.6 ×（1 ＋ 剣のポイント × 0.1）。初期状態で3（17.3）
func test_sword():
	assert_eq(Damage.sword(5, 0, 0), 3)
	assert_eq(Damage.sword(5, 5, 0), 4)  # 3 × 1.5 = 4.5

## 落下斬り：×（1 ＋ 落ちた段数 × 0.5）。技能「落下斬り強化」で 0.75
func test_falling_slash():
	assert_eq(Damage.sword(5, 0, 2), 6)
	assert_eq(Damage.sword(5, 0, 2, true), 7)  # 3 × 2.5 = 7.5

## 弓：攻撃力 × チャージ率 × 矢の倍率 ×（1 ＋ 弓のポイント × 0.1）。フルチャージで5（17.4）
func test_bow():
	assert_eq(Damage.bow(5, 1.0, 1.0, 0), 5)
	assert_eq(Damage.bow(5, 0.3, 1.0, 0), 1)
	assert_eq(Damage.bow(5, 1.0, 0.5, 0), 2)
	assert_eq(Damage.bow(5, 1.0, 1.0, 0, 2), 10)  # 高所射撃で2段下

## 魔法：つよさ × 魔法の倍率 ×（1 ＋ 魔法のポイント × 0.1）× 高所の有利
func test_magic():
	assert_eq(Damage.magic(10, 0.6, 0), 6)
	assert_eq(Damage.magic(10, 0.6, 5), 9)
	assert_eq(Damage.magic(10, 1.2, 0, 1), 15)

## 高所の有利：自分より低い敵を剣で攻めると、1段につき×（1 ＋ 0.25）【提案】
func test_sword_high_ground():
	assert_eq(Damage.sword(10, 0, 0, false, 0), 6)
	assert_eq(Damage.sword(10, 0, 0, false, 1), 7)  # 6 × 1.25 = 7.5
	assert_eq(Damage.sword(10, 0, 0, false, 2), 9)  # 6 × 1.5
	assert_eq(Damage.high_ground(2), 1.5)
	assert_eq(Damage.high_ground(-1), 1.0)  # 下から攻めても減らない
