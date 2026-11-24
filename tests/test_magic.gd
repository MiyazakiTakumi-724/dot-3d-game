extends GutTest
## 魔法（2026-11-24 決定）：装備する杖で使える魔法が決まる（杖ごとの魔法は ItemCatalog）。
## ステータスの「魔法」で、同時に使える数（1〜3）が決まる。

## 炎の雨は、高い所から使うほど広い
func test_rain_radius_grows_with_height():
	assert_eq(Magic.rain_radius(2, 2), Magic.RAIN_BASE_RADIUS)
	assert_eq(Magic.rain_radius(4, 2), Magic.RAIN_BASE_RADIUS + 2 * Magic.RAIN_RADIUS_PER_LEVEL)
	assert_eq(Magic.rain_radius(0, 2), Magic.RAIN_BASE_RADIUS)

## 魔法ごとに待ち時間がある。ほかの魔法は（少しの間をおけば）使える
func test_spell_cooldown():
	var m := Magic.new()
	var mana := Mana.new()
	mana.max_value = 200
	mana.value = 200.0
	assert_true(m.try_cast(Magic.Spell.FIREBALL, mana))
	m.update(Magic.INTERVAL)
	assert_false(m.try_cast(Magic.Spell.FIREBALL, mana))
	assert_gt(m.remaining(Magic.Spell.FIREBALL), 0.0)
	assert_true(m.try_cast(Magic.Spell.FIRE_PILLAR, mana))
	m.update(Magic.COOLDOWN[Magic.Spell.FIREBALL])
	assert_eq(m.remaining(Magic.Spell.FIREBALL), 0.0)
	assert_true(m.try_cast(Magic.Spell.FIREBALL, mana))

## マナの燃費は悪い：満タン（50）から無の弾は5発、炎の雨は1回まで【提案】
func test_mana_costs_are_high():
	assert_eq(Mana.BASE_MAX / Magic.COST[Magic.Spell.NULL_BOLT], 5)
	assert_eq(Mana.BASE_MAX / Magic.COST[Magic.Spell.FIRE_RAIN], 1)

## 使うとマナが減り、少しの間は次を使えない。マナが足りなければ使えない
func test_cast_spends_mana_and_waits():
	var m := Magic.new()
	var mana := Mana.new()
	assert_true(m.try_cast(Magic.Spell.FIRE_RAIN, mana))
	assert_eq(mana.value, Mana.BASE_MAX - Magic.COST[Magic.Spell.FIRE_RAIN])
	assert_false(m.try_cast(Magic.Spell.NULL_BOLT, mana))
	m.update(100.0)
	mana.value = 3.0
	assert_false(m.try_cast(Magic.Spell.NULL_BOLT, mana))
	assert_eq(mana.value, 3.0)

## ホイールで、使える魔法の中から選ぶ（端は回り込む）
func test_select_cycles_spells():
	var m := Magic.new()
	var list := [Magic.Spell.FIREBALL, Magic.Spell.FIRE_PILLAR]
	assert_eq(m.current(list), Magic.Spell.FIREBALL)
	m.cycle(1, list)
	assert_eq(m.current(list), Magic.Spell.FIRE_PILLAR)
	m.cycle(1, list)
	assert_eq(m.current(list), Magic.Spell.FIREBALL)
	m.cycle(-1, list)
	assert_eq(m.current(list), Magic.Spell.FIRE_PILLAR)
	# 使える数が減ったら、範囲の中に戻す
	assert_eq(m.current([Magic.Spell.FIREBALL]), Magic.Spell.FIREBALL)
