extends GutTest
## ダメージの式（design.md 17章）。

## 2026-11-25 夜（2回目の直し）にダメージの式を見直した（docs/superpowers/specs/2026-11-25-tuning-2.md 2章）。
## つよさの基本を5から10にして、武器の倍率を半分にした（はじめのダメージは前と同じ。つよさ1ポイントで1割ずつ伸びる）。
## 鉄球：つよさ × 0.5 ×（1 ＋ 落とした高さ × 0.5）。レベルで勝手に強くなる分はやめた
func test_iron_ball():
	assert_eq(Damage.iron_ball(10, 0), 5)
	assert_eq(Damage.iron_ball(10, 1), 7)  # 7.5 を切り捨て
	assert_eq(Damage.iron_ball(10, 2), 10)
	assert_eq(Damage.iron_ball(12, 0), 6)

func test_iron_ball_never_below_one():
	assert_eq(Damage.iron_ball(0, 0), 1)

func test_iron_ball_below_own_height_counts_as_zero():
	assert_eq(Damage.iron_ball(10, -1), 5)

func test_enemy_hit_and_easy_mode():
	assert_eq(Damage.enemy_hit(3), 3)
	assert_eq(Damage.enemy_hit(3, true), 1)
	assert_eq(Damage.enemy_hit(4, true), 2)
	assert_eq(Damage.enemy_hit(1, true), 1)

## 敵の体力・攻撃力：レベルが1上がるごとに、レベル1の値の15%ずつ（前は20%）
func test_enemy_stats_grow_15_percent_per_level():
	assert_eq(Damage.enemy_scaled(10, 1), 10)
	assert_eq(Damage.enemy_scaled(10, 3), 13)  # 10 × 1.3
	assert_eq(Damage.enemy_scaled(20, 2), 23)

## 剣：つよさ × 0.3 ×（1 ＋ 剣のポイント × 0.05）。はじめは3
func test_sword():
	assert_eq(Damage.sword(10, 0, 0), 3)
	assert_eq(Damage.sword(10, 10, 0), 4)  # 3 × 1.5 = 4.5

## 落下斬り：×（1 ＋ 落ちた段数 × 0.5）。技能「落下斬り強化」で 0.75
func test_falling_slash():
	assert_eq(Damage.sword(10, 0, 2), 6)
	assert_eq(Damage.sword(10, 0, 2, true), 7)  # 3 × 2.5 = 7.5

## 弓：つよさ × 0.5 × チャージ率 × 矢の倍率 ×（1 ＋ 弓のポイント × 0.05）。フルチャージで5
func test_bow():
	assert_eq(Damage.bow(10, 1.0, 1.0, 0), 5)
	assert_eq(Damage.bow(10, 0.3, 1.0, 0), 1)
	assert_eq(Damage.bow(10, 1.0, 0.5, 0), 2)
	assert_eq(Damage.bow(10, 1.0, 1.0, 0, 2), 10)  # 高所射撃で2段下
	assert_eq(Damage.bow(10, 1.0, 1.0, 10), 7)  # 5 × 1.5 = 7.5

## 魔法：つよさ × 0.5 × 魔法の倍率 ×（1 ＋ 魔法のポイント × 0.05）。高さによる上乗せはない
func test_magic():
	assert_eq(Damage.magic(20, 0.6, 0), 6)
	assert_eq(Damage.magic(20, 0.6, 10), 9)
	assert_eq(Damage.magic(10, 1.2, 0), 6)

## 下から上へは攻撃できない（1段でも上の相手には当たらない）。同じ高さと下へは当たる（2026-11-24 決定）
func test_cannot_attack_upward():
	assert_true(Damage.can_hit(2, 2))
	assert_true(Damage.can_hit(2, 0))
	assert_false(Damage.can_hit(2, 3))

## 守り（防具の def と守りの薬）：受けるダメージがその数だけ減る。最低1
func test_defense_reduces_enemy_hit():
	assert_eq(Damage.enemy_hit(6, false, 2), 4)
	assert_eq(Damage.enemy_hit(3, false, 5), 1)
	assert_eq(Damage.enemy_hit(6, true, 1), 2)
